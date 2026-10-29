"""Verify saved catalog coverage, identities and source digests without execution."""
import csv
import hashlib
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(os.environ.get('SKILL_SURVEY_OUTPUT', ROOT / 'docs/04-methodology/group-b/skill-survey'))

def load(path):
    return json.loads(path.read_text('utf-8'))

def main():
    coverage = load(OUT / 'coverage.json')
    rows = load(OUT / 'reviewed-skills.json')
    plan = load(ROOT/'data/sampling-plan.json')
    expected = 50 + len(plan)
    assert len(rows) == expected == len({r['id'] for r in rows})
    assert sum(r['source'] == 'bundled' for r in rows) == 50
    assert all(r['original_runtime_status'] == r['harmony_runtime_status'] == '未运行' for r in rows)
    assert all(r['reason'] and r['next_action'] and r['source_url'] for r in rows)
    for r in rows:
        if r['source'] == 'bundled':
            path = ROOT / 'data/openclaw-skills' / r['id'].split(':', 1)[1] / 'SKILL.md'
        else:
            path = ROOT / 'data/clawhub-reviewed' / r['id'].split(':', 1)[1] / 'source/SKILL.md'
        assert hashlib.sha256(path.read_bytes()).hexdigest() == r['sha256']
    official = load(ROOT / 'data/bundled-tree.json')['tree']['tree']
    official_count = 0
    for f in official:
        if f['type'] != 'blob':
            continue
        content = (ROOT / 'data/openclaw-skills' / f['path']).read_bytes()
        assert hashlib.sha1(b'blob ' + str(len(content)).encode() + b'\0' + content).hexdigest() == f['sha']
        official_count += 1
    candidate_files = 0
    for p in (ROOT / 'data/clawhub-reviewed').glob('*/*/version.json'):
        for entry in load(p)['version']['files']:
            content = (p.parent / 'source' / entry['path']).read_bytes()
            assert hashlib.sha256(content).hexdigest() == entry['sha256']
            candidate_files += 1
    with (OUT / 'reviewed-skills.csv').open(encoding='utf-8-sig', newline='') as stream:
        assert len(list(csv.DictReader(stream))) == expected
    ids = set()
    pending = 0
    with (OUT / 'clawhub-catalog.csv').open(encoding='utf-8-sig', newline='') as stream:
        for r in csv.DictReader(stream):
            assert r['id'] not in ids
            ids.add(r['id'])
            pending += r['portability'] == '待分类'
            assert r['screening_status'].startswith('自动摘要初筛')
            assert r['functional_category'] and r['screening_signal']
    assert len(ids) == coverage['clawhub_unique_listings']
    assert pending == coverage['clawhub_pending_classification']
    partition_files = list((ROOT / 'data/clawhub-prefixes').glob('*/coverage.json'))
    states = [load(p) for p in partition_files] if partition_files else load(ROOT/'data/catalog-coverage.json')['partitions']
    assert len(states) == 36
    for state in states:
        assert state['complete'] and state['next_cursor'] is None
    for p in partition_files:
        state = load(p)
        pages = sorted(p.parent.glob('[0-9]*.json'))
        assert len(pages) == state['pages']
        assert load(pages[-1]).get('nextCursor') is None
        for page in pages:
            assert all(item['slug'].startswith(state['prefix']) for item in load(page).get('items', []))
    assert coverage['clawhub_listing_complete']
    assert sum(coverage['screening_signals'].values()) == len(ids)
    assert sum(coverage['functional_categories'].values()) == len(ids)
    assert coverage['clawhub_reviewed_samples'] == len(plan)
    legacy = next(r for r in rows if r['id']=='clawhub:steipete/apple-notes')
    assert legacy['metadata_namespace']=='clawdbot'
    assert legacy['requires_bins_all']=='memo' and legacy['declared_os']=='darwin'
    result = {
        'status': 'PASS', 'reviewed_records': len(rows), 'public_catalog_records': len(ids),
        'completed_prefixes': 36, 'verified_bundled_files': official_count,
        'verified_clawhub_candidate_files': candidate_files,
        'raw_pagination_rechecked': bool(partition_files),
        'original_runtime_verified': False, 'harmony_runtime_verified': False,
    }
    (OUT / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), 'utf-8')
    print(json.dumps(result, ensure_ascii=False))

if __name__ == '__main__':
    main()
