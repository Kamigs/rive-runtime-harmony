#!/usr/bin/env bash
set -euo pipefail
serial=${1:?device};output=${2:?output};renderer=${3:-canvas};baseline=${4:-native-0.1.11}
mkdir -p "$output"
output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
exec > >(tee "$output/actions.log") 2>&1
"$hdc" -t "$serial" shell aa force-stop com.mgclub.rivevalidation
python3 -c 'import time;print(time.time_ns())' > "$output/launch-host-ns.txt"
"$hdc" -t "$serial" shell aa start -a EntryAbility -b com.mgclub.rivevalidation --ps renderer "$renderer" --ps baseline "$baseline"
devecocli ui screenshot --device "$serial" --path "$output/first-observed.png"
python3 -c 'import time;print(time.time_ns())' > "$output/first-observed-host-ns.txt"
sleep 5
pid=$("$hdc" -t "$serial" shell pidof com.mgclub.rivevalidation | tr -d '\r\n')
printf '%s\n' "$pid" > "$output/pid.txt"
"$hdc" -t "$serial" shell hidumper --mem "$pid" > "$output/memory-before.txt"
"$hdc" -t "$serial" shell hitrace --trace_begin -b 32768 app graphic ace > "$output/trace-begin.txt"
sleep 12
"$hdc" -t "$serial" shell hitrace --trace_finish -o /data/local/tmp/rive-performance.trace > "$output/trace-finish.txt"
"$hdc" -t "$serial" file recv /data/local/tmp/rive-performance.trace "$output/frame.trace"
"$hdc" -t "$serial" shell hidumper --mem "$pid" > "$output/memory-after.txt"
devecocli ui click --device "$serial" --id report-metrics
devecocli log --device "$serial" --keyword RiveValidation --from 2m --tail 80 > "$output/metrics-hilog.txt" 2>&1
devecocli ui screenshot --device "$serial" --path "$output/steady.png"
