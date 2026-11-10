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

import rive from 'libohos_rive.so';
import { RendererType } from '../renderers/RendererType';
import { FileAsset } from './FileAsset';
import { NativeObject } from './NativeObject';
import { LifecycleScope } from './LifecycleScope';
import { HttpService } from '../services/HttpService';

/**
 * Base class for asset loading. Overload loadContents to customize the loading process.
 *
 *  - Allows choosing how assets (images, fonts, audio) are loaded when referenced by a Rive file.
 *  - Asset loaders are typed to a specific {@link RendererType} because images are renderer specific.
 *  - The loader creates {@link FileAsset}s, so it must share renderer details with C++.
 */
export abstract class FileAssetLoader extends NativeObject {
  protected rendererType: RendererType | null = null;
  // Lifetime scope of the File currently being imported. `loadContents` is invoked
  // synchronously by the native import, and async asset loaders (CDN/custom network)
  // capture THIS scope into their completion callbacks. The owning File cancels its
  // scope on disposal, which makes any late decode skip its native call instead of
  // dereferencing a freed FileAsset (SIGSEGV). Null until a File attaches its scope.
  private _currentScope: LifecycleScope | null = null;

  protected constructor() {
    super(NativeObject.NULL_POINTER);
    const pointer = this.constructorCpp();
    if (pointer === NativeObject.NULL_POINTER) {
      throw new Error('Failed to create FileAssetLoader native instance.');
    }
    this.cppPointer = pointer;
    this.refs.incrementAndGet();
  }

  /**
   * Attaches the importing File's lifetime scope. Called by {@link File} immediately
   * before the native import so that `loadContents` reads the correct scope.
   */
  attachScope(scope: LifecycleScope): void {
    this._currentScope = scope;
  }

  /** The File lifetime currently associated with this loader (null before first import). */
  get currentScope(): LifecycleScope | null {
    return this._currentScope;
  }

  /**
   * Captures the importing File's lifetime scope as an alive-check closure. Async
   * loaders MUST call this at `loadContents` entry and consult the returned closure
   * before `asset.decode()` in their completion callback.
   *
   * Reading `currentScope`/`isReleased` at *callback* time is incorrect: a later
   * import reuses the loader and `attachScope` overwrites the current scope, so a late
   * callback from an earlier (already-disposed) File would observe the NEW scope still
   * alive and decode a freed native FileAsset (SIGSEGV). Capturing at entry binds the
   * check to THIS import's File scope. Returns `true` while the scope is alive (or when
   * no scope was ever attached — matching the historical fall-through behavior).
   */
  protected captureScopeAlive(): () => boolean {
    const scope = this._currentScope;
    return () => scope === null || scope.alive;
  }

  /**
   * Attach the importing File's lifetime scope to a dispatched {@link FileAsset}.
   * Loaders that retain the asset beyond `loadContents` (e.g. a custom loader
   * caching assets for later background download) MUST call this on the asset at
   * `loadContents` entry. The asset then self-invalidates its native pointer once
   * the File is disposed (scope cancelled), so a late callback writing to the
   * asset after teardown/swap skips native instead of SIGSEGV (the native
   * FileAsset is freed by the rive runtime with the File, not tracked by the JS
   * wrapper's ref count — `hasCppObject` alone can't detect it). No-op when no
   * scope is attached (matches fall-through behavior for test-constructed assets).
   */
  protected bindScope(asset: FileAsset): void {
    if (this._currentScope) {
      asset.attachScope(this._currentScope);
    }
  }

  /**
   * @deprecated since R3. Prefer reading {@link currentScope} and checking
   * `scope.alive`. Kept for view-teardown call sites; cancels the attached scope
   * (if any) so in-flight async loads void their native decode.
   */
  markReleased(): void {
    if (this._currentScope) {
      this._currentScope.cancel();
    }
  }

  /**
   * @deprecated since R3. Returns whether the attached scope (if any) is cancelled.
   * New code should read {@link currentScope} directly.
   */
  get isReleased(): boolean {
    return this._currentScope ? !this._currentScope.alive : false;
  }

