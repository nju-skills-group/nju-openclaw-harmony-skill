"""Fetch version-pinned candidate metadata and text for static review only."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import urllib.parse
from fetch_clawhub import get

ROOT = Path(__file__).resolve().parents[1]
CANDIDATES = [(r['owner'], r['slug'], r['version']) for r in
              json.loads((ROOT / 'data' / 'sampling-plan.json').read_text('utf-8'))]

def fetch(candidate):
    owner, slug, version = candidate
    folder = ROOT / 'data' / 'clawhub-reviewed' / owner / slug
    folder.mkdir(parents=True, exist_ok=True)
    base = 'https://clawhub.ai/api/v1/skills/' + slug
    query = urllib.parse.urlencode({'ownerHandle': owner})
    detail_path, version_path = folder / 'detail.json', folder / 'version.json'
    detail = json.loads(detail_path.read_text('utf-8')) if detail_path.exists() else json.loads(get(base + '?' + query))
    release = json.loads(version_path.read_text('utf-8')) if version_path.exists() else json.loads(get(base + '/versions/' + version + '?' + query))
    actual_owner = (detail.get('owner') or {}).get('handle')
    if actual_owner and actual_owner != owner:
        raise RuntimeError('Publisher identity mismatch')
    if release.get('version', {}).get('version') != version:
        raise RuntimeError('Requested version mismatch')
    (folder / 'detail.json').write_text(json.dumps(detail, ensure_ascii=False, indent=2), 'utf-8')
    (folder / 'version.json').write_text(json.dumps(release, ensure_ascii=False, indent=2), 'utf-8')
    files = release.get('version', release).get('files', [])
    if not files:
        raise RuntimeError('Missing release file inventory')
    def fetch_file(entry):
        path = entry['path']
        if Path(path).is_absolute() or '..' in Path(path).parts:
            raise RuntimeError('Invalid release path')
        dest = folder / 'source' / path
        if not dest.resolve().is_relative_to((folder / 'source').resolve()):
            raise RuntimeError('Release path escapes source directory')
        data = dest.read_bytes() if dest.exists() else get(base + '/file?' + urllib.parse.urlencode({
            'path': path, 'version': version, 'ownerHandle': owner,
        }))
        if entry.get('sha256') and hashlib.sha256(data).hexdigest() != entry['sha256']:
            raise RuntimeError('File digest mismatch')
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
    with ThreadPoolExecutor(max_workers=4) as file_pool:
        list(file_pool.map(fetch_file, files))
    print(f'Review candidate downloaded: {owner}/{slug}@{version}, {len(files)} files', flush=True)

if __name__ == '__main__':
    with ThreadPoolExecutor(max_workers=6) as pool:
        list(pool.map(fetch, CANDIDATES))
