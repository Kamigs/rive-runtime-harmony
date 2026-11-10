#!/usr/bin/env python3
"""Copy the actual built HAR to the independent example's local dependency."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parent.parent
version = json.loads((ROOT / 'library/oh-package.json5').read_text())['version']
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--har', type=Path, default=ROOT / f'dist/rive-harmony-{version}-api26-release.har')
args = parser.parse_args()
target = ROOT / 'examples/libs/rive.har'
target.parent.mkdir(exist_ok=True)
shutil.copyfile(args.har, target)
host = ROOT / 'examples/har-consumer'
if not (host / 'build-profile.json5').exists():
    shutil.copyfile(host / 'build-profile.template.json5', host / 'build-profile.json5')
print(f'{hashlib.sha256(target.read_bytes()).hexdigest()}  {target}')
