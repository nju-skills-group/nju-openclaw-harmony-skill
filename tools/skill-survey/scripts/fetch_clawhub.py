"""Cache the public ClawHub catalog. Read-only; never installs skills.

Run with Python 3. Resume uses the last saved opaque cursor. Listing coverage
is separate from source review and runtime validation.
"""
import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[1]

def get(url):
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={
                'User-Agent': 'NJU-Skill-Survey/1.0 (public read-only coursework)'
            }), timeout=45) as response:
                return response.read()
        except urllib.error.HTTPError as exc:
            if exc.code not in (429, 500, 502, 503, 504) or attempt == 3:
                raise
            delay = max(2 ** attempt, int(exc.headers.get('Retry-After', '5')))
            print(f'HTTP {exc.code}; retry in {delay}s', flush=True)
            time.sleep(delay)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--max-pages', type=int, default=2000)
    args = parser.parse_args()
    raw = ROOT / 'data' / 'clawhub-pages'
    raw.mkdir(parents=True, exist_ok=True)
    checkpoint = ROOT / 'data' / 'clawhub-coverage.json'
    state = json.loads(checkpoint.read_text('utf-8')) if checkpoint.exists() else {
        'started_at': dt.datetime.now(dt.timezone.utc).isoformat(),
        'endpoint': 'https://clawhub.ai/api/v1/skills',
        'sort': 'name', 'limit': 200, 'pages': 0, 'next_cursor': None,
        'listing_complete': False, 'detail_review_complete': False,
        'scope': 'public native skills exposed by this API; excludes private/hidden items, plugins and other registry families',
        'consistency': 'live cursor traversal; not an atomic historical snapshot',
    }
    if state['listing_complete']:
        print('Catalog already complete; using cached pages.')
        return
    seen_cursors = set()
    for _ in range(args.max_pages):
        query = {'limit': 200, 'sort': 'name'}
        if state['next_cursor']:
            query['cursor'] = state['next_cursor']
        url = state['endpoint'] + '?' + urllib.parse.urlencode(query)
        payload = get(url)
        page = json.loads(payload)
        number = state['pages'] + 1
        (raw / f'{number:05}.json').write_bytes(payload)
        cursor = page.get('nextCursor')
        if cursor and cursor in seen_cursors:
            raise RuntimeError('Repeated cursor; refusing false completeness')
        if cursor:
            seen_cursors.add(cursor)
        state.update(pages=number, next_cursor=cursor,
                     listing_complete=cursor is None,
                     updated_at=dt.datetime.now(dt.timezone.utc).isoformat())
        checkpoint.write_text(json.dumps(state, ensure_ascii=False, indent=2), 'utf-8')
        print(f'page={number} items={len(page.get("items", []))} complete={state["listing_complete"]}', flush=True)
        if cursor is None:
            break

if __name__ == '__main__':
    main()
