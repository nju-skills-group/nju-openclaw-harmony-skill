# E3 ontology 测试日志

## 来源与版本核验

- 普查记录：`docs/04-methodology/group-b/skill-survey/reviewed-skills.csv`
- 固定来源：ClawHub `oswalpalash/ontology` v1.0.4
- `SKILL.md` SHA-256：`669830c58a0caa4b977229a79e3723c09e5c2fdd74da84007f125891aa0c7488`
- `scripts/ontology.py` SHA-256：`25e10809ab4f809f2fd3b475989a882e6fcdd9127655ec40fccf44d10f0c0491`
- 核验结果：与 `source-manifest.json` 一致。

## 安装日志

第一次：

```text
failed to extract archive: FsSafeError: permission denied (EPERM)
```

使用外部权限重试：

```text
Downloading ontology@1.0.4 from ClawHub…
Installing to D:\OpenClaw\workspace\skills\ontology…
Installed ontology@1.0.4 -> D:\OpenClaw\workspace\skills\ontology
```

## 加载状态

```text
source=openclaw-workspace
filePath=D:\OpenClaw\workspace\skills\ontology\SKILL.md
eligible=true
modelVisible=true
userInvocable=true
missing.bins=[]
missing.env=[]
missing.config=[]
```

## 模型初始化

```text
Provider: Ollama local
Model: qwen2.5:7b
Live completion: success
First response: 84.9s
Cost: 0
```

## OpenClaw 调用尝试

### normal-001

```text
durationMs=98295
toolSummary.calls=7
toolSummary.failures=3
toolSummary.unresolvedError=openclaw
replayInvalid=true
graph_exists=false
```

模型文字声称成功，但给出的命令遗漏 `--id` 并使用不存在的 `query --rel`，因此以文件证据为准判定失败。

### normal-002

```text
OpenClaw agent has no command "Skill".
graph_exists=false
```

### normal-003

```text
tool_call failed: This id names a skill, not a callable tool.
raw_params={"id":"clawhub","args":{"query":"ontology Skill"}}
```

之后持续无输出，超过 300 秒人工中止。`graph_exists=false`。

## 脚本级正常案例

```text
CREATE Project proj_e3: success
CREATE Task task_e3: success
RELATE proj_e3 --has_task--> task_e3: success
RELATED proj_e3 has_task: returned task_e3
```

实际查询结果：

```json
[
  {
    "relation": "has_task",
    "entity": {
      "id": "task_e3",
      "type": "Task",
      "properties": {
        "title": "Baseline ontology test",
        "status": "open"
      }
    }
  }
]
```

## 脚本级异常案例

```text
Invalid graph path: must stay within workspace root 'D:\OpenClaw\workspace'
negative_exit=1
outside_exists=False
```

## 判定

```text
OpenClaw Skill 加载：成功
OpenClaw 真实脚本调用：首次失败，换模型后成功
脚本独立运行：成功
异常路径保护：成功
综合状态：功能成功（qwen3.5:4b-q4_K_M 复测通过）
```

## 后续流程综合日志

### 1. 确认旧链路失败

```text
目标：D:\OpenClaw\workspace\memory\ontology\openclaw-test.jsonl
核验：TARGET_EXISTS=False
结论：minimal-004 没有真实产物，旧失败判定成立。
```

### 2. 查找并选择新模型

- 来源：Ollama 官方模型库 `qwen3.5:4b-q4_K_M`。
- 原因：官方标记 `tools`，约 3.3 GB，适配本机 8 GB RTX 4060。
- 下载目录：`D:\OpenClaw\ollama-tool-models`。
- 独立服务：`127.0.0.1:11435`。

```text
pull result=success
sha256 verification=success
model size=3.3 GB
processor=100% GPU
```

### 3. 模型原生工具自检

定义临时函数 `write_note(id,text)`，要求模型只调用一次。

```json
{"name":"write_note","arguments":{"id":"e3_native","text":"native tool test"}}
```

结果：函数名和两个参数均准确，证明新模型本身能生成结构化工具调用。

### 4. OpenClaw 配置切换

```text
配置备份=D:\OpenClaw\state\openclaw.json.e3-backup-20261030-223349
ollama.baseUrl=http://127.0.0.1:11435
defaultModel=ollama/qwen3.5:4b-q4_K_M
config validate=valid
modelRouteIssues=[]
```

模型目录初次仍显示旧缓存，但默认路由已解析到新模型，后续实际调用确认生效。

### 5. 解决 Agent 临时库清理问题

首次 `agent exec` 的模型请求已结束，但清理 C 盘临时 SQLite 时失败：

```text
EBUSY: resource busy or locked, unlink ...openclaw-agent.sqlite
```

解决：显式添加 `--state-dir D:\OpenClaw\state --cwd D:\OpenClaw\workspace`。复测结果：

```text
ok=true
final=E3_OPENCLAW_OK
model=qwen3.5:4b-q4_K_M
provider=ollama
exit=0
```

### 6. OpenClaw 完整 ontology 调用

脚本来源：`D:\OpenClaw\workspace\skills\ontology\scripts\ontology.py`，由同目录 `SKILL.md` 的 Create Entity 流程指定。

执行中 Windows PTY 不可用，OpenClaw 自动回退为非 PTY。模型第一次遗漏 `--id`，产生随机 ID；随后按正确参数创建固定 ID。最终结果：

```text
ok=true
stopReason=stop
tools=read,exec
toolSummary.calls=23
toolSummary.failures=0
output=D:\OpenClaw\workspace\memory\ontology\openclaw-qwen35.jsonl
bytes=647
lines=2
```

### 7. 文件与查询验收

```text
TARGET_EXISTS=True
ontology.py get --id note_openclaw_e3 --graph ...
QUERY_EXIT=0
content=OpenClaw E3 chain success
tags=[e3,openclaw]
normalized_sha256=B0E00C4408B3D72BDA682F0F84F6441BC2B2A1C1076B087C352DA9CAF7EEA564
JSON_RECORDS_MATCH=True
```

仓库证据副本使用 LF，D 盘原始文件使用 CRLF，原始字节数相差 2；换行归一化后的 SHA-256 相同，两条 JSON 记录逐条解析比较也完全一致。

最终判定：后续步骤本身不会自动修复调用链；本次成功来自更换工具模型、固定 D 盘状态目录、使用正确的 Skill→脚本执行路径，并以落盘文件和查询结果验收。
