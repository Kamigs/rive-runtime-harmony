#!/usr/bin/env bash
set -euo pipefail
module=$(cd "$(dirname "$0")/.." && pwd)
serial=${1:?};output=${2:?}
mkdir -p "$output"
exec > >(tee "$output/actions.log") 2>&1
click(){ bash "$module/verification/click-control.sh" "$serial" "$1"; }
shot(){ devecocli ui screenshot --device "$serial" --path "$output/$1.png"; devecocli log --device "$serial" --keyword RiveValidation --from 1m --tail 250 > "$output/$1-hilog.txt" 2>&1; }
launch(){ bash "$module/verification/launch-fixture.sh" "$serial" "$1" "$output/$2"; }
launch vehicles.riv boolean
click artboard-Jeep
click input-Raining-1
shot boolean/02-raining
launch skills.riv number
click input-Level-2
shot number/02-level2
launch electrified_button_nested_text.riv text
click edit-value
shot text/02-edited
launch rewards.riv databinding
click edit-value
sleep 2
shot databinding/02-edited
launch rating.riv events
click input-rating-3
shot events/02-rating3
launch vehicles.riv api
click api-check
shot api/02-api
click edit-value
shot api/03-bytes
launch rive_rendering_test.riv rendering
launch layout_test.riv layout
launch vehicles.riv lifecycle
click multi-instance
shot lifecycle/02-multi
click multi-instance
click report-metrics
click mount-toggle
click report-metrics
sleep 3
click report-metrics
shot lifecycle/03-unmounted
click mount-toggle
for n in $(seq 1 20);do click mount-toggle;click mount-toggle;done
shot lifecycle/04-after-20-cycles
click report-metrics
devecocli log --device "$serial" --keyword RiveValidation --from 15m --tail 2000 > "$output/hilog.txt" 2>&1
devecocli log --device "$serial" --bundle-name com.mgclub.rivevalidation --from 15m --tail 3000 > "$output/lifecycle-native.txt" 2>&1
