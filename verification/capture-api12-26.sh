#!/usr/bin/env bash
# Device acceptance for the additive host integration. No pass is inferred
# from screenshots until they are reviewed. Keep the renderer fixed for A/B runs.
set -euo pipefail
serial=${1:?device serial}; output=${2:?output directory}; renderer=${3:-rive}
legacy=${4:-false}; gate=${5:-true}; mode=${6:-pool}
mkdir -p "$output"
output=$(cd "$output" && pwd)
hdc=${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}
exec > >(tee "$output/actions.log") 2>&1
click() { devecocli ui click --device "$serial" --id "$1"; }
shot() { devecocli ui screenshot --device "$serial" --path "$output/$1.png"; }
report() {
  click life-report
  devecocli log --device "$serial" --keyword RiveLifecycle --from 1m --tail 100 >> "$output/checkpoints.log" 2>&1
  devecocli log --device "$serial" --keyword RIVE_LIFECYCLE --from 1m --tail 100 >> "$output/tsfn-checkpoints.log" 2>&1
}
trace() {
  "$hdc" -t "$serial" shell hitrace --trace_begin -b 16384 app graphic ace > "$output/$1-begin.txt"
  sleep 6
  "$hdc" -t "$serial" shell hitrace --trace_finish -o /data/local/tmp/rive-lifecycle.trace > "$output/$1-end.txt"
  "$hdc" -t "$serial" file recv /data/local/tmp/rive-lifecycle.trace "$output/$1.trace"
}
"$hdc" -t "$serial" shell aa force-stop com.mgclub.rivevalidation
"$hdc" -t "$serial" shell aa start -a EntryAbility -b com.mgclub.rivevalidation --ps suite lifecycle --ps renderer "$renderer" --ps legacyHooks "$legacy" --ps lifecycleGate "$gate" --ps lifecycleMode "$mode"
sleep 3
"$hdc" -t "$serial" shell pidof com.mgclub.rivevalidation > "$output/pid.txt"
report
shot 01-playing
sleep 3
report
if [[ "$mode" == list ]]; then
  devecocli ui swipe --device "$serial" --speed 500 700 2200 700 900
  devecocli ui swipe --device "$serial" --speed 500 700 2200 700 900
  # Stop inertial scrolling before measuring a stationary visible/cache set.
  devecocli ui click --device "$serial" 700 1600
  sleep 2
  report
  shot 02-scrolled
  sleep 5
  report
  devecocli ui swipe --device "$serial" --speed 500 700 1000 700 2300
  devecocli ui swipe --device "$serial" --speed 500 700 1000 700 2300
  devecocli ui click --device "$serial" 700 1600
  sleep 2
  report
  shot 03-returned
else
  if [[ "$gate" == true ]]; then
    if [[ ${RIVE_CYCLE_TRACE:-true} == true ]]; then trace before-cycle; fi
    click life-cycle
    if [[ ${RIVE_CYCLE_TRACE:-true} == true ]]; then trace after-cycle; fi
    report
  fi
  click life-toggle
  sleep 1
  report
  shot 02-inactive
  "$hdc" -t "$serial" shell hitrace --trace_begin -b 8192 app graphic ace > "$output/trace-begin.txt"
  sleep 6
  "$hdc" -t "$serial" shell hitrace --trace_finish -o /data/local/tmp/rive-inactive.trace > "$output/trace-end.txt"
  "$hdc" -t "$serial" file recv /data/local/tmp/rive-inactive.trace "$output/inactive.trace"
  report
  click life-toggle
  sleep 2
  report
  shot 03-reused
  if [[ "$gate" == true ]]; then
    click life-pause
    sleep 1
    report
    click life-toggle
    click life-toggle
    sleep 3
    report
    shot 04-manual-pause-retained
    click life-resume
    sleep 2
    report
    "$hdc" -t "$serial" shell uitest uiInput keyEvent Home
    sleep 3
    "$hdc" -t "$serial" shell aa start -a EntryAbility -b com.mgclub.rivevalidation
    sleep 2
    report
    shot 05-foreground
  fi
fi
click life-exit
sleep 2
shot 06-destroyed
if [[ ${RIVE_CYCLE_TRACE:-true} == true ]]; then trace disposed; fi
devecocli log --device "$serial" --keyword RiveLifecycle --from 5m --tail 1500 > "$output/lifecycle.log" 2>&1
devecocli log --device "$serial" --keyword RIVE_LIFECYCLE --from 5m --tail 1500 > "$output/tsfn.log" 2>&1
devecocli log --device "$serial" --keyword OHOS_RIVE --from 5m --tail 200 > "$output/native.log" 2>&1
