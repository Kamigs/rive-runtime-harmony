#!/usr/bin/env bash
# Test-host controls live in one Scroll below the fixed playback buttons.
set -euo pipefail
serial=${1:?device}; control=${2:?control id}
case "$control" in
  pause|resume|mount-toggle)
    devecocli ui click --device "$serial" --id "$control"
    exit
    ;;
esac
layout=$(mktemp -t rive-control)
trap 'rm -f "$layout"' EXIT
for attempt in 1 2 3; do
  devecocli ui layout --device "$serial" --format json > "$layout"
  result=$(python3 - "$layout" "$control" <<'PY'
import json,sys
def walk(nodes):
 for n in nodes:
  yield n
  yield from walk(n.get('children',[]))
nodes=list(walk(json.JSONDecoder().raw_decode(open(sys.argv[1]).read().lstrip())[0]))
if any(n.get('id')==sys.argv[2] for n in nodes):
 print('visible');sys.exit()
scroll=next(n for n in nodes if n.get('type')=='Scroll')
x1,y1,x2,y2=scroll['bounds']; x=(x1+x2)//2
print(x,int(y2-(y2-y1)*.15),x,int(y1+(y2-y1)*.15))
PY
)
  if [ "$result" = visible ]; then
    devecocli ui click --device "$serial" --id "$control"
    exit
  fi
  read -r x1 y1 x2 y2 <<< "$result"
  devecocli ui swipe --device "$serial" "$x1" "$y1" "$x2" "$y2"
done
echo "Control not visible after scrolling: $control" >&2
exit 1
