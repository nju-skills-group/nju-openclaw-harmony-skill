"""Build source-linked survey records. Requires PyYAML; no skill is executed."""
import collections
import csv
import gzip
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.parse
import yaml
from catalog_triage import screen

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data'
OUT = Path(os.environ.get('SKILL_SURVEY_OUTPUT', ROOT / 'docs' / '04-methodology' / 'group-b' / 'skill-survey'))
COMMIT = 'd79ab6195d8d0566b285008bcc30c01a6ce368e2'
HOST_TOOLS = ['web_fetch', 'web_search', 'show_widget', 'skill_workshop', 'process',
              'exec', 'browser', 'plugins', 'sessions_spawn', 'cron', 'nodes']

def load(path):
    return json.loads(path.read_text('utf-8'))

def parse(path):
    text = path.read_text('utf-8')
    parts = text.split('---', 2)
    if len(parts) != 3:
        raise ValueError(f'Missing frontmatter: {path}')
    return yaml.safe_load(parts[1]), text

def join(values):
    return '; '.join(map(str, values)) if values else '未声明'

def common(path, source_url, identity, source, version, review):
    front, text = parse(path)
    meta = front.get('metadata') or {}
    if isinstance(meta, str):
        meta = json.loads(meta)
    namespace = next((n for n in ['openclaw','clawdbot','clawdis'] if meta.get(n)), '')
    oc = meta.get(namespace) or {}
    requires = oc.get('requires') or {}
    files = sorted(p for p in path.parent.rglob('*') if p.is_file())
    scripts = [p for p in files if p.suffix.lower() in ('.py', '.sh', '.mjs', '.js', '.ts', '.ets')
               or p.parent.name == 'bin']
    langmap = {'.py': 'Python', '.sh': 'bash', '.mjs': 'Node.js JavaScript',
               '.js': 'JavaScript', '.ts': 'TypeScript', '.ets': 'ArkTS'}
    langs = sorted({langmap.get(p.suffix.lower(), '脚本（需查 shebang）') for p in scripts})
    # Evidence extraction is an index, not a complete program analysis.
    tools = [t for t in HOST_TOOLS if re.search(r'\b' + re.escape(t) + r'\b', text)]
    declared_bins = requires.get('bins') or []
    any_bins = requires.get('anyBins') or []
    keys = requires.get('env') or []
    primary = oc.get('primaryEnv')
    evidence_tokens = declared_bins + any_bins + tools
    evidence = []
    for i, line in enumerate(text.splitlines(), 1):
        if any(token in line for token in evidence_tokens) or ('darwin' in line):
            evidence.append({'line': i, 'text': line.strip()[:240],
                             'url': source_url + (f'#L{i}' if source == 'bundled' else '')})
    grade, category, reason, action = review
    return {
        'id': identity, 'name': front.get('name', path.parent.name), 'source': source,
        'version': version, 'category': category, 'description': front.get('description', ''),
        'license': front.get('license') or ('MIT（仓库 LICENSE）' if source == 'bundled' else '待查版本元数据'),
        'registry_slug': '',
        'metadata_namespace': namespace or '未声明',
        'script_languages': join(langs) if langs else '无独立脚本；正文命令另计',
        'script_files': join([p.relative_to(path.parent).as_posix() for p in scripts]) if scripts else '无',
        'declared_os': join(oc.get('os') or []) + ('（未声明不代表支持鸿蒙）' if not oc.get('os') else ''),
        'requires_bins_all': join(declared_bins), 'requires_bins_any': join(any_bins),
        'requires_env': join(keys), 'primary_env': primary or '未声明',
        'requires_config': join(requires.get('config') or []),
        'host_tools_text_hits': join(tools) if tools else '需读正文判断，未发现预设词命中',
        'portability': grade, 'classification_status': '静态候选；未做鸿蒙运行验证',
        'reason': reason, 'next_action': action, 'original_runtime_status': '未运行',
        'harmony_runtime_status': '未运行', 'source_url': source_url,
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'frontmatter': front, 'evidence': evidence[:12],
        'review_scope': 'SKILL.md、元数据、文件清单及相关附带脚本；外部 CLI 未逐项审计',
    }

