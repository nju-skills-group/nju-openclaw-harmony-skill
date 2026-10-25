"""Purposeful coverage sampling, not a random estimate of ecosystem prevalence."""
import json
import gzip
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STRATA = {
    '描述与推理': [('perpetualhui','adaptive-socratic-questioning'), ('aircraft06','academic-paper-writing-style'), ('clawdiri-ai','davinci-first-principles')],
    'HTTP 与云服务': [('steipete','notion'), ('byungkyu','api-gateway'), ('jacky1n7','openclaw-tavily-search')],
    '文件与结构化数据': [('oswalpalash','ontology'), ('ivangdavila','word-docx'), ('ivangdavila','excel-xlsx')],
    '桌面应用与平台': [('steipete','peekaboo'), ('steipete','apple-notes'), ('steipete','things-mac')],
    '音视频与模型运行时': [('steipete','openai-whisper'), ('steipete','nano-banana-pro'), ('steipete','nano-pdf')],
    '宿主调度与代理': [('seanford','coding-agent'), ('maximeprades','auto-updater'), ('halthelobster','proactive-agent')],
    'MCP 与工具协议': [('steipete','mcporter'), ('paudyyin','mcp-builder'), ('liuboacean','agent-comm-hub')],
    '设备与局域网': [('iahmadzain','home-assistant'), ('steipete','sonoscli'), ('steipete','openhue')],
}

def main():
    catalog = {}
    pages = sorted((ROOT/'data/clawhub-prefixes').glob('*/[0-9]*.json'))
    if pages:
        groups = (json.loads(page.read_text('utf-8'))['items'] for page in pages)
    else:
        with gzip.open(ROOT/'data/catalog-input.jsonl.gz','rt',encoding='utf-8') as stream:
            groups = [[json.loads(line) for line in stream]]
    for group in groups:
        for item in group:
            catalog[(item.get('ownerHandle'),item['slug'])] = item
    selected = []
    for stratum, keys in STRATA.items():
        for key in keys:
            item = catalog[key]
            selected.append({'owner':key[0], 'slug':key[1], 'version':item['tags']['latest'],
                             'stratum':stratum, 'selection_reason':'覆盖此依赖形态的可识别实例；非随机抽样，不用于总体比例估计',
                             'downloads_observed': item['stats'].get('downloads')})
    (ROOT/'data/sampling-plan.json').write_text(json.dumps(selected, ensure_ascii=False, indent=2),'utf-8')
    print(f'{len(selected)} samples in {len(STRATA)} strata')

if __name__ == '__main__':
    main()
