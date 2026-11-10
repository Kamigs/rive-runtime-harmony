#!/usr/bin/env bash
# Capture the short CLI bounce on-device, avoiding host round-trip latency.
set -euo pipefail
serial=${1:?device serial}; output=${2:?output directory}
mkdir -p "$output"; output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
devecocli ui layout --device "$serial" --format json > "$output/layout.json"
read -r x y < <(python3 - "$output/layout.json" <<'PY'
import json, sys
def walk(nodes):
    for n in nodes:
        yield n
        yield from walk(n.get('children', []))
nodes=json.JSONDecoder().raw_decode(open(sys.argv[1]).read().lstrip())[0]
node=next(n for n in walk(nodes) if n.get('id') == 'trigger-bump')
x1,y1,x2,y2=node['bounds']; print((x1+x2)//2, (y1+y2)//2)
PY
)
remote="/data/local/tmp/rive-trigger-$(date +%s)"
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$output/timing.txt"
"$hdc" -t "$serial" shell "mkdir -p '$remote'; (i=0; while [ \"\$i\" -lt 24 ]; do snapshot_display -f '$remote/frame-'\$i'.jpeg' -w 660 -h 1424 > /dev/null; i=\$((i+1)); done) & uitest uiInput click '$x' '$y'; wait"
date -u '+%Y-%m-%dT%H:%M:%SZ' >> "$output/timing.txt"
"$hdc" -t "$serial" file recv "$remote/" "$output/" > "$output/pull.log" 2>&1
python3 - "$output" <<'PY'
from pathlib import Path
import sys
frames=list(Path(sys.argv[1]).rglob('frame-*.jpeg'))
assert len(frames) == 24, f'Expected 24 captures, got {len(frames)}; inspect pull.log'
PY
