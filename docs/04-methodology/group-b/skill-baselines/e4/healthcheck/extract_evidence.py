"""Verify one exported healthcheck trajectory; never request a model or overwrite outputs."""
import argparse
import json
from pathlib import Path

COMMANDS = {'openclaw security audit --deep': 'security-audit',
            'openclaw gateway status --deep': 'gateway-status', 'openclaw doctor --lint': 'doctor-lint'}

def walk(obj):
    if isinstance(obj, dict):
        yield obj
        for value in obj.values():
            yield from walk(value)
    elif isinstance(obj, list):
        for value in obj:
            yield from walk(value)

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--trace', type=Path, required=True)
    p.add_argument('--agent-result', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    a = p.parse_args()
    events = [json.loads(line) for line in a.trace.read_text(encoding='utf-8-sig').splitlines() if line.strip()]
    runtime = [e for e in events if e.get('source') == 'runtime']
    calls = {e['data']['toolCallId']: e for e in runtime if e['type'] == 'tool.call'}
    origins, completed, reads, polls, actual, failures = {}, {}, [], [], [], []
    for e in runtime:
        d = e['data']
        if e['type'] == 'tool.call':
            args = d.get('args', {})
            if 'command' in args:
                actual.append({'seq': e['seq'], 'command': args['command']})
            if d.get('name') == 'process':
                polls.append({'seq': e['seq'], 'args': args})
            continue
        if e['type'] != 'tool.result':
            continue
        call = calls.get(d.get('toolCallId'), {})
        args = call.get('data', {}).get('args', {})
        name = call.get('data', {}).get('name')
        if d.get('success') is False:
            failures.append({'seq': e['seq'], 'tool': name})
        if name == 'read' and d.get('success') and str(args.get('path', '')).endswith('/healthcheck/SKILL.md'):
            reads.append({'call_seq': call['seq'], 'result_seq': e['seq'], 'path': args['path']})
        cmd = args.get('command')
        if name == 'process':
            cmd = origins.get(args.get('sessionId'))
        for obj in walk(d.get('result', {})):
            if cmd in COMMANDS and obj.get('sessionId'):
                origins[obj['sessionId']] = cmd
            if cmd in COMMANDS and isinstance(obj.get('aggregated'), str) and obj.get('exitCode') is not None:
                completed[COMMANDS[cmd]] = {'command': cmd, 'call_seq': call.get('seq'), 'result_seq': e['seq'],
                                           'exit_code': obj['exitCode'], 'tool': name, 'output': obj['aggregated']}
    agent = json.loads(a.agent_result.read_text(encoding='utf-8-sig'))
    allowed = len(actual) == 3 and {x['command'] for x in actual} == set(COMMANDS)
    exits_ok = (completed.get('security-audit', {}).get('exit_code') == 0
                and completed.get('gateway-status', {}).get('exit_code') == 0
                and completed.get('doctor-lint', {}).get('exit_code') in (0, 1))
    passed = bool(reads) and allowed and len(completed) == 3 and exits_ok and agent.get('status') == 'ok'
    a.output.mkdir(parents=True, exist_ok=False)
    for label, item in completed.items():
        (a.output / (label + '-tool-output.txt')).write_text(item.pop('output'), encoding='utf-8')
    report = '\n\n'.join(x.get('text', '') for x in agent.get('result', {}).get('payloads', []))
    (a.output / 'model-report.md').write_text(report, encoding='utf-8')
    summary = {'passed': passed, 'meaning': 'Skill read and three completed commands; not a clean security bill',
               'skill_reads': reads, 'actual_shell_commands': actual, 'process_calls': polls,
               'check_results': completed, 'failed_runtime_tools': failures, 'agent_status': agent.get('status'),
               'trace_event_count': len(events)}
    (a.output / 'verification.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0 if passed else 1

if __name__ == '__main__':
    raise SystemExit(main())
