#!/usr/bin/env python3
"""Check frozen ArkTS declarations, native payload consumption, ABI and licenses."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('har', type=Path)
parser.add_argument('hap', type=Path)
parser.add_argument('--report', type=Path, required=True)
args = parser.parse_args()
def sha(data): return hashlib.sha256(data).hexdigest()
with tarfile.open(args.har) as archive:
    files = {m.name.removeprefix('package/'):archive.extractfile(m).read() for m in archive if m.isfile()}
expected = json.loads((ROOT/'verification/api/published-api.json').read_text())['declaration_files']
decl = {p:b.replace(b'\r\n',b'\n') for p,b in files.items() if p.endswith('.d.ets')}
changed = sorted(p for p in expected if decl.get(p) != expected[p]['declaration'].replace('\r\n','\n').encode())
added = sorted(decl.keys() - expected.keys())
with zipfile.ZipFile(args.hap) as archive:
    hap_libs = {p:archive.read(p) for p in archive.namelist() if p.endswith('.so')}
har_libs = {p:b for p,b in files.items() if p.endswith('.so')}
licenses = sorted(p for p in files if '/rawfile/rive_licenses/' in p)
payload_match = har_libs == hap_libs and bool(har_libs)
machines = {p:struct.unpack_from('<H',b,18)[0] for p,b in har_libs.items()}
report = {'har_sha256':sha(args.har.read_bytes()), 'hap_sha256':sha(args.hap.read_bytes()),
          'declarations':{'baseline':len(expected),'built':len(decl),'changed_or_missing':changed,'added':added},
          'native_payloads_match':payload_match, 'elf_machine':machines,
          'libraries':{p:sha(b) for p,b in har_libs.items()}, 'licenses':licenses}
report['passed'] = not changed and not added and len(decl)==71 and payload_match and len(licenses)>=10 and all(m==183 for m in machines.values())
args.report.parent.mkdir(parents=True,exist_ok=True)
args.report.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
raise SystemExit(not report['passed'])
