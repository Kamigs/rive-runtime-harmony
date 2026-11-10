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

#include <memory>
#include <vector>

#include "../../include/helpers/exception_handler.h"
#include "../../include/helpers/factories.h"
#include "../../include/helpers/resource.h"
#include "../../include/helpers/thread_state_pls.h"
#include "../../include/helpers/worker_ref.h"

#include "helpers/canvas_render_objects.h"
#include "helpers/image_decode.h"
#include "rive/math/math_types.hpp"
#include "rive/renderer/gl/render_buffer_gl_impl.hpp"
#include "rive/renderer/gl/render_context_gl_impl.hpp"
#include "rive/renderer/rive_render_factory.hpp"
#include "rive/renderer/rive_render_image.hpp"

using namespace rive;
using namespace rive::gpu;

namespace ohos_rive {

// Resolves the GL render context for the worker thread's DrawableThreadState.
// Returns null if the thread state is not a PLS thread state or the GL render
// context failed to initialize (PLSThreadState stays with a null renderContext
// if RenderContextGLImpl::MakeContext() failed). Shared by PLSRenderBuffer and
// OhosImage so both guard the same call chain consistently.
static RenderContextGLImpl *GetRenderContextGLImpl(DrawableThreadState *threadState)
{
    if (threadState == nullptr) {
        return nullptr;
    }
    auto *plsState = static_cast<PLSThreadState *>(threadState);
    auto *renderContext = plsState->renderContext();
    if (renderContext == nullptr) {
        return nullptr;
    }
    auto *renderContextImpl = renderContext->static_impl_cast<RenderContextGLImpl>();
    return renderContextImpl;
}
template <>
rive::rcp<rive::RenderImage> decode(rive::Span<const uint8_t> data, RendererType rendererType)
{
    rive::Factory *factory = GetFactory(rendererType);
    return factory->decodeImage(data);
}

template <>
rive::rcp<rive::Font> decode(rive::Span<const uint8_t> data, RendererType rendererType)
{
    rive::Factory *factory = GetFactory(rendererType);
    return factory->decodeFont(data);
}

template <>
rive::rcp<rive::AudioSource> decode(rive::Span<const uint8_t> data, RendererType rendererType)
{
    rive::Factory *factory = GetFactory(rendererType);
    return factory->decodeAudio(data);
}

class PLSRenderBuffer : public RenderBufferGLImpl {
public:
    PLSRenderBuffer(RenderBufferType type, RenderBufferFlags flags, size_t sizeInBytes)
        : RenderBufferGLImpl(type, flags, sizeInBytes), m_glWorker(RefWorker::RiveWorker())
    {
        if (std::this_thread::get_id() != m_glWorker->ThreadID()) {
            // We aren't on the GL thread. Init this object on the GL thread.
            // Keep this class alive until the worker thread finishes
            // initializing it.
            rcp<PLSRenderBuffer> thisRef = ref_rcp(this);
            m_bufferCreationWorkID = m_glWorker->Run([thisRef](DrawableThreadState *threadState) {
                thisRef->EnsureInitialized(threadState);
            });
        } else {
            EnsureInitialized(m_glWorker->GetThreadState());
            m_bufferCreationWorkID = WorkerThread::kWorkIDAlwaysFinished;
        }
    }

    ~PLSRenderBuffer() override
    {
        if (std::this_thread::get_id() != m_glWorker->ThreadID()) {
            // Ensure we are done initializing the buffers before we turn around
            // and delete them.
            m_glWorker->WaitUntilComplete(m_bufferCreationWorkID);
            // We aren't on the GL thread. Intercept the buffers before
            // ~RenderBufferGLImpl(), and then marshal them off to the GL thread
            // for deletion.
            auto bufferToDelete = detachBuffer();
            rcp<GLState> glState = ref_rcp(state());
            m_glWorker->Run([bufferToDelete, glState](DrawableThreadState *) {
                if (bufferToDelete != 0) {
                    glState->deleteBuffer(bufferToDelete);
                }
            });
        }
    }

    void *onMap() override
    {
        if (std::this_thread::get_id() != m_glWorker->ThreadID()) {
            // We aren't on the GL thread. Allocate a side buffer to fill.
            if (m_offThreadBufferDataMirror != nullptr) {
                LOGE("PLSRenderBuffer::onMap off-thread buffer mirror already allocated, buffer=%p", this);
                return nullptr;
            }
            m_offThreadBufferDataMirror.reset(new uint8_t[sizeInBytes()]);
            return m_offThreadBufferDataMirror.get();
        } else {
            // A RenderBuffer can be created while the Rive worker is blocked in its
            // worker -> JS draw handshake. Its queued initialization then sits behind
            // the current doFrame, while that same doFrame may immediately consume the
            // newly staged Mesh. Initialize inline on the GL worker before first use;
            // the queued initialization task observes state() and becomes a no-op.
            EnsureInitialized(m_glWorker->GetThreadState());
            if (state() == nullptr) {
                // init() should not fail on the GL worker thread in normal
                // operation. Callers of map() do not null-check the result, so
                // surface this loudly (LOGE is a no-op outside debug builds).
                LOGE("PLSRenderBuffer::onMap failed to initialize GL state, buffer=%p", this);
                return nullptr;
            }
            return RenderBufferGLImpl::onMap();
        }
    }

