#!/usr/bin/env bash
set -euo pipefail
serial=${1:?device serial}; output=${2:?output directory}; renderer=${3:-rive}; fallback=${4:-true}
mkdir -p "$output"
output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
exec > >(tee "$output/actions.log") 2>&1
# A fresh process is mandatory: fallback fonts are registered globally.
"$hdc" -t "$serial" shell aa force-stop com.mgclub.rivevalidation
"$hdc" -t "$serial" shell aa start -a EntryAbility -b com.mgclub.rivevalidation --ps fixture electrified_button_nested_text.riv --ps renderer "$renderer" --ps cjkFallback "$fallback" --ps textValue '会员积分奖励'
sleep 3
devecocli ui screenshot --device "$serial" --path "$output/01-before-edit.png"
devecocli ui click --device "$serial" --id edit-value
sleep 2
devecocli ui screenshot --device "$serial" --path "$output/02-chinese.png"
devecocli log --device "$serial" --keyword RiveValidation --from 1m --tail 250 > "$output/hilog.txt" 2>&1
