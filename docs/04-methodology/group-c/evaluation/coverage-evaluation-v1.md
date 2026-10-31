# SkillVM 覆盖率评估报告 v1.0

> 最终成果 C-2；状态：**方法与工具链验证已有交付；目标运行、原平台基线与覆盖率数字仍无结论**。参考工作包 C-2A（样本/评价方法）、C-2B（工具链实测/结果）可先分工推进，但必须共同将方法、结果与限制整合到**同一份报告**，再申请整体验收。中间 PR 合并不代表 C-2 完成。
>
> 附件：[C-2A 方法协议](c-2a-method-v1.md) · [27 个基础用例](c-2a-cases-v1.md) · [记录模板](c-2a-record-template.md) · [样本清单](c-2a-samples-v1.json) · [C-2B 预注册参数](c-2b-preregistration-v1.md) · [C-2B 工具链验证批次 01](c-2b-toolchain-batch01.md)

## 1. 目标与范围

用乙组的 L1/L2/L3 代表性 Skill 逐级评价 SkillVM 路线的承载能力。定位是**评估与原型验证**，不从零开发完整 VM；抽样不能外推为全生态可移植率。

## 2. 样本及版本

来源：乙组 [普查 PR #13](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/pull/13)，提交 `126d80d5507293af800e7fafe538a772b16e4f21`。以下是乙组 handoff 中的**候选**，并非丙组已经验证的结果。具体纳入/替换样本需在 PR 中说明。

| 分类 | 样本 | 原始来源/版本确认 | 静态障碍 | 工具链实验 | 原平台调用 | 鸿蒙调用 |
| --- | --- | --- | --- | --- | --- | --- |
| L1 | adaptive-socratic-questioning | 乙组 handoff，待复核 | 待填 | 未测（原包未取得） | 未测 | 未测 |
| L1 | academic-paper-writing-style | 乙组 handoff，待复核 | 待填 | 未测（原包未取得） | 未测 | 未测 |
| L1 | davinci-first-principles | 乙组 handoff，待复核 | 待填 | 未测（原包未取得） | 未测 | 未测 |
| L2 | weather | SKILL.md 哈希已核对 | 待填 | 通过（SkCC 四目标均产出；SkVM 阻断） | 未测 | 未测 |
| L2 | trello | SKILL.md 哈希已核对 | 待填 | 部分通过（SkCC validate 通过，未编译） | 未测 | 未测 |
| L2 | meme-maker | SKILL.md 哈希已核对 | 待填 | 部分通过（SkCC validate 通过，未编译） | 未测 | 未测 |
| L3 | tmux | SKILL.md 哈希已核对 | PTY / shell | 通过（SkCC validate + claude 目标编译；SkVM 阻断） | 未测 | 未测 |
| L3 | mcporter | SKILL.md 哈希已核对 | MCP 协议 / 进程 | 部分通过（SkCC validate 通过，未编译） | 未测 | 未测 |
| L3 | peekaboo | SKILL.md 哈希已核对 | 平台 UI / 权限 | 部分通过（SkCC validate 通过，未编译） | 未测 | 未测 |

S04–S09 的 `SKILL.md` 已按固定提交 `d79ab6195d8d0566b285008bcc30c01a6ce368e2` 逐字节核对，SHA-256 与样本清单一致；完整包清单尚未与乙组采集数据逐项对照。S01–S03 为 ClawHub 样本，本次未在本环境取得可校验原包，因此不计入任何工具链结论。上表"工具链实验"一列的判定依据见 [C-2B 工具链验证批次 01](c-2b-toolchain-batch01.md)，其状态定义见 [C-2B 预注册第 6 节](c-2b-preregistration-v1.md)。

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
| 工具链处理覆盖（SkCC） | 通过 2/9，部分通过 4/9，未测 3/9 | 通过 = S04（四目标）、S07（claude 目标）；部分通过 = S05/S06/S08/S09（仅 validate）；未测 = S01–S03（原包未取得）。范围限于非鸿蒙目标 |
| 工具链处理覆盖（SkVM） | 阻断 6/9，未测 3/9 | S04–S09 均在缺 TCP profile 处中止；不产出适配物 |
| 完整本机覆盖 | 未测（0 个样本具备证据，不等于 0 个可移植） | 缺原平台对照、鸿蒙入口与权限映射 |
| HarmonyOS 真正可执行数量 | 未测 | 无设备与 ArkTS 入口；构建成功/文本生成均不计 |
| 原平台对照与行为一致性 | 未测 | 等待乙组同输入轨迹 |
| 甲组性能数据 | 待交接 | 未收到 |
| 执行进度 | 0/9 有运行记录 | 27 个基础用例全部未执行，超时与重试参数见 [预注册](c-2b-preregistration-v1.md) |

已发现的障碍与失败原因（按主因分类，允许一项多标签）：

- **目标能力/协议**：三条工具链路的目标都是 agent 宿主（SkVM 的 6 个 adapter、SkCC 的 4 个 emitter、SkillSmith 的 Python 模块），没有系统级 Skill 注册形态。这是移植工作必须在工具链之外另做绑定层的直接原因。
- **工具链**：SkVM 无 win32 构建，且编译各 pass 均依赖 LLM provider；SkCC 的 npm 包不含二进制，必须自建 Rust 工具链；三者文档与实现存在漂移（SkCC README 的 `--target` 参数不存在；SkVM 的 CLI 只接受 6 个 adapter，源码 registry 却注册了 8 个）。
- **源样本问题**：S01–S03 的 ClawHub 原包在本环境无稳定下载入口，无法校验即不进入实验；这正是样本清单把 `full_package_reverification` 标为 pending 的原因。
- **测试环境**：无 OpenClaw 运行环境、无鸿蒙设备，故原平台基线与目标运行均记为未测而非失败。

对 C-1 与 C-3 的可追溯输入：三工具"目标宿主"清单与接口形态（SkVM `AgentAdapter` 四成员、SkCC `TargetPlatform` 枚举与 emitter 注册 API、SkillSmith 的 `artifact_boundary`/`run_boundary_artifact`）应作为对比表与 IR 目标绑定章节的实证依据，而不是按论文声称推断。

## 6. 跨组依赖

- 乙组：普查、L3 问题清单；后续逐个交付已移植 Skill 与原平台基线；另需 S01–S03 的 ClawHub 原包（含逐文件清单），否则 L1 的工具链与运行验证无法开始。
- 甲组：鸿蒙调用入口、运行环境和性能结果。
- 丙组：将有依据的技术结论反馈乙组，更新障碍分类和本报告。

## 7. 本轮新增材料与下一步

| 材料 | 状态 | 说明 |
| --- | --- | --- |
| [C-2A 方法协议](c-2a-method-v1.md) 等四份 | 已提交 | 评价口径、27 用例、记录模板、样本清单 |
| [C-2B 预注册参数](c-2b-preregistration-v1.md) | 待 C-2A 确认 | 27 例 T_timeout、重试上限、计时容差、工具链判定判据 |
| [C-2B 工具链验证批次 01](c-2b-toolchain-batch01.md) | 已完成本批 | SkVM 阻断 / SkCC 四目标通过 / SkillSmith 阻断 |
| [`code/skill-vm/`](../../../../code/skill-vm/README.md) | 已提交 | 三份可复现脚本 + 一份产物质量核对脚本 |

下一步（按依赖顺序）：

1. C-2A 确认预注册参数，否则超时类断言无判定效力；
2. 组内决定是否配置 LLM provider 以解除 SkVM 与 SkillSmith 的阻断，或明确接受"SkVM 只做机制分析、不做实测"并写入限制；
3. 取得 S01–S03 原包后补 L1 的工具链与运行验证；
4. 甲组提供 ArkTS 最小调用入口后，按 [记录模板](c-2a-record-template.md)第 5 节开展目标运行，仍缺原平台对照时不得宣称行为一致。
