/*
 * Copyright (C) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const TAG: string = 'FileCache';

/**
 * Process-level cache of raw `.riv` byte buffers.
 *
 * Why bytes and not {@link File}: each {@link File} owns its own
 * {@link LifecycleScope} and native object; sharing one File across many views
 * would entangle their lifetimes. Caching at the byte layer lets every view build
 * its own File (and own its scope) while still skipping the repeated network/rawfile
 * IO for the same resource — the dominant cost when a list renders many cells of the
 * same `.riv`. (Per-cell `Napi_File_import` is a separate, later optimisation.)
 *
 * `getOrLoad` deduplicates concurrent loads of the same key: the first caller's
 * in-flight promise is shared by subsequent callers, so N simultaneous requests for
 * the same resource trigger exactly one fetch.
 */
export class FileCache {
  private static instance: FileCache | null = null;

  /**
   * Upper bound on cached entries. The cache is process-global and keyed by resource
   * identity; without a cap, every distinct `.riv` ever loaded would keep its byte
   * buffer alive for the process lifetime (a slow memory leak across long-lived apps
   * that touch many different files). A modest LRU bound keeps the dedup benefit for
   * hot resources (e.g. a RecyclerPage rendering the same file across cells) while
   * bounding worst-case residency.
   */
  private static readonly MAX_ENTRIES = 32;

  /** Cached byte buffers, keyed by resource key (resourceId/url/bytes-hash). Insertion
   * order tracks recency: the head is the least-recently-used (eviction victim). */
  private readonly cache: Map<string, ArrayBuffer> = new Map();
  /** In-flight loaders, so concurrent `getOrLoad` calls share a single fetch. */
  private readonly pending: Map<string, Promise<ArrayBuffer>> = new Map();

  private constructor() {}

  static getInstance(): FileCache {
    if (FileCache.instance === null) {
      FileCache.instance = new FileCache();
    }
    return FileCache.instance;
  }

  /**
   * Returns the cached buffer for `key`, or invokes `loader` (once, even under
   * concurrency), caches its result, and resolves all waiters with it.
   *
   * @param key Stable cache key (resourceId, url, or a bytes hash).
   * @param loader Produces the buffer when uncached. Called at most once per key
   *    while its load is in flight; failures are not cached.
   */
  getOrLoad(key: string, loader: () => Promise<ArrayBuffer>): Promise<ArrayBuffer> {
    const cached = this.cache.get(key);
    if (cached !== undefined) {
      // LRU bump: re-insert at the tail so this key is the most-recently-used.
      this.cache.delete(key);
      this.cache.set(key, cached);
      return Promise.resolve(cached);
    }
    const pendingLoad = this.pending.get(key);
    if (pendingLoad !== undefined) {
      return pendingLoad;
    }
    const load = loader()
      .then((buffer: ArrayBuffer) => {
        this.put(key, buffer);
        this.pending.delete(key);
        return buffer;
      })
      .catch((error: Error) => {
        // Do not cache failures; let a later retry re-attempt the load.
        this.pending.delete(key);
        console.error(`${TAG}: load failed for key ${key}: ${error}`);
        throw error;
      });
    this.pending.set(key, load);
    return load;
  }

  /**
   * Inserts `buffer` under `key`, evicting the least-recently-used entry when the cache
   * exceeds {@link MAX_ENTRIES}. Re-inserting an existing key refreshes its recency
   * (Map re-set moves it to the tail) rather than counting as a new entry.
   */
  private put(key: string, buffer: ArrayBuffer): void {
    // Map.set on an existing key updates the value in place (does NOT move it to the
    // tail), so delete first to guarantee a tail insertion for the LRU order.
    if (this.cache.has(key)) {
      this.cache.delete(key);
    }
    this.cache.set(key, buffer);
    while (this.cache.size > FileCache.MAX_ENTRIES) {
      // Map iteration order is insertion order; the first key is the LRU victim.
      // `for...of` over Map.keys() yields typed keys directly (no IteratorResult.value
      // access), so it satisfies arkts-no-any-unknown without materialising the whole
      // key set into an array just to read the first element.
      let lruKey: string | null = null;
      for (const k of this.cache.keys()) {
        lruKey = k;
        break;
      }
      if (lruKey === null) {
        break;
      }
      this.cache.delete(lruKey);
    }
  }

  /** Computes a cache key for an in-memory byte buffer. */
  static bytesKey(bytes: ArrayBuffer): string {
    // A content-derived key that resists collisions without a full-content scan.
    // Sampling only head/mid/tail (3 bytes) collided across distinct same-length buffers;
    // we instead stride-spread ~256 samples (every len/256 bytes) plus the head/tail and
    // fold them with FNV-1a, a cheap non-crypto hash. Discriminates realistic `.riv`
    // inputs while staying O(256) regardless of file size.
    const view = new Uint8Array(bytes);
    const len = view.byteLength;
    if (len === 0) {
      return 'bytes:0';
    }
    // FNV-1a 32-bit (TS numbers are doubles; mask to 32 bits to stay integral).
    // Inlined (no closure) so every value keeps a concrete `number` type under ArkTS.
    let hash = 0x811c9dc5;
    const foldInto = (h: number, b: number): number => {
      h ^= b & 0xff;
      // h *= FNV prime 0x01000193, keep low 32 bits.
      return (h + ((h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24))) >>> 0;
    };
    hash = foldInto(hash, len & 0xff);
    hash = foldInto(hash, (len >>> 8) & 0xff);
    hash = foldInto(hash, (len >>> 16) & 0xff);
    hash = foldInto(hash, (len >>> 24) & 0xff);
    const samples = Math.min(256, len);
    const stride = len > samples ? len / samples : 1;
    for (let i = 0; i < samples; i++) {
      // Clamp to len-1: with a fractional stride, i*stride for the last index can round
      // up to >= len, and view[oob] is `undefined` -> `undefined & 0xff` is NaN, which
      // collapses the whole hash to 0 (NaN >>> 0). Clamping keeps every fold in range.
      const idx = Math.min(Math.floor(i * stride), len - 1);
      hash = foldInto(hash, view[idx]);
    }
    hash = foldInto(hash, view[len - 1]);
    return `bytes:${len}:${(hash >>> 0).toString(16)}`;
  }
}
