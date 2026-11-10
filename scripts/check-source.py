#!/usr/bin/env python3
"""Verify extraction integrity of runtime, ArkTS implementation, native bindings and fixtures."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
manifest = json.loads((ROOT / 'verification/extraction-manifest.json').read_text())
prefixes = ('runtime/', 'library/Index.ets', 'library/src/', 'examples/har-consumer/entry/src/',
            'examples/flutter-comparison/assets/', 'examples/cli-projects/')
# Only the SDK fallback in this build file changed during extraction.
exceptions = {'library/src/main/cpp/CMakeLists.txt'}
counts = {}
errors = []
for row in manifest['files']:
    name = row['path']
    if not name.startswith(prefixes) or name in exceptions:
        continue
    path = ROOT / name
    actual = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
    if actual != row['sha256']:
        errors.append(name)
    group = 'runtime' if name.startswith('runtime/') else name.split('/')[0]
    counts[group] = counts.get(group, 0) + 1
print(json.dumps({'source_commit':manifest['source_commit'], 'checked':counts,
                  'changed_or_missing':errors}, indent=2))
raise SystemExit(bool(errors))
