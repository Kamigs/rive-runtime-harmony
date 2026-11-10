#!/usr/bin/env bash
set -euo pipefail
device=${1:?device}
fixture=${2:?fixture filename}
output=${3:?output directory}
renderer=${4:-canvas}
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
mkdir -p "$output"
exec > >(tee "$output/launch.log") 2>&1
"$hdc" -t "$device" shell aa force-stop com.mgclub.rivevalidation
"$hdc" -t "$device" shell aa start -a EntryAbility -b com.mgclub.rivevalidation --ps fixture "$fixture" --ps renderer "$renderer"
devecocli ui layout --device "$device" --format json > "$output/layout.json"
devecocli ui screenshot --device "$device" --path "$output/01-loaded.png"
devecocli log --device "$device" --keyword RiveValidation --from 1m --tail 250 > "$output/hilog.txt" 2>&1
