"""Read-only verification of archived E2 evidence; no network or credentials needed."""
import hashlib,json,re
from pathlib import Path
from urllib.parse import urlparse
TOOL=Path(__file__).resolve().parents[1]
REPO=TOOL.parents[2]
DOCS=REPO/'docs/04-methodology/group-b/skill-baselines/e2'
def read(group,name):return json.loads((DOCS/'evidence'/group/name).read_text(encoding='utf-8-sig'))
def calls(trace):return [c for e in trace if e['role']=='assistant' for c in e['content'] if c['type']=='toolCall']
def target_read(trace,skill):return any(c['name']=='read' and c['arguments'].get('path','').replace('\\','/').endswith(f'/skills/{skill}/SKILL.md') for c in calls(trace))
def exec_results(trace):return [e for e in trace if e.get('toolName')=='exec' and e['role']=='toolResult']
def nested_fetch(trace):return next(e['details']['result']['details'] for e in trace if e['role']=='custom' and e.get('details',{}).get('toolName')=='web_fetch')
release=json.loads((TOOL/'source/tavily/release.json').read_text(encoding='utf-8'))
assert (release['owner'],release['slug'],release['version'])==('jacky1n7','openclaw-tavily-search','0.2.1')
for f in release['files']:assert hashlib.sha256((TOOL/'source/tavily'/f['path']).read_bytes()).hexdigest()==f['sha256'],f['path']
b=(TOOL/'source/weather/SKILL.md').read_bytes()
assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==read('weather','source-manifest.json')['git_blob_sha1']
for case,message in [('missing','Missing TAVILY_API_KEY'),('invalid','authentication failed')]:
 result=read('tavily',f'script-{case}.json');assert result['exitCode']==1 and message in result['stderr']
assert read('tavily','script-valid.json')['exitCode']==0
t=read('tavily','normal-clean-trace.json');assert target_read(t,'tavily-search')
commands=[c for c in calls(t) if c['name']=='exec'];assert len(commands)==1 and '/tavily-search/scripts/tavily_search.py' in commands[0]['arguments']['command']
raw=exec_results(t)[0]['details']['aggregated'];assert 'SCRIPT_EXITCODE=0' in raw
search=json.JSONDecoder().raw_decode(raw[raw.index('{'):])[0]
assert search==read('tavily','search-response.json')
assert len(search['results'])==3 and all(urlparse(r['url']).hostname=='docs.python.org' and all(k in r for k in ['title','url','snippet']) for r in search['results'])
http=nested_fetch(t);assert http['status']==200 and 'timeout' in http['text'] and 'blocking operations' in http['text']
assert len([c for c in calls(t) if c['name']=='tool_call' and c['arguments'].get('id')=='web_fetch'])==1
invalid=read('tavily','invalid-trace.json');assert target_read(invalid,'tavily-search')
assert len([c for c in calls(invalid) if c['name']=='exec'])==1
err=exec_results(invalid)[0]['details']['aggregated'];assert 'authentication failed' in err and re.search(r'(?:EXIT|CODE)[A-Z_]*\s*[=:]\s*1',err)
assert not any(c['name'] in ['web_fetch','tool_call'] for c in calls(invalid))
for case in ['normal-clean','invalid']:assert read('tavily',case+'-receipt.json')['terminalReceipt']['rerouted'] is False
offline=read('tavily','offline-boundaries.json');assert offline['passed'] and offline['testsRun']==12
w=read('weather','normal-trace.json');assert target_read(w,'weather')
wh=nested_fetch(w);assert wh['status']==200 and wh['truncated'] is False
data=json.JSONDecoder().raw_decode(wh['text'][wh['text'].index('{'):])[0];assert data==read('weather','weather-response.json')
answer=(DOCS/'evidence/weather/normal-answer.txt').read_text(encoding='utf-8')
for value in [data['current_condition'][0]['temp_C'],data['current_condition'][0]['humidity'],data['current_condition'][0]['weatherDesc'][0]['value'],data['nearest_area'][0]['areaName'][0]['value']]:assert value in answer
assert 'EXITCODE=0' in exec_results(read('weather','fallback-trace.json'))[0]['details']['aggregated']
errors=exec_results(read('weather','error-trace.json'));assert len(errors)==1 and 'CURL_EXITCODE=28' in errors[0]['details']['aggregated']
for case in ['normal','invalid']:
 mt=read('migration',case+'-trace.json')
 mc=calls(mt)
 assert any(c['name']=='read' and re.sub(r'[\\/]+','/',c['arguments'].get('path','')).endswith('/skills/tavily-search/SKILL.md') for c in mc)
 assert len([c for c in mc if c['name']=='exec'])==1
 mr=exec_results(mt)[0]['details']['aggregated']
 if case=='normal':
  assert 'SCRIPT_EXITCODE=0' in mr
  assert len(json.JSONDecoder().raw_decode(mr[mr.index('{'):])[0]['results'])==3
  assert nested_fetch(mt)['status']==200
 else:assert 'authentication failed' in mr and re.search(r'(?:EXIT|CODE)[A-Z_]*\s*[=:]\s*1',mr)
 assert read('migration',case+'-receipt.json')['terminalReceipt']['rerouted'] is False
manifest_path=DOCS/'publication-manifest.json'
if manifest_path.exists():
 for row in json.loads(manifest_path.read_text(encoding='utf-8'))['files']:
  assert hashlib.sha256((REPO/row['path']).read_bytes().replace(b'\r\n',b'\n')).hexdigest()==row['sha256'],row['path']
print(json.dumps({'source_hashes_verified':True,'tavily_missing_invalid_valid_verified':True,'tavily_agent_single_search_and_source_read_verified':True,'tavily_invalid_agent_stopped':True,'weather_normal_fallback_timeout_verified':True,'archived_offline_cases':12,'publication_manifest_checked':manifest_path.exists(),'limits':'Archived runs only; output wording caveats remain in reports. Fresh API calls are separate.'},indent=2))
