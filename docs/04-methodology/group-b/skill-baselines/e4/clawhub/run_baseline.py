"""Read-only clawhub discovery baseline; Linux/WSL, unique sessions and outputs."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parent

def save(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

def inventory():
    result = {}
    for rel in ['.openclaw/workspace/skills', '.openclaw/skills']:
        folder = Path.home() / rel
        result[rel] = {p.relative_to(folder).as_posix(): sha(p) for p in folder.rglob('*') if p.is_file()} if folder.exists() else None
    return result

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--case', choices=['plugins', 'skills', 'all'], default='all')
    p.add_argument('--openclaw', default='openclaw')
    p.add_argument('--skill-file', type=Path)
    p.add_argument('--output-root', type=Path, default=ROOT / 'runs')
    p.add_argument('--timeout', type=int, default=240)
    p.add_argument('--prepare-only', action='store_true')
    a = p.parse_args()
    cli = shutil.which(a.openclaw)
    if not cli:
        p.error('OpenClaw not found; use --openclaw')
    source = (a.skill_file or Path(cli).resolve().parent / 'skills/clawhub/SKILL.md').expanduser().resolve()
    if not source.is_file():
        p.error('clawhub/SKILL.md not found; use --skill-file')
    config = Path(os.environ.get('OPENCLAW_CONFIG_PATH', str(Path.home() / '.openclaw/openclaw.json')))
    failed = False
    for case in (['plugins', 'skills'] if a.case == 'all' else [a.case]):
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex
        session = 'e4-clawhub-' + case + '-' + stamp.lower()
        out = a.output_root.expanduser().resolve() / stamp
        out.mkdir(parents=True, exist_ok=False)
        (out / 'SKILL.md').write_bytes(source.read_bytes())
        prompt = (ROOT / 'prompts' / (case + '.txt')).read_text(encoding='utf-8').replace('{skill_file}', str(source))
        (out / 'input.txt').write_text(prompt, encoding='utf-8')
        help_result = subprocess.run([cli, case, 'search', '--help'], capture_output=True, text=True, timeout=75)
        (out / 'search-help.txt').write_text(help_result.stdout + help_result.stderr, encoding='utf-8')
        meta = {'case': case, 'session_id': session, 'session_key': 'agent:main:explicit:' + session,
                'started_utc': datetime.now(timezone.utc).isoformat(), 'skill_sha256': sha(source),
                'prepare_only': a.prepare_only, 'help_exit_code': help_result.returncode,
                'config_sha256_before': sha(config), 'skill_inventory_before': inventory(),
                'isolation': 'unique session/output; existing Gateway/config/workspace shared',
                'restriction': 'prompt constraints, not an enforced tool allowlist'}
        save(out / 'run-metadata.json', meta)
        print(json.dumps({'case': case, 'output_dir': str(out), 'session_id': session, 'prepare_only': a.prepare_only}), flush=True)
        if help_result.returncode:
            failed = True
            continue
        if a.prepare_only:
            continue
        command = [cli, 'agent', '--agent', 'main', '--session-id', session, '--message-file', str(out / 'input.txt'),
                   '--thinking', 'off', '--timeout', str(a.timeout), '--json']
        meta['command'] = command
        start = time.monotonic()
        try:
            with (out / 'agent-result.json').open('w', encoding='utf-8') as stdout, (out / 'agent-stderr.txt').open('w', encoding='utf-8') as stderr:
                try:
                    r = subprocess.run(command, stdout=stdout, stderr=stderr, timeout=a.timeout + 45)
                    meta['cli_exit_code'] = r.returncode
                except subprocess.TimeoutExpired:
                    meta['cli_exit_code'] = 'outer_timeout'
            meta['duration_seconds'] = round(time.monotonic() - start, 2)
            r = subprocess.run([cli, 'sessions', 'export-trajectory', '--agent', 'main', '--session-key', meta['session_key'],
                                '--workspace', str(out), '--output', 'baseline', '--json'], capture_output=True, text=True, timeout=90)
            (out / 'export-result.json').write_text(r.stdout, encoding='utf-8')
            (out / 'export-stderr.txt').write_text(r.stderr, encoding='utf-8')
            meta['export_exit_code'] = r.returncode
            trace = out / '.openclaw/trajectory-exports/baseline/events.jsonl'
            if r.returncode == 0 and trace.exists():
                r = subprocess.run([sys.executable, str(ROOT / 'extract_evidence.py'), '--case', case, '--trace', str(trace),
                                    '--agent-result', str(out / 'agent-result.json'), '--input', str(out / 'input.txt'),
                                    '--output', str(out / 'selected')], capture_output=True, text=True, timeout=30)
                (out / 'verification-log.txt').write_text(r.stdout + r.stderr, encoding='utf-8')
                meta['verification_exit_code'] = r.returncode
        finally:
            meta['config_sha256_after'] = sha(config)
            meta['config_unchanged'] = meta['config_sha256_before'] == meta['config_sha256_after']
            meta['skill_inventory_after'] = inventory()
            meta['skill_inventory_unchanged'] = meta['skill_inventory_before'] == meta['skill_inventory_after']
            save(out / 'run-metadata.json', meta)
        failed |= meta.get('cli_exit_code') != 0 or meta.get('verification_exit_code') != 0
        print(json.dumps({'case': case, 'cli_exit_code': meta.get('cli_exit_code'),
                          'verification_exit_code': meta.get('verification_exit_code'),
                          'config_unchanged': meta['config_unchanged'],
                          'skill_inventory_unchanged': meta['skill_inventory_unchanged']}), flush=True)
    return int(failed)

if __name__ == '__main__':
    raise SystemExit(main())
