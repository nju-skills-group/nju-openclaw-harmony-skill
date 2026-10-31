# SkillVM 覆盖率评估报告 v1.0

> 最终成果 C-2；状态：**方法、工具链验证（批次 01）、样本溯源与原平台环境核验（批次 02）已有交付；目标运行、原平台用例基线与覆盖率数字仍无结论**。参考工作包 C-2A（样本/评价方法）、C-2B（工具链实测/结果）可先分工推进，但必须共同将方法、结果与限制整合到**同一份报告**，再申请整体验收。中间 PR 合并不代表 C-2 完成。
>
> 附件：[C-2A 方法协议](c-2a-method-v1.md) · [27 个基础用例](c-2a-cases-v1.md) · [记录模板](c-2a-record-template.md) · [样本清单](c-2a-samples-v1.json) · [C-2B 预注册参数](c-2b-preregistration-v1.md) · [C-2B 工具链验证批次 01](c-2b-toolchain-batch01.md) · [C-2B 批次 02：样本溯源与原平台环境核验](c-2b-batch02-baseline-and-provenance.md)

## 1. 目标与范围

用乙组的 L1/L2/L3 代表性 Skill 逐级评价 SkillVM 路线的承载能力。定位是**评估与原型验证**，不从零开发完整 VM；抽样不能外推为全生态可移植率。

## 2. 样本及版本