    void onUnmap() override
    {
        if (std::this_thread::get_id() != m_glWorker->ThreadID()) {
            // We aren't on the GL thread. Marshal our side buffer to the GL
            // thread to update the buffer.
            // Keep this class alive until the worker thread finishes updating
            // the buffer. The bytes are held in a shared_ptr so the lambda is
            // copyable (std::function requires a CopyConstructible target) and
            // the memory is freed even if Run() drops the task without running
            // it (e.g. the worker is terminated during teardown).
            std::shared_ptr<uint8_t[]> sideBufferData(m_offThreadBufferDataMirror.release());
            if (sideBufferData == nullptr) {
                LOGE("PLSRenderBuffer::onUnmap sideBufferData is nullptr, buffer=%p", this);
                return;
            }
            rcp<PLSRenderBuffer> thisRef = ref_rcp(this);
            m_glWorker->Run([sideBufferData, thisRef](DrawableThreadState *threadState) {
                thisRef->EnsureInitialized(threadState);
                if (thisRef->state() == nullptr) {
                    LOGE("PLSRenderBuffer::onUnmap failed to initialize GL state, buffer=%p", thisRef.get());
                    return;
                }
                void *ptr = thisRef->RenderBufferGLImpl::onMap();
                if (ptr && sideBufferData) {
                    auto *dst = static_cast<uint8_t *>(ptr);
                    std::copy(sideBufferData.get(), sideBufferData.get() + thisRef->sizeInBytes(), dst);
                }
                thisRef->RenderBufferGLImpl::onUnmap();
            });
        } else {
            if (m_offThreadBufferDataMirror) {
                LOGE("m_offThreadBufferDataMirror is not nullptr");
                return;
            }
            // Mirror onMap's guard: RenderBuffer::unmap() invokes onUnmap()
            // unconditionally, so it can be reached before GL state is ready.
            EnsureInitialized(m_glWorker->GetThreadState());
            if (state() == nullptr) {
                LOGE("PLSRenderBuffer::onUnmap failed to initialize GL state, buffer=%p", this);
                return;
            }
            RenderBufferGLImpl::onUnmap();
        }
    }

protected:
    void EnsureInitialized(DrawableThreadState *threadState)
    {
        // Initialization and all direct GL access are serialized on m_glWorker.
        // This guard also makes the constructor's originally queued init harmless
        // when first-use initialization has already run inline.
        if (state() != nullptr) {
            return;
        }
        auto *renderContextImpl = GetRenderContextGLImpl(threadState);
        if (renderContextImpl == nullptr || renderContextImpl->state() == nullptr) {
            LOGE("PLSRenderBuffer::EnsureInitialized renderContext/GLState is null, buffer=%p", this);
            return;
        }
        init(ref_rcp(renderContextImpl->state()));
    }

