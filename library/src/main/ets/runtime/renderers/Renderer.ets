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
import { NativeObject } from '../core/NativeObject';
import { RendererType } from './RendererType';
import rive from 'libohos_rive.so';
import { Fit } from '../core/Fit';
import { Alignment } from '../core/Alignment';
import { RectF } from './RectF';
import { SharedSurface } from './SharedSurface';
import { RefCount } from '../core/RefCount';
import { RiveFramCallBack } from './RiveFramCallBack';
import { JSON } from '@kit.ArkTS';

const TAG = 'Renderer'

// Keep one outstanding framework callback across stop/start within the same
// vsync. Stopping must retain the callback object until the framework fires it.
// This implementation detail does not add fields to the exported Renderer API.
class ScheduledFrameCallback extends RiveFramCallBack {
    pending: boolean = false;

    override onFrame(frameTimeNanos: number): void {
        this.pending = false;
        super.onFrame(frameTimeNanos);
    }
}

export abstract class Renderer extends NativeObject {
    public uiContext: UIContext
    public type: RendererType
    public trace: boolean
    public isPlaying: boolean = false
    public isAttached: boolean = false
    // R6: true once start() has run cppStart (which creates the worker TSFN on the
    // native side). Used by the view teardown to decide whether native Artboard/File
    // release can be deferred to the worker-drained DISPOSE callback (started → yes,
    // there may be an in-flight doFrame) or must run synchronously (never started → no
    // worker frames exist, so no race, and no TSFN to deliver the deferred callback).
    public everStarted: boolean = false
    private sharedSurface: SharedSurface | null = null
    // True once destroySurface() has run for the current native surface. destroySurface
    // can be invoked twice in the teardown path (onSurfaceDestroyed callback, then
    // delete()→destroySurface()); without this guard cppDestroySurface would reach the
    // native layer twice for the same surface. Idempotent guard prevents the double call.
    private surfaceDestroyed: boolean = false
    public framCallBack: RiveFramCallBack | null = null

    constructor(uiContext: UIContext, type: RendererType = RendererType.Rive, trace: boolean = false) {
        super(NativeObject.NULL_POINTER);
        this.uiContext = uiContext
        this.type = type
        this.trace = trace
    }

    // Per-frame cpp wrappers: intentionally no console.* here. cppDoFrame runs ~60×/s
    // × N views; logging it (and save/restore/transform) is pure Hilog IPC + GC churn
    // on the UI thread. Use this.trace-driven diagnostics elsewhere if needed.

    private cppStart(rendererPointer: BigInt) {
        rive.Napi_Renderer_cppStart(rendererPointer)
    }

    private cppStop(rendererPointer: BigInt) {
        rive.Napi_Renderer_cppStop(rendererPointer)
    }

    private cppSave(rendererPointer: BigInt) {
        rive.Napi_Renderer_cppSave(rendererPointer)
    }

    private cppRestore(rendererPointer: BigInt) {
        rive.Napi_Renderer_cppRestore(rendererPointer)
    }

    private cppWidth(rendererPointer: BigInt): number {
        return rive.Napi_Renderer_cppWidth(rendererPointer)
    }

    private cppHeight(rendererPointer: BigInt): number {
        return rive.Napi_Renderer_cppHeight(rendererPointer)
    }

    private cppAvgFps(rendererPointer: BigInt): number {
        return rive.Napi_Renderer_cppAvgFps(rendererPointer)
    }

    cppDoFrame(rendererPointer: BigInt) {
        rive.Napi_Renderer_cppDoFrame(rendererPointer)
    }

    /**
     * Flags this renderer as disposing so any doFrame already queued on the shared
     * native worker bails out of its JS handshake wait instead of blocking on a
     * callback that won't arrive. Called by the view teardown BEFORE the File/Artboard
     * is released, to close the cross-thread use-after-free window (R6).
     */
    cppMarkDisposing(): void {
        if (!this.hasCppObject) {
            return;
        }
        rive.Napi_Renderer_cppMarkDisposing(this.cppPointer)
    }

    private cppSetSurface(surfaceId: string, rendererPointer: BigInt) {
        // An empty/undefined surfaceId would coerce to 0n and reach the native layer as
        // a null native window, leading to EGL_BAD_MATCH / SIGSEGV. Bail out instead.
        if (!surfaceId) {
            console.warn(`${TAG}, cppSetSurface: empty surfaceId, skipping`)
            return
        }
        rive.Napi_Renderer_cppSetSurface(rendererPointer, BigInt(surfaceId))
    }

