#!/usr/bin/env python3
"""Summarize recorded lifecycle evidence for one PID; visual review stays manual."""
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
pid = (root / 'pid.txt').read_text().strip()
logs = '\n'.join(p.read_text(errors='replace') for p in root.glob('*.log'))
lines = sorted(set(line for line in logs.splitlines() if re.search(r'\s' + pid + r'\s', line)))
metrics = []
for line in lines:
    match = re.search(r'(\d\d:\d\d:\d\d\.\d+) .*METRIC instance=(\d+) item=(\d+) active=(\w+) visible=(\w+) playing=(\w+) frames=(\d+)', line)
    if match:
        t, instance, item, active, visible, playing, frames = match.groups()
        metrics.append(dict(time=t, instance=int(instance), item=int(item), active=active == 'true',
                            visible=visible == 'true', playing=playing == 'true', frames=int(frames)))
traces = {}
for path in root.glob('*.trace'):
    times = []
    frame_times = []
    ui_vsyncs = 0
    for line in path.open(errors='replace'):
        match = re.search(r'(\d+\.\d+): tracing_mark_write:', line)
        if match:
            time = float(match[1])
            times.append(time)
            if f'B|{pid}|H:Rive::frame|' in line:
                frame_times.append(time)
            if f'B|{pid}|H:OnVsyncEvent now:' in line:
                ui_vsyncs += 1
    traces[path.name] = dict(span_s=max(times) - min(times) if times else None,
                            native_frame_count=len(frame_times),
                            ui_vsync_count=ui_vsyncs,
                            native_frames_per_ui_vsync=len(frame_times) / ui_vsyncs if ui_vsyncs else None,
                            native_frames_per_second=len(frame_times) / (max(times) - min(times)) if times and max(times) > min(times) else None)
out = dict(pid=pid, metrics=metrics, traces=traces,
           tsfn_create=[line for line in lines if 'TSFN_CREATE' in line],
           tsfn_release=[line for line in lines if 'TSFN_RELEASE' in line],
           lifecycle=[line for line in lines if any(token in line for token in [' ACTIVE ', ' REUSE', ' DISPOSE ', ' ABILITY ', 'CYCLE100_DONE'])],
           note='Metrics count advance callbacks; trace counts native Rive::frame entries. Neither proves pixels or GPU duration.')
(root / 'summary.json').write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(dict(pid=pid, metrics=len(metrics), traces=traces,
                     tsfn_create=len(out['tsfn_create']), tsfn_release=len(out['tsfn_release'])), indent=2))
