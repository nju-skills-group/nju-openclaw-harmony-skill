# E1 OpenClaw Skill 基线测试记录

以下为本次 E1 基线测试的原始记录整理，重点确认纯提示词型 Skill 的发现、加载、显式调用和 JSON 输出行为。

## 1. 测试目标

环境组 E1：验证 OpenClaw 能否正确完成纯提示词型 Skill 的发现、加载、显式调用和指令执行，并通过运行记录确认目标 Skill 确实被读取和使用，而不是仅由基础模型独立完成任务。

## 2. 测试样本

### 2.1 主测样本

| 字段 | 内容 |
|---|---|
| Skill 名称 | adaptive-socratic-questioning |
| 显示名称 | Adaptive Socratic Questioning |
| 来源 | ClawHub |
| 发布者 | perpetualhui |
| 固定版本 | 1.1.0 |
| 来源标识 | @perpetualhui/adaptive-socratic-questioning |
| 安装路径 | <USER_HOME>/.openclaw/workspace/skills/adaptive-socratic-questioning |
| Skill 文件 | SKILL.md |
| 类型 | 纯提示词与静态 Markdown/JSON 资源 |
| 独立执行脚本 | 无 |
| 外部二进制依赖 | 无 |
| 环境变量依赖 | 无 |
| 操作系统限制 | 无 |

### 2.2 备选样本

| 字段 | 内容 |
|---|---|
| Skill 名称 | davinci-first-principles |
| 来源 | ClawHub |
| 发布者 | clawdiri-ai |
| 固定版本 | 1.0.0 |
| 来源标识 | @clawdiri-ai/davinci-first-principles |
| 当前状态 | 已完成固定版本安全验证，未安装、未执行 |
| 备选理由 | 无执行脚本、凭据和外部运行时，输出阶段固定，适合作为纯提示词类备选样本 |

## 3. 测试环境

| 字段 | 内容 |
|---|---|
| 宿主系统 | Windows |
| Linux 环境 | WSL2 |
| Linux 发行版 | Ubuntu 22.04.5 LTS |
| Linux 内核 | 6.6.87.2-microsoft-standard-WSL2 |
| Linux 用户 | <USER> |
| Node.js | v24.21.0 |
| OpenClaw | 2026.10.3（59cb447） |
| Gateway | 手动前台运行 |
| Gateway 地址 | 127.0.0.1:18789 |
| Agent | main |
| Workspace | <USER_HOME>/.openclaw/workspace |
| 模型 Provider | OpenRouter |
| 测试模型 | nvidia/nemotron-3.5-lightning:free |
| 模型认证 | OpenRouter API Key，保存在 OpenClaw Auth Profile 中 |
| 本次模型费用 | 0 美元 |

> 说明：WSL 环境没有可用服务管理器，因此 Gateway 使用 `openclaw gateway run` 前台运行。测试期间 Gateway 连通状态为正常。

## 4. 安全验证

安装前执行：

```bash
openclaw skills verify @perpetualhui/adaptive-socratic-questioning --version 1.1.0
```

验证结果：

| 项目 | 结果 |
|---|---|
| 总体决策 | pass |
| 安全状态 | clean |
| 判定 | benign |
| 置信度 | high |
| 隐藏代码 | 未发现 |
| 凭据访问 | 未发现 |
| 持久化或破坏行为 | 安全扫描未发现 |
| 可执行文件 | 无 |
| 签名 | unsigned |
| GitHub 导入来源证明 | unavailable |

静态扫描提示该 Skill 的触发描述范围偏宽，可能在普通教学或研究问题中自动介入。因此本测试采用显式 `$skill-name` 调用，不依赖自动触发。

## 5. 安装与加载检查

安装命令：

```bash
openclaw skills install @perpetualhui/adaptive-socratic-questioning --version 1.1.0 --agent main
```

安装结果：

```text
Installed adaptive-socratic-questioning@1.1.0
```

加载检查结果：

