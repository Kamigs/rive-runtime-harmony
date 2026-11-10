#!/usr/bin/env python3
"""Capture the exact published HAR declaration surface without inferring behavior."""
import argparse
import hashlib
import json
import re
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('package', type=Path, help='Extracted HAR package/ directory')
parser.add_argument('output', type=Path)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
index = (args.package / 'Index.d.ets').read_text()
exports = []
for names, module in re.findall(r'export\s*\{(.*?)\}\s*from\s*[\'"](.*?)[\'"]', index, re.S):
    exports.append({'module': module, 'exports': [n.strip() for n in names.split(',') if n.strip()]})
files = {}
parts = ['# @ohos/rive 1.0.4 发布包声明清单\n',
         '以下从发布 HAR 的 `.d.ets` 生成，保留参数、可选性、返回类型和回调签名。'
         '默认值和运行行为不能从声明推断，另见 API 兼容记录。\n']
for path in sorted(args.package.rglob('*.d.ets')):
    name = path.relative_to(args.package).as_posix()
    declaration = path.read_text()
    files[name] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'declaration': declaration}
    # Keep internal declarations in JSON; report root exports and their declaration modules.
    root_exported = name == 'Index.d.ets' or any(e['module'].removeprefix('./') + '.d.ets' == name for e in exports)
    if root_exported:
        visible = '\n'.join(line for line in declaration.splitlines() if not line.strip().startswith('private '))
        parts.append(f'## {name}\n\n```typescript\n{visible}\n```\n')
manifest = {'root_exports': exports, 'declaration_files': files}
(args.output / 'published-api.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
(args.output / 'published-api.md').write_text('\n'.join(parts))
print(f'{len(exports)} export groups; {len(files)} declaration files captured')