    private cppDestroySurface(rendererPointer: BigInt) {
        rive.Napi_Renderer_cppDestroySurface(rendererPointer)
    }

    private cppAlign(
        cppPointer: BigInt,
        fit: Fit,
        alignment: Alignment,
        targetBounds: RectF,
        srcBounds: RectF,
        scaleFactor: number,
    ) {
        rive.Napi_Renderer_cppAlign(cppPointer, fit, alignment, targetBounds, srcBounds, scaleFactor)
    }

    private cppTransform(
        cppPointer: BigInt,
        x: number,
        sy: number,
        sx: number,
        y: number,
        tx: number,
        ty: number,
    ) {
        rive.Napi_Renderer_cppTransform(cppPointer, x, sy, sx, y, tx, ty)
    }

    private getCppRenderer(trace: boolean, type: number): BigInt {
        return rive.Napi_Renderer_cppConstructor(this, trace, type)
    }

    protected override cppDelete(pointer: BigInt): void {
        rive.Napi_Renderer_cppDelete(pointer)
    }


    /**
     * Creates the native renderer object
     */
    make(): void {
        if (!this.hasCppObject) {
            this.cppPointer = this.getCppRenderer(this.trace, this.type.valueOf());
            this.refs.incrementAndGet();
        }
    }

    /**
     * Helper function to reassign the renderer type.
     */
    setRendererType(newType: number): void {
        if (newType !== this.type.valueOf()) {
            this.type = RendererType.fromIndex(newType);
        }
    }

    /**
     * Abstract method to be implemented by concrete renderers
     */
    abstract draw(): void;

    /**
     * Abstract method to be implemented by concrete renderers
     */
    abstract advance(elapsed: number): void;

    /**
     * Starts the renderer and registers for frame callbacks
     */
    start(): void {
        if (this.isPlaying) {
            return;
        }
        if (!this.isAttached) {
            console.warn(`${TAG}, start: not attached`)
            return;
        }
        if (!this.hasCppObject) {
            console.warn(`${TAG}, start: no cpp object`)
            return;
        }

        this.isPlaying = true;
        try {
            this.cppStart(this.cppPointer);
            // cppStart created the native worker TSFN, so an in-flight doFrame may now
            // exist on the shared worker. Teardown will defer Artboard/File release to
            // the worker-drained DISPOSE callback (R6) instead of racing such a frame.
            this.everStarted = true;
            this.scheduleFrame();
        } catch (e) {
            // cppStart failed: no worker/TSFN was created, so everStarted stays false and
            // the teardown path must take the synchronous-release branch. Reset isPlaying
            // too, otherwise stop()/stopThread() would no-op on the isPlaying guard and
            // leave this renderer permanently marked as playing.
            this.isPlaying = false;
            const err = e as Error;
            console.error(`${TAG}, start catch e = ${err?.message ?? e}`)
        }
    }

    /**
     * Sets the drawing surface for the renderer
     * @deprecated This method is dangerous as it does not correctly manage the Surface's lifecycle
     */
    setSurface(surfaceId: string): void {
        const sharedSurface = new SharedSurface(surfaceId);
        this.setSharedSurface(sharedSurface);
    }

    /**
     * Sets the drawing surface for the renderer using SharedSurface
     */
    setSharedSurface(surface: SharedSurface): void {
        if (this.sharedSurface) {
            this.sharedSurface.release();
        }
        surface.acquire();
        this.sharedSurface = surface;

        this.cppSetSurface(surface.surfaceId, this.cppPointer);
        this.isAttached = true;
        // A new native surface is now bound — clear the destroy flag so a subsequent
        // destroySurface() (teardown) is not skipped. Without this, a surface that was
        // destroyed and then re-created (e.g. XComponent surface rebuild) would have its
        // final destroy silently dropped, leaking the native window.
        this.surfaceDestroyed = false;
        this.start();
    }

    /**
     * Marks the animation as stopped
     */
    stopThread(): void {
        if (!this.isPlaying) {
            return;
        }
        if (!this.hasCppObject) {
            return;
        }

        this.isPlaying = false;
        this.cppStop(this.cppPointer);
    }

    /**
     * Calls stopThread and removes any pending frame callbacks
     */
    stop(): void {
        this.stopThread();
        // Intentionally NOT nulling `this.framCallBack`. A frame callback may already
        // be posted (the next vsync will fire it). The callback holds `this.renderer`
        // and the renderer holds the callback — a reference cycle that keeps the posted
        // callback object alive until that final firing, where `onFrame` sees
        // `isPlaying == false` and returns without rescheduling. The cycle is then
        // collected by GC; the native renderer was already freed by dispose()/cppDelete,
        // so this is not a native leak — only a brief JS-object retention.
        //
        // Nulling it here (an earlier change) dropped the only JS reference before the
        // pending post fired; the framework's PostFrameCallback then read `onFrame` off a
        // collected/undefined object and crashed (TypeError: Cannot read property onFrame
        // of undefined) — reproducible by rapidly re-entering a page (RecyclerPage).
    }