  /* C++ constructor */
  protected constructorCpp(): BigInt {
    return rive.Napi_FileAssetLoader_constructor(this);
  }

  /* Destructor invoked when refs drop to zero */
  protected override cppDelete(pointer: BigInt): void {
    rive.Napi_FileAssetLoader_cppDelete(pointer);
  }

  protected cppRef(pointer: BigInt): void {
    rive.Napi_FileAssetLoader_cppRef(pointer);
  }

  private cppSetRendererType(pointer: BigInt, rendererTypeValue: number): void {
    rive.Napi_FileAssetLoader_cppSetRendererType(pointer, rendererTypeValue);
  }

  /**
   * Override this to customize how assets are loaded.
   * @param asset The {@link FileAsset} being loaded.
   * @param inBandBytes Bytes embedded inside the Rive file (empty when asset is referenced/hosted).
   * @returns true if the asset was loaded, false if the loader refused the asset.
   */
  abstract loadContents(asset: FileAsset, inBandBytes: Uint8Array): boolean;

  setRendererType(rendererType: RendererType): void {
    this.checkPointer();
    this.cppSetRendererType(this.cppPointer, rendererType);
    this.rendererType = rendererType;
  }

  getRendererType(): RendererType | null {
    return this.rendererType;
  }

  override acquire(): number {
    this.cppRef(this.cppPointer);
    return super.acquire();
  }

  getNativePtr(): BigInt {
    return this.cppPointer;
  }
}

/**
 * Asset loader with access to a Context-like object (for reflection-style instantiation).
 */
export abstract class ContextAssetLoader extends FileAssetLoader {
  protected readonly context: Context;

  protected constructor(context:Context) {
    super();
    this.context = context;
  }
}

/**
 * Default loader used when cascading multiple loaders (memory cache, local storage, network, etc.).
 */
export class FallbackAssetLoader extends FileAssetLoader {
  protected readonly loaders: FileAssetLoader[] = [];
  // Children THIS fallback created internally (the CDN loader). Their ctor self-ref
  // (refs=1) is THIS fallback's ownership — nobody else holds it. Borrowed children
  // (passed in via the ctor `loader` param / appendLoader) are NOT here; their ctor
  // ref belongs to the caller (e.g. the demo page), and releasing them here would
  // over-release a shared loader. See cppDelete override below.
  private readonly ownedLoaders: FileAssetLoader[] = [];
  private readonly context: Context | null;

  constructor(
    context: Context | null,
    loadCDNAssets: boolean = true,
    loader: FileAssetLoader | null = null
  ) {
    super();
    this.context = context;
    if (loader) {
      this.appendLoader(loader);
    }
    if (loadCDNAssets && context) {
      this.appendOwnedLoader(new CDNAssetLoader(context));
    }
  }

  appendLoader(loader: FileAssetLoader): void {
    this.loaders.push(loader);
    this.addDependency(loader);
  }

  prependLoader(loader: FileAssetLoader): void {
    this.loaders.unshift(loader);
    this.addDependency(loader);
  }

  // Track a child this fallback owns (created internally). Unlike appendLoader
  // (borrowed — caller owns the ctor ref), this child's ctor ref is ours to
  // release. We still addDependency so dispose() releases the +1 that
  // addDependency acquired; the ctor ref is released separately in cppDelete.
  private appendOwnedLoader(loader: FileAssetLoader): void {
    this.loaders.push(loader);
    this.ownedLoaders.push(loader);
    this.addDependency(loader);
  }

  // NativeObject.dispose() releases each dependency (the addDependency ref) BEFORE
  // calling cppDelete. So by the time this runs, every child — owned and borrowed —
  // has had its addDependency ref decremented. Borrowed children are now back at
  // their caller-owned ctor ref (left alone — correct). Owned children are now at
  // refs=1 (just their ctor self-ref, which is ours). Release it so they reach 0.
  protected override cppDelete(pointer: BigInt): void {
    for (const owned of this.ownedLoaders) {
      owned.release();
    }
    this.ownedLoaders.length = 0;
    super.cppDelete(pointer);
  }

