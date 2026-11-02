# C-2B 工具链验证记录：批次 01

日期：2026-10-31。状态：**工具链验证已执行，目标运行与原平台基线仍未测**。本文件只记录工具链验证；用例结果见 [C-2A 用例](c-2a-cases-v1.md)与 [记录模板](c-2a-record-template.md)，超时与重试参数见 [C-2B 预注册](c-2b-preregistration-v1.md)。

本批次回答一个问题：**2026-10-31 固定版本下，SkVM / SkCC / SkillSmith 能否真的把 OpenClaw Skill 编译成某种目标产物，以及那个目标是不是鸿蒙。** 结论是：三者都能定位到代码并说明"目标是什么"，但没有任何一个把鸿蒙 `skillProfiles` + ArkTS 入口作为目标。

## 1. 状态摘要

| 工具 | 固定版本 | 本批状态 | 一句话结论 |
| --- | --- | --- | --- |
| SkVM | npm `@ipads-skvm/skvm@0.1.5`，源码 `632cefe` | 阻断（缺 provider 密钥与 TCP profile） | 工具可安装运行、适配器可枚举，但每次编译在缺少 profile 时直接中止；适配器列表无鸿蒙 |
| SkCC | `nexa-skill 0.1.0`，源码 `59faa3a` | 通过（限四个非鸿蒙目标） | 6/6 样本 validate 通过、4 个目标真实产出产物；但产物里出现行内标识丢失与依赖声明丢失，且无鸿蒙目标 |
| SkillSmith | `AetherHeart-AI/Aeloon@e5afaa1` | 阻断（缺 Python 3.11+ 与 provider 密钥） | 编译器是 agent 插件（`/skill_compiler`），产物形态为 Python 模块 + 边界元数据；本次未能运行 |

状态定义见 [预注册第 6 节](c-2b-preregistration-v1.md)。

## 2. 环境与固定输入

| 项目 | 值 |
| --- | --- |
| 宿主 | Windows 10/11 + WSL2 Ubuntu 20.04（`Linux 6.6.87.2-microsoft-standard-WSL2 x86_64`） |
| Node / npm | v20.19.1 / 10.8.2（WSL 内，来自 npmmirror 二进制） |
| Rust | rustc 1.99.1 (58cf8f9c3 2026-10-13)，cargo 1.99.1 |
| Python（WSL） | 3.8.10 |
| 时钟与精度 | 记录时间 2026-10-31T05:15Z 起（UTC），本机时区 Asia/Shanghai |
| 网络 | 大陆网络环境：raw.githubusercontent.com 不可达，github.com / api.github.com / registry.npmjs.org / static.rust-lang.org 可达 |

固定输入为 [c-2a-samples-v1.json](c-2a-samples-v1.json) 中的 S04–S09，取自 OpenClaw 仓库 `d79ab6195d8d0566b285008bcc30c01a6ce368e2`。**六个 SKILL.md 的 SHA-256 与样本清单完全一致**，且补齐了逐文件清单（S04/S05/S08/S09 目录下只有 `SKILL.md`；S06 另有 `references/templates.json`、`scripts/meme.mjs`；S07 另有 `scripts/find-sessions.sh`、`scripts/wait-for-text.sh`）：

| 样本 | 路径 | 字节 | SHA-256（SKILL.md） |
| --- | --- | --- | --- |
| S04 weather | `skills/weather/SKILL.md` | 2905 | `62ab4821aa873949d1c1091836be1659a42b32caadce4bd145f5505a1ceaeec1` |
| S05 trello | `skills/trello/SKILL.md` | 2956 | `dc524f73bd87b8089d061187bb26add41101ee82e288a1597a2d7b89fd934222` |
| S06 meme-maker | `skills/meme-maker/SKILL.md` | 2566 | `682db7cba34a3d3ca791f7cccaee9488810c731d6622d8886a9bcca77c59d2f3` |
| S07 tmux | `skills/tmux/SKILL.md` | 2564 | `8aeaa6f3dfe06d58e09721778b8c9e654bcbd47590f26f442c4dc87c9349c572` |
| S08 mcporter | `skills/mcporter/SKILL.md` | 1612 | `010ed9b265e58d45d1e95e6deac5e60b1e46e6ebab00fc3fe30429a1048e236e` |
| S09 peekaboo | `skills/peekaboo/SKILL.md` | 4340 | `4369238bd780adc502acc48eef83a41d1a5fb8e6369b6cd258e11779043bfcb4` |

