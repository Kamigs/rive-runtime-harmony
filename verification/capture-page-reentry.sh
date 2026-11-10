#!/usr/bin/env bash
set -euo pipefail
serial=${1:?device}; output=${2:?output}
mkdir -p "$output"; output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
exec > >(tee "$output/actions.log") 2>&1
pid=$("$hdc" -t "$serial" shell pidof com.mgclub.rivevalidation | tr -d '\r\n')
"$hdc" -t "$serial" shell hidumper --mem "$pid" > "$output/before-memory.txt"
bash "$(dirname "$0")/click-control.sh" "$serial" leave-page
sleep 2
devecocli ui screenshot --device "$serial" --path "$output/01-blank.png"
"$hdc" -t "$serial" shell hidumper --mem "$pid" > "$output/blank-memory.txt"
devecocli ui click --device "$serial" --id return-page
sleep 2
devecocli ui screenshot --device "$serial" --path "$output/02-returned.png"
"$hdc" -t "$serial" shell hidumper --mem "$pid" > "$output/returned-memory.txt"
devecocli log --device "$serial" --keyword RiveValidation --from 1m --tail 200 > "$output/hilog.txt" 2>&1