    /**
     * Tears down the bound surface (stops rendering + releases the native surface).
     * Called by the view when the XComponent surface is destroyed, so the renderer does
     * not keep operating on a dead native window (EGL_BAD_NATIVE_WINDOW / SIGSEGV).
     */
    destroySurface(): void {
        if (!this.hasCppObject || this.surfaceDestroyed) {
            return;
        }
        this.isAttached = false;
        this.stop();
        this.cppDestroySurface(this.cppPointer);
        this.surfaceDestroyed = true;
    }

    scheduleFrame(): void {
        // Reuse a single callback instance instead of allocating one every frame
        // (this is invoked ~60×/s). Each discarded instance held a reference to the
        // renderer until GC, creating avoidable memory churn.
        if (this.framCallBack === null) {
            this.framCallBack = new ScheduledFrameCallback(this)
        }
        const callback = this.framCallBack;
        if (callback instanceof ScheduledFrameCallback) {
            if (callback.pending) {
                return;
            }
            callback.pending = true;
            try {
                this.uiContext.postFrameCallback(callback);
            } catch (error) {
                callback.pending = false;
                throw error as Error;
            }
        } else {
            // Preserve the existing extension point for caller-supplied callbacks.
            this.uiContext.postFrameCallback(callback);
        }
    }

    save(): void {
        this.cppSave(this.cppPointer);
    }

    restore(): void {
        this.cppRestore(this.cppPointer);
    }

    get width(): number {
        return this.cppWidth(this.cppPointer);
    }

    get height(): number {
        return this.cppHeight(this.cppPointer);
    }

    get averageFps(): number {
        return this.cppAvgFps(this.cppPointer);
    }

    align(
        fit: Fit,
        alignment: Alignment,
        targetBounds: RectF,
        sourceBounds: RectF,
        scaleFactor: number = 1.0
    ): void {
        this.cppAlign(
            this.cppPointer,
            fit,
            alignment,
            targetBounds,
            sourceBounds,
            scaleFactor
        );
    }

    transform(x: number, sy: number, sx: number, y: number, tx: number, ty: number): void {
        this.cppTransform(this.cppPointer, x, sy, sx, y, tx, ty);
    }

    scale(sx: number, sy: number): void {
        this.transform(sx, 0, 0, sy, 0, 0);
    }

    translate(dx: number, dy: number): void {
        this.transform(1, 0, 0, 1, dx, dy);
    }

    /**
     * Tears down the renderer and releases the underlying C++ object via the
     * ref-count disposal path (NativeObject.dispose), NOT a direct delete.
     *
     * Order matters: the worker/surface must be stopped and detached before the
     * native Renderer is freed. The Renderer is single-owner (only ever created
     * via make(), never externally acquired), so one release() drops refs to 0
     * and triggers dispose(), which releases dependencies (the controller) and
     * runs cppDelete. The SharedSurface is held in a dedicated field (not in the
     * dependency list) so it is released explicitly here first.
     */
    delete(): void {
        this.stop();
        this.destroySurface();

        // SharedSurface is tracked outside the dependency list; release it first
        // so its ref reaches 0 (the renderer's borrow + the ctor self-ref).
        if (this.sharedSurface) {
            this.sharedSurface.release();
            this.sharedSurface = null;
        }

        if (this.hasCppObject) {
            // Drive the standard ref-count path: refs 1 -> 0 -> dispose() releases
            // the dependency list (controller) and runs cppDelete.
            this.release();
        } else {
            // Renderer was never made() (no native object, refs == 0). Still
            // release the JS-side dependents (e.g. the controller) to avoid a
            // logical leak, but skip the ref-count path that would underflow.
            this.dependencies.forEach((dep: RefCount) => dep.release());
            this.dependencies.clear();
        }
    }

    /**
     * Releases all of this renderer's dependents
     */
    protected disposeDependencies(): void {
        if (this.sharedSurface) {
            this.sharedSurface.release();
            this.sharedSurface = null;
        }
        try {
            this.dependencies.forEach((dep: RefCount) => dep.release());
            this.dependencies.clear();
        } catch (error) {
            const err = error as Error;
            console.error(`${TAG}, disposeDependencies error: ${err?.message ?? error}`)
        }
    }
}
