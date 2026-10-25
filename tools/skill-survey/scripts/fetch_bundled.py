"""Fetch only official bundled skill files at a pinned commit; never execute them."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import urllib.parse
from fetch_clawhub import get

ROOT = Path(__file__).resolve().parents[1]
COMMIT = 'd79ab6195d8d0566b285008bcc30c01a6ce368e2'
def main():
    api = 'https://api.github.com/repos/openclaw/openclaw/git/trees/'
    root = json.loads(get(api + COMMIT))
    skills_sha = next(x['sha'] for x in root['tree'] if x['path'] == 'skills')
    tree = json.loads(get(api + skills_sha + '?recursive=1'))
    if tree.get('truncated'):
        raise RuntimeError('Incomplete skills tree')
    (ROOT / 'data' / 'bundled-tree.json').write_text(json.dumps({
        'repository': 'https://github.com/openclaw/openclaw', 'commit': COMMIT,
        'tree': tree,
    }, ensure_ascii=False, indent=2), 'utf-8')
    def fetch(entry):
        rel = entry['path']
        dest = ROOT / 'data' / 'openclaw-skills' / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            content = dest.read_bytes()
        else:
            url = f'https://raw.githubusercontent.com/openclaw/openclaw/{COMMIT}/skills/' + urllib.parse.quote(rel)
            content = get(url)
            dest.write_bytes(content)
        gitsha = hashlib.sha1(b'blob ' + str(len(content)).encode() + b'\0' + content).hexdigest()
        if gitsha != entry['sha']:
            raise RuntimeError(f'Content hash mismatch: {rel}')
        return rel
    files = [x for x in tree['tree'] if x['type'] == 'blob']
    with ThreadPoolExecutor(max_workers=8) as pool:
        downloaded = list(pool.map(fetch, files))
    print(json.dumps({'commit': COMMIT, 'verified_files': len(downloaded),
                      'skills': sum(p.endswith('/SKILL.md') for p in downloaded)}))
if __name__ == '__main__':
    main()