这一步顺带完成了样本清单里标为 `full_package_reverification: pending` 的**部分**工作：SKILL.md 已逐字节核对，但乙组采集的完整包清单尚未逐项对照，因此仍不算"完整包复核完成"。

## 3. 批次 A：SkVM

### 3.1 安装与平台事实

- npm 全局安装 `@ipads-skvm/skvm` 在 **Windows 原生失败**，原文：
  `skvm postinstall: unsupported platform win32-x64. Supported: darwin-arm64, darwin-x64, linux-x64, linux-arm64.`
- 改为 WSL2 Ubuntu 内安装成功，`skvm --version` = `0.1.5`。因此本批所有 SkVM 记录的执行位置都是 **WSL2 Linux**，不是 Windows 原生，也不是鸿蒙。
- 追溯源码检出的提交为 `632cefe42cdade636720d5ef97494d1e5431682b`（2026-09-11）。

### 3.2 适配器枚举（关键结果）

以不存在的适配器名探测，得到工具自己给出的合法集合，原文：

```
Invalid adapter: harmonyos. Valid: bare-agent, openclaw, opencode, hermes, jiuwenclaw, pi
```

`skvm config doctor` 亦只列出 openclaw / opencode / hermes / jiuwenclaw / pi 五个外部 harness（bare-agent 为内置）。**集合中没有鸿蒙、没有 ArkTS、没有任何"系统 Skill"形态的目标。**

另发现一处版本内不一致：源码 `src/adapters/registry.ts` 的 `ALL_ADAPTERS` 含 8 项（多出 `claude-code`、`codex`），但 CLI 实际只接受 6 项——对这两个名字分别探测，均返回 `Invalid adapter: claude-code. Valid: …` / `Invalid adapter: codex. Valid: …`。`--help` 列出的也是这 6 项。引用时以 CLI 实测为准，并把该漂移记为工具侧文档/校验问题，而不是"SkVM 已支持 Codex/Claude Code 适配器"。

### 3.3 编译尝试

6 个样本分别对 `--adapter=openclaw`、`--pass=1` 做 `--dry-run`，全部在同一处中止：

```
Missing profiles:
  anthropic/claude-sonnet-4.6--openclaw
Run 'skvm profile' first.
```

- 按 README 说法 pass 2（`bind-env`）应不消费 profile，但实测 `--pass=bind-env` 同样报同一条 `Missing profiles`；不 dry-run 直接执行时退出码 1，未产生任何产物。
- `skvm profile` 需要真实模型服务：provider 注册表只有 openrouter（`OPENROUTER_API_KEY`）、anthropic（`ANTHROPIC_API_KEY`）、openai-compatible 三类，**没有离线/mock provider**。本机未配置任何 provider（`config doctor`：`Providers · not configured`），因此 profile 与 pass 1 都无法执行。
- 结论：SkVM 的"编译"不是纯静态转换，**编译链路上有 LLM 参与**（pass 1 的 rewriting、pass 2 的依赖推断与 env 脚本自动修复都走 `ctx.provider`）。

### 3.4 对鸿蒙移植的结构性观察

- `AgentAdapter` 接口只有四个成员：`name` / `setup(config)` / `run({prompt, workDir, skill, taskId, convLog, timeoutMs})` / `teardown()`（`src/core/types.ts`）。也就是说，SkVM 眼里的"目标宿主"是**能跑子进程 agent、按 prompt 驱动一轮对话并返回结果的东西**。
- 这解释了为什么适配器全是 CLI/agent harness：接入新宿主的工作量主要落在"实现这个接口"，而不是"生成 ArkTS 代码"。
- 对鸿蒙的直接含义：即使实现了该接口，`run()` 里仍要有可执行进程与文件工作目录；ArkTS 侧 `scriptManager` 走的是应用内脚本调用，二者不是同一种执行模型。**SkVM 的适配层不能替代鸿蒙绑定层**（C-3 的结论需要这条证据）。

