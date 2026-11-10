#!/usr/bin/env python3
"""Restore exact source commits. Optional cache is a read-only source of Git objects."""
import argparse
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--cache-root', type=Path,
                    help='optional source checkout with the same paths as dependencies.lock.json')
parser.add_argument('--check', action='store_true', help='verify existing pins without fetching')
args = parser.parse_args()

def git(path, *argv):
    return subprocess.check_output(['git', '-C', str(path), *argv], text=True).strip()

for entry in json.loads((ROOT / 'dependencies.lock.json').read_text()):
    path = ROOT / entry['path']
    if not (path / '.git').exists():
        if args.check:
            raise SystemExit(f'Missing dependency: {path}')
        if path.exists() and any(path.iterdir()):
            raise SystemExit(f'Nonempty dependency without Git metadata: {path}')
        path.mkdir(parents=True, exist_ok=True)
        git(path, 'init', '-q')
        git(path, 'remote', 'add', 'origin', entry['remote'])
        source = str((args.cache_root / entry['path']).resolve()) if args.cache_root else 'origin'
        git(path, 'fetch', '--depth', '1', source, entry['sha'])
        git(path, '-c', 'advice.detachedHead=false', 'checkout', '--detach', entry['sha'])
    actual = git(path, 'rev-parse', 'HEAD')
    if actual != entry['sha'] or git(path, 'status', '--porcelain', '--untracked-files=no'):
        raise SystemExit(f'Dependency differs from lock: {path}; resolve explicitly before building')
    print(f"{actual}  {entry['path']}")
