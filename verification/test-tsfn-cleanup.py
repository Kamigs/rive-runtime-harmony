#!/usr/bin/env python3
"""Exercise the actual TSFNCallback body without a Harmony VM.

Minimal Node-API stubs make any accidental JS call during null-env draining fail.
Captured lifetime sentinels detect leaked data; the old env==null early return
fails this test. This is not an OS env-teardown integration test.
"""
from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', type=Path)
args = parser.parse_args()
source = args.source or Path(__file__).resolve().parents[1] / 'library/src/main/cpp/src/models/renderer.cpp'
text = source.read_text()
start = text.index('void Renderer::TSFNCallback(')
end = text.index('\nvoid Renderer::TSFNCallbackExecuteCallback', start)
callback = text[start:end]
prefix = r'''
#include <cassert>
#include <functional>
#include <memory>
#include <iostream>
using napi_env = void*;
using napi_value = void*;
using napi_handle_scope = void*;
int jsCalls = 0;
int napi_open_handle_scope(napi_env env, napi_handle_scope* scope) { assert(env); *scope=env; return 0; }
int napi_close_handle_scope(napi_env env, napi_handle_scope) { assert(env); return 0; }
struct TSFNData {
    enum class Type { ADVANCE, DRAW, ADVANCE_AND_DRAW, DISPOSE };
    Type type;
    std::function<void()> completionCallback;
};
class Renderer {
public:
    bool disposed = false;
    bool IsDisposeScheduled() const { return disposed; }
    static void TSFNCallback(napi_env, napi_value, void*, void*);
    static void TSFNCallbackExecuteCallback(napi_env env, napi_value cb, TSFNData*) {
        assert(env && cb); ++jsCalls;
    }
};
'''
suffix = r'''
int main() {
    int dummy=0;
    for (auto type: {TSFNData::Type::ADVANCE, TSFNData::Type::DRAW,
                    TSFNData::Type::ADVANCE_AND_DRAW, TSFNData::Type::DISPOSE}) {
        for (bool nullEnv: {true, false}) {
            bool completed=false;
            auto lifetime=std::make_shared<int>(42);
            std::weak_ptr<int> weak=lifetime;
            auto* data=new TSFNData{type, [lifetime, &completed]() { completed=true; }};
            lifetime.reset();
            // Intentionally invalid context: closed-env cleanup must not dereference it.
            Renderer::TSFNCallback(nullEnv ? nullptr : &dummy,
                                   nullEnv ? &dummy : nullptr,
                                   reinterpret_cast<void*>(1), data);
            if (!weak.expired()) {
                std::cerr << "FAIL: queued callback data retained after closed-env drain\n";
                return 2;
            }
            assert(completed == (type == TSFNData::Type::DISPOSE));
        }
    }
    Renderer::TSFNCallback(nullptr,nullptr,nullptr,nullptr);
    assert(jsCalls==0);
    Renderer renderer;
    bool completed=false;
    Renderer::TSFNCallback(&dummy,&dummy,&renderer,
        new TSFNData{TSFNData::Type::ADVANCE_AND_DRAW,[&]() {completed=true;}});
    assert(jsCalls==1 && completed);
    renderer.disposed=true;
    completed=false;
    Renderer::TSFNCallback(&dummy,&dummy,&renderer,
        new TSFNData{TSFNData::Type::ADVANCE_AND_DRAW,[&]() {completed=true;}});
    assert(jsCalls==1 && !completed);
    Renderer::TSFNCallback(&dummy,&dummy,&renderer,
        new TSFNData{TSFNData::Type::DISPOSE,[&]() {completed=true;}});
    assert(jsCalls==2 && completed);
    std::cout << "PASS: 8 closed-env/callback cases, normal dispatch, stale frame, dispose\n";
}
'''
with tempfile.TemporaryDirectory(prefix='rive-tsfn-') as tmp:
    cpp = Path(tmp) / 'test.cpp'; binary = Path(tmp) / 'test'
    cpp.write_text(prefix + callback + suffix)
    subprocess.run(['clang++','-std=c++17','-fsanitize=address,undefined','-g',str(cpp),'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
