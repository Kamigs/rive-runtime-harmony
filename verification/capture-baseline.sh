#!/bin/bash
set -euo pipefail
# Run after installing the desired HAP. Images need visual review; this script
# records actions and evidence and does not declare that a case passed.
device="${1:?usage: capture-baseline.sh DEVICE OUTPUT_DIRECTORY}"
output="${2:?output directory required}"
renderer="${3:-canvas}"
mkdir -p "$output"
output="$(cd "$output" && pwd)"
exec > >(tee "$output/actions.log") 2>&1
hdc="${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}"
shot() { devecocli ui screenshot --device "$device" --path "$output/$1.png"; }
click() { devecocli ui click --device "$device" --id "$1"; }
date -u '+%Y-%m-%dT%H:%M:%SZ'
devecocli device view -t "$device"
devecocli ui layout --device "$device" --format json > "$output/layout.json"
shot 01-playing
sleep 2
shot 02-playing
click pause
shot 03-paused
sleep 2
shot 04-paused
click resume
shot 05-resumed
bash "$(dirname "$0")/click-control.sh" "$device" trigger-bump
shot 06-trigger
click mount-toggle
shot 07-unmounted
click mount-toggle
shot 08-remounted
devecocli log --device "$device" --keyword RiveValidation --from 10m --tail 500 > "$output/controls-hilog.txt" 2>&1
"$hdc" -t "$device" shell aa force-stop com.mgclub.rivevalidation
"$hdc" -t "$device" shell aa start -a EntryAbility -b com.mgclub.rivevalidation --ps renderer "$renderer"
shot 09-cold-relaunch
devecocli log --device "$device" --bundle-name com.mgclub.rivevalidation --from 10m --tail 1500 > "$output/hilog.txt" 2>&1
date -u '+%Y-%m-%dT%H:%M:%SZ'