  loadContents(asset: FileAsset, inBandBytes: Uint8Array): boolean {
    // The File attaches its scope to this fallback loader. Propagate it to every
    // child (CDN/custom) so their async decodes void on disposal too. Children read
    // `currentScope` at their own loadContents entry and close over it.
    const scope: LifecycleScope | null = this.currentScope;

    for (let i = 0; i < this.loaders.length; i++) {
      const loader = this.loaders[i];
      if (scope) {
        loader.attachScope(scope);
      }
      if (loader.loadContents(asset, inBandBytes)) {
        return true;
      }
    }
    return false;
  }

  override setRendererType(rendererType: RendererType): void {
    super.setRendererType(rendererType);
    for (const loader of this.loaders) {
      loader.setRendererType(rendererType);
    }
  }

  // acquire()/release() overrides intentionally absent.
  //
  // The overrides cascaded acquire/release into `this.loaders[]` to keep child
  // loader refs in step with the fallback's own ref. But `appendLoader()` also
  // calls `addDependency()`, which puts each child into the NativeObject
  // `dependencies` list AND acquires it. So a child lived in BOTH `loaders[]` and
  // `dependencies`. When the fallback's refs hit 0, dispose() released each
  // dependency once, and then the release() override's
  // `loaders.forEach(loader => loader.release())` released each child a SECOND
  // time → double-release (Reference count already zero crash, or over-release of
  // a borrowed/injected child → UAF).
  //
  // Children are now owned solely through the NativeObject dependency list, the
  // same single-path model used for File→Artboard and Renderer→Controller (R1).
  // dispose() walks `dependencies` exactly once per child. `loaders[]` is kept
  // only for loadContents() iteration order; it no longer participates in ref
  // counting. Ref balance: ctor(+1) + addDependency(+1) on construct, one
  // release per child at dispose → balanced (verified per native pointer).

  override markReleased(): void {
    super.markReleased();
    // Propagate to child loaders (e.g. CDNAssetLoader) so their in-flight async
    // callbacks also skip native calls after teardown.
    this.loaders.forEach(loader => loader.markReleased());
  }
}

/**
 * Loads assets from Rive's CDN when marked as "Hosted" in the editor.
 */
export class CDNAssetLoader extends ContextAssetLoader {
  private readonly tag = 'CDNAssetLoader';

  constructor(context: Context ) {
    super(context);
  }

  loadContents(asset: FileAsset, inBandBytes: Uint8Array): boolean {
    const url = asset.cdnUrl;
    if (!url || url.trim() === '') {
      return false;
    }

    // Capture the importing File's lifetime scope NOW. The fetch resolves later; if
    // the File has since been disposed (view teardown, file swap) the scope is
    // cancelled and we skip the decode that would dereference a freed native
    // FileAsset. Closing over `scope` (not `this.currentScope`) keeps this correct
    // when the loader is reused across multiple imports.
    const scope: LifecycleScope | null = this.currentScope;

    HttpService.fetchBytes(url, 30000, 30000)
      .then((arrayBuffer: ArrayBuffer) => {
        // The File (and thus the native FileAsset this `asset` wraps) may have been
        // released while the request was in flight. The JS wrapper's pointer is then
        // dangling, so calling decode() would crash (SIGSEGV). Skip it when the File's
        // lifetime scope is no longer alive.
        if (scope && !scope.alive) {
          console.warn(`${this.tag}: dropping asset decode; File scope cancelled`);
          return;
        }

        const uint8Array = new Uint8Array(arrayBuffer);
        if (!asset.decode(uint8Array)) {
          console.error(`${this.tag}: Failed to decode asset from ${url}`);
        }
      })
      .catch((error: Error) => {
        console.error(`${this.tag}: Error loading asset ${url}: ${error}`);
      });

    return true; // Request dispatched; treat as handled.
  }
}