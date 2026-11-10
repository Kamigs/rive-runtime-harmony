#!/usr/bin/env python3
"""Read-only duplicate .so audit for HAP/APP inputs; never remove libraries.

Group by ABI first so arm64/x86 variants are not incorrectly reported as conflicts.
For a multi-HAP Release APP also run the SDK packing tool's --stat-duplicate.
"""
import argparse
import collections
import hashlib
import io
import json
import zipfile
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('packages', nargs='+', type=Path)
p.add_argument('--report', type=Path, required=True)
a = p.parse_args()
rows = []

def visit(data, origin):
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for name in archive.namelist():
            if name.endswith('.hap'):
                visit(archive.read(name), origin + '!' + name)
            elif name.endswith('.so'):
                payload = archive.read(name)
                path = Path(name)
                rows.append({'package': origin, 'path': name, 'abi': path.parent.name,
                             'name': path.name, 'bytes': len(payload),
                             'sha256': hashlib.sha256(payload).hexdigest()})

for source in a.packages:
    visit(source.read_bytes(), str(source.resolve()))
names = collections.defaultdict(list)
content = collections.defaultdict(list)
for row in rows:
    names[(row['abi'], row['name'])].append(row)
    content[(row['abi'], row['sha256'])].append(row)
report = {'libraries': rows,
          'same_name': [{'abi': k[0], 'name': k[1], 'identical': len({r['sha256'] for r in v}) == 1,
                         'copies': v} for k, v in names.items() if len(v) > 1],
          'same_content': [v for v in content.values() if len(v) > 1],
          'action': 'report only; no deduplication performed'}
a.report.parent.mkdir(parents=True, exist_ok=True)
a.report.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'libraries': len(rows), 'same_name_groups': len(report['same_name']),
                  'same_content_groups': len(report['same_content'])}))
