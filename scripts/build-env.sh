#!/usr/bin/env bash
# Sourced by build scripts; SDK and host tools remain machine-local.
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export DEVECO_CLI_STUDIO_PATH=${DEVECO_CLI_STUDIO_PATH:-/Applications/DevEco-Studio.app}
export OHOS_NDK=${OHOS_NDK:-$DEVECO_CLI_STUDIO_PATH/Contents/sdk/default/openharmony/native}
toolroot=${RIVE_HOST_TOOLS:-$root/.tools}
export RIVE_NINJA=${RIVE_NINJA:-$toolroot/ninja-python/bin/ninja}
if [[ ! -x "$OHOS_NDK/llvm/bin/clang++" || ! -x "$RIVE_NINJA" ]]; then
    echo 'Set DEVECO_CLI_STUDIO_PATH/OHOS_NDK to SDK26 and run scripts/setup-host-tools.sh (or set RIVE_NINJA).' >&2
    exit 1
fi
export PYTHONPATH="$root/library/src/main/cpp/dependencies/dabeaz_ply_3.11${PYTHONPATH:+:$PYTHONPATH}"
export NODE_OPTIONS="${NODE_OPTIONS:-} --require=$root/verification/host-ninja.cjs"
export RIVE_PREMAKE_TAG=v5.0.0-beta7
