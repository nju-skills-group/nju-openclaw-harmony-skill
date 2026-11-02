"""Extract read-only discovery evidence; no model or registry requests."""
import argparse
import json
from pathlib import Path

def walk(x):
    if isinstance(x, dict):
        yield x
        for value in x.values():
            yield from walk(value)
    elif isinstance(x, list):
        for value in x:
            yield from walk(value)

def scrub(x):
    if isinstance(x, str):
        return x.replace(str(Path.home()), '<USER_HOME>').replace('/mnt/e/大三上/项目/skill移植', '<PROJECT_ROOT>')
    if isinstance(x, list):
        return [scrub(v) for v in x]
    if isinstance(x, dict):
        return {k: scrub(v) for k, v in x.items()}
    return x

def save(path, value):
    path.write_text(json.dumps(scrub(value), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--case', choices=['plugins', 'skills'], required=True)
    p.add_argument('--trace', type=Path, required=True)
    p.add_argument('--agent-result', type=Path, required=True)
    p.add_argument('--input', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    a = p.parse_args()
    events = [json.loads(line) for line in a.trace.read_text(encoding='utf-8-sig').splitlines() if line.strip()]
    calls = [e for e in events if e.get('source') == 'runtime' and e['type'] == 'tool.call']
    results = [e for e in events if e.get('source') == 'runtime' and e['type'] == 'tool.result']
    # Keep native tool calls/results; omit code-mode wrappers and wait bookkeeping.
    native = [e for e in calls if not (e['data'].get('name') == 'exec' and 'code' in e['data'].get('args', {})) and e['data'].get('name') != 'wait']
    ids = {e['data']['toolCallId'] for e in native}
    selected = [e for e in events if e.get('source') == 'runtime' and e['type'] in ('tool.call', 'tool.result') and e['data'].get('toolCallId') in ids]
    reads, routes, outputs, forbidden, failures, native_outputs = [], [], [], [], [], []
    for e in native:
        d, args = e['data'], e['data'].get('args', {})
        if d.get('name') == 'read' and str(args.get('path', '')).endswith('/clawhub/SKILL.md'):
            reads.append(e)
        cmd = args.get('command', '')
        if cmd.startswith('openclaw ' + a.case + ' search') or (d.get('name') == 'plugins' and args.get('action') == 'search' and a.case == 'plugins'):
            routes.append(e)
        if cmd and not (cmd.startswith('openclaw ' + a.case + ' search') or cmd.endswith(' --help')):
            forbidden.append({'seq': e['seq'], 'name': d.get('name'), 'args': args})
        if d.get('name') in ('write', 'edit') or args.get('action') in ('install', 'uninstall', 'update', 'publish', 'sync'):
            forbidden.append({'seq': e['seq'], 'name': d.get('name'), 'args': args})
    success_ids = {e['data'].get('toolCallId') for e in results if e['data'].get('success') is True}
    read_ok = any(e['data']['toolCallId'] in success_ids for e in reads)
    route_ids = {e['data']['toolCallId'] for e in routes}
    for e in results:
        d = e['data']
        if d.get('success') is False:
            failures.append({'seq': e['seq'], 'name': d.get('name')})
        if d.get('toolCallId') not in ids:
            continue
        if d.get('toolCallId') in route_ids and d.get('name') != 'exec':
            native_outputs.append({'seq': e['seq'], 'tool': d.get('name'), 'success': d.get('success'),
                                   'result': d.get('result')})
        for obj in walk(d.get('result', {})):
            if isinstance(obj.get('aggregated'), str) and obj.get('exitCode') is not None:
                item = {'seq': e['seq'], 'tool': d.get('name'), 'exit_code': obj['exitCode'], 'output': obj['aggregated']}
                if item not in outputs:
                    outputs.append(item)
    agent = json.loads(a.agent_result.read_text(encoding='utf-8-sig'))
    am = agent.get('result', {}).get('meta', {}).get('agentMeta', {})
    receipt = {k: agent[k] for k in ('runId', 'status', 'summary') if k in agent}
    receipt['result'] = {'payloads': agent.get('result', {}).get('payloads', []), 'meta': {
        'durationMs': agent.get('result', {}).get('meta', {}).get('durationMs'),
        'agentMeta': {k: am[k] for k in ('sessionId', 'provider', 'model', 'terminalReceipt') if k in am}}}
    summary = {'case': a.case, 'skill_read_confirmed': read_ok, 'correct_discovery_route_observed': bool(routes),
               'read_events': [{'call_seq': e['seq'], 'tool_call_id': e['data']['toolCallId']} for e in reads],
               'route_calls': [{'seq': e['seq'], 'name': e['data']['name'], 'args': e['data'].get('args')} for e in routes],
               'native_calls': [{'seq': e['seq'], 'name': e['data']['name'], 'args': e['data'].get('args')} for e in native],
               'completed_process_outputs': [{k: v for k, v in x.items() if k != 'output'} for x in outputs],
               'native_search_result_events': [{'seq': e['seq'], 'tool': e['tool'], 'success': e['success']} for e in native_outputs],
               'forbidden_calls_observed': forbidden, 'failed_tools': failures, 'agent_status': agent.get('status'),
               'scope': 'call evidence only; inspect returned search data separately'}
    summary['call_chain_verified'] = read_ok and bool(route_ids & success_ids) and not forbidden and agent.get('status') == 'ok'
    a.output.mkdir(parents=True, exist_ok=False)
    (a.output / 'events.jsonl').write_text(''.join(json.dumps(scrub(e), ensure_ascii=False) + '\n' for e in selected), encoding='utf-8')
    (a.output / 'input.txt').write_text(scrub(a.input.read_text(encoding='utf-8')), encoding='utf-8')
    save(a.output / 'agent-result.json', receipt)
    save(a.output / 'verification.json', summary)
    text_outputs = ['seq=' + str(x['seq']) + ' exit=' + str(x['exit_code']) + '\n' + scrub(x['output']) for x in outputs]
    text_outputs += ['seq=' + str(x['seq']) + ' native_tool=' + x['tool'] + ' success=' + str(x['success']) + '\n' +
                     json.dumps(scrub(x['result'].get('details') or x['result']), ensure_ascii=False, indent=2) for x in native_outputs]
    (a.output / 'tool-output.txt').write_text('\n\n'.join(text_outputs), encoding='utf-8')
    print(json.dumps(scrub(summary), ensure_ascii=False, indent=2))
    return 0 if summary['call_chain_verified'] else 1

if __name__ == '__main__':
    raise SystemExit(main())