## 4. 批次 B：SkCC（nexa-skill）

### 4.1 构建与运行

- 源码 `59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6`（2026-07-11），`cargo install --path nexa-skill-cli`，release 构建 23.34s，产出 `nexa-skill 0.1.0`。
- npm 包 `nexa-skill-compiler` 只是壳：`nsc` 会去找 `nexa-skill` 可执行文件，未做 Rust 构建时直接报 `'nexa-skill.exe' is not recognized`。所以 **SkCC 的"一次 npm 安装即可用"不成立**，真实前置是 Rust 工具链。

### 4.2 validate 与 build 结果

| 操作 | 输入 | 结果 |
| --- | --- | --- |
| `validate` | S04–S09 六个样本 | 6/6 `✅ Validate command executed successfully`，退出码 0 |
| `build --claude` | S04 weather | 成功，输出 `SKILL.md` |
| `build --codex` | S04 weather | 成功，输出 `weather.md` |
| `build --gemini` | S04 weather | 成功，输出 `weather.md` + `assets/config.yaml` |
| `build --kimi` | S04 weather | 成功，输出 `SKILL.md` |
| `build --all` | S04 weather | 成功，四目标齐全 |
| `build --claude` | S07 tmux（带脚本的 L3） | 成功 |

产物 SHA-256（同一输入、同一工具版本）：

| 产物 | SHA-256 |
| --- | --- |
| `claude/SKILL.md` | `53c72abfe7628b37a9dbfd00d3bb3afcc037691ceeeb859df9c9865c29997458` |
| `claude/manifest.json` | `800b9ee6ddb18b6c6cb5190b240b7d5af11e4c1fa26f609cb532d151bcf1e784` |
| `codex/weather.md` | `b3925f3ecc021590ae00578b279c639b710c249288e0e04322649d447d4c82b3` |
| `gemini/weather.md` | `d78e16aae193fd617586e5a13b791773da9d3796a29f80f7daf63cfac4080c46` |
| `gemini/assets/config.yaml` | `e9f0c9c112184395de5850b76e40d7200ac292cfa794a1c0c32f75610604d565` |
| `kimi/SKILL.md` | `0886a889d8ba4f83bfc40c57bdd7b2923b7f01b78f4a75ea36ee22452ab77b6b` |

**溯源可核对**：SkCC 自己写的 `manifest.json` 里 `source_hash` 为 `62ab4821aa873949d1c1091836be1659a42b32caadce4bd145f5505a1ceaeec1`，与我们独立计算的 S04 源文件哈希一致；`security_level: "medium"`、`hitl_required: false` 也由该文件给出。

### 4.3 目标集合

`nexa-skill build` 的合法目标由源码 `nexa-skill-core/src/backend/registry.rs` 决定，内置只有 **Claude / Codex / Gemini / Kimi**；CLI 帮助原文：`--claude`、`--codex`、`--gemini`、`--kimi`、`--all`。**没有鸿蒙目标，也没有可插拔的自定义 emitter 命令行入口**（源码有 `register()` API，但 CLI 未开放）。

顺带记录一处文档与实现不一致：README 写的是 `nsc build skill.md --target claude`，实测 `--target` 不存在，原文 `error: unexpected argument '--target' found`，必须用 `--claude`。

### 4.4 产物质量问题（对移植判断有影响）

以 S04 为例，源文件与四个产物对比：

| 指标 | 源 SKILL.md | claude | codex | gemini | kimi |
| --- | --- | --- | --- | --- | --- |
| 反引号数 | 78 | 36 | 20 | 36 | 36 |
| `web_fetch` 出现次数 | 7 | 6 | 4 | 5 | 4 |

claude 产物中可读到的原文空洞（逐字）：

