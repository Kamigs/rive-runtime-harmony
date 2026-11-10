#!/usr/bin/env python3
"""Verify, optionally publish locally, and synchronize the CLI acceptance asset.

This is a fixture contract, not a general Rive file compatibility analyzer.
The locked runtime must still import and render every exported candidate.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent.parent / 'examples'
PROJECT = ROOT / 'cli-projects/runtime-contract'
CLI_VERSION = '1.9.2'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(args, log):
    result = subprocess.run(args, text=True, capture_output=True)
    log.with_suffix('.stderr.log').write_text(result.stderr)
    log.write_text(result.stdout)
    if result.returncode:
        raise SystemExit(f'{args[0]} failed ({result.returncode}); see {log} and its stderr log')
    return result.stdout


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def varuint(data, offset):
    value = 0
    for shift in range(0, 35, 7):
        if offset >= len(data):
            raise ValueError('truncated Rive header')
        byte = data[offset]
        offset += 1
        value |= (byte & 127) << shift
        if not byte & 128:
            return value, offset
    raise ValueError('invalid Rive header varuint')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', required=True, type=Path)
    source = parser.add_mutually_exclusive_group()
    source.add_argument('--publish-local', action='store_true', help='requires Rive login and publishing allowance; never publishes a website')
    source.add_argument('--exported', type=Path, help='existing signed export made from this project')
    args = parser.parse_args()
    out = args.evidence.resolve()
    out.mkdir(parents=True, exist_ok=True)
    version = subprocess.check_output(['rive', '--version'], text=True).strip()
    if version.split()[-1] != CLI_VERSION:
        raise SystemExit(f'Expected Rive CLI {CLI_VERSION}, found {version}; review/revalidate before updating the lock')
    verified = json.loads(command(['rive', str(PROJECT), '--verify', '--format=json'], out / 'verify.json'))
    if not verified.get('success') or verified.get('errors'):
        raise SystemExit('CLI verification failed')
    tree = json.loads(command(['rive', 'inspect', str(PROJECT), '--json'], out / 'inspect.json'))
    if tree.get('problems'):
        raise SystemExit(f'Inspect reported problems: {tree["problems"]}')
    objects = list(walk(tree))
    required = [('Artboard', 'CLI Contract'), ('StateMachine', 'bumpy'),
                ('StateMachineTrigger', 'bump'), ('StateMachineBool', 'enabled'),
                ('StateMachineNumber', 'Level'), ('TextValueRun', 'button_text'),
                ('Event', 'cli_bump')]
    for kind, name in required:
        if not any(o.get('type') == kind and o.get('name') == name for o in objects):
            raise SystemExit(f'Missing contract object: {kind} {name}')
    # This sample intentionally exercises the retained classic input API.
    if any('Script' in o.get('type', '') or '3D' in o.get('type', '') for o in objects):
        raise SystemExit('Sample contract excludes scripting and 3D; add a separate validated fixture for these')
    exported = args.exported
    if args.publish_local:
        result = json.loads(command(['rive', str(PROJECT), '--publish=local', f'--output-dir={out}', '--format=json'], out / 'publish.json'))
        if not result.get('success'):
            raise SystemExit('Local publishing failed')
        exported = Path(result['data']['riv'])
        # Account metadata is not part of the reproducible asset record.
        (out / 'publish.json').write_text(json.dumps({k: v for k, v in result.items() if k not in ('workspace', 'credits', 'allowance')}, indent=2) + '\n')
    if exported is None:
        print('CLI source contract verified; no .riv exported or copied. Use --publish-local after login.')
        return
    data = exported.read_bytes()
    if data[:4] != b'RIVE':
        raise SystemExit('Not a Rive runtime file')
    major, offset = varuint(data, 4)
    minor, _ = varuint(data, offset)
    if major != 7:
        raise SystemExit(f'Runtime 0.1.11 requires format major 7, found {major}')
    targets = [ROOT / 'har-consumer/entry/src/main/resources/rawfile/runtime-contract.riv',
               ROOT / 'flutter-comparison/assets/runtime-contract.riv']
    for target in targets:
        shutil.copyfile(exported, target)
    manifest = {
        'fixture': 'runtime-contract.riv', 'purpose': 'CLI technical acceptance; not a formal MG_Club asset',
        'cli': version, 'runtime': 'rive_native 0.1.11', 'flutter': 'rive 0.14.11',
        'format': {'major': major, 'minor': minor}, 'bytes': len(data), 'sha256': sha(exported),
        'sources': {str(p.relative_to(ROOT)): sha(p) for p in (PROJECT / 'scene.rml', PROJECT / 'rive.yaml', ROOT / 'har-consumer/entry/src/main/resources/rawfile/Inter-Regular.ttf')},
        'contract': {'artboard': 'CLI Contract', 'stateMachine': 'bumpy', 'inputs': {'bump': 'trigger', 'enabled': 'boolean', 'Level': 'number'}, 'event': 'cli_bump', 'textRun': 'button_text'},
        'copies': {str(p.relative_to(ROOT)): sha(p) for p in targets},
        'acceptance': 'export provenance only; target-runtime import, rendering and interaction require a separate validation record'
    }
    (ROOT.parent / 'verification/cli-fixture-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    (out / 'fixture-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'sha256': manifest['sha256'], 'bytes': len(data), 'format': manifest['format'], 'copies': 2}))


if __name__ == '__main__':
    main()
