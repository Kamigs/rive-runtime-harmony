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
#include "models/worker_impl.h"
#include "helpers/exception_handler.h"
#include "helpers/thread_state_egl.h"

#include "rive/audio/audio_engine.hpp"
#include "rive/renderer/gl/render_target_gl.hpp"

#include "napi/native_api.h"
#include <native_drawing/drawing_bitmap.h>
#include <native_drawing/drawing_rect.h>
#include <native_window/external_window.h>
#include <sys/mman.h>
#include <poll.h>
#include <unistd.h>
#include <cerrno>

namespace ohos_rive {
// R6.3: bounded wait for the JS ADVANCE/DRAW handshake. Only hit on the abnormal
// path (JS not responding / component torn down mid-frame); normal frames complete
// in a few milliseconds. Prevents the single shared worker thread from pinning
// forever (the white-screen deadlock this replaces).
constexpr auto CALLBACK_TIMEOUT = std::chrono::milliseconds(500);

std::unique_ptr<WorkerImpl> WorkerImpl::Make(SurfaceVariant surface,
                                             DrawableThreadState *threadState,
                                             const RendererType type)
{
    if (surface.index() <= 0) {
        LOGE("Invalid surface index.");
        return nullptr;
    }
    bool success = false;
    std::unique_ptr<WorkerImpl> impl;
    switch (type) {
        case RendererType::RIVE: {
            EGLNativeWindowType window = std::get<EGLNativeWindowType>(surface);
            impl = std::make_unique<PLSWorkerImpl>(window, threadState, &success);
            break;
        }
        case RendererType::CANVAS: {
            OHNativeWindow *window = std::get<OHNativeWindow *>(surface);
            impl = std::make_unique<CanvasWorkerImpl>(window, &success);
            break;
        }
        default:
            break;
    }
    if (!success) {
        impl->destroy(threadState);
        impl.reset();
    }
    return impl;
}

// 启动 Worker，记录起始帧时间并标记为已启动状态
void WorkerImpl::start(std::chrono::high_resolution_clock::time_point frameTime)
{
    m_lastFrameTime = frameTime; // 保存当前帧时间，用于后续帧间时间差计算
    m_isStarted = true;          // 设置启动标志，表示 Worker 已开始运行

#ifdef WITH_RIVE_AUDIO
    // 若编译时开启音频支持，则启动 Rive 音频引擎
    if (auto engine = rive::AudioEngine::RuntimeEngine(false)) {
        engine->start();
    }
#endif
}

// 停止 Worker 的主流程
void WorkerImpl::stop()
{
    // 如果尚未启动，直接返回，避免重复操作
    if (!m_isStarted) {
        return;
    }
#ifdef WITH_RIVE_AUDIO
    // 若编译时开启音频支持，则停止 Rive 音频引擎
    if (auto engine = rive::AudioEngine::RuntimeEngine(false)) {
        engine->stop();
    }
#endif
    // 标记 Worker 为已停止状态
    m_isStarted = false;
}

static void draw(Renderer* renderer)
{
    Renderer::PendingDraw draw;
    if (!renderer->TakePendingDraw(draw)) {
        return; // Nothing was staged; no File ref was transferred.
    }
    // TakePendingDraw transferred ownership of the staged File ref to `draw`. It MUST be
    // released before returning (below) — the File was ref'd in SetPendingDraw to keep it
    // (and the shared Animations/StateMachines the ArtboardInstance dereferences) alive
    // across this worker draw. See PendingDraw::file.
    auto* dArtboard = draw.artboard;
    auto* dRenderer = draw.renderer;
    if (draw.isValid && dArtboard != nullptr && dRenderer != nullptr) {
        if (draw.isDrawAligned) {
            float w = static_cast<float>(renderer->GetWidth(true));
            float h = static_cast<float>(renderer->GetHeight(true));

            dRenderer->save();
            dRenderer->align(draw.fit, draw.alignment, rive::AABB(0, 0, w, h), dArtboard->bounds(),
                             draw.scaleFactor);
            dArtboard->draw(dRenderer);
            dRenderer->restore();
        } else {
            dArtboard->draw(dRenderer);
        }
    }
    // Always release the transferred File ref (a stage with a null artboard still
    // transfers it). rive::File is RefCnt (thread-safe atomic unref); the File is freed
    // only when the last ref drops, so a JS-thread release that raced this draw could not
    // have freed it mid-draw. The File ref keeps the shared Animations/StateMachines the
    // ArtboardInstance dereferences alive — the confirmed UAF root cause.
    if (draw.file != nullptr) {
        draw.file->unref();
    }
}

// 执行一帧渲染的主流程
void WorkerImpl::doFrame(ITracer *tracer,
                         DrawableThreadState *threadState,
                         std::chrono::high_resolution_clock::time_point frameTime,
                         Renderer* renderer,
                         napi_threadsafe_function worker_tsfn)
{
    // 将帧时间转换为毫秒精度，方便后续日志或调试
    auto timestamp_ms = std::chrono::time_point_cast<std::chrono::milliseconds>(frameTime);

    // 若 Worker 未启动，直接跳过本帧
    if (!m_isStarted) {
        LOGE("Worker not started, skipping frame");
        return;
    }

    // R6.3: bail immediately if this Renderer is being torn down. The shared worker
    // thread must never block on (or do work for) a disposing Renderer — its JS
    // callbacks will not arrive, and continuing could dereference a freed Artboard.
    if (renderer->IsDisposeScheduled()) {
        return;
    }

    // 计算距离上一帧的耗时（毫秒）
    float elapsedMs = std::chrono::duration<float>(frameTime - m_lastFrameTime).count();
    m_lastFrameTime = frameTime; // 更新上一帧时间
    tracer->beginSection("Rive::frame");

    // R6.4: single JS roundtrip per frame. The worker used to send two TSFN messages
    // (ADVANCE then DRAW) and block on the JS thread twice per frame. We now send ONE
    // ADVANCE_AND_DRAW message; the JS callback runs advance(elapsed) then draw() back
    // to back, so the worker crosses to JS once and waits once. prepareForDraw (GL
    // makeCurrent + clear) moves AFTER the wait — it runs on the worker thread and only
    // needs to precede the actual draw(), which it still does. Clear ordering vs the JS
    // draw() (which only stages SetPendingDraw) is unchanged: clear happens after
    // SetPendingDraw and before TakePendingDraw, same as before.
    if (worker_tsfn != nullptr) {
        auto *frameData = new TSFNData{TSFNData::Type::ADVANCE_AND_DRAW};
        frameData->elapsedMs = elapsedMs; // 传递帧间隔
        frameData->frameTime = frameTime; // 传递当前帧时间
        frameCompleted.store(false, std::memory_order_release); // 重置完成标志
        frameData->completionCallback = [this]() {
            // Runs on the JS thread (inside TSFNCallback). Signal the worker's wait.
            std::lock_guard<std::mutex> lk(m_callbackMutex);
            frameCompleted.store(true, std::memory_order_release);
            m_callbackCv.notify_one();
        };
        // 非阻塞调用，将任务投递到 JS 线程
        const napi_status enqueueStatus =
            napi_call_threadsafe_function(worker_tsfn, frameData, napi_tsfn_nonblocking);
        if (enqueueStatus != napi_ok) {
            // Ownership only transfers to TSFNCallback after successful enqueue.
            delete frameData;
            tracer->endSection();
            return;
        }
        // Block (no spin) on the condition variable until the JS callback completes,
        // this Renderer is flagged for disposal, or the timeout elapses. The predicate
        // form is immune to lost notifications. The timeout is a safety net: if JS
        // never responds (component torn down, JS thread blocked elsewhere) we abandon
        // this frame rather than pinning the single shared worker thread forever
        // (the white-screen deadlock this replaces).
        std::unique_lock<std::mutex> lk(m_callbackMutex);
        m_callbackCv.wait_for(lk, CALLBACK_TIMEOUT, [this, renderer]() {
            return frameCompleted.load(std::memory_order_acquire) || renderer->IsDisposeScheduled();
        });
        lk.unlock();
        if (!frameCompleted.load(std::memory_order_acquire)) {
            // Distinguish the expected teardown path from a genuine timeout. When
            // MarkDisposing() is set (page exit), the wait predicate returns immediately
            // — frameCompleted is still false, but this is the designed bail, not a
            // stall. Only a true 500ms timeout (JS unresponsive) is worth a warning.
            if (renderer->IsDisposeScheduled()) {
                tracer->endSection();
                return;
            }
            LOGW("doFrame: ADVANCE_AND_DRAW handshake timed out (%lldms), skipping frame",
                 static_cast<long long>(CALLBACK_TIMEOUT.count()));
            tracer->endSection();
            return;
        }
    }

    // 进入绘制阶段，记录性能追踪区间
    tracer->beginSection("draw()");
    prepareForDraw(threadState); // 准备绘制上下文

    // gl线程自主完成绘制逻辑
    draw(renderer);

    // 刷新 GPU 指令，提交渲染命令
    tracer->beginSection("flush()");
    flush(threadState);
    tracer->endSection(); // flush

    // 交换前后缓冲区，将渲染结果呈现到屏幕
    tracer->beginSection("swapBuffers()");
    threadState->SwapBuffers();
    tracer->endSection(); // SwapBuffers

    tracer->endSection(); // draw
    tracer->endSection(); // Rive::frame, including the ArkTS roundtrip
}

/*
 * PLSWorkerImpl 构造函数：初始化基于 PLS（Pixel Local Storage）的 Worker 实现
 * 参数：
 *   window      – 平台原生窗口句柄（EGLNativeWindowType）
 *   threadState – 当前线程的绘制状态管理器
 *   success     – 输出参数，标记本阶段初始化是否成功
 */
PLSWorkerImpl::PLSWorkerImpl(EGLNativeWindowType window, DrawableThreadState *threadState, bool *success)
    : EGLWorkerImpl(window, threadState, success) // 先调用基类完成 EGL 相关初始化
{
    // 若基类 EGL 初始化失败，直接返回，不再继续
    if (!success) {
        LOGE("EGLWorkerImpl creation failed");
        return;
    }

    // 将通用线程状态转换为 EGL 专用状态，方便后续 EGL 调用
    auto eglThreadState = static_cast<EGLThreadState *>(threadState);

    // 将 EGL 上下文绑定到当前线程，确保后续 GL 指令在正确上下文执行
    eglThreadState->makeCurrent(m_eglSurface);

    // 获取 PLS 线程状态及其关联的 GPU 渲染上下文
    rive::gpu::RenderContext *renderContext = PLSWorkerImpl::PlsThreadState(eglThreadState)->renderContext();
    if (renderContext == nullptr) {
        LOGE("PLS render context is null, PLS not supported");
        return; // 当前环境不支持 PLS，提前结束
    }

    // 查询窗口实际宽高，用于创建与窗口尺寸匹配的渲染目标
    int32_t width = 0;
    int32_t height = 0;
    OH_NativeWindow_NativeWindowHandleOpt(reinterpret_cast<OHNativeWindow *>(window), GET_BUFFER_GEOMETRY, &height,
                                          &width);

    // 获取系统默认帧缓冲区的多重采样样本数，用于后续创建同采样配置的渲染目标
    GLint sampleCount;
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glGetIntegerv(GL_SAMPLES, &sampleCount);

    // 创建 PLS 渲染目标（FramebufferRenderTargetGL），尺寸与窗口一致，采样数与系统一致
    m_renderTarget = rive::make_rcp<rive::gpu::FramebufferRenderTargetGL>(width, height, 0, sampleCount);

    // 创建 Rive 渲染器，绑定到当前 GPU 渲染上下文
    m_plsRenderer = std::make_unique<rive::RiveRenderer>(renderContext);

    m_width = width;
    m_height = height;
    m_window = window;

    // 全部初始化成功，标记 success 为 true
    *success = true;
}

void PLSWorkerImpl::destroy(DrawableThreadState *threadState)
{
    m_plsRenderer.reset();
    m_renderTarget.reset();
    EGLWorkerImpl::destroy(threadState);
}

// 清空当前渲染目标，为下一帧绘制做准备
void PLSWorkerImpl::clear(DrawableThreadState *threadState) const
{
    // 获取当前线程的 PLS 状态，确保使用正确的渲染上下文
    PLSThreadState *plsThreadState = PLSWorkerImpl::PlsThreadState(threadState);
    // 取出 GPU 渲染上下文，用于提交清空命令
    rive::gpu::RenderContext *renderContext = plsThreadState->renderContext();
    // 开始新帧，指定渲染目标尺寸、加载动作为清空，并设置清空颜色为透明（0x00000000）
    renderContext->beginFrame({
        .renderTargetWidth = m_renderTarget->width(),
        .renderTargetHeight = m_renderTarget->height(),
        .loadAction = rive::gpu::LoadAction::clear,
        .clearColor = 0x00000000,
    });
}

// 将当前帧的渲染命令提交到 GPU，完成 PLS（Pixel Local Storage）管线的 flush 操作
void PLSWorkerImpl::flush(DrawableThreadState *threadState)
{
    // 获取当前线程的 PLS 状态对象，确保上下文正确
    PLSThreadState *plsThreadState = PLSWorkerImpl::PlsThreadState(threadState);
    // 取出与当前线程绑定的 Rive GPU 渲染上下文
    rive::gpu::RenderContext *renderContext = plsThreadState->renderContext();
    // 检查窗口尺寸是否与当前渲染目标一致，不一致则重新创建渲染目标
    checkNativeWindowSize();
    // 向 GPU 提交渲染命令，使用已构建的帧缓冲区渲染目标
    renderContext->flush({.renderTarget = m_renderTarget.get()});
}

rive::Renderer *PLSWorkerImpl::renderer() const
{
    return m_plsRenderer.get();
}

/* CanvasWorkerImpl */
void CanvasWorkerImpl::destroy(DrawableThreadState *)
{
    OH_Drawing_CanvasDestroy(cScreenCanvas_);
    cScreenCanvas_ = nullptr;
    m_canvasRenderer->UnlockAndPost();
    m_canvasRenderer.reset();

    OH_Drawing_BitmapDestroy(cScreenBitmap_);
    cScreenBitmap_ = nullptr;

    m_nativeWindow = nullptr;
}

void CanvasWorkerImpl::getDrawingCanvas(bool isGetWindowSize)
{
    if (isGetWindowSize) {
        OH_NativeWindow_NativeWindowHandleOpt(m_nativeWindow, GET_BUFFER_GEOMETRY, &height_, &width_);
        if (width_ <= 0 || height_ <= 0) {
            LOGE("Invalid window dimensions: %{public}d, %{public}d", width_, height_);
            return;
        }
    }

    // Share the Canvas surface dimensions with Renderer before the first JS draw.
    m_width = width_;
    m_height = height_;

    cScreenBitmap_ = OH_Drawing_BitmapCreate();
    if (!cScreenBitmap_) {
        LOGE("fail to create bitmap");
        return;
    }
    OH_Drawing_BitmapFormat cFormat{colorType, alphaType};
    OH_Drawing_BitmapBuild(cScreenBitmap_, width_, height_, &cFormat);
    cScreenCanvas_ = OH_Drawing_CanvasCreate();
    if (!cScreenCanvas_) {
        LOGE("fail to create canvas");
        return;
    }
    OH_Drawing_CanvasBind(cScreenCanvas_, cScreenBitmap_);
}

void CanvasWorkerImpl::prepareForDraw(DrawableThreadState *)
{
    int32_t currentWidth = 0;
    int32_t currentHeight = 0;
    OH_NativeWindow_NativeWindowHandleOpt(m_nativeWindow, GET_BUFFER_GEOMETRY, &currentHeight, &currentWidth);

    if (width_ != currentWidth || height_ != currentHeight || !cScreenCanvas_ || !cScreenBitmap_) {
        width_ = currentWidth;
        height_ = currentHeight;
        OH_Drawing_Canvas *oldCanvas = cScreenCanvas_;
        OH_Drawing_Bitmap *oldBitmap = cScreenBitmap_;

        const_cast<CanvasWorkerImpl *>(this)->getDrawingCanvas(false);
        if (oldCanvas && oldCanvas != cScreenCanvas_) {
            OH_Drawing_CanvasDestroy(oldCanvas);
        }
        if (oldBitmap && oldBitmap != cScreenBitmap_) {
            OH_Drawing_BitmapDestroy(oldBitmap);
        }
    }

    if (!cScreenCanvas_) {
        return;
    }
    OH_Drawing_CanvasClear(cScreenCanvas_, 0xFFFFFFFF);
    m_canvasRenderer->BindCanvas(cScreenCanvas_);
}

bool CanvasWorkerImpl::requestAndPrepareBuffer(NativeWindowBuffer **outBuffer,
                                               int *outFenceFd,
                                               BufferHandle **outBufferHandle,
                                               uint32_t **outMappedAddr) const
{
    int fenceFd = -1;
    int ret = OH_NativeWindow_NativeWindowRequestBuffer(m_nativeWindow, outBuffer, &fenceFd);
    if (ret != 0 || *outBuffer == nullptr) {
        LOGE("flush: request buffer failed");
        return false;
    }

    // RequestBuffer returns the consumer's release fence. CPU writes must wait
    // until that consumer has finished reading the buffer; it is not the fence
    // to pass back to FlushBuffer after producing a new frame.
    if (fenceFd >= 0) {
        pollfd fence{fenceFd, POLLIN, 0};
        int waitResult;
        do {
            waitResult = poll(&fence, 1, 3000);
        } while (waitResult < 0 && (errno == EINTR || errno == EAGAIN));
        close(fenceFd);
        if (waitResult <= 0 || !(fence.revents & POLLIN)) {
            LOGE("flush: consumer fence wait failed (%{public}d)", waitResult);
            OH_NativeWindow_NativeWindowAbortBuffer(m_nativeWindow, *outBuffer);
            return false;
        }
    }

    *outBufferHandle = OH_NativeWindow_GetBufferHandleFromNative(*outBuffer);
    if (!*outBufferHandle) {
        OH_NativeWindow_NativeWindowAbortBuffer(m_nativeWindow, *outBuffer);
        return false;
    }

    *outMappedAddr = static_cast<uint32_t *>(
        mmap(nullptr, (*outBufferHandle)->size, PROT_READ | PROT_WRITE, MAP_SHARED, (*outBufferHandle)->fd, 0));
    if (*outMappedAddr == MAP_FAILED) {
        LOGE("flush: mmap failed");
        OH_NativeWindow_NativeWindowAbortBuffer(m_nativeWindow, *outBuffer);
        return false;
    }

    *outFenceFd = -1; // CPU copy completes synchronously before FlushBuffer.
    return true;
}

bool CanvasWorkerImpl::getBitmapData(void **outBitmapAddr,
                                     int32_t *outBitmapWidth,
                                     int32_t *outBitmapHeight,
                                     int32_t *outBitmapStrideBytes) const
{
    void *bitmapAddr = OH_Drawing_BitmapGetPixels(cScreenBitmap_);
    if (!bitmapAddr) {
        LOGE("flush: get bitmap pixels failed");
        return false;
    }

    int32_t bitmapWidth = OH_Drawing_BitmapGetWidth(cScreenBitmap_);
    int32_t bitmapHeight = OH_Drawing_BitmapGetHeight(cScreenBitmap_);
    if (bitmapWidth <= 0 || bitmapHeight <= 0) {
        LOGE("flush: invalid bitmap dimensions");
        return false;
    }

    *outBitmapAddr = bitmapAddr;
    *outBitmapWidth = bitmapWidth;
    *outBitmapHeight = bitmapHeight;
    *outBitmapStrideBytes = bitmapWidth * NUM_FOUR;
    return true;
}

void CanvasWorkerImpl::flush(DrawableThreadState *)
{
    if (!cScreenCanvas_ || !m_nativeWindow || !m_canvasRenderer || !cScreenBitmap_) {
        return;
    }

    int32_t windowWidth = 0;
    int32_t windowHeight = 0;
    OH_NativeWindow_NativeWindowHandleOpt(m_nativeWindow, GET_BUFFER_GEOMETRY, &windowHeight, &windowWidth);
    if (width_ != windowWidth || height_ != windowHeight) {
        return;
    }

    NativeWindowBuffer *buffer = nullptr;
    int fenceFd = 0;
    BufferHandle *bufferHandle = nullptr;
    uint32_t *mappedAddr = nullptr;
    if (!requestAndPrepareBuffer(&buffer, &fenceFd, &bufferHandle, &mappedAddr)) {
        return;
    }

    void *bitmapAddr = nullptr;
    int32_t bitmapWidth = 0;
    int32_t bitmapHeight = 0;
    int32_t bitmapStrideBytes = 0;
    if (!getBitmapData(&bitmapAddr, &bitmapWidth, &bitmapHeight, &bitmapStrideBytes)) {
        munmap(mappedAddr, bufferHandle->size);
        OH_NativeWindow_NativeWindowAbortBuffer(m_nativeWindow, buffer);
        return;
    }

    int32_t windowStrideBytes = bufferHandle->stride;
    uint8_t *srcPixels = static_cast<uint8_t *>(bitmapAddr);
    uint8_t *dstPixels = reinterpret_cast<uint8_t *>(mappedAddr);
    for (int32_t y = 0; y < bitmapHeight && y < windowHeight; ++y) {
        uint8_t *srcRow = srcPixels + y * bitmapStrideBytes;
        uint8_t *dstRow = dstPixels + y * windowStrideBytes;

        int32_t copyWidthBytes = std::min(bitmapWidth, windowWidth) * 4;
        std::copy(srcRow, srcRow + copyWidthBytes, dstRow);
    }

    Region region{nullptr, 0};
    int ret = OH_NativeWindow_NativeWindowFlushBuffer(m_nativeWindow, buffer, fenceFd, region);
    if (ret != 0) {
        LOGE("flush: submit buffer failed (%{public}d)", ret);
        OH_NativeWindow_NativeWindowAbortBuffer(m_nativeWindow, buffer);
    }

    munmap(mappedAddr, bufferHandle->size);
}
} // namespace ohos_rive
