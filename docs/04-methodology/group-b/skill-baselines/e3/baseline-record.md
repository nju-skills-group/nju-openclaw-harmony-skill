# E3 OpenClaw Skill 基线测试记录：ontology v1.0.4

## 1. 结论摘要

- 测试日期：2026-10-30（Asia/Shanghai）
- 测试人：张庆涵（E3，本地脚本执行）
- 主测 Skill：`oswalpalash/ontology` v1.0.4
- 综合状态：**功能成功（OpenClaw 调用链复测通过）**
- 脚本级状态：**成功**
- 初始阻塞：本地 `ollama/qwen2.5:7b` 能完成普通回复，但未能可靠完成 Skill 指令加载与 `exec` 工具调用；多次 Agent 尝试出现虚构执行、把 Skill 当作可调用工具及挂起。
- 解决结果：改用本地 `ollama/qwen3.5:4b-q4_K_M`，并将 Agent 状态目录固定到 D 盘后，OpenClaw 实际读取 `SKILL.md`、调用 `scripts/ontology.py`、生成 JSONL，并能按固定 ID 查询到实体。
- 重要边界：首次失败记录仍保留；最终成功以实际文件和脚本查询结果为准，不以模型文字声明为准。

## 2. Skill 名称与来源

| 字段 | 内容 |
| --- | --- |
| 名称 | `ontology` |
| 来源 | ClawHub：`oswalpalash/ontology` |
| 固定版本 | `1.0.4` |
| Skill 页面 | <https://clawhub.ai/oswalpalash/skills/ontology> |
| 安装目录 | `D:\OpenClaw\workspace\skills\ontology` |
| 主脚本 | `scripts/ontology.py` |
| 脚本 SHA-256 | `25e10809ab4f809f2fd3b475989a882e6fcdd9127655ec40fccf44d10f0c0491` |
| SKILL.md SHA-256 | `669830c58a0caa4b977229a79e3723c09e5c2fdd74da84007f125891aa0c7488` |

已安装文件的 SHA-256 与普查目录 `source-manifest.json` 中的 v1.0.4 固定快照一致。

## 3. 安全审查

ClawHub 验证结果为 `decision=fail`、`security.status=suspicious`、`signature.status=unsigned`。扫描摘要指出该 Skill 的持久化写入行为比文档声明更宽，且保护不足。

执行前逐文件检查了 `SKILL.md` 与 `scripts/ontology.py`：

- 无网络请求、外部进程启动或凭据读取；
- `resolve_safe_path` 将 graph/schema/file 参数限制在当前工作区内；
- 默认写入 `memory/ontology/graph.jsonl` 与 `memory/ontology/schema.yaml`；
- `delete` 是向 JSONL 追加逻辑删除记录，不直接删除文件；
- 测试仅使用虚构数据和隔离工作区。

初次安装因 D 盘解压权限失败：`failed to extract archive: FsSafeError: permission denied (EPERM)`。改用外部权限执行相同的官方固定版本安装命令后成功。

## 4. 测试环境

| 字段 | 内容 |
| --- | --- |
| 操作系统 | Windows `10.0.26200` |
| OpenClaw | `2026.10.4 (383c124)` |
| Node.js | `v26.12.0` |
| Python | `3.10.2` |
| PyYAML | `6.0.3` |
| 模型提供方 | 本地 Ollama |
| 初始模型 | `qwen2.5:7b`（4.7 GB，调用链失败） |
| 复测模型 | `qwen3.5:4b-q4_K_M`（3.3 GB，调用链成功） |
| 复测模型目录 | `D:\OpenClaw\ollama-tool-models` |
| 复测 Ollama 地址 | `http://127.0.0.1:11435` |
| OpenClaw 工作区 | `D:\OpenClaw\workspace` |
| OpenClaw 状态目录 | `D:\OpenClaw\state` |
| Gateway | loopback `127.0.0.1:18789`；本次使用 embedded `--local` Agent |
| 网络/费用 | 模型本地运行，报告的调用费用为 0 |

旧模型的 Ollama live completion 验证成功，首次响应耗时 84.9 秒，但工具路由失败。新模型先通过原生工具调用自检：准确返回一次 `write_note` 调用及指定参数；随后通过 OpenClaw 基础回复测试。`ontology` 的 OpenClaw 状态为 `eligible=true`、`modelVisible=true`、`userInvocable=true`，无缺失 bin/env/config。

## 5. 功能范围和预期行为

主测范围：创建 Project、创建 Task、建立 `has_task` 关系、查询关联，并检查 JSONL 输出。

固定测试数据：

- Project：`id=proj_e3`，`name=Harmony Skill Port`，`status=active`
- Task：`id=task_e3`，`title=Baseline ontology test`，`status=open`
- Relation：`proj_e3 --has_task--> task_e3`

预期结果：OpenClaw Agent 加载 ontology Skill，实际调用 `scripts/ontology.py`，生成 `memory/ontology/graph.jsonl`，并能查询到 `task_e3`。

## 6. OpenClaw 调用记录

### 尝试 1：普通自然语言触发

