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

#ifndef OHOS_RIVE_RENDERER_H
#define OHOS_RIVE_RENDERER_H

#include "../helpers/render_type.h"
#include "../helpers/tracer.h"
#include "../helpers/worker_ref.h"
#include "rive/artboard.hpp"
#include "rive/file.hpp"
#include "worker_impl.h"
#include <napi/native_api.h>
#include <condition_variable>
#include <mutex>

namespace ohos_rive {
class Renderer {
public:
    // Constructor and destructor
    explicit Renderer(napi_env env,
                      napi_value ohosRenderer,
                      bool trace = false,
                      RendererType rendererType = RendererType::RIVE);
    ~Renderer();

    // Lifecycle management
    void ScheduleDispose();

    // Release the persistent napi ref to the JS Renderer object. MUST be called on the JS
    // thread (see impl). Called by RendererCppDelete before ScheduleDispose.
    void ReleaseRendererRef(napi_env env);

    // True once this Renderer is being torn down — either MarkDisposing flagged it
    // (early, from the JS teardown path, to bail in-flight doFrame) or ScheduleDispose
    // began the real native teardown. Consulted by WorkerImpl::doFrame's ADVANCE/DRAW
    // wait predicate so an in-flight frame on the shared worker bails out instead of
    // blocking on a JS callback that will never arrive (the component is being torn
    // down). NOTE: this is a logical OR of two distinct flags — see m_isDisposeScheduled
    // vs m_isMarkedDisposing below for why they must NOT be the same flag.
    bool IsDisposeScheduled() const
    {
        return m_isDisposeScheduled.load(std::memory_order_acquire) ||
               m_isMarkedDisposing.load(std::memory_order_acquire);
    }

    // Flags this Renderer as disposing WITHOUT queueing the full teardown. Used by the
    // JS teardown path (RiveAnimationView.aboutToDisappear) to make any already-queued
    // doFrame bail out BEFORE the owning File (and its Artboard) is released, closing
    // the cross-thread use-after-free window.
    // CRITICAL: this sets m_isMarkedDisposing, NOT m_isDisposeScheduled. ScheduleDispose
    // uses m_isDisposeScheduled.exchange(true) as its once-only guard. If MarkDisposing
    // set that same flag, the later cppDelete→ScheduleDispose would see it already true
    // and return immediately — skipping the worker destroy + DISPOSE TSFN, so
    // disposeDependencies() (which releases the File/Artboard) would NEVER run and
    // every File/Artboard/GPU-texture would leak. The two intents ("bail in-flight
    // doFrame early" vs "run the real teardown once") are distinct and need distinct
    // flags; IsDisposeScheduled() ORs them for the doFrame predicate.
    void MarkDisposing()
    {
        m_isMarkedDisposing.store(true, std::memory_order_release);
        // Immediately wake any doFrame blocked in the ADVANCE/DRAW handshake wait_for
        // on the shared worker so it re-checks IsDisposeScheduled() and bails instead
        // of waiting for the 500ms timeout (which would stack across queued frames and
        // freeze the shared worker under multi-view teardown). doFrame already past
        // the wait (mid-draw()) is handled by deferring the Artboard release to the
        // worker-drained DISPOSE callback (see RiveArtboardRenderer.disposeDependencies).
        if (m_workerImpl) {
            m_workerImpl->InterruptWait();
        }
    }

    // Surface management
    void SetSurface(SurfaceVariant &surface);
    int GetWidth(bool isDraw = false) const;
    int GetHeight(bool isDraw = false) const;

    // Renderer access
    rive::Renderer *GetRendererOnWorkerThread() const;
    RendererType GetRendererType() const
    {
        return m_worker->GetRendererType();
    };

    // Rendering control
    void Start();
    void Stop();
    void DoFrame();

    // Performance metrics
    double AverageFps() const
    {
        return m_averageFps;
    }