```
Use  first when the tool is available. Request JSON because wttr.in
For short answers, summarize , , and the
```

源文件对应的是 ``Use `web_fetch` first…`` 与 ``summarize `current_condition[0]`, `nearest_area[0]`, and the``。即**行内代码标识（工具名、JSON 字段名）在产物中被剥离**，而正文其余部分保留。具体机制未读 emitter 实现验证，从现象推断可能是把反引号内容当作可绑定占位符、无绑定时丢空；无论机制如何，对"工具名/字段名必须保真"的移植场景都是实质缺陷，不能只看 `Build completed successfully`。

另一处：源 frontmatter 的 `metadata.openclaw.install`（`brew` 安装 `curl`，`bins: ["curl"]`）在所有产物中都消失，取而代之的是一行静态告警：

```
WARN nexa_skill_core: [nsc::security::permission_warning] Keyword 'curl' in step 1 may require Network permission
```

同一样本族的第二例（S07 tmux，带 `scripts/` 的 L3）：源文件第 84–85 行以行内代码给出的两个辅助脚本说明（`scripts/find-sessions.sh`、`scripts/wait-for-text.sh`）在 `--claude` 产物中消失，只有代码块里的 `scripts/wait-for-text.sh -t shared:0.0 …` 调用被保留，`scripts/` 引用由 3 处降为 2 处。即"有哪些辅助脚本"这类结构化说明最先被丢掉，而这恰好是移植者判断"需要实现哪些脚本"的依据。

也就是说 SkCC 把依赖/权限降级为**关键词启发式提示**，没有把结构化依赖声明带到目标产物里。这一点对鸿蒙尤其关键：`skillProfiles.permissions` 需要确定的权限项，而关键词命中无法区分"只是文档里提到 curl"与"运行时要发起网络请求"。

### 4.5 判定

按 [预注册第 6 节](c-2b-preregistration-v1.md)：**通过**，但范围严格限定为"把 OpenClaw `SKILL.md` 离线编译成 Claude/Codex/Gemini/Kimi 四种提示格式"，且附带 4.4 的质量缺陷。该结果**不构成**任何"鸿蒙可运行"的证据。

## 5. 批次 C：SkillSmith（Aeloon）

- 论文 arXiv 2605.15215 给出的代码入口为 `github.com/AetherHeart-AI/Aeloon`，检出提交 `e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4`（2026-05-20），MIT。
- 编译器不是独立 CLI，而是 agent 插件：`aeloon/plugins/SkillGraph/compiler.py` 暴露命令 `/skill_compiler <skill-path> [--model MODEL] [--runtime-model MODEL] [--strict-validate]`，核心函数签名为
  `compile_skill_to_workspace(*, workspace: Path, provider: LLMProvider, default_model: str, request: SkillCompilerRequest)`。
- 产物形态由源码可见：编译结果落到 `project_compiled_skills_root()`，生成 `aeloon_skill_compiler_<name>` 形式的 **Python 模块** + manifest/sandbox/report/config；运行侧由 `skillgraph/boundary_runtime.py` 的 `run_boundary_artifact` 执行，产物携带 `artifact_boundary`（`boundary: adapter | typed_operator`，含 `operators`、`planlets`、`tool_schema`）。
- 本次 **阻断**，原因两条，均可复现：① 需要 `provider: LLMProvider` 与模型，本机无密钥；② 仓库要求 Python 3.11+，WSL 内为 3.8.10 且未安装依赖。
- 对移植判断的意义（不作为已验证结论）：SkillSmith 的"编译产物"是**带边界元数据的 Python 可执行模块**，目标运行时是 Python agent；移植到鸿蒙需要的不只是重写提示，还要重写这个模块的执行语义。这条与 SkVM 的 adapter 结论一致：**三者的"目标"都是某种 agent 宿主，而不是系统级 Skill 注册**。

## 6. 三工具横向对照（仅本批实测部分）