| 项目 | 结果 |
|---|---|
| source | openclaw-workspace |
| bundled | false |
| disabled | false |
| eligible | true |
| modelVisible | true |
| userInvocable | true |
| commandVisible | true |
| blockedByAllowlist | false |
| blockedByAgentFilter | false |
| platformIncompatible | false |
| 缺失二进制 | 无 |
| 缺失环境变量 | 无 |
| 缺失配置 | 无 |
| 缺失操作系统能力 | 无 |
| ClawHub 关联 | valid / linked |
| 已安装版本 | 1.1.0 |

安装后的 `SKILL.md` SHA-256 与安全验证记录中的哈希一致。

## 6. Skill 功能说明

该 Skill 要求：

1. 分析学生回答的准确性、深度、知识缺口和错误观念。
2. 根据回答选择解释、证据、因果、比较、反例或泛化问题。
3. 生成 3～7 个具有递进关系的问题。
4. 提供教师指导。
5. 输出包含以下四个顶层字段的 JSON：
   - `followup_questions`
   - `reasoning_path`
   - `misconception_flags`
   - `teacher_guidance`

当学生使用“所有”“一定”等绝对化表述时，预期生成反例类问题。

## 7. 测试输入

显式调用方式：

```text
$adaptive-socratic-questioning
```

完整测试内容：

```text
请严格使用此 Skill。
学生水平：本科；
学习目标：分析论证；
学生观点：“短视频一定能提高学习效率，因为内容更短，所以所有学生都学得更好。”
只输出该 Skill 规定的 JSON 对象，不要添加 JSON 之外的解释。
```

固定模型运行命令：

```bash
openclaw agent --agent main \
  --session-id e1-main-skill-clean \
  --model openrouter/nvidia/nemotron-3.5-lightning:free \
  --message '$adaptive-socratic-questioning 请严格使用此 Skill。学生水平：本科；学习目标：分析论证；学生观点：“短视频一定能提高学习效率，因为内容更短，所以所有学生都学得更好。”只输出该 Skill 规定的 JSON 对象，不要添加 JSON 之外的解释。' \
  --thinking off \
  --verbose on \
  --json
```

## 8. 预期行为

- OpenClaw 将目标 Skill 加入当前 Agent 的可见 Skill 列表。
- 运行时读取目标 `SKILL.md`。
- 生成 3～7 个递进问题。
- 至少包含证据、因果和反例类问题。
- 针对“所有学生都学得更好”的绝对化观点给出反例追问。
- 输出符合 Skill 规定的 JSON 结构。
- 不调用外部脚本或系统命令。
- 不产生未请求的持久化文件。

## 9. 实际输出

实际生成 5 个递进问题，问题类型包括：

1. explanation
2. evidence
3. counterexample
4. causality
5. generalization

输出同时包含：

- `reasoning_path`
- `misconception_flags`
- `teacher_guidance`

其中反例问题直接针对“短视频对所有学生都有效”的绝对化主张，符合 Skill 的问题选择算法。

运行结果：

| 项目 | 结果 |
|---|---|
| status | ok |
| summary | completed |
| Provider | openrouter |
| 请求模型 | nvidia/nemotron-3.5-lightning:free |
| 实际响应模型 | nvidia/nemotron-3.5-lightning:free |
| 是否重新路由 | false |
| fallback | 未使用 |
| 模型费用 | 0 美元 |
| 工具失败数 | 0 |
| 成功工具 | read、write |

## 10. Skill 使用确认

本次测试确认 Skill 被加载和使用，依据如下：

1. `openclaw skills info` 显示该 Skill 为 `eligible: true`、`modelVisible: true`、`userInvocable: true`。
2. `systemPromptReport.skills.entries` 中存在 `adaptive-socratic-questioning`。
3. 用户输入使用了显式引用 `$adaptive-socratic-questioning`。
4. `terminalReceipt.successfulToolNames` 包含 `read`，说明运行时实际读取了 Skill 文件。
5. 最终输出遵循 Skill 中的四字段结构和问题生成算法。
6. 输出包含 Skill 明确要求的反例追问、推理路径、错误观念标记和教师指导。

因此，“Skill 使用确认”记录为：**已确认**。

## 11. 发现的问题

