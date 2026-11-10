#!/usr/bin/env bash
set -euo pipefail
serial=${1:?device};output=${2:?output}
mkdir -p "$output";output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
exec > >(tee "$output/actions.log") 2>&1
pid=$("$hdc" -t "$serial" shell pidof com.mgclub.rivevalidation | tr -d '\r\n')
printf '%s\n' "$pid" > "$output/pid.txt"
click(){ devecocli ui click --device "$serial" --id "$1"; }
shot(){ devecocli ui screenshot --device "$serial" --path "$output/$1.png"; }
mem(){ "$hdc" -t "$serial" shell hidumper --mem "$pid" > "$output/$1-memory.txt"; }
mem 01-mounted
shot 01-mounted
click multi-instance
shot 02-multi
mem 02-multi
click multi-instance
click report-metrics
"$hdc" -t "$serial" shell uitest uiInput keyEvent Home
sleep 3
"$hdc" -t "$serial" shell aa start -a EntryAbility -b com.mgclub.rivevalidation
shot 03-foreground
click report-metrics
click mount-toggle
sleep 2
click report-metrics
mem 04-unmounted
sleep 3
click report-metrics
shot 04-unmounted
click mount-toggle
shot 05-remounted
mem 05-remounted
devecocli log --device "$serial" --keyword RiveValidation --from 3m --tail 500 > "$output/hilog.txt" 2>&1
devecocli log --device "$serial" --bundle-name com.mgclub.rivevalidation --from 3m --tail 3000 > "$output/native-hilog.txt" 2>&1