    const rcp<RefWorker> m_glWorker;
    std::unique_ptr<uint8_t[]> m_offThreadBufferDataMirror;
    // kWorkIDAlwaysFinished makes WaitUntilComplete a no-op if the constructor
    // throws before assigning a real WorkID; otherwise ~PLSRenderBuffer would
    // wait on an indeterminate value and deadlock.
    RefWorker::WorkID m_bufferCreationWorkID = WorkerThread::kWorkIDAlwaysFinished;
};

OhosImage::OhosImage(int width, int height, std::unique_ptr<const uint8_t[]> imageDataRGBAPtr)
    : RiveRenderImage(width, height), m_glWorker(ohos_rive::RefWorker::RiveWorker())
{
    // Create the texture on the worker thread where the GL context is current.
    // Hold the bytes in a shared_ptr so the memory is freed even if Run() drops
    // the task without running it (e.g. the worker is terminated during teardown),
    // consistent with onUnmap's sideBufferData handling.
    std::shared_ptr<const uint8_t[]> imageDataRGBA(imageDataRGBAPtr.release());
    // The caller may already be running on the GL worker thread (e.g. the worker
    // itself dropping the last reference during releaseResources/texture turnover).
    // In that case we must NOT re-enter the worker's queue/mutex via Run() — doing
    // so self-deadlocks the worker and freezes the JS main thread that decodes
    // images on this same worker (THREAD_BLOCK_6S appfreeze). Run the GL texture
    // creation inline instead. Mirrors the guard PLSRenderBuffer already has.
    if (std::this_thread::get_id() != m_glWorker->ThreadID()) {
        m_textureCreationWorkID = m_glWorker->Run([this, imageDataRGBA](ohos_rive::DrawableThreadState *threadState) {
            auto *renderContextImpl = GetRenderContextGLImpl(threadState);
            if (renderContextImpl == nullptr) {
                LOGE("OhosImage ctor failed to resolve GL render context on worker");
                return;
            }
            uint32_t mipLevelCount = math::msb(m_Height | m_Width);
            resetTexture(renderContextImpl->makeImageTexture(m_Width, m_Height, mipLevelCount, rive::GPUTextureFormat::rgba32, imageDataRGBA.get()));
        });
    } else {
        auto *renderContextImpl = GetRenderContextGLImpl(m_glWorker->GetThreadState());
        if (renderContextImpl == nullptr) {
            LOGE("OhosImage ctor failed to resolve GL render context, image=%p", this);
            return;
        }
        uint32_t mipLevelCount = math::msb(m_Height | m_Width);
        resetTexture(renderContextImpl->makeImageTexture(m_Width, m_Height, mipLevelCount, rive::GPUTextureFormat::rgba32, imageDataRGBA.get()));
        m_textureCreationWorkID = WorkerThread::kWorkIDAlwaysFinished;
    }
}

OhosImage::~OhosImage()
{
    // Ensure we are done initializing the texture before we turn around and
    // delete it.
    // If we are already on the GL worker thread, the texture was either created
    // inline above (kWorkIDAlwaysFinished) or is being torn down from within the
    // worker; in both cases WaitUntilComplete()/Run() would re-enter the worker's
    // mutex and self-deadlock. Skip the queue and operate inline.
    const bool onWorkerThread = std::this_thread::get_id() == m_glWorker->ThreadID();
    if (!onWorkerThread) {
        m_glWorker->WaitUntilComplete(m_textureCreationWorkID);
    }
    // Since this is the destructor, we know nobody else is using this
    // object anymore and there is not a race condition from accessing the
    // texture from any thread.
    Texture *texture = releaseTexture();
    if (texture != nullptr) {
        if (onWorkerThread) {
            // GL context is current on this thread; release the texture inline.
            texture->unref();
        } else {
            // Delete the texture on the worker thread where the GL context is
            // current.
            m_glWorker->Run([texture](ohos_rive::DrawableThreadState *) { texture->unref(); });
        }
    }
}

rcp<RenderBuffer> OhosRiveRenderFactory::makeRenderBuffer(RenderBufferType type,
                                                          RenderBufferFlags flags,
                                                          size_t sizeInBytes)
{
    return make_rcp<PLSRenderBuffer>(type, flags, sizeInBytes);
}

rcp<RenderImage> OhosRiveRenderFactory::decodeImage(Span<const uint8_t> encodedBytes)
{
    return renderImageFromNapiDecode(this->env, encodedBytes, true);
}

rive::rcp<rive::RenderBuffer> OhosCanvasFactory::makeRenderBuffer(rive::RenderBufferType type,
                                                                  rive::RenderBufferFlags flags,
                                                                  size_t sizeInBytes)
{
    return rive::make_rcp<rive::DataRenderBuffer>(type, flags, sizeInBytes);
}

rive::rcp<rive::RenderImage> OhosCanvasFactory::decodeImage(rive::Span<const uint8_t> encodedBytes)
{
    return make_rcp<CanvasRenderImage>(encodedBytes);
}

rive::rcp<rive::RenderShader> OhosCanvasFactory::makeLinearGradient(float sx,
                                                                    float sy,
                                                                    float ex,
                                                                    float ey,
                                                                    const rive::ColorInt colors[],
                                                                    const float stops[],
                                                                    size_t count)
{
    LinearData position = {sx, sy, ex, ey};
    return rive::rcp<rive::RenderShader>(new LinearGradientCanvasShader(position, colors, stops, count));
}

rive::rcp<rive::RenderShader> OhosCanvasFactory::makeRadialGradient(float cx,
                                                                    float cy,
                                                                    float radius,
                                                                    const rive::ColorInt colors[],
                                                                    const float stops[],
                                                                    size_t count)
{
    RadialData position = {cx, cy, radius};
    return rive::rcp<rive::RenderShader>(new RadialGradientCanvasShader(position, colors, stops, count));
}

rive::rcp<rive::RenderPath> OhosCanvasFactory::makeRenderPath(rive::RawPath &rawPath, rive::FillRule fillRule)
{
    return rive::make_rcp<CanvasRenderPath>(rawPath, fillRule);
}

rive::rcp<rive::RenderPath> OhosCanvasFactory::makeEmptyRenderPath()
{
    return rive::make_rcp<CanvasRenderPath>();
}

rive::rcp<rive::RenderPaint> OhosCanvasFactory::makeRenderPaint()
{
    return rive::make_rcp<CanvasRenderPaint>();
}
} // namespace ohos_rive
