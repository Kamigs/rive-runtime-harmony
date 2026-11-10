#!/usr/bin/env python3
"""Summarize HiTrace B/E wall durations; never call frame intervals render cost."""
import json,math,re,sys
from pathlib import Path
p=Path(sys.argv[1]);pid=(p/'pid.txt').read_text().strip()
pattern=re.compile(r'^\s*.*?-(\d+)\s+\([^)]*\)\s+\[\d+\].*?\s(\d+\.\d+): tracing_mark_write: (.*)')
stacks={};samples={};submissions=[];first=None;last=None
for line in (p/'frame.trace').open(errors='replace'):
 m=pattern.match(line)
 if not m:continue
 tid,ts,payload=m.groups();t=float(ts);first=t if first is None else first;last=t
 parts=payload.split('|');kind=parts[0]
 if kind=='B' and len(parts)>=3:
  name=re.sub(r'^\[[^\]]+\]#', '', parts[2].removeprefix('H:'))
  stacks.setdefault(tid,[]).append((t,parts[1],name))
 elif kind=='E' and stacks.get(tid):
  start,process,name=stacks[tid].pop();key=None
  if process==pid and name in ('Rive::frame','draw()','flush()','swapBuffers()', 'NativeWindowFlushBuffer', 'NativeWindowRequestBuffer'):key=name
  elif name.startswith('RSMainThread::DoComposition:'):key='RenderService composition (whole device)'
  if key:samples.setdefault(key,[]).append((t-start)*1000)
  if process==pid and name=='NativeWindowFlushBuffer':submissions.append(t)
def stats(a):
 a=sorted(a);return {'count':len(a),'p50_ms':a[math.ceil(.50*len(a))-1],'p95_ms':a[math.ceil(.95*len(a))-1],'max_ms':a[-1]}
out={'pid':pid,'trace_span_s':last-first if first is not None else None,'duration_scope':'wall time of paired B/E markers, includes waits; not GPU execution time','durations':{k:stats(v) for k,v in samples.items()}}
if len(submissions)>1:
 submissions.sort()
 out['buffer_submission_interval']=stats([(b-a)*1000 for a,b in zip(submissions, submissions[1:])])
 out['buffer_submission_note']='Same-process native window flush completion intervals; cadence, not render cost.'
for name in ['memory-before','memory-after','memory-recovered']:
 f=p/(name+'.txt')
 if f.exists():
  m=re.search(r'^\s*Total\s+(\d+)',f.read_text(),re.M)
  if m:out[name+'_pss_kib']=int(m[1])
if (p/'first-observed-host-ns.txt').exists():
 out['first_visible_observation_upper_bound_ms']=(int((p/'first-observed-host-ns.txt').read_text())-int((p/'launch-host-ns.txt').read_text()))/1e6
 out['first_visible_note']='Upper bound includes host command/screenshot overhead; requires visual review of first-observed.png.'
log=(p/'metrics-hilog.txt').read_text()
for name,pattern in [('first_advance_ms',r'FIRST_ADVANCE launch_ms=(\d+)'),('callback_interval_p95_ms',r'FRAME_INTERVAL .*p95_ms=([0-9.]+)')]:
 m=re.findall(pattern,log)
 if m:out[name]=float(m[-1])
(p/'summary.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
