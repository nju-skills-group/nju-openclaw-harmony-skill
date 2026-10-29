"""Deterministic abstract-only screening. Never substitutes for source review."""
import re

VERSION = 'abstract-screen-v1'
RULES = [
    ('平台专用', 'L3线索', r'\b(?:macos|darwin|windows-only|linux-only)\b|macOS-only|仅限苹果|仅限桌面'),
    ('宿主或工具协议', 'L3线索', r'\b(?:MCP|stdio|PTY|tmux|ACP|gateway|cron|OpenClaw|Clawdbot)\b|后台进程|任务编排|工具调用协议'),
    ('运行时或外部工具', 'L3线索', r'\b(?:python|node\.js|nodejs|bash|CLI|ffmpeg|whisper|ONNX|browser automation|headless browser)\b|命令行|浏览器自动化|本地推理'),
    ('网络与通用处理', 'L2线索', r'\b(?:HTTP|REST|API|webhook|endpoint|JSON|CSV|script)\b|脚本|数据清洗|接口调用'),
    ('明确描述型声明', 'L1线索', r'\b(?:prompt-only|text-only|markdown-only|no code execution|no tools required|reference-only)\b|纯描述|纯提示词|纯文本|无需工具|无代码执行'),
]

CATEGORIES = [
    ('设备与物联网', r'\b(?:smart home|home assistant|sonos|hue|bluOS|IoT|camera|eight sleep)\b|智能家居|设备控制|摄像头'),
    ('系统与安全', r'\b(?:security|audit|firewall|credential|vulnerability|permission|backup|ssh)\b|安全|漏洞|权限|备份|运维'),
    ('媒体与内容生成', r'\b(?:image|video|audio|speech|transcri\w*|TTS|music|meme|GIF|podcast)\b|图像|视频|音频|语音|音乐'),
    ('开发与工具协议', r'\b(?:coding|code|debug\w*|git\w*|MCP|SDK|API|CLI|server|deploy\w*|programming)\b|代码|开发|调试|接口|编程|部署'),
    ('科研与教学', r'\b(?:research|academic|paper|student|teach\w*|learn\w*|socratic|study|education)\b|科研|学术|论文|教学|学习|学生'),
    ('数据与分析', r'\b(?:data|analysis|analytics|database|SQL|CSV|spreadsheet|XLSX|statistics|knowledge graph)\b|数据|分析|统计|知识图谱|表格'),
    ('办公与协作', r'\b(?:notion|office|document|DOCX|Word|mail|email|gmail|calendar|Slack|Teams|Trello|notes|reminder)\b|邮件|办公|文档|笔记|协作|日历'),
    ('检索与信息获取', r'\b(?:search|browse|web|weather|news|fetch|RSS|lookup)\b|搜索|检索|天气|新闻|资讯'),
    ('写作与推理', r'\b(?:writing|write|edit\w*|reason\w*|thinking|brainstorm\w*|copywriting|summari\w*)\b|写作|润色|推理|思考|摘要'),
    ('商业与个人事务', r'\b(?:marketing|sales|finance|stock|crypto|travel|shopping|business|customer|resume|career|fitness|health)\b|营销|销售|金融|股票|旅行|购物|简历|求职|健身'),
    ('代理与工作流', r'\b(?:agent|automation|workflow|memory|task|proactive)\b|智能体|工作流|自动化|记忆|任务'),
]

def screen(item):
    text = '\n'.join([item.get('displayName') or '', item.get('summary') or '',
                      ' '.join(item.get('topics') or [])])
    category = next((label for label, regex in CATEGORIES if re.search(regex,text,re.I)), '通用／主题未识别')
    clues = []
    metadata = item.get('metadata') or {}
    oses = metadata.get('os') or []
    if oses:
        clues.append({'kind':'平台声明', 'signal':'L3线索', 'field':'metadata.os',
                      'match':', '.join(oses) if isinstance(oses,list) else str(oses)})
    for kind, signal, regex in RULES:
        match = re.search(regex,text,re.I)
        if match:
            clues.append({'kind':kind, 'signal':signal, 'field':'displayName/summary/topics', 'match':match.group(0)})
    signal = next((s for s in ['L3线索','L2线索','L1线索'] if any(c['signal']==s for c in clues)), '摘要证据不足')
    return {'functional_category':category, 'screening_signal':signal,
            'screening_clues':clues, 'screening_rule_version':VERSION,
            'screening_status':'自动摘要初筛；非源码分级；非运行结论'}
