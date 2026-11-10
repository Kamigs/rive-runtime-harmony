#!/usr/bin/env python3
"""Compare published declarations and verify that a HAP consumes the supplied HAR."""
import argparse
import hashlib
import json
import struct
import tarfile
import zipfile
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('published_har', type=Path)
parser.add_argument('target_har', type=Path)
parser.add_argument('host_hap', type=Path)
parser.add_argument('report', type=Path)
args = parser.parse_args()

def sha(data):
    return hashlib.sha256(data).hexdigest()

def unpack(path):
    with tarfile.open(path) as archive:
        return {m.name: archive.extractfile(m).read() for m in archive if m.isfile()}

published = unpack(args.published_har)
target = unpack(args.target_har)
old = {p: b.replace(b'\r\n', b'\n') for p, b in published.items() if p.endswith('.d.ets')}
new = {p: b.replace(b'\r\n', b'\n') for p, b in target.items() if p.endswith('.d.ets')}
with zipfile.ZipFile(args.host_hap) as archive:
    hap_libs = {p: archive.read(p) for p in archive.namelist() if p.endswith('.so')}
har_libs = {p.removeprefix('package/'): b for p, b in target.items() if p.endswith('.so')}
missing = sorted(old.keys() - new.keys())
added = sorted(new.keys() - old.keys())
changed = sorted(p for p in old.keys() & new.keys() if old[p] != new[p])
payload_match = har_libs.keys() == hap_libs.keys() and all(hap_libs[p] == b for p, b in har_libs.items())
report = {
    'published_har_sha256': sha(args.published_har.read_bytes()),
    'target_har_sha256': sha(args.target_har.read_bytes()),
    'host_hap_sha256': sha(args.host_hap.read_bytes()),
    'declarations': {'published_count': len(old), 'target_count': len(new),
                     'missing': missing, 'added': added, 'changed': changed},
    'native_payloads_match': payload_match,
    'libraries': {p: {'sha256': sha(b), 'elf_machine': struct.unpack_from('<H', b, 18)[0]}
                  for p, b in har_libs.items()},
    'license_files': sorted(p for p in target if '/rawfile/rive_licenses/' in p),
}
args.report.parent.mkdir(parents=True, exist_ok=True)
args.report.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
raise SystemExit(0 if not (missing or added or changed) and payload_match else 1)
