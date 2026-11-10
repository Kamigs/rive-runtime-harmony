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

#ifndef OHOS_RIVE_TRACER_H
#define OHOS_RIVE_TRACER_H

#include "helpers/general.h"
#include <hitrace/trace.h>

namespace ohos_rive {
/**
 * Interface for a generic Tracer
 */
class ITracer {
public:
    ITracer() = default;
    virtual ~ITracer() = default;
    virtual void beginSection(const char *sectionName) = 0;
    virtual void endSection() = 0;
};

class NoopTracer : public ITracer {
public:
    NoopTracer() = default;
    ~NoopTracer() override = default;
    void beginSection(const char *sectionName) override {};
    void endSection() override {};
};

class Tracer : public ITracer {
public:
    Tracer() = default;
    ~Tracer() override = default;

    void beginSection(const char *sectionName) override
    {
        if (sectionName != nullptr) {
            OH_HiTrace_StartTrace(sectionName);
        }
    };

    void endSection() override
    {
        OH_HiTrace_FinishTrace();
    };

};
} // namespace ohos_rive

#endif // OHOS_RIVE_TRACER_H
