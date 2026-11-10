#!/usr/bin/env bash
set -euo pipefail
device=${1:?device serial}
output=${2:?output directory}
count=${3:-100}
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
mkdir -p "$output"
output=$(cd "$output" && pwd)
remote="/data/local/tmp/rive-burst-$(date +%s)"
# Call this only after the host reports a loaded file and a visible first frame.
# Startup frames are a separate first-frame measurement, not playback flicker.
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$output/timing.txt"
"$hdc" -t "$device" shell "mkdir -p '$remote'; i=0; while [ \"\$i\" -lt '$count' ]; do snapshot_display -f '$remote/frame-'\$i'.jpeg' -w 660 -h 1424 > /dev/null; i=\$((i+1)); done"
date -u '+%Y-%m-%dT%H:%M:%SZ' >> "$output/timing.txt"
"$hdc" -t "$device" file recv "$remote/" "$output/" > "$output/pull.log" 2>&1
python3 - "$output" "$count" <<'PY'
from pathlib import Path
from PIL import Image
import json, sys
root=Path(sys.argv[1]); files=sorted(root.rglob('frame-*.jpeg'))
assert len(files)==int(sys.argv[2]), (len(files),sys.argv[2])
rows=[]
for p in files:
    im=Image.open(p).convert('RGB')
    color=im.getpixel((60,410))
    rows.append({'file':str(p.relative_to(root)), 'canvas_background':color,
                 'blank': max(color)-min(color)<10 and min(color)>230})
report={'frames':len(rows),'blank_frames':sum(r['blank'] for r in rows),'samples':rows}
(root/'frame-analysis.json').write_text(json.dumps(report,indent=2)+'\n')
print({k:v for k,v in report.items() if k!='samples'})
PY
