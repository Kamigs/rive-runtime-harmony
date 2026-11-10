#!/usr/bin/env bash
# Regression for the host's borrowed animation reference and subsequent file swap.
set -euo pipefail
serial=${1:?device serial}; output=${2:?output directory}
root=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$output"; output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
exec > >(tee "$output/actions.log") 2>&1
devecocli log --device "$serial" --keyword Rive --follow > "$output/stream.log" 2>&1 &
logger=$!
trap 'kill "$logger" 2>/dev/null || true; wait "$logger" 2>/dev/null || true' EXIT
for backend in canvas rive; do
  folder="$output/$backend"
  bash "$root/launch-fixture.sh" "$serial" vehicles.riv "$folder" "$backend"
  "$hdc" -t "$serial" shell pidof com.mgclub.rivevalidation > "$folder/pid.txt"
  for n in 1 2 3; do
    bash "$root/click-control.sh" "$serial" api-check
    bash "$root/click-control.sh" "$serial" edit-value
    sleep 1
    devecocli ui screenshot --device "$serial" --path "$folder/reloaded-$n.png"
    bash "$root/click-control.sh" "$serial" report-metrics
  done
  bash "$root/click-control.sh" "$serial" pause
  sleep 1
  devecocli ui screenshot --device "$serial" --path "$folder/paused-1.png"
  sleep 2
  devecocli ui screenshot --device "$serial" --path "$folder/paused-2.png"
  bash "$root/click-control.sh" "$serial" resume
  sleep 1
  devecocli ui screenshot --device "$serial" --path "$folder/resumed.png"
  bash "$root/click-control.sh" "$serial" mount-toggle
  bash "$root/click-control.sh" "$serial" mount-toggle
  sleep 1
  devecocli ui screenshot --device "$serial" --path "$folder/remounted.png"
done
python3 - "$output" <<'PY'
from pathlib import Path
from PIL import Image, ImageChops
import json, re, sys
root=Path(sys.argv[1]); log=(root/'stream.log').read_text(); results={}
for backend in ['canvas','rive']:
    p=root/backend; pid=(p/'pid.txt').read_text().strip()
    lines=[s for s in log.splitlines() if re.search(r'\s'+pid+r'\s',s)]
    text='\n'.join(lines); (p/'pid.log').write_text(text+'\n')
    owned=text.count('SEEK_OWNERSHIP retained=2 remaining=1')
    swaps=text.count('RESOURCE setRiveBytes requested')
    errors=[s for s in lines if re.search(r'Error|ERROR| FAIL|already zero|released C\+\+',s)]
    after_swap=[]
    for i,s in enumerate(lines):
        if 'RESOURCE setRiveBytes requested' in s:
            tail=lines[i+1:]; end=next((n for n,t in enumerate(tail) if 'RESOURCE setRiveBytes requested' in t),len(tail))
            after_swap.append(any('LOADED fixture=vehicles.riv' in t for t in tail[:end]))
    frames={}
    for name in ['reloaded-1','reloaded-2','reloaded-3','remounted']:
        im=Image.open(p/f'{name}.png').convert('RGB')
        band=im.crop((0,int(im.height*.25),im.width,int(im.height*.58)))
        frames[name]=sum(r>180 and g<90 and 40<b<160 for r,g,b in band.getdata())
    im=Image.open(p/'paused-1.png').convert('RGB'); band=im.crop((0,500,im.width,1600))
    mask=Image.new('L',band.size);mask.putdata([255 if r>180 and g<90 and 40<b<160 else 0 for r,g,b in band.getdata()])
    x1,y1,x2,y2=mask.getbbox();crop=(x1,y1+500,x2,y2+500)
    def changed(a,b):
        a=Image.open(p/f'{a}.png').convert('RGB').crop(crop)
        b=Image.open(p/f'{b}.png').convert('RGB').crop(crop)
        return sum(max(v)>0 for v in ImageChops.difference(a,b).getdata())
    result={'pid':pid,'paired_temporary_refs':owned,'byte_reload_requests':swaps,
            'on_ready_after_reload':after_swap,'errors':errors,'red_artboard_pixels':frames,
            'paused_changed_pixels':changed('paused-1','paused-2'),
            'resumed_changed_pixels':changed('paused-2','resumed')}
    result['passed']=owned==3 and swaps==3 and len(after_swap)==3 and all(after_swap) and not errors and min(frames.values())>10000 and result['paused_changed_pixels']==0 and result['resumed_changed_pixels']>0
    results[backend]=result
(root/'summary.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(results,indent=2))
assert all(r['passed'] for r in results.values()), 'Inspect reload regression evidence'
PY
