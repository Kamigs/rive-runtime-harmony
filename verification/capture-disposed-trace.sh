#!/usr/bin/env bash
# Run with vehicles visible and riveTraceAnimations enabled; leaves it unmounted.
set -euo pipefail
serial=${1:?device}; output=${2:?output}
mkdir -p "$output"; output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
exec > >(tee "$output/actions.log") 2>&1
"$hdc" -t "$serial" shell pidof com.mgclub.rivevalidation | tr -d '\r\n' > "$output/pid.txt"
devecocli ui click --device "$serial" --id mount-toggle
sleep 2
"$hdc" -t "$serial" shell hitrace --trace_begin -b 8192 app graphic ace > "$output/trace-begin.txt"
sleep 8
"$hdc" -t "$serial" shell hitrace --trace_finish -o /data/local/tmp/rive-disposed.trace > "$output/trace-finish.txt"
"$hdc" -t "$serial" file recv /data/local/tmp/rive-disposed.trace "$output/frame.trace"
devecocli log --device "$serial" --keyword RiveValidation --from 30s --tail 80 > "$output/metrics-hilog.txt" 2>&1
devecocli ui screenshot --device "$serial" --path "$output/unmounted.png"
python3 "$(dirname "$0")/analyze-performance.py" "$output"