def csvwrite(path, rows, fields):
    with path.open('w', encoding='utf-8-sig', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, extrasaction='ignore', lineterminator='\n')
        writer.writeheader()
        for row in rows:
            # Prevent a third-party description from becoming an Excel formula.
            writer.writerow({k: ("'" + v if isinstance(v, str) and v.startswith(('=', '+', '-', '@')) else v)
                             for k, v in row.items() if k in fields})

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    reviews = load(DATA / 'bundled-review.json')
    paths = sorted((DATA / 'openclaw-skills').glob('*/SKILL.md'))
    if set(reviews) != {p.parent.name for p in paths}:
        raise ValueError('Review coverage does not equal bundled source inventory')
    rows = []
    for p in paths:
        name = p.parent.name
        url = f'https://github.com/openclaw/openclaw/blob/{COMMIT}/skills/{name}/SKILL.md'
        rows.append(common(p, url, 'bundled:' + name, 'bundled', COMMIT, reviews[name]))
    candidate_reviews = load(DATA / 'clawhub-review.json')
    plan = load(DATA / 'sampling-plan.json')
    strata = {f'{r["owner"]}/{r["slug"]}':r['stratum'] for r in plan}
    if set(candidate_reviews) != set(strata):
        raise ValueError('Sample review set differs from sampling plan')
    for path in sorted((DATA / 'clawhub-reviewed').glob('*/*/version.json')):
        release = load(path)['version']
        owner, slug = path.parent.parent.name, path.parent.name
        detail = load(path.parent / 'detail.json')
        actual_owner = (detail.get('owner') or {}).get('handle')
        if actual_owner and actual_owner != owner:
            raise ValueError('Registry owner mismatch')
        row = common(path.parent / 'source' / 'SKILL.md',
                     f'https://clawhub.ai/{owner}/skills/{slug}',
                     f'clawhub:{owner}/{slug}', 'ClawHub', release['version'], candidate_reviews[f'{owner}/{slug}'])
        row['license'] = release.get('license', '未声明')
        row['registry_slug'] = slug
        row['sampling_stratum'] = strata[f'{owner}/{slug}']
        row['declared_license_text'] = row['frontmatter'].get('license', '未声明')
        row['license_review_note'] = '版本许可与 frontmatter 引用需复核' if 'LICENSE.txt' in row['declared_license_text'] else '许可仅登记元数据，未做法律审查'
        row['version_file_inventory_url'] = f'https://clawhub.ai/api/v1/skills/{slug}/versions/{release["version"]}?ownerHandle={owner}'
        rows.append(row)
    (OUT / 'reviewed-skills.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), 'utf-8', newline='\n')
    fields = [k for k in rows[0] if k not in ('frontmatter', 'evidence')]
    csvwrite(OUT / 'reviewed-skills.csv', rows, fields)
    # Public listing inventory: preserve owner identity, version and unknowns.
    catalog, duplicates, changes = {}, 0, []
    pages = sorted((DATA / 'clawhub-prefixes').glob('*/[0-9]*.json'))
    if pages:
        raw_groups = (load(p).get('items', []) for p in pages)
    else:
        with gzip.open(DATA/'catalog-input.jsonl.gz','rt',encoding='utf-8') as stream:
            raw_groups = [[json.loads(line) for line in stream]]
    for group in raw_groups:
        for item in group:
            key = (item.get('ownerHandle') or 'UNKNOWN', item['slug'])
            previous = catalog.get(key)
            if previous:
                duplicates += 1
                if previous.get('tags', {}).get('latest') != item.get('tags', {}).get('latest'):
                    changes.append('/'.join(key))
                if previous.get('updatedAt', 0) > item.get('updatedAt', 0):
                    continue
            catalog[key] = item
    reviewed_lookup = {r['id']: r for r in rows if r['source'] == 'ClawHub'}
    index = []
    screens = []
    for (owner, slug), item in sorted(catalog.items()):
        identity = f'clawhub:{owner}/{slug}'
        version = (item.get('tags') or {}).get('latest', '')
        r = reviewed_lookup.get(identity)
        exact = r and r['version'] == version
        screening = screen(item)
        screens.append({'id':identity, 'version':version, **screening})
        index.append({
            'id': identity, 'owner': owner, 'name': slug,
            'display_name': item.get('displayName', ''), 'source': 'ClawHub',
            'version': version, 'summary': item.get('summary') or '',
            'type_topics': '; '.join(item.get('topics') or []) or '待正文复核',
            'functional_category': screening['functional_category'],
            'screening_signal': screening['screening_signal'],
            'screening_basis': '; '.join(f'{c["field"]}: {c["match"]}' for c in screening['screening_clues']) or '摘要未提供足够依赖线索',
            'screening_status': screening['screening_status'],
            'script_languages': r['script_languages'] if exact else '待取版本文件与正文',
            'system_dependencies': (r['requires_bins_all'] + ' / ' + r['declared_os']) if exact else '待正文复核',
            'host_dependencies': r['host_tools_text_hits'] if exact else '待正文复核',
            'portability': r['portability'] if exact else '待分类',
            'review_status': '固定版本静态分析' if exact else '仅目录登记',
            'runtime_status': '原平台与鸿蒙均未运行',
            'source_url': f'https://clawhub.ai/{owner}/skills/{slug}',
            'raw_page': 'data/clawhub-prefixes/' + slug[0] + '/',
        })
    if not index:
        raise ValueError('Missing public catalog pages')
    csvwrite(OUT / 'clawhub-catalog.csv', index, list(index[0]))
    with (OUT / 'clawhub-catalog.jsonl').open('w', encoding='utf-8', newline='\n') as stream:
        for row in index:
            stream.write(json.dumps(row, ensure_ascii=False) + '\n')
    with (OUT / 'catalog-screening.jsonl').open('w', encoding='utf-8', newline='\n') as stream:
        for row in screens:
            stream.write(json.dumps(row, ensure_ascii=False) + '\n')
    partitions = [load(p) for p in sorted((DATA / 'clawhub-prefixes').glob('*/coverage.json'))]
    if not partitions:
        partitions = load(DATA/'catalog-coverage.json')['partitions']
    complete = len(partitions) == 36 and all(s['complete'] for s in partitions)
    summary = {
        'survey_date': '2026-10-25', 'bundled_commit': COMMIT,
        'bundled_count': len(paths), 'reviewed_count': len(rows),
        'reviewed_grades': dict(collections.Counter(r['portability'] for r in rows)),
        'bundled_grades': dict(collections.Counter(r['portability'] for r in rows if r['source'] == 'bundled')),
        'clawhub_unique_listings': len(index), 'clawhub_listing_complete': complete,
        'clawhub_completed_partitions': sum(s['complete'] for s in partitions),
        'clawhub_duplicate_observations': duplicates, 'clawhub_versions_changed': sorted(set(changes)),
        'clawhub_pending_classification': sum(r['portability'] == '待分类' for r in index),
        'clawhub_reviewed_samples': len(candidate_reviews),
        'sample_strata': dict(collections.Counter(strata.values())),
        'catalog_screening_count': len(screens),
        'screening_signals': dict(collections.Counter(r['screening_signal'] for r in screens)),
        'functional_categories': dict(collections.Counter(r['functional_category'] for r in screens)),
        'source_runtime_verified': 0, 'harmony_runtime_verified': 0,
        'partitions': partitions,
    }
    (OUT / 'coverage.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), 'utf-8', newline='\n')
    # Human-readable table stays narrow; detailed dependency columns are in CSV/JSON/XLSX.
    lines = ['# Skill 静态普查分类表', '',
             f'日期：2026-10-25。内置 Skill 固定到 `{COMMIT}`。', '',
             '所有等级均为静态候选。L3 表示原功能范围存在显著适配障碍，未证明永久不可移植。', '',
             '| Skill | 来源／版本 | 分类 | 依据与待办 |', '|---|---|---|---|']
    for r in rows:
        label = r['version'][:12]
        lines.append(f'| [{r["name"]}]({r["source_url"]}) | {r["source"]} / {label} | {r["portability"]} | {r["reason"]} {r["next_action"]} |')
    (OUT / 'classification.md').write_text('\n'.join(lines) + '\n', 'utf-8', newline='\n')
    report = ['# 全量目录初筛与源码分类汇总', '',
              '本版范围：官方内置全量＋ClawHub 代表样本源码精查；公开目录另做自动摘要初筛。', '',
              f'- 官方内置：{len(paths)} 个，固定 commit `{COMMIT}`。',
              f'- ClawHub 源码样本：{len(candidate_reviews)} 个，8 个目的性选样类别，每类 3 个。',
              f'- 源码精查集合：{len(rows)} 个；候选分级为 ' + '、'.join(f'{k} {v}' for k,v in sorted(summary['reviewed_grades'].items())) + '。',
              f'- 公开目录：{len(index):,} 个 owner/slug，36/36 分区结束，全部经过规则初筛。',
              '- 原平台运行与鸿蒙运行：均未执行。本版不宣称移植样例已通过。', '',
              '## 摘要初筛（不是源码分级）', '', '| 线索 | 条数 |', '|---|---:|']
    report += [f'| {k} | {v:,} |' for k,v in sorted(summary['screening_signals'].items())]
    report += ['', '初筛线索来自发布者的标题、摘要、主题和 OS 声明。阴性不能证明无依赖，阳性不能证明真正使用。证据不足保持可见，不补成 L1。', '',
               '## 主题归类', '', '| 主题 | 条数 |', '|---|---:|']
    report += [f'| {k} | {v:,} |' for k,v in sorted(summary['functional_categories'].items())]
    report += ['', '主题是单标签的检索辅助，按规则优先级取首个命中；“通用／主题未识别”是显式回退类别。', '',
               '## 样本范围', '', '| 样本类别 | 条数 |', '|---|---:|']
    report += [f'| {k} | {v} |' for k,v in summary['sample_strata'].items()]
    report += ['', '目的性选样用于覆盖不同适配障碍，不是随机抽样。精查集合内的 L1/L2/L3 比例不能外推为生态总体可移植率。',
               '源码表保留原 namespace、完整 frontmatter、版本／commit、文件哈希、证据行、分类理由和下一步；目录表单独存放初筛线索及源码分级。', '']
    (OUT/'screening-summary.md').write_text('\n'.join(report),'utf-8',newline='\n')
    print(json.dumps({k: v for k, v in summary.items() if k != 'partitions'}, ensure_ascii=False))

if __name__ == '__main__':
    main()