    struct PendingDraw {
        rive::ArtboardInstance* artboard = nullptr;
        rive::Renderer* renderer = nullptr;
        rive::Fit fit = rive::Fit::contain;
        rive::Alignment alignment = rive::Alignment::center;
        float scaleFactor = 1.0f;
        bool isDrawAligned = false;
        bool isValid = false;
        // The File that owns the shared Animations/StateMachines the ArtboardInstance
        // dereferences during draw. rive's Artboard::instance() shares RAW pointers
        // into the File-owned artboard template (artboard.cpp: only the source/template
        // deletes m_Animations/m_StateMachines; instances borrow them). So if the File
        // is freed on the JS thread while the worker is mid-Artboard::draw, those
        // shared objects are freed under the worker -> use-after-free (SIGSEGV/SIGABRT,
        // the StressTestPage cppcrash). We hold a ref on the File (and the ArtboardInstance)
        // across the worker draw so no JS-thread release can free either mid-draw.
        // nullptr when the draw path has no File (e.g. Canvas renderer).
        rive::File* file = nullptr;
    };

    void SetPendingDraw(rive::ArtboardInstance* ab, rive::Renderer* r, rive::File* file = nullptr)
    {
        StageDraw(ab, r, rive::Fit::contain, rive::Alignment::center, 1.0f, false, file);
    }

    void SetPendingDraw(rive::ArtboardInstance* ab, rive::Renderer* r, rive::Fit f, rive::Alignment a,
                        float scale, rive::File* file = nullptr)
    {
        StageDraw(ab, r, f, a, scale, true, file);
    }

    // Returns true if a staged draw was transferred to `out` (caller then owns out's File
    // ref and MUST unref it). Returns false when nothing was staged (no ref transferred).
    // NOTE: returns whether a stage was transferred, NOT out.isValid — a stage with a null
    // artboard (isValid false) still transfers its File ref, which the caller must release.
    bool TakePendingDraw(PendingDraw& out)
    {
        if (!m_hasPendingDraw.load(std::memory_order_acquire)) {
            return false;
        }
        out = m_pendingDraw;
        m_hasPendingDraw.store(false, std::memory_order_release);
        // Ownership of the staged File ref transfers to the caller (`out`); the worker
        // draw() unrefs it after dArtboard->draw(). Clear our copy so a later
        // SetPendingDraw can't double-unref.
        m_pendingDraw.artboard = nullptr;
        m_pendingDraw.file = nullptr;
        return true;
    }

private:
    // Constants
    static constexpr uint8_t kMaxScheduledFrames = 2;
    static constexpr int INVALID_DIMENSION = -1;

    rive::rcp<RefWorker> m_worker;
    napi_value m_renderer;

    napi_env m_env;
    napi_ref m_rendererRef = nullptr;

    SurfaceVariant m_surface = std::monostate{};

    std::thread::id m_workerThreadID;
    std::unique_ptr<WorkerImpl> m_workerImpl;
    std::atomic_uint8_t m_numScheduledFrames = 0;

    // FPS calculation
    std::chrono::steady_clock::time_point m_fpsLastFrameTime;
    std::atomic<double> m_averageFps = -1.0f;
    double m_fpsSum = 0.0f;
    int m_fpsCount = 0;

    // State tracking
    // m_isDisposeScheduled: set once by ScheduleDispose as its once-only teardown guard.
    // m_isMarkedDisposing: set early by MarkDisposing (JS teardown) to bail in-flight
    //   doFrame WITHOUT inhibiting the later ScheduleDispose (see MarkDisposing comment).
    std::atomic<bool> m_isDisposeScheduled = false;
    std::atomic<bool> m_isMarkedDisposing = false;

    // R6: DISPOSE handshake. napi_call_threadsafe_function(..., napi_tsfn_blocking)
    // does NOT block until the JS callback runs — it only blocks when the TSFN queue is
    // full, and ours is unlimited (max_queue_size=0). So the worker would enqueue DISPOSE
    // and immediately proceed to `delete this` -> ~Renderer -> napi_release_threadsafe_
    // function(abort), which discards the still-queued DISPOSE callback. disposeDependencies
    // never ran -> File/Artboard leaked. We mirror the ADVANCE/DRAW pattern: the worker
    // waits on this CV until the JS-thread TSFNCallback signals (via completionCallback)
    // that disposeDependencies ran, and only then does the cleanup (delete ref, release
    // surface, delete this) proceed. Local to Renderer (not WorkerImpl, which is destroyed
    // earlier in the same ScheduleDispose lambda).
    std::mutex m_disposeMutex;
    std::condition_variable m_disposeCv;
    std::atomic<bool> m_disposeCallbackDone{false};

