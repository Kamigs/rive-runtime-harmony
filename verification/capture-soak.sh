#!/usr/bin/env bash
# Bounded device/emulator soak; this does not measure energy efficiency.
set -euo pipefail
serial=${1:?device serial}; output=${2:?output directory}; minutes=${3:-10}; renderer=${4:-rive}
root=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$output"; output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
exec > >(tee "$output/actions.log") 2>&1
bash "$root/launch-fixture.sh" "$serial" vehicles.riv "$output/launch" "$renderer"
pid=$("$hdc" -t "$serial" shell pidof com.mgclub.rivevalidation | tr -d '\r\n')
printf '%s\n' "$pid" > "$output/pid.txt"
for ((n=0; n<=minutes; n++)); do
  current=$("$hdc" -t "$serial" shell pidof com.mgclub.rivevalidation | tr -d '\r\n')
  [[ "$current" == "$pid" ]] || { echo "Process changed: $pid -> $current"; exit 1; }
  date -u '+%Y-%m-%dT%H:%M:%SZ' >> "$output/sample-times.txt"
  "$hdc" -t "$serial" shell hidumper --mem "$pid" > "$output/memory-$n.txt"
  devecocli ui click --device "$serial" --id report-metrics
  devecocli log --device "$serial" --keyword RiveValidation --from 1m --tail 30 >> "$output/checkpoints.log" 2>&1
  devecocli ui screenshot --device "$serial" --path "$output/frame-$n.png"
  [[ "$n" == "$minutes" ]] || sleep 60
done
devecocli ui click --device "$serial" --id mount-toggle
sleep 5
"$hdc" -t "$serial" shell hidumper --mem "$pid" > "$output/memory-disposed.txt"
devecocli ui screenshot --device "$serial" --path "$output/disposed.png"
devecocli log --device "$serial" --crash --bundle-name com.mgclub.rivevalidation > "$output/crash-query.txt" 2>&1
python3 - "$output" "$minutes" <<'PY'
import json, pathlib, re, sys
p=pathlib.Path(sys.argv[1]); rows=[]
for n in range(int(sys.argv[2])+1):
    text=(p/f'memory-{n}.txt').read_text()
    total=re.search(r'^\s*Total\s+(\d+)', text, re.M)
    graph=re.search(r'^\s*Graph\s+(\d+)', text, re.M)
    rows.append({'sample':n,'pss_kib':int(total[1]) if total else None,'graph_kib':int(graph[1]) if graph else None})
report={'requested_minutes':int(sys.argv[2]),'samples':rows,'note':'bounded runtime sample; not a long-term leak-free or energy-efficiency proof'}
(p/'summary.json').write_text(json.dumps(report,indent=2)+'\n')
print(report)
PY
