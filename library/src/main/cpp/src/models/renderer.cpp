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

#include "models/renderer.h"
#include "helpers/exception_handler.h"
#include "helpers/general.h"
#include "helpers/resource.h"
#include "models/canvas_renderer.h"
#include <js_native_api.h>

using namespace std::chrono_literals;

namespace ohos_rive {
void Renderer::TSFNCallback(napi_env env, napi_value js_callback, void *context, void *data)
{
    if (data == nullptr) {
        return;
    }

    auto *tsfnData = static_cast<TSFNData *>(data);
    if (env == nullptr || js_callback == nullptr) {
        // TSFN teardown drains queued data without a usable JS environment. Do not
        // touch context: an aborted frame may outlive its Renderer/WorkerImpl.
        // DISPOSE is different: WaitDisposeDependencies keeps its Renderer alive
        // until this completion, so release that wait even when JS cannot run.
        // Frame completion captures WorkerImpl and must never run on this path.
        if (tsfnData->type == TSFNData::Type::DISPOSE && tsfnData->completionCallback) {
            tsfnData->completionCallback();
        }
        delete tsfnData;
        return;
    }
    Renderer *renderer = static_cast<Renderer *>(context);

    // DISPOSE is fired by ScheduleDispose AFTER the worker ran m_workerImpl->destroy()
    // — i.e. the shared worker has drained every in-flight doFrame for this renderer.
    // It must execute even though m_isDisposeScheduled is already set: it delivers
    // disposeDependencies() to the JS layer, which releases the File/Artboard (the
    // objects an in-flight draw() could have dereferenced). Bailing here (the old H1
    // path) discarded DISPOSE, so disposeDependencies never ran and the File/Artboard
    // plus their decoded bytes / GPU textures leaked on every page exit.
    if (tsfnData->type == TSFNData::Type::DISPOSE) {
        napi_handle_scope scope;
        napi_open_handle_scope(env, &scope);
        TSFNCallbackExecuteCallback(env, js_callback, tsfnData);
        napi_close_handle_scope(env, scope);
        // Signal the worker's m_disposeCv wait so it knows disposeDependencies ran and
        // can safely proceed to delete ref / release surface / delete this. Without this
        // the worker would abort the TSFN and drop this callback (leak).
        if (tsfnData->completionCallback) {
            tsfnData->completionCallback();
        }
        delete tsfnData;
        return;
    }

    // ADVANCE/DRAW/ADVANCE_AND_DRAW while the renderer is being disposed. The doFrame
    // that queued this has already bailed out of its handshake wait via the
    // IsDisposeScheduled() predicate (notified by MarkDisposing), so it does NOT need
    // this completionCallback. Skip it: invoking the WorkerImpl-capturing lambda here
    // risks a use-after-free, because ScheduleDispose (queued behind that bailed
    // doFrame) may have destroyed the WorkerImpl by the time this stale callback is
    // processed on the JS thread. (R6.3 replaced the unbounded spin with a
    // predicate-gated wait_for, so the doFrame no longer relies on the bail invoking
    // completionCallback to avoid spinning.)
    if (!renderer || renderer->IsDisposeScheduled()) {
        delete tsfnData;
        return;
    }

    napi_handle_scope scope;
    napi_open_handle_scope(env, &scope);

    TSFNCallbackExecuteCallback(env, js_callback, tsfnData);
    napi_close_handle_scope(env, scope);
    if (tsfnData->completionCallback) {
        tsfnData->completionCallback();
    }
    delete tsfnData;
}

void Renderer::TSFNCallbackExecuteCallback(napi_env env, napi_value js_callback, TSFNData *tsfnData)
{
    switch (tsfnData->type) {
        case TSFNData::Type::ADVANCE:
            ExecuteAdvance(env, js_callback, tsfnData);
            break;
        case TSFNData::Type::DRAW:
            ExecuteDraw(env, js_callback);
            break;
        case TSFNData::Type::ADVANCE_AND_DRAW:
            ExecuteAdvanceAndDraw(env, js_callback, tsfnData);
            break;
        case TSFNData::Type::DISPOSE:
            ExecuteDispose(env, js_callback);
            break;
    }
}

void Renderer::ExecuteAdvance(napi_env env, napi_value js_callback, TSFNData *tsfnData)
{
    napi_value method;
    if (napi_get_named_property(env, js_callback, "advance", &method) != napi_ok) {
        LOGE("TSFNCallback napi_get_named_property ADVANCE failed");
        return;
    }
    napi_value elapsedMsValue;
    napi_create_double(env, tsfnData->elapsedMs, &elapsedMsValue);
    napi_value argv[] = {elapsedMsValue};
    if (napi_call_function(env, js_callback, method, 1, argv, nullptr) != napi_ok) {
        LOGE("TSFNCallback napi_call_function ADVANCE failed");
    }
}

void Renderer::ExecuteDraw(napi_env env, napi_value js_callback)
{
    napi_value method;
    if (napi_get_named_property(env, js_callback, "draw", &method) != napi_ok) {
        LOGE("TSFNCallback napi_get_named_property DRAW failed");
        return;
    }
    if (napi_call_function(env, js_callback, method, 0, nullptr, nullptr) != napi_ok) {
        LOGE("TSFNCallback napi_call_function DRAW failed");
    }
}

// R6.4: one JS roundtrip does both. advance(elapsed) first (advances animation state
// machines / linear animations), then draw() (stages SetPendingDraw for the worker to
// render). Order matters: draw() reads the state advance() just wrote.
void Renderer::ExecuteAdvanceAndDraw(napi_env env, napi_value js_callback, TSFNData *tsfnData)
{
    napi_value advanceMethod;
    if (napi_get_named_property(env, js_callback, "advance", &advanceMethod) != napi_ok) {
        LOGE("TSFNCallback napi_get_named_property ADVANCE (merged) failed");
        return;
    }
    napi_value elapsedMsValue;
    napi_create_double(env, tsfnData->elapsedMs, &elapsedMsValue);
    napi_value advanceArgv[] = {elapsedMsValue};
    napi_status status = napi_call_function(env, js_callback, advanceMethod, 1, advanceArgv, nullptr);
    if (status != napi_ok) {
        LOGE("TSFNCallback napi_call_function ADVANCE (merged) failed");
        return;
    }

    napi_value drawMethod;
    if (napi_get_named_property(env, js_callback, "draw", &drawMethod) != napi_ok) {
        LOGE("TSFNCallback napi_get_named_property DRAW (merged) failed");
        return;
    }
    if (napi_call_function(env, js_callback, drawMethod, 0, nullptr, nullptr) != napi_ok) {
        LOGE("TSFNCallback napi_call_function DRAW (merged) failed");
    }
}

void Renderer::ExecuteDispose(napi_env env, napi_value js_callback)
{
    napi_value method;
    napi_get_named_property(env, js_callback, "disposeDependencies", &method);
    napi_call_function(env, js_callback, method, 0, nullptr, nullptr);
}

Renderer::Renderer(napi_env env, napi_value ohosRenderer, bool trace, const RendererType rendererType)
    : m_worker(RefWorker::CurrentOrFallback(rendererType)),
      m_renderer(ohosRenderer),
      m_env(env),
      m_tracer(MakeTracer(trace)),
      m_traceLifecycle(trace)
{
    // Create a persistent reference to the renderer object
    if (env != nullptr && ohosRenderer != nullptr) {
        napi_create_reference(env, ohosRenderer, 1, &m_rendererRef);
    }
}

Renderer::~Renderer()
{
    if (m_tsfn != nullptr) {
        napi_release_threadsafe_function(m_tsfn, napi_tsfn_abort);
        m_tsfn = nullptr;
        if (m_traceLifecycle) {
            OH_LOG_Print(LOG_APP, LOG_INFO, RIVE_LOG_DOMAIN, RIVE_LOG_TAG,
                         "RIVE_LIFECYCLE TSFN_RELEASE renderer=%{public}p", this);
        }
    }
    if (!m_isDisposeScheduled) {
        LOGE("Renderer was deleted directly instead of scheduling disposal!");
    }
    // Release any draw staged but never consumed by the worker (e.g. a frame that
    // bailed after its JS handshake once disposal was scheduled). Its artboard/file
    // refs would otherwise leak. ~Renderer runs on the worker after ScheduleDispose
    // drained in-flight frames, and the JS draw() path is gated by IsDisposeScheduled,
    // so m_pendingDraw is not being concurrently staged here.
    if (m_hasPendingDraw.load(std::memory_order_acquire)) {
        ReleaseStagedDrawRefs();
        m_hasPendingDraw.store(false, std::memory_order_release);
    }
}

// 异步调度销毁流程，确保线程安全且只执行一次
void Renderer::ScheduleDispose()
{
    // 原子标记：若已置位则直接返回，防止重复销毁
    bool isDisposed = m_isDisposeScheduled.exchange(true);
    if (isDisposed) {
        return;
    }
    // 在工作线程中完成真正的资源释放（主体抽到 DisposeOnWorkerThread，控制嵌套深度）。
    m_worker->Run([this](DrawableThreadState *threadState) { DisposeOnWorkerThread(threadState); });
}

// 工作线程上的销毁主体（从 ScheduleDispose 的内联 lambda 抽出，以满足最大嵌套深度限制）。
void Renderer::DisposeOnWorkerThread(DrawableThreadState *threadState)
{
    // 1. 销毁底层渲染实现
    if (m_workerImpl) {
        m_workerImpl->destroy(threadState);
    }

    // 2. 通过 TSFN 通知 JS 层执行 disposeDependencies，并等待其真正执行完毕。
    // napi_tsfn_blocking 不保证阻塞到 JS callback 执行——队列无上限时投递即返回，
    // 若不等待，worker 会紧接着 delete this -> ~Renderer -> release TSFN(abort)，
    // 丢弃尚未处理的 DISPOSE 回调 -> disposeDependencies 永不执行 -> File/Artboard 泄漏。
    // 故沿用 ADVANCE/DRAW 的 CV 等待模式：JS 侧 TSFNCallback 执行完 disposeDependencies
    // 后经 completionCallback 置 m_disposeCallbackDone 并 notify；worker 等到后再清理。
    WaitDisposeDependencies();

    // 3. 释放 surface 资源 (GL/native-window resources — safe on the worker).
    ReleaseSurface(m_surface);
    // 4. 自毁，注意此时已无任何外部引用。m_rendererRef was released on the JS thread by
    // RendererCppDelete (ReleaseRendererRef) before ScheduleDispose was queued.
    delete this;
}

// 投递 DISPOSE TSFN 到 JS 线程并等待 disposeDependencies 真正执行完毕（m_disposeCv）。
// 无 TSFN（渲染器从未 start）时为空操作。
void Renderer::WaitDisposeDependencies()
{
    if (m_tsfn == nullptr) {
        LOGW("RIVE_LIFECYCLE: ScheduleDispose has no TSFN — disposeDependencies will NOT run");
        // No TSFN (renderer never started): no worker frames exist and the view's
        // aboutToDisappear already released the File/Artboard synchronously. Nothing to
        // wait for. m_rendererRef was already released on the JS thread by
        // RendererCppDelete (ReleaseRendererRef) before this ran.
        return;
    }

    auto *data = new TSFNData{TSFNData::Type::DISPOSE};
    // Runs on the JS thread inside TSFNCallback, after disposeDependencies().
    // m_rendererRef is NOT released here — it was already released on the JS thread by
    // RendererCppDelete (Renderer::ReleaseRendererRef) before ScheduleDispose was called.
    data->completionCallback = [this]() { SignalDisposeCallbackDone(); };

    napi_status tsfnStatus = napi_call_threadsafe_function(m_tsfn, data, napi_tsfn_blocking);
    if (tsfnStatus != napi_ok) {
        // The call did not enqueue, so TSFNCallback (the normal deleter) will never run for
        // this data — free it here to avoid leaking the TSFNData + lambda.
        LOGE("RIVE_LIFECYCLE: DISPOSE TSFN call failed status=%d", static_cast<int>(tsfnStatus));
        delete data;
        return;
    }

    // Wait for the JS thread to actually run disposeDependencies. The wait is UNBOUNDED on
    // purpose: disposeDependencies releases the File/Artboard (and their decoded bytes / GPU
    // textures). A bounded timeout that elapsed under JS-thread back-pressure (e.g.
    // RecyclerPage multi-view teardown) would let us proceed to `delete this` WITHOUT the
    // release ever running -> permanent File/Artboard/GPU-texture leak. Because the doFrame
    // for a disposing Renderer bails out via the IsDisposeScheduled() predicate rather than
    // waiting on a JS callback, the JS thread is not blocked on this worker, so it will
    // drain the DISPOSE callback as soon as it is free — no deadlock.
    std::unique_lock<std::mutex> lk(m_disposeMutex);
    m_disposeCv.wait(lk, [this]() { return m_disposeCallbackDone.load(std::memory_order_acquire); });
}

// 在 DISPOSE TSFN 的 completionCallback 中（JS 线程）调用：通知 worker 的
// WaitDisposeDependencies 解除阻塞。
void Renderer::SignalDisposeCallbackDone()
{
    std::lock_guard<std::mutex> lk(m_disposeMutex);
    m_disposeCallbackDone.store(true, std::memory_order_release);
    m_disposeCv.notify_one();
}

// Release the persistent napi ref to the JS Renderer object. MUST be called on the JS
// thread — napi_delete_reference touches the EcmaVM, which asserts JS-thread access
// (EcmaVM::CheckThread); calling it on the worker thread SIGABRT'd
// (cppcrash 20260628165615/165635). Called by RendererCppDelete (JS thread) before
// ScheduleDispose queues the worker teardown. Once-only: guards against a double delete
// if invoked twice (it should not be, but the ref outlives the renderer otherwise).
void Renderer::ReleaseRendererRef(napi_env env)
{
    if (m_rendererRef != nullptr && env != nullptr) {
        napi_delete_reference(env, m_rendererRef);
        m_rendererRef = nullptr;
    }
}

void Renderer::SetSurface(SurfaceVariant &surface)
{
    if (m_isDisposeScheduled) {
        return;
    }

    auto oldSurface = m_surface;
    AcquireSurface(surface);
    auto newSurface = m_surface;

    m_worker->Run([this, oldSurface, newSurface](DrawableThreadState *threadState) mutable {
        m_workerThreadID = std::this_thread::get_id();
        // Window buffer operations are not thread-safe. Keep buffer hold on the
        // same worker as Request/Flush/EGL, and never pass the initial null window.
        if (auto oldWindow = std::get_if<EGLNativeWindowType>(&oldSurface)) {
            if (*oldWindow != 0) {
                OH_NativeWindow_SetBufferHold(reinterpret_cast<OHNativeWindow *>(*oldWindow));
            }
        }
        if (m_workerImpl) {
            m_workerImpl->destroy(threadState);
            m_workerImpl.reset();
        }
        ReleaseSurface(oldSurface);

        // Capture each transition, including detach, rather than reading a later
        // JS-thread assignment after multiple resize/destroy events were queued.
        if (newSurface.index() > 0) {
            m_workerImpl = WorkerImpl::Make(newSurface, threadState, m_worker->GetRendererType());
        }
    });
}

rive::Renderer *Renderer::GetRendererOnWorkerThread() const
{
    if (!m_workerImpl) {
        return nullptr;
    }
    return m_workerImpl->renderer();
}

// 启动渲染器：创建线程安全函数（TSFN）并在工作线程中初始化底层渲染实现
void Renderer::Start()
{
    // 若已调度销毁则直接返回，避免对已释放资源操作
    if (m_isDisposeScheduled) {
        return;
    }

    // A TSFN belongs to this renderer, not to one play interval. Reusing it on
    // resume avoids retaining one JS renderer/queue per inactive-active cycle.
    if (m_tsfn == nullptr) {
        napi_value ohosRenderer;
        napi_status tmpStatus = napi_get_reference_value(m_env, m_rendererRef, &ohosRenderer);
        if (tmpStatus != napi_ok) {
            LOGE("Failed to create reference for renderer");
            return;
        }

        // 创建线程安全函数名称
        napi_value resource_name;
        napi_create_string_utf8(m_env, "RendererTSFN", NAPI_AUTO_LENGTH, &resource_name);

        // 创建线程安全函数，用于跨线程回调 JS 层方法（advance/draw/dispose）
        napi_status status = napi_create_threadsafe_function(m_env, ohosRenderer, nullptr, resource_name,
                                                             0, // Unbounded queue
                                                             1, // Initial thread count
                                                             nullptr,
                                                             nullptr, // finalizer
                                                             this, TSFNCallback, &m_tsfn);
        if (status != napi_ok) {
            m_tsfn = nullptr;
            napi_throw_error(m_env, nullptr, "Rive renderer could not create its thread-safe callback");
            return;
        }
        if (m_traceLifecycle) {
            OH_LOG_Print(LOG_APP, LOG_INFO, RIVE_LOG_DOMAIN, RIVE_LOG_TAG,
                         "RIVE_LIFECYCLE TSFN_CREATE renderer=%{public}p", this);
        }
    }

    m_worker->Run([this](DrawableThreadState *threadState) {
        if (!m_workerImpl) {
            return;
        }

        auto now = std::chrono::steady_clock::now();
        m_fpsLastFrameTime = now;
        m_workerImpl->start(now);
    });
}

// 停止渲染循环
// 若已调度销毁则直接返回，避免对已释放资源操作
void Renderer::Stop()
{
    if (m_isDisposeScheduled) {
        return;
    }
    // 在工作线程中安全地停止底层渲染实现
    m_worker->Run([this](DrawableThreadState *threadState) {
        if (!m_workerImpl) {
            return;
        }
        m_workerImpl->stop();
    });
}

// 执行一帧渲染：若未处于销毁流程且未超限，则向工作线程投递渲染任务
void Renderer::DoFrame()
{
    // 若已触发销毁流程，直接返回，避免对已释放资源操作
    if (m_isDisposeScheduled) {
        return;
    }

    // 防止帧任务堆积：若已调度帧数达到上限，跳过本次请求
    if (m_numScheduledFrames >= kMaxScheduledFrames) {
        return;
    }

    m_worker->Run([this](DrawableThreadState *threadState) {
        if (!m_workerImpl) {
            return;
        }

        auto now = std::chrono::high_resolution_clock::now();
        m_workerImpl->doFrame(m_tracer.get(), threadState, now, this, m_tsfn);
        m_numScheduledFrames--;
        CalculateFps(now);
    });

    // 增加已调度帧计数，表示已提交一个异步帧任务
    m_numScheduledFrames++;
}

std::unique_ptr<ITracer> Renderer::MakeTracer(bool trace)
{
    if (!trace) {
        return std::make_unique<NoopTracer>();
    } else {
        return std::make_unique<Tracer>();
    }
}

void Renderer::CalculateFps(std::chrono::high_resolution_clock::time_point frameTime)
{
    m_tracer->beginSection("CalculateFps()");
    static constexpr int FPS_SAMPLES = 10;
    double elapsed = std::chrono::duration<double>(frameTime - m_fpsLastFrameTime).count();
    if (elapsed == 0) {
        return;
    }
    m_fpsSum += 1.0f / elapsed;
    m_fpsCount++;
    if (m_fpsCount == FPS_SAMPLES) {
        m_averageFps = m_fpsSum / static_cast<double>(FPS_SAMPLES);
        m_fpsSum = 0;
        m_fpsCount = 0;
    }
    m_fpsLastFrameTime = frameTime;
    m_tracer->endSection();
}

void Renderer::AcquireSurface(SurfaceVariant &surface)
{
    if (auto *window = std::get_if<EGLNativeWindowType>(&surface)) {
        OH_NativeWindow_NativeObjectReference(reinterpret_cast<void *>(*window));
    } else if (auto *window = std::get_if<OHNativeWindow *>(&surface)) {
        OH_NativeWindow_NativeObjectReference(reinterpret_cast<void *>(*window));
    }
    // monostate is a real transition: leaving the previous window here would
    // recreate a surface on detach and later release the same reference twice.
    m_surface = surface;
}

void Renderer::ReleaseSurface(SurfaceVariant &surface)
{
    if (auto *window = std::get_if<EGLNativeWindowType>(&surface)) {
        OH_NativeWindow_NativeObjectUnreference(reinterpret_cast<void *>(*window));
    } else if (auto *window = std::get_if<OHNativeWindow *>(&surface)) {
        OH_NativeWindow_NativeObjectUnreference(reinterpret_cast<void *>(*window));
    }
}

int Renderer::GetWidth(bool isDraw) const
{
    if (GetRendererType() == RendererType::CANVAS) {
        if (m_workerThreadID == std::thread::id{} || !m_workerImpl) {
            return INVALID_DIMENSION;
        }

        // CanvasRenderer is bound after the first JS draw callback. Layout
        // sizing runs in that callback, so read the already-created surface.
        return m_workerImpl->getWidth();
    } else if (auto window = std::get_if<EGLNativeWindowType>(&m_surface)) {
        if (!isDraw) {
            int width = 0;
            int height = 0;
            OHNativeWindow *nativeWindow = reinterpret_cast<OHNativeWindow *>(*window);
            OH_NativeWindow_NativeWindowHandleOpt(nativeWindow, GET_BUFFER_GEOMETRY, &height, &width);
            return width;
        } else if (m_workerImpl) {
            return m_workerImpl->getWidth();
        }
    }

    return INVALID_DIMENSION;
}

int Renderer::GetHeight(bool isDraw) const
{
    if (GetRendererType() == RendererType::CANVAS) {
        if (m_workerThreadID == std::thread::id{} || !m_workerImpl) {
            return INVALID_DIMENSION;
        }

        return m_workerImpl->getHeight();
    } else if (auto window = std::get_if<EGLNativeWindowType>(&m_surface)) {
        if (!isDraw) {
            int width = 0;
            int height = 0;
            OHNativeWindow *nativeWindow = reinterpret_cast<OHNativeWindow *>(*window);
            OH_NativeWindow_NativeWindowHandleOpt(nativeWindow, GET_BUFFER_GEOMETRY, &height, &width);
            return height;
        } else if (m_workerImpl) {
            return m_workerImpl->getHeight();
        }
    }
    return INVALID_DIMENSION;
}

bool Renderer::CallRendererMethod(const char *methodName)
{
    if (m_env == nullptr || methodName == nullptr || m_renderer == nullptr) {
        return false;
    }

    napi_value method;
    if (napi_get_named_property(m_env, m_renderer, methodName, &method) != napi_ok) {
        return false;
    }

    napi_valuetype type;
    napi_typeof(m_env, method, &type);
    if (type != napi_function) {
        return false;
    }

    napi_value result;
    if (napi_call_function(m_env, m_renderer, method, 0, nullptr, &result) != napi_ok) {
        return false;
    }
    return true;
}
} // namespace ohos_rive
