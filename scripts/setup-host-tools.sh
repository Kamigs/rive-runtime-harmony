#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
toolroot=${RIVE_HOST_TOOLS:-$root/.tools}
mkdir -p "$toolroot"
# Premake beta7 is built from the commit in dependencies.lock.json by build_rive.sh.
# PLY comes from the same locked source dependencies; only host Ninja is installed here.
python3 -m pip install --target "$toolroot/ninja-python" 'ninja==1.11.1.3'
"$toolroot/ninja-python/bin/ninja" --version