- session：`e3-ontology-normal-001`
- duration：98,295 ms
- 模型：`ollama/qwen2.5:7b`
- Agent 识别到了 ontology Skill，但最终文字声称已执行命令。
- 模型给出的命令遗漏固定 `--id`，还使用了脚本不支持的 `query --rel`。
- OpenClaw 元数据：`toolSummary.calls=7`、`failures=3`、`unresolvedError=openclaw`、`replayInvalid=true`。
- 文件核验：`graph.jsonl` 不存在。
- 判定：**功能失败，模型虚构执行结果**。

### 尝试 2：slash 命令触发

- session：`e3-ontology-normal-002`
- 输入以 `/ontology` 开头。
- CLI 在进入模型前报错：`OpenClaw agent has no command "Skill"`。
- 文件核验：无输出文件。
- 判定：**CLI 命令分发失败**。

### 尝试 3：绝对路径与强制核验

- session：`e3-ontology-normal-003`
- 提示明确要求读取 Skill、调用 `exec`、使用脚本绝对路径、正确 `--id` 和 `related` 子命令，并读取最终文件。
- 模型错误地把 `clawhub` Skill 当作可调用工具。
- OpenClaw 报错：`This id names a skill, not a callable tool.`
- 随后 Agent 长时间无输出，超过 300 秒后人工中止。
- 文件核验：`graph.jsonl` 不存在。
- 判定：**工具选择/Skill 加载错误并挂起**。

### 尝试 4：最小提示复测（旧模型）

- session：`e3-ontology-minimal-004`
- 模型仍将 `ontology` 当作 callable tool，多次收到：`This id names a skill, not a callable tool.`
- duration：83,274 ms；`toolSummary.calls=9`、`failures=7`、`replayInvalid=true`。
- 文件核验：`openclaw-test.jsonl` 不存在。
- 判定：**旧模型不适合本任务的 Skill/工具路由**。

### 尝试 5：更换工具模型并完成调用链

- 模型：`ollama/qwen3.5:4b-q4_K_M`；模型文件全部位于 D 盘。
- OpenClaw 基础测试返回精确文本 `E3_OPENCLAW_OK`，`ok=true`、退出码 0。
- 最终 Agent 实际使用 `read` 和 `exec`，`toolSummary.calls=23`、`failures=0`，退出码 0。
- 输出文件：`D:\OpenClaw\workspace\memory\ontology\openclaw-qwen35.jsonl`，647 bytes，两条追加记录。
- 固定 ID 查询：`ontology.py get --id note_openclaw_e3 --graph ...` 返回目标 Note，退出码 0。
- 判定：**OpenClaw 调用链成功**。

复测中还发现两个非阻塞问题：Windows PTY 不可用时 OpenClaw 自动回退到非 PTY 执行；模型第一次把 `id` 放进 `--props`，产生随机 ID 记录，随后用正确 `--id` 再次创建目标实体。依据 Skill 的 append-only 规则，两条记录均保留为真实证据。

## 7. 脚本级对照测试

为了区分脚本故障与 OpenClaw 调度故障，使用同一份已核验脚本执行对照。

### 正常案例

按顺序执行创建 Project、创建 Task、建立 `has_task` 关系及 `related` 查询。四步均成功，查询返回 `task_e3`。输出文件为 `D:\OpenClaw\workspace\memory\ontology\graph.jsonl`，包含两条 `create` 和一条 `relate` 记录。证据见 `evidence/graph.jsonl` 与 `evidence/test-log.md`。

### 异常案例：越界路径

尝试将 graph 写入 `D:\OpenClaw\outside.jsonl`，实际结果：

```text
Invalid graph path: must stay within workspace root 'D:\OpenClaw\workspace'
```

退出码为 1，目标文件不存在。异常处理符合预期。

## 8. 实际依赖

- Python 3.10.2；
- Python 标准库：`argparse`、`json`、`uuid`、`datetime`、`pathlib`；
- PyYAML 6.0.3（schema 读写和 validate 路径需要）；
- 工作区文件读写权限；
- OpenClaw 模型必须能稳定遵循 Skill 加载规则并调用 `exec` 工具。

测试还观察到 `semantic vector embeddings unavailable`，该问题仅影响记忆向量检索，不是 ontology 脚本失败原因。

## 9. 最终状态与后续问题

| 项目 | 状态 |
| --- | --- |
| Skill 被 OpenClaw 加载 | 成功 |
| Skill 指令被模型读取 | 成功（复测） |
| OpenClaw 实际调用脚本 | 成功（复测） |
| 脚本独立运行 | 成功 |
| 本地文件输出 | OpenClaw 与脚本级均成功 |
| 越界路径保护 | 成功 |
| OpenClaw 调用链验证 | 通过 |

后续建议：

1. 继续保留 `qwen2.5:7b` 失败记录，作为模型能力差异证据；
2. slash 命令 `/ontology` 的分发仍未修复，后续可独立提交 OpenClaw 兼容性问题；
3. 正式复现时固定使用 D 盘状态目录，避免临时 SQLite 清理出现 `EBUSY`；
4. `original_runtime_status` 可标为“成功（更换本地模型后复测通过）”，并注明首次模型失败与一次多余追加记录。