| 维度 | SkVM | SkCC | SkillSmith |
| --- | --- | --- | --- |
| 本次能否实际编译 | 否（缺 profile/密钥） | 是（4 目标） | 否（缺 Python 3.11/密钥） |
| 编译是否需要 LLM | 是 | 否（纯静态转换 + 关键词安全检查） | 是 |
| 目标形态 | 面向 agent harness 重写的 SKILL.md + env 脚本 | Claude/Codex/Gemini/Kimi 提示格式 | Python 模块 + 边界元数据 |
| 目标里有无鸿蒙 | 无（6 个适配器全为 agent/CLI） | 无（4 个 emitter） | 无（Python agent 运行时） |
| Windows 原生可用 | 否（无 win32 预编译） | 需自建 Rust 工具链 | 未测（Python 3.11+ 未满足） |
| 本次证据强度 | 命令与报错原文 | 可哈希产物 + 工具自报 source_hash | 源码级定位 + 阻断原因 |

**共同结论（本批唯一敢下的）**：三条路线都不提供"OpenClaw Skill → 鸿蒙系统 Skill"的目标端；它们都要把 skill 适配到**某个具体 agent 宿主**上。因此丙组的移植工作不能表述为"用 SkVM 把 Skill 编译到鸿蒙"，只能表述为"用工具链做语义中间层，再单独实现鸿蒙绑定与权限映射"。

## 7. 复现方式与附件

| 内容 | 位置 |
| --- | --- |
| SkVM 批次脚本 | [`code/skill-vm/skvm-batch01.sh`](../../../../code/skill-vm/skvm-batch01.sh) |
| SkCC 批次脚本 | [`code/skill-vm/skcc-batch02.sh`](../../../../code/skill-vm/skcc-batch02.sh)、[`skcc-batch02b.sh`](../../../../code/skill-vm/skcc-batch02b.sh) |
| 产物质量核对脚本 | [`code/skill-vm/skcc-verify-loss.sh`](../../../../code/skill-vm/skcc-verify-loss.sh) |
| 原始运行日志 | 本机 WSL `/home/dreaminsight/c2b/logs/`，三个文件 SHA-256 见下；日志未入库，脚本可重放 |

| 日志 | 字节 | SHA-256 |
| --- | --- | --- |
| `batch01-20261031T131524.log` | 6399 | `ff0633abeb2c4851b018b11b7adc8cea9c0dfaa9cfc15a5897233439d18b6ecc` |
| `batch02-20261031T131649.log` | 5233 | `512db078530287e890cc7e5091c4706656611a8afc61c0b6eb7cac57a44f1611` |
| `batch02b-20261031T131657.log` | 7452 | `10acb03490266494e9877fbef13d0acd9e566360e546b404bc2f778e16b874e1` |

以上脚本与日志均不含密钥；产物目录未入库（第三方 Skill 内容的再分发边界问题由 C-4 的许可证策略决定）。

## 8. 本批未测与限制

| 未测项 | 原因 | 谁能解除 |
| --- | --- | --- |
| SkVM 真实编译与产物 | 无 provider 密钥、无 TCP profile | 组内决定是否申请密钥；或改用具离线 mock 的替代路径（当前版本无） |
| SkillSmith 任何编译产物 | Python 3.11+ 与密钥均缺 | 同 C-2B 后续批次 |
| 四个目标产物的"能否驱动真实 agent 完成任务" | 无对应 agent 宿主与配额 | 甲/乙组环境 |
| 目标运行（鸿蒙） | 无设备与 ArkTS 入口 | 甲组 |
| 原平台基线 | 本批时无 OpenClaw 运行环境 | 已由 [批次 02](c-2b-batch02-baseline-and-provenance.md) 建成环境并核验加载状态；用例执行仍缺模型凭证 |
| Windows 原生 SkVM | 官方无 win32 构建 | 需向作者确认或用 WSL（本批做法） |

本批**不**改变 C-2 报告第 5 节任何"鸿蒙可执行"结论：工具链验证通过 ≠ 目标运行通过。"原平台基线"一行在批次 02 中已部分解除，但"能加载技能"仍不等于"基线已建立"。
