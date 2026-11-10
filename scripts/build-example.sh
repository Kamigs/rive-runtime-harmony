#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/build-env.sh"
cd "$root"
python3 scripts/prepare-example.py "$@"
cd examples/har-consumer
# devecocli build resolves OHPM packages, including the actual local HAR.
devecocli build --modules entry --build-mode release
cd "$root"
python3 - <<'PY'
import hashlib, json, shutil
from pathlib import Path
version = json.loads(Path('library/oh-package.json5').read_text())['version']
output = Path('examples/har-consumer/entry/build/default/outputs/default')
dist = Path('dist'); dist.mkdir(exist_ok=True)
for path in sorted(output.glob('*.hap')):
    kind = 'unsigned' if 'unsigned' in path.name else 'signed'
    target = dist / f'rive-validation-{version}-api26-release-{kind}.hap'
    shutil.copyfile(path, target)
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    target.with_suffix('.hap.sha256').write_text(f'{digest}  {target.name}\n')
    print(f'HAP: {target.resolve()}\nSHA256: {digest}')
PY
