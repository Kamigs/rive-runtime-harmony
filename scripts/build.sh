#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/build-env.sh"
mode=${1:-release}
case "$mode" in release|debug) ;; *) echo 'Usage: scripts/build.sh [release|debug]' >&2; exit 2;; esac
cd "$root"
python3 scripts/restore-dependencies.py --check
# Refresh Hvigor's external configuration so edits in runtime/ are noticed.
devecocli build clean
devecocli build --modules rive_ohos --build-mode "$mode"
python3 - "$mode" <<'PY'
import hashlib, json, shutil, sys
from pathlib import Path
version = json.loads(Path('library/oh-package.json5').read_text())['version']
out = Path('dist'); out.mkdir(exist_ok=True)
target = out / f'rive-harmony-{version}-api26-{sys.argv[1]}.har'
shutil.copyfile('library/build/default/outputs/default/rive_ohos.har', target)
digest = hashlib.sha256(target.read_bytes()).hexdigest()
target.with_suffix('.har.sha256').write_text(f'{digest}  {target.name}\n')
print(f'HAR: {target.resolve()}\nSHA256: {digest}')
PY