来源：乙组 [普查 PR #13](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/pull/13)，提交 `126d80d5507293af800e7fafe538a772b16e4f21`。以下是乙组 handoff 中的**候选**，并非丙组已经验证的结果。具体纳入/替换样本需在 PR 中说明。

| 分类 | 样本 | 原始来源/版本确认 | 静态障碍 | 工具链实验 | 原平台调用 | 鸿蒙调用 |
| --- | --- | --- | --- | --- | --- | --- |
| L1 | adaptive-socratic-questioning | ClawHub `perpetualhui@1.1.0`；原包 12 文件全部取得并校验 | 待填（evals/tests/examples 已可用） | 未测（批次 01 未纳入 L1） | 未测（加载状态未核验） | 未测 |
| L1 | academic-paper-writing-style | ClawHub `aircraft06@1.0.0`；原包 4 文件全部取得并校验 | 待填 | 未测（同上） | 未测 | 未测 |
| L1 | davinci-first-principles | ClawHub `clawdiri-ai@1.0.0`；原包 2 文件全部取得并校验 | 待填 | 未测（同上） | 未测 | 未测 |
| L2 | weather | 固定提交 `d79ab619…`；完整包 1 文件核对通过 | 待填 | 通过（SkCC 四目标均产出；SkVM 阻断） | 未测（已加载、可见；无模型凭证） | 未测 |
| L2 | trello | 固定提交；完整包 1 文件核对通过 | 待填 | 部分通过（SkCC validate 通过，未编译） | 未测（缺 `jq` 与账号令牌） | 未测 |
| L2 | meme-maker | 固定提交；完整包 3 文件核对通过 | 待填 | 部分通过（SkCC validate 通过，未编译） | 未测（已加载、可见） | 未测 |
| L3 | tmux | 固定提交；完整包 3 文件核对通过 | PTY / shell | 通过（SkCC validate + claude 目标编译；SkVM 阻断） | 未测（已加载、可见） | 未测 |
| L3 | mcporter | 固定提交；完整包 1 文件核对通过 | MCP 协议 / 进程 | 部分通过（SkCC validate 通过，未编译） | 未测（缺 `mcporter` CLI） | 未测 |
| L3 | peekaboo | 固定提交；完整包 1 文件核对通过 | 平台 UI / 权限 | 部分通过（SkCC validate 通过，未编译） | 未测（平台判定 `os: darwin` 不兼容） | 未测 |

九个样本的**原包均已取得并逐文件校验**（S01–S03 走 ClawHub release inventory 的 `sha256`；S04–S09 由 git tree 的 blob `sha1`、乙组 `source-manifest.json` 的 `sha256`、OpenClaw 运行时包三方交叉一致），因此样本清单中"仅核对 SKILL.md"的限制已解除。取得方式、逐文件哈希与失败中止规则见 [C-2B 批次 02](c-2b-batch02-baseline-and-provenance.md) 第 2、3 节。原平台一列右括号内的说明来自同一批次的 OpenClaw 2026.10.9 加载核验（第 4 节）：它证明"平台能否加载"，不证明"用例能跑通"。上表"工具链实验"一列的判定依据见 [C-2B 批次 01](c-2b-toolchain-batch01.md)，状态定义见 [C-2B 预注册第 6 节](c-2b-preregistration-v1.md)。

## 3. 评价方法（待执行）

- **机制可表达性**：来源文本/依赖是否可用 IR 或编译/适配步骤描述？依据是什么？
- **工具链验证**：是否真实使用 SkVM 等工具处理输入；保留版本、命令、目标 harness、输出和失败原因。
- **原平台基线**：由乙组提供 OpenClaw 同输入运行记录；静态分析不能替代。
- **目标运行**：由甲组确认目标契约，按实际鸿蒙调用验证；不能以生成 ArkTS 文本替代运行成功。
- **覆盖率口径**：每次统计说明样本集合、分母、成功层级和不满足的门槛；允许“未知/未测”，不把 L3 视为永久不可移植。
- **性能数据**：注明甲组数据来源、设备/系统、计时边界、重复次数、统计量；无数据时保持“未测”。

## 4. 工具链最小验证记录

执行日期 2026-10-31，执行位置 WSL2 Ubuntu 20.04（SkVM 无 win32 构建）。完整记录、命令原文与日志哈希见 [C-2B 工具链验证批次 01](c-2b-toolchain-batch01.md)，可复现脚本见 [`code/skill-vm/`](../../../../code/skill-vm/README.md)。

| 项目 | 当前值 |
| --- | --- |
| 工具/提交版本 | SkVM `@ipads-skvm/skvm@0.1.5`（源码 `632cefe`）；SkCC `nexa-skill 0.1.0`（源码 `59faa3a`）；SkillSmith `AetherHeart-AI/Aeloon@e5afaa1` |
| 运行环境与模型配置（不得包含密钥） | WSL2 Ubuntu 20.04；Node v20.19.1；rustc 1.99.1；未配置任何 LLM provider（无密钥） |
| 测试 Skill 与固定来源 | S04–S09，OpenClaw `d79ab619…`，六个 SKILL.md 哈希与样本清单一致 |
| 命令和输入 | SkVM：`aot-compile --pass=1/--pass=bind-env --dry-run`；SkCC：`validate`、`build --claude/--codex/--gemini/--kimi/--all` |
| 真实输出或错误 | SkVM `Missing profiles … Run 'skvm profile' first.`（退出码 1）；SkCC 四目标 `Build completed successfully` 并产出可哈希产物；SkillSmith 未运行（需 Python 3.11+ 与密钥） |
| 可复现附件/脚本 | [`code/skill-vm/`](../../../../code/skill-vm/README.md) 四个脚本；原始日志三份（哈希见批次记录第 7 节） |
| 对鸿蒙移植的意义与局限 | 三工具的目标集合均无鸿蒙（SkVM 适配器 6 个全为 agent/CLI；SkCC emitter 4 个；SkillSmith 产物为 Python 模块）。可编译 ≠ 可在鸿蒙运行；适配层不能替代鸿蒙绑定层 |

| 工具 | 本批状态 | 依据（可核对） |
| --- | --- | --- |
| SkVM | 阻断 | `Invalid adapter: harmonyos. Valid: bare-agent, openclaw, opencode, hermes, jiuwenclaw, pi`；所有 pass 在缺 TCP profile 时中止 |
| SkCC | 通过（限四个非鸿蒙目标） | 6/6 validate 通过；四目标产物哈希已记录；manifest `source_hash` 与源文件哈希一致 |
| SkillSmith | 阻断 | 编译器为 agent 插件 `/skill_compiler`，需 `provider: LLMProvider`；仓库要求 Python 3.11+，环境为 3.8.10 |

本批发现的两处工具侧质量问题已记入批次记录第 4.4 节：SkCC 产物丢失行内代码标识（S04 反引号 78 → 36，`web_fetch` 7 → 6，出现 `Use  first`、`summarize , , and the` 等空洞；S07 亦复现，丢失两条 `scripts/` 辅助脚本说明），以及源 frontmatter 的 `metadata.openclaw.install` 依赖声明未进入产物、仅退化为关键词权限告警。因此"工具链通过"只表示工具完成了声明的转换，不表示产物可用于移植交付。

## 5. 覆盖结果与限制

固定分母 N=9（各等级 N_L=3）。**本节不提供单一"覆盖率数字"**：目标运行尚未开展，任何百分比都会被误读为可移植率。

| 指标 | 当前值 | 说明 |
| --- | --- | --- |
| 工具链处理覆盖（SkCC） | 通过 2/9，部分通过 4/9，未测 3/9 | 通过 = S04（四目标）、S07（claude 目标）；部分通过 = S05/S06/S08/S09（仅 validate）；未测 = S01–S03（原包已取得，但批次 01 未处理 L1）。范围限于非鸿蒙目标 |
| 工具链处理覆盖（SkVM） | 阻断 6/9，未测 3/9 | S04–S09 均在缺 TCP profile 处中止；不产出适配物 |
| 完整本机覆盖 | 未测（0 个样本具备证据，不等于 0 个可移植） | 缺原平台对照、鸿蒙入口与权限映射 |
| HarmonyOS 真正可执行数量 | 未测 | 无设备与 ArkTS 入口；构建成功/文本生成均不计 |
| 原平台环境就绪 | 已就绪（OpenClaw 2026.10.9，六样本加载状态已核验） | 环境不再缺；见 [批次 02](c-2b-batch02-baseline-and-provenance.md) 第 4 节 |
| 原平台对照与行为一致性 | 未测 | 阻塞点已缩小为"无模型凭证"，不再是"无环境" |
| 甲组性能数据 | 待交接 | 未收到 |
| 执行进度 | 0/9 有运行记录 | 27 个基础用例全部未执行，超时与重试参数见 [预注册](c-2b-preregistration-v1.md) |

已发现的障碍与失败原因（按主因分类，允许一项多标签）：

- **目标能力/协议**：三条工具链路的目标都是 agent 宿主（SkVM 的 6 个 adapter、SkCC 的 4 个 emitter、SkillSmith 的 Python 模块），没有系统级 Skill 注册形态。这是移植工作必须在工具链之外另做绑定层的直接原因。
- **工具链**：SkVM 无 win32 构建，且编译各 pass 均依赖 LLM provider；SkCC 的 npm 包不含二进制，必须自建 Rust 工具链；三者文档与实现存在漂移（SkCC README 的 `--target` 参数不存在；SkVM 的 CLI 只接受 6 个 adapter，源码 registry 却注册了 8 个；OpenClaw `2026.10.9` 的 `engines.node` 为 `>=24.22.1`，与甲组手册"Node ≥ 22"不一致）。
- **源样本**：九个样本原包均可取得并已校验，不再是障碍。此前"S01–S03 不可得"的记录是我方用错 API 端点（`/api/skills/…` → 404）所致，已更正；正确的 `/api/v1/skills/…` 端点取自乙组脚本。
- **原平台**：环境已建成，`openclaw skills check` 显示 55 个技能中 20 个可用；但默认模型无凭证（`Missing auth: openai`），且本地模型路线因 github 不可达（`ollama` 运行时无法下载）未建立。因此原平台用例基线仍为未测。
- **目标环境**：无鸿蒙设备、无 ArkTS 入口，且契约 E7（非预置应用能否上架开放 Skill）未决——目标运行的阻塞不止"缺设备"。

对 C-1 与 C-3 的可追溯输入：三工具"目标宿主"清单与接口形态（SkVM `AgentAdapter` 四成员、SkCC `TargetPlatform` 枚举与 emitter 注册 API、SkillSmith 的 `artifact_boundary`/`run_boundary_artifact`）应作为对比表与 IR 目标绑定章节的实证依据，而不是按论文声称推断。

## 6. 跨组依赖

- 乙组：普查、L3 问题清单；后续逐个交付已移植 Skill 与原平台基线。S01–S03 原包已由丙组按 ClawHub v1 API 自行取得并逐文件校验，不再需要乙组提供；仍需乙组确认 `source-manifest.json` 的 `sha256` 记录（丙组已用它完成交叉校验）并在移植记录中沿用同一哈希口径。
- 甲组：鸿蒙调用入口、运行环境和性能结果。目标运行另需明确回答契约 E7（非预置应用能否上架开放 Skill），否则即使有设备也只能得到"App 内部入口"证据。
- 组内：原平台基线与 SkVM/SkillSmith 的解除都收敛到同一个决策——是否配置可用的模型 provider 与限额。
- 丙组：将有依据的技术结论反馈乙组，更新障碍分类和本报告。

## 7. 本轮新增材料与下一步

| 材料 | 状态 | 说明 |
| --- | --- | --- |
| [C-2A 方法协议](c-2a-method-v1.md) 等四份 | 已提交 | 评价口径、27 用例、记录模板、样本清单 |
| [C-2B 预注册参数](c-2b-preregistration-v1.md) | 待 C-2A 确认 | 27 例 T_timeout、重试上限、计时容差、工具链判定判据 |
| [C-2B 工具链验证批次 01](c-2b-toolchain-batch01.md) | 已完成本批 | SkVM 阻断 / SkCC 四目标通过 / SkillSmith 阻断 |
| [C-2B 批次 02](c-2b-batch02-baseline-and-provenance.md) | 已完成本批 | S01–S09 原包与逐文件清单、OpenClaw 2026.10.9 环境与加载状态 |
| [`code/skill-vm/`](../../../../code/skill-vm/README.md) | 已提交 | 三份工具链脚本 + 一份产物质量核对脚本；本批新增样本取得、包校验、原平台核验三份脚本 |

下一步（按依赖顺序）：

1. C-2A 确认预注册参数，否则超时类断言无判定效力；同时确认是否把样本清单的 `full_package_reverification` 改为完成（依据见批次 02 第 5 节）；
2. 组内决定是否配置 LLM provider：这一项同时解除"原平台用例基线"与"SkVM/SkillSmith 实测"；若决定不配，须在报告中把三者统一写成"未测/阻断"并说明原因；
3. 用批次 01 的 SkCC 流程补 S01–S03（原包已可用），把工具链处理的未测 3/9 消掉；
4. 甲组提供 ArkTS 最小调用入口并回答 E7 后，按 [记录模板](c-2a-record-template.md)第 5 节开展目标运行；仍缺原平台对照时不得宣称行为一致。
