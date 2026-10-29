"""Enumerate disjoint public slug prefixes with resumable per-prefix cursors.

The upstream validator restricts initial characters to [a-z0-9]. Each partition
is complete only after its own cursor becomes null. No detail classification
is inferred from a listing summary.
"""
from concurrent.futures import ThreadPoolExecutor
import datetime as dt
import json
from pathlib import Path
import string
import urllib.parse
from fetch_clawhub import get

ROOT = Path(__file__).resolve().parents[1]
PREFIXES = string.digits + string.ascii_lowercase

def crawl(prefix):
    folder = ROOT / 'data' / 'clawhub-prefixes' / prefix
    folder.mkdir(parents=True, exist_ok=True)
    checkpoint = folder / 'coverage.json'
    state = json.loads(checkpoint.read_text('utf-8')) if checkpoint.exists() else {
        'prefix': prefix, 'pages': 0, 'next_cursor': None, 'complete': False,
        'started_at': dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    while not state['complete']:
        q = {'limit': 200, 'sort': 'name', 'prefix': prefix}
        previous = state['next_cursor']
        if previous:
            q['cursor'] = previous
        payload = get('https://clawhub.ai/api/v1/skills?' + urllib.parse.urlencode(q))
        page = json.loads(payload)
        if any(not x['slug'].startswith(prefix) for x in page.get('items', [])):
            raise RuntimeError('API did not honor prefix')
        number = state['pages'] + 1
        (folder / f'{number:05}.json').write_bytes(payload)
        cursor = page.get('nextCursor')
        if cursor and cursor == previous:
            raise RuntimeError('Repeated cursor')
        state.update(pages=number, next_cursor=cursor, complete=cursor is None,
                     updated_at=dt.datetime.now(dt.timezone.utc).isoformat())
        checkpoint.write_text(json.dumps(state, ensure_ascii=False, indent=2), 'utf-8')
        if number % 5 == 0 or state['complete']:
            print(f'prefix={prefix} page={number} complete={state["complete"]}', flush=True)
    return state

def main():
    with ThreadPoolExecutor(max_workers=6) as pool:
        states = list(pool.map(crawl, PREFIXES))
    state = {
        'endpoint': 'https://clawhub.ai/api/v1/skills',
        'sort': 'name', 'limit': 200, 'prefixes': list(PREFIXES),
        'listing_complete': all(s['complete'] for s in states),
        'detail_review_complete': False,
        'scope': 'public native-skill listings readable via API across [0-9a-z] prefixes; excludes hidden/private entries and other registry families',
        'consistency': 'live traversal, not an atomic snapshot; deleted/updated items may change during collection',
        'slug_shape_source': 'https://github.com/openclaw/clawhub/blob/main/convex/lib/skillSlugValidator.ts',
        'partitions': states,
    }
    (ROOT / 'data' / 'clawhub-prefix-coverage.json').write_text(json.dumps(state, ensure_ascii=False, indent=2), 'utf-8')
    print('All public slug partitions complete.', flush=True)

if __name__ == '__main__':
    main()
