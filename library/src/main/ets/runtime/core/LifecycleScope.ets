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

import { AtomicInteger } from './RefCount';

/**
 * A cooperative lifetime token owned by a {@link File}.
 *
 * Background: Rive asset loaders (CDN/hosted fonts, custom network loaders) fetch
 * bytes asynchronously. Their completion callbacks capture a {@link FileAsset} JS
 * wrapper, which holds a *raw* native pointer that is owned and destroyed by the
 * parent {@link File}. If the File is released (view teardown, `setRiveFile`
 * swapping the file) while a fetch is in flight, a late callback calling
 * `asset.decode()` would dereference the now-freed native object and crash
 * (SIGSEGV).
 *
 * The scope fixes this structurally instead of with scattered boolean flags: each
 * File owns a scope; async continuations read {@link alive} before touching native
 * state; {@link cancel} is invoked exactly once when the File is disposed. A
 * cancelled scope makes every in-flight callback skip the unsafe native call, so
 * the bug cannot recur regardless of whether the File is freed by teardown or by
 * a file swap.
 *
 * The alive flag is atomic so the cancel (on the releasing thread) and the
 * `alive` read (on the HTTP-resume microtask) race safely.
 */
export class LifecycleScope {
  private readonly _alive: AtomicInteger;

  constructor() {
    // 1 = alive, 0 = cancelled.
    this._alive = new AtomicInteger(1n);
  }

  /** True while the owning File is still alive; false once it has been disposed. */
  get alive(): boolean {
    return this._alive.get() !== 0n;
  }

  /** Mark the scope cancelled. Idempotent; safe to call more than once. */
  cancel(): void {
    this._alive.set(0n);
  }
}