    // Tracing
    std::unique_ptr<ITracer> m_tracer;
    bool m_traceLifecycle = false;

    // Helper methods
    static std::unique_ptr<ITracer> MakeTracer(bool trace);
    void CalculateFps(std::chrono::high_resolution_clock::time_point frameTime);
    void AcquireSurface(SurfaceVariant &surface);
    void ReleaseSurface(SurfaceVariant &surface);

    bool CallRendererMethod(const char *methodName);

    // ScheduleDispose helpers — split out so ScheduleDispose stays within the toolchain's
    // max-nesting-depth limit (the original single lambda nested 5 deep). All run on the
    // worker thread (ScheduleDispose enqueues DisposeOnWorkerThread).
    // Destroys the worker impl, waits for the JS disposeDependencies callback, releases the
    // surface, then `delete this`.
    void DisposeOnWorkerThread(DrawableThreadState *threadState);
    // Posts the DISPOSE TSFN to the JS thread and blocks (on m_disposeCv) until the JS
    // completionCallback signals disposeDependencies ran. No-op when there is no TSFN
    // (renderer never started).
    void WaitDisposeDependencies();
    // JS-thread side (runs inside the DISPOSE TSFN completionCallback): signals the worker
    // that disposeDependencies completed so WaitDisposeDependencies can stop waiting.
    void SignalDisposeCallbackDone();

    // Releases the File ref held by the currently-staged PendingDraw, if any. Called when
    // an unconsumed stage is overwritten (SetPendingDraw) and from ~Renderer for a
    // never-consumed stage. Balanced against the ref() taken in StageDraw; the consume
    // path (worker draw()) unrefs the copied-out PendingDraw. (Only the File is refcounted
    // — rive::File is RefCnt; the ArtboardInstance is NOT RefCnt, it is `delete`d by the JS
    // wrapper, so we cannot ref it here. The File ref keeps the shared Animations/StateMachines
    // the instance dereferences alive across the draw, which is the confirmed UAF root cause.)
    void ReleaseStagedDrawRefs()
    {
        if (m_pendingDraw.file != nullptr) {
            m_pendingDraw.file->unref();
            m_pendingDraw.file = nullptr;
        }
    }

    // Stages a draw, holding a ref on the owning File across the worker draw (see
    // PendingDraw::file). The ref is released either by the worker draw() (consumed) or
    // by ReleaseStagedDrawRefs (overwritten / never-consumed).
    void StageDraw(rive::ArtboardInstance* ab, rive::Renderer* r, rive::Fit f, rive::Alignment a,
                   float scale, bool aligned, rive::File* file)
    {
        if (m_hasPendingDraw.load(std::memory_order_acquire)) {
            // A previous stage was never consumed by the worker — release its File ref so
            // it doesn't leak when overwritten.
            ReleaseStagedDrawRefs();
            m_hasPendingDraw.store(false, std::memory_order_release);
        }
        if (file != nullptr) {
            file->ref();
        }
        m_pendingDraw.artboard = ab;
        m_pendingDraw.renderer = r;
        m_pendingDraw.fit = f;
        m_pendingDraw.alignment = a;
        m_pendingDraw.scaleFactor = scale;
        m_pendingDraw.isValid = (ab != nullptr);
        m_pendingDraw.isDrawAligned = aligned;
        m_pendingDraw.file = file;
        m_hasPendingDraw.store(true, std::memory_order_release);
    }

    // About threadsafe
    napi_threadsafe_function m_tsfn = nullptr;
    static void TSFNCallback(napi_env env, napi_value js_callback, void *context, void *data);
    static void TSFNCallbackExecuteCallback(napi_env env, napi_value js_callback, TSFNData *tsfnData);
    // TSFNCallbackExecuteCallback per-type handlers (split to keep each function ≤50 lines).
    static void ExecuteAdvance(napi_env env, napi_value js_callback, TSFNData *tsfnData);
    static void ExecuteDraw(napi_env env, napi_value js_callback);
    static void ExecuteAdvanceAndDraw(napi_env env, napi_value js_callback, TSFNData *tsfnData);
    static void ExecuteDispose(napi_env env, napi_value js_callback);
    std::atomic<bool> m_hasPendingDraw{false};
    PendingDraw m_pendingDraw;
};
} // namespace ohos_rive
#endif // OHOS_RIVE_RENDERER_H

