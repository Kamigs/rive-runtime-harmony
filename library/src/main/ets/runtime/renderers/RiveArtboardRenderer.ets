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

import { RiveFileController } from '../controllers/RiveFileController';
import { Fit } from '../core/Fit';
import { RendererType } from './RendererType';
import { Renderer } from './Renderer';
import { Alignment } from '../core/Alignment';

const TAG = 'RiveArtboardRenderer'

/**
 * Open class for Rive artboard renderers in HarmonyOS/ETS
 */
export class RiveArtboardRenderer extends Renderer {
    private _controller: RiveFileController;

    constructor(
        uiContext: UIContext,
        controller: RiveFileController,
        trace: boolean = false,
        rendererType: RendererType = RendererType.Rive
    ) {
        super(uiContext, rendererType, trace);
        this._controller = controller;

        // Initialize controller
        this._controller.onStart = () => this.start();
        this._controller.acquire();
        // Add controller to the Renderer dependencies.
        // When the renderer is disposed, it'll `release()` it
        try {
            this.dependencies.add(this._controller);
        } catch (error) {
            const err = error as Error;
            console.error(`${TAG}, constructor error = ${err?.message ?? error}`)
        }
    }

    get controller(): RiveFileController {
        return this._controller;
    }

    private get fit(): Fit {
        return this._controller.fit;
    }

    private get alignment(): Alignment {
        return this._controller.alignment;
    }

    private get scaleFactor(): number {
        return this._controller.layoutScaleFactorActive;
    }

    /**
     * Resizes the artboard based on the current fit and scale factor
     */
    private resizeArtboard(): void {
        if (this.fit === Fit.LAYOUT) {
            const newWidth = this.width / this.scaleFactor;
            const newHeight = this.height / this.scaleFactor;
            const activeArtboard = this._controller.activeArtboard;
            if (activeArtboard) {
                activeArtboard.width = newWidth;
                activeArtboard.height = newHeight;
            }
        } else {
            const activeArtboard = this._controller.activeArtboard;
            if (activeArtboard) {
                activeArtboard.resetArtboardSize();
            }
        }
    }

    /**
     * Draws the artboard - be aware of thread safety!
     */
    draw(): void {
        if (this._controller.requireArtboardResize == true) {
            this._controller.requireArtboardResize = false
            this.resizeArtboard()
        }

        if (!this.hasCppObject || !this._controller.isActive) {
            return;
        }
        const activeArtboard = this._controller.activeArtboard;
        if (activeArtboard) {
            // Pass the owning File's cppPointer so the native layer can ref it across the worker
            // draw. rive's ArtboardInstance shares raw pointers into File-owned memory; without
            // this, a JS-thread File release (page exit / setRiveFile) frees that shared memory
            // under an in-flight worker Artboard::draw -> use-after-free (StressTestPage crash).
            const file = this._controller.file;
            const filePtr = (file && file.hasCppObject) ? file.cppPointer : 0n;
            activeArtboard.drawFit(this.cppPointer, this.fit, this.alignment, this.scaleFactor, filePtr);
        }
    }

    /**
     * Advances the animation - be aware of thread safety!
     */
    override advance(elapsed: number): void {
        if (!this.hasCppObject) {
            return;
        }
        if (this._controller.isActive) {
            this._controller.advance(elapsed);
        }

        if (!this._controller.isAdvancing) {
            this.stopThread();
        }
    }

    /**
     * Resets the renderer and controller
     */
    reset(): void {
        this._controller.stopAllAnimations();
        this._controller.reset();
        this.stop();
        this._controller.selectArtboard();
        this.start();
    }

    /**
     * Disposes dependencies in an orderly manner.
     *
     * R6: the controller's native Artboard (`reset()`) and File (`file.release()`) are
     * released HERE, from the DISPOSE threadsafe callback — NOT synchronously in
     * aboutToDisappear. The DISPOSE TSFN is fired by ScheduleDispose AFTER the worker
     * ran `m_workerImpl->destroy()`, which is queued behind every in-flight doFrame. So
     * by the time this runs, no doFrame — including one already past its DRAW handshake
     * and mid-`draw()` dereferencing the Artboard — remains on the shared worker. The
     * Artboard/File can be released safely (no cross-thread UAF), and the release happens
     * on the app's main JS context (which outlives the page), so it is reliable.
     *
     * This requires TSFNCallback to let the DISPOSE callback through even though
     * m_isDisposeScheduled is set (the old H1 bail discarded it and leaked). ADVANCE/DRAW
     * callbacks are still bailed (their doFrame exits via the IsDisposeScheduled wait
     * predicate instead), but DISPOSE must run.
     *
     * Only reached when the renderer was started (cppStart created the TSFN). A renderer
     * that never started has no TSFN, so ScheduleDispose skips DISPOSE — the view releases
     * synchronously in aboutToDisappear instead (see RiveAnimationView.aboutToDisappear).
     */
    protected override disposeDependencies(): void {
        super.disposeDependencies();
        if (this._controller) {
            this._controller.reset();
            if (this._controller.file) {
                this._controller.file.release();
            }
        }
    }
}