### 11.1 未请求的持久化操作

虽然提示要求“只输出 JSON”，模型仍调用了 `write`，创建了：

```text
<USER_HOME>/.openclaw/workspace/memory/2026-10-30.md
<USER_HOME>/.openclaw/workspace/.skills-cache/adaptive-socratic-questioning-response.json
```

检查后确认：

- 没有修改 OpenClaw 配置或凭据文件。
- memory 文件保存了本次测试主题摘要。
- skills-cache 文件保存了结构化 Skill 输出。
- 该行为不是测试输入明确要求的，应记录为额外运行行为。

### 11.2 可见输出与缓存输出存在字段差异

终端可见输出中，第 5 个问题错误地使用：

```json
"purity": "..."
```

但缓存文件中对应字段正确为：

```json
"purpose": "..."
```

说明最终回复投影与持久化结果之间存在一处字段名不一致。

### 11.3 重放状态

运行记录包含：

```text
replayInvalid: true
```

虽然本次运行的最终状态为 `ok`、工具失败数为 0，且输出可见，但该标记仍应保留，后续可进一步调查 OpenClaw 的重放语义。

## 12. 实际依赖

静态元数据显示该 Skill 本身没有外部依赖，但完整运行链实际依赖：

- OpenClaw Gateway
- 可用的 Agent
- LLM Provider 和模型认证
- 支持读取 Skill 文件的 `read` 工具
- 工作区文件系统
- OpenRouter 网络连接

本次还观察到模型使用 `write` 工具创建内存和缓存文件。因此运行时实际能力范围大于 Skill 静态元数据中声明的依赖范围。

## 13. 测试状态

| 项目 | 结论 |
|---|---|
| Skill 安装 | 成功 |
| Skill 发现 | 成功 |
| Skill 可见性 | 成功 |
| Skill 文件读取 | 成功 |
| 核心功能 | 成功 |
| JSON 顶层结构 | 成功 |
| 问题数量与类型 | 成功 |
| 可见输出字段一致性 | 存在一处偏差 |
| 未请求的文件写入 | 存在 |
| 环境阻塞 | 无 |
| Skill 使用确认 | 已确认 |

综合状态：

> **功能成功，但存在已记录的输出字段偏差和未请求持久化行为。**

## 14. 测试范围

本次覆盖：

- 固定版本安全验证
- Skill 安装
- Inventory/Readiness/Visibility 检查
- 显式引用
- Skill 文件读取确认
- 正常输入案例
- JSON 输出检查
- 模型路由与费用检查
- 文件副作用检查

本次未覆盖：

- 多轮学生回答适配
- 异常输入
- 不同模型的一致性比较
- 鸿蒙端运行验证
- Skill 自动触发准确率
- 备选样本实际安装和运行

## 15. 证据文件

| 文件 | 内容 |
|---|---|
| `environment.txt` | 系统、OpenClaw、Gateway、Agent 和模型环境 |
| `skill-info.json` | 主测 Skill 的安装、版本、依赖和可见性 |
| `main-skill-run.json` | 主测 Skill 的完整运行记录 |
| `unexpected-memory.md` | 未请求创建的 memory 文件副本 |
| `skill-output.json` | Skill 缓存的结构化输出 |
| `security-verification.json` | 主测样本安全验证结果 |

证据目录：

```text
<USER_HOME>/.openclaw/workspace/evidence/e1
```

## 16. 结论

OpenClaw 2026.10.3 在 WSL2 Ubuntu 环境中能够成功发现、加载并执行 `adaptive-socratic-questioning@1.1.0`。运行记录证明目标 Skill 已进入 Agent Skill 目录、被运行时读取，并对最终问题类型、推理路径和 JSON 结构产生了可观察影响。

该 Skill 的核心功能在当前原平台环境中运行成功，但测试同时发现免费模型会执行未请求的文件持久化操作，并且终端可见输出与缓存结果存在一处字段差异。这些现象需要在后续迁移和鸿蒙端适配时作为行为边界与验证重点保留。


注：公开材料中的个人用户名与用户目录已替换为占位符，实验输入输出保持不变。