"""Run a healthcheck baseline without replacing earlier evidence (Linux/WSL)."""
import argparse
import concurrent.futures
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import os
import shutil
import subprocess
import sys
import time
import uuid

HERE = Path(__file__).resolve().parent

def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--openclaw', default='openclaw')
    p.add_argument('--skill-file', type=Path)
    p.add_argument('--config', type=Path, help='File to hash, not a config override')
    p.add_argument('--output-root', type=Path, default=HERE / 'runs')
    p.add_argument('--model', help='Optional per-run override; default uses existing routing')
    p.add_argument('--timeout', type=int, default=240)
    p.add_argument('--prepare-only', action='store_true', help='Prepare only; no model request')
    args = p.parse_args()
    if args.timeout < 30:
        p.error('--timeout must be at least 30 seconds')
    cli = shutil.which(args.openclaw)
    if not cli:
        p.error('OpenClaw executable not found; use --openclaw')
    skill = (args.skill_file or Path(cli).resolve().parent / 'skills/healthcheck/SKILL.md').expanduser().resolve()
    if not skill.is_file():
        p.error('Skill file not found; use --skill-file')
    config = (args.config or Path(os.environ.get('OPENCLAW_CONFIG_PATH', str(Path.home() / '.openclaw/openclaw.json')))).expanduser().resolve()
    run_id = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex
    session = 'e4-healthcheck-' + run_id.lower()
    out = args.output_root.expanduser().resolve() / run_id
    out.mkdir(parents=True, exist_ok=False)
    (out / 'source').mkdir()
    shutil.copyfile(skill, out / 'source/SKILL.md')
    prompt = (HERE / 'prompt-template.txt').read_text(encoding='utf-8').replace('{skill_file}', str(skill))
    (out / 'prompt.txt').write_text(prompt, encoding='utf-8')
    commands = [('security-audit', ['security', 'audit'], ['--deep', '--fix']),
                ('gateway-status', ['gateway', 'status'], ['--deep']), ('doctor', ['doctor'], ['--lint'])]
    def help_capture(item):
        label, subcmd, required = item
        result = subprocess.run([cli, *subcmd, '--help'], capture_output=True, text=True, timeout=75)
        text = result.stdout + result.stderr
        (out / (label + '-help.txt')).write_text(text, encoding='utf-8')
        return {'name': label, 'exit_code': result.returncode, 'required_options_found': all(x in text for x in required)}
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        helps = list(pool.map(help_capture, commands))
    meta = {'run_id': run_id, 'session_id': session, 'session_key': 'agent:main:explicit:' + session,
            'created_utc': datetime.now(timezone.utc).isoformat(), 'prepare_only': args.prepare_only,
            'openclaw': cli, 'skill_file': str(skill), 'skill_sha256': sha(skill),
            'config_file_hashed': str(config), 'config_sha256_before': sha(config), 'help_results': helps,
            'isolation': 'unique session and output; existing Gateway/config/workspace shared',
            'restriction': 'prompt restrictions; not an enforced tool allowlist'}
    write_json(out / 'run-metadata.json', meta)
    print(json.dumps({'output_dir': str(out), 'session_id': session, 'prepare_only': args.prepare_only}), flush=True)
    if not all(h['exit_code'] == 0 and h['required_options_found'] for h in helps):
        return 2
    if args.prepare_only:
        return 0
    cmd = [cli, 'agent', '--agent', 'main', '--session-id', session, '--message-file', str(out / 'prompt.txt'),
           '--thinking', 'off', '--timeout', str(args.timeout), '--json']
    if args.model:
        cmd += ['--model', args.model]
    meta['command'] = cmd
    started = time.monotonic()
    try:
        with (out / 'agent-result.json').open('w', encoding='utf-8') as stdout, (out / 'agent-stderr.txt').open('w', encoding='utf-8') as stderr:
            try:
                result = subprocess.run(cmd, stdout=stdout, stderr=stderr, timeout=args.timeout + 45, text=True)
                meta['cli_exit_code'] = result.returncode
            except subprocess.TimeoutExpired:
                meta['cli_exit_code'] = 'outer_timeout'
        meta['elapsed_seconds'] = round(time.monotonic() - started, 2)
        export_cmd = [cli, 'sessions', 'export-trajectory', '--agent', 'main', '--session-key', meta['session_key'],
                      '--workspace', str(out), '--output', 'baseline', '--json']
        export = subprocess.run(export_cmd, capture_output=True, text=True, timeout=90)
        (out / 'trajectory-export.json').write_text(export.stdout, encoding='utf-8')
        (out / 'trajectory-export-stderr.txt').write_text(export.stderr, encoding='utf-8')
        meta['export_exit_code'] = export.returncode
        exported = out / '.openclaw/trajectory-exports/baseline'
        if export.returncode == 0 and (exported / 'events.jsonl').is_file():
            shutil.copytree(exported, out / 'trajectory')
            check = subprocess.run([sys.executable, str(HERE / 'extract_evidence.py'), '--trace', str(out / 'trajectory/events.jsonl'),
                                    '--agent-result', str(out / 'agent-result.json'), '--output', str(out / 'verified')],
                                   capture_output=True, text=True, timeout=30)
            (out / 'verification-log.txt').write_text(check.stdout + check.stderr, encoding='utf-8')
            meta['evidence_verification_exit_code'] = check.returncode
    finally:
        meta['config_sha256_after'] = sha(config)
        meta['config_unchanged'] = meta['config_sha256_before'] == meta['config_sha256_after']
        write_json(out / 'run-metadata.json', meta)
    print(json.dumps({'output_dir': str(out), 'cli_exit_code': meta.get('cli_exit_code'),
                      'verification_exit_code': meta.get('evidence_verification_exit_code'),
                      'config_unchanged': meta['config_unchanged']}), flush=True)
    return 0 if meta.get('cli_exit_code') == 0 and meta.get('evidence_verification_exit_code') == 0 else 1

if __name__ == '__main__':
    raise SystemExit(main())
