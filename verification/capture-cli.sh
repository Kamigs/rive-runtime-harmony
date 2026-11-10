#!/usr/bin/env bash
# Run on the emulator first; review images as well as the observed API/event log.
set -euo pipefail
serial=${1:?device serial}; output=${2:?output directory}; renderer=${3:-rive}
root=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$output"; output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
exec > >(tee "$output/actions.log") 2>&1
# On physical devices the shared log buffer can roll over within this suite.
devecocli log --device "$serial" --keyword Rive --follow > "$output/stream.log" 2>&1 &
logger=$!
trap 'kill "$logger" 2>/dev/null || true; wait "$logger" 2>/dev/null || true' EXIT
click() { bash "$root/click-control.sh" "$serial" "$1"; }
shot() { devecocli ui screenshot --device "$serial" --path "$output/$1.png"; }
"$hdc" -t "$serial" shell aa force-stop com.mgclub.rivevalidation
"$hdc" -t "$serial" shell aa start -a EntryAbility -b com.mgclub.rivevalidation --ps fixture runtime-contract.riv --ps renderer "$renderer" --ps cjkFallback true --ps textValue '会员积分奖励'
sleep 2
"$hdc" -t "$serial" shell pidof com.mgclub.rivevalidation > "$output/pid.txt"
devecocli ui layout --device "$serial" --format json > "$output/layout.json"
shot 01-loaded
sleep 1
shot 02-playing
click edit-value
shot 03-text
click trigger-bump
shot 04-trigger
bash "$root/capture-trigger-burst.sh" "$serial" "$output/trigger-burst"
click input-enabled-1
shot 05-boolean-on
click input-enabled-0
shot 06-boolean-off
click input-Level-2
shot 07-number-large
click input-Level-1
shot 08-number-small
click pause
sleep 1
shot 09-paused
sleep 2
shot 10-paused
click resume
sleep 1
shot 11-resumed
click mount-toggle
shot 12-destroyed
click mount-toggle
sleep 2
shot 13-reloaded
devecocli log --device "$serial" --keyword RiveValidation --from 10m --tail 2000 > "$output/hilog.txt" 2>&1
devecocli log --device "$serial" --keyword OHOS_RIVE --from 10m --tail 300 > "$output/native.log" 2>&1
python3 - "$output" <<'PY'
import json, pathlib, re, sys
p = pathlib.Path(sys.argv[1]); pid = (p/'pid.txt').read_text().strip()
lines = [s for s in (p/'hilog.txt').read_text().splitlines() if re.search(r'\b'+re.escape(pid)+r'\b', s)]
lines += [s for s in (p/'stream.log').read_text().splitlines() if re.search(r'\b'+re.escape(pid)+r'\b', s)]
log = '\n'.join(lines)
checks = {
    'loaded': 'LOADED fixture=runtime-contract.riv' in log,
    'trigger_input': 'name=bump type=trigger' in log,
    'boolean_input': 'name=enabled type=boolean' in log,
    'number_input': 'name=Level type=number' in log,
    'event': 'EVENT cli_bump' in log,
    'text_value': 'after=会员积分奖励' in log,
    'boolean_change': 'SET_INPUT bumpy/enabled=1' in log,
    'number_change': 'SET_INPUT bumpy/Level=2' in log,
    'no_reported_error': not re.search(r' EDIT FAIL| API FAIL|ERROR|Error in loadFileFromResource|Reference count already zero', log),
}
(p/'api-checks.json').write_text(json.dumps({'pid': pid, 'checks': checks,
    'visual_review': 'required separately; API success does not prove rendering'}, indent=2)+'\n')
print(checks)
if not all(checks.values()): raise SystemExit('CLI fixture API contract failed; inspect evidence')
PY
