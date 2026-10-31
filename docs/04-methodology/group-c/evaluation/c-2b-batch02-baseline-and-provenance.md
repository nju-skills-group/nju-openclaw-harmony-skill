# C-2B 批次 02：样本溯源与原平台环境核验

> 类型：取证批次（不产生用例执行结论）。执行日期 2026-10-31，执行位置 WSL2 Ubuntu 20.04。
> 上游材料：[C-2A 方法协议](c-2a-method-v1.md) · [样本清单](c-2a-samples-v1.json) · [C-2B 批次 01](c-2b-toolchain-batch01.md)。
> 本批结论一句话：**九个样本的原包与逐文件清单全部取得且校验通过，OpenClaw 原平台环境建成并核验；但两者都还没有产生"用例执行"证据。**

## 1. 起因：复核甲乙组与乙组交付后发现三条可用材料

批次 01 把两项记为"缺条件"，理由是"S01–S03 原包不可得"与"无 OpenClaw 运行环境"。逐份复核其他组已提交的材料后，发现这两条并非真的不可得：

| 材料 | 出处 | 可用之处 |
| --- | --- | --- |
| ClawHub v1 API 调用式 | 乙组 [`tools/skill-survey/scripts/fetch_candidates.py`](../../../../tools/skill-survey/scripts/fetch_candidates.py) | 给出 `/api/v1/skills/<slug>`、`/versions/<version>`、`/file?path=…` 三个端点，并用 release inventory 的逐文件 `sha256` 做校验；可据此取得 S01–S03 原包 |
| 逐文件清单与固定提交树 | 乙组 [`source-manifest.json`](../../group-b/skill-survey/source-manifest.json)（593 文件 `sha256`）、[`bundled-tree.json`](../../../../tools/skill-survey/data/bundled-tree.json)（`d79ab619…` 的 git tree，含 blob `sha1` 与字节数） | 对 S04–S09 做双源交叉校验，解除"仅核对 SKILL.md"的限制 |
| OpenClaw 无密钥安装链路 | 甲组 [`openclaw_setup_v1.md`](../../../03-environment/Group_A/openclaw_setup_v1.md)（A1 孙冉） | 装 OpenClaw 与 Gateway 不需要密钥；只有 agent 推理需要 provider |
| 鸿蒙侧实测字段与调用门槛 | 甲组 [`harmony-setup.md`](../../../03-environment/Group_A/harmony-setup.md)（A2 李朝阳） | `skillProfiles` 实际字段、`completeArkTSScriptInApp` 回包、"系统调用须真机 + 小艺平台"的判定 |

**更正**：批次 01 与 C-2 报告第 5 节把 S01–S03 不可得归因于"clawhub.ai 无稳定下载入口"。实际原因是我当时用错了端点（`/api/skills/...`，返回 404），乙组脚本里已有正确端点，实测可用。这条已按 §2.1 修正。

## 2. S01–S03：按 ClawHub release inventory 取得并逐文件校验

### 2.1 调用式（原样，勿改参数名）

```text
GET https://clawhub.ai/api/v1/skills/<slug>?ownerHandle=<owner>
GET https://clawhub.ai/api/v1/skills/<slug>/versions/<version>?ownerHandle=<owner>
GET https://clawhub.ai/api/v1/skills/<slug>/file?path=<path>&version=<version>&ownerHandle=<owner>
```

第二个响应的 `version.files[]` 给出每个文件的 `path` 与 `sha256`，第三个端点按该清单取内容；脚本以 inventory 的 `sha256` 逐个比对，任何一处不符即中止，不落盘为"可信样本"。

### 2.2 校验结果

| 样本 | 来源 | 文件数 | 总字节 | SKILL.md 字节 | SKILL.md SHA-256 | 与样本清单 |
| --- | --- | --- | --- | --- | --- | --- |
| S01 | `perpetualhui/adaptive-socratic-questioning@1.1.0` | 12 | 65164 | 8309 | `61b6f2219b52b76b9266f9c435b2a355228ba4a86753e96c88e12c51f05f01aa` | 一致 |
| S02 | `aircraft06/academic-paper-writing-style@1.0.0` | 4 | 24817 | 9701 | `cf44335ff427b91246ac9d9a44662ce6844f59310cdf25a1e4884fa55bd91a0f` | 一致 |
| S03 | `clawdiri-ai/davinci-first-principles@1.0.0` | 2 | 7207 | 5335 | `b972afd762a9a8557738d36f088e3d44cf612e8ddea3a3a8fb87793aa3bfdac3` | 一致 |

同时校验：发布者 `ownerHandle` 与样本清单一致（防止同名不同作者）；请求版本与实际返回版本一致；12/4/2 个文件的 `sha256` 与 inventory 全部一致。

S01 的包内清单（此前完全不可见）：`SKILL.md`、`README.md`、`README_SKILL_STATUS.md`、`skill.json`、`skill-card.md`、`evals/evals.json`、`examples/{data-analysis,paper-writing,problem-solving,research-design}.md`、`tests/{test-report,test-suite}.md`。这印证乙组对 L1"evals 是静态源码、不是可执行脚本"的判断；这些文件现在可以进入静态验证（机制可表达性）的输入，而不必再写"原包未取得"。

## 3. S04–S09：三重一致（git tree / 乙组清单 / 运行时包）

取得载体：`openclaw@2026.10.9` 的 npm 包内含 `skills/`（50 个目录），以及运行时已安装包中的同名目录。校验三方一致：

1. 我本地的 `SKILL.md` 与样本清单 `skill_md_sha256` 一致（批次 01 已完成）；
2. 按 git 规则重算的 blob `sha1` 与 [`bundled-tree.json`](../../../../tools/skill-survey/data/bundled-tree.json) 中 `d79ab619…` 的记录一致，字节数亦一致；
3. 逐文件 `sha256` 与乙组 [`source-manifest.json`](../../group-b/skill-survey/source-manifest.json) 的记录一致。

| 文件 | 字节 | SHA-256 | git blob `sha1` 一致 | 乙组清单一致 |
| --- | --- | --- | --- | --- |
| `weather/SKILL.md` | 2905 | `62ab4821aa873949d1c1091836be1659a42b32caadce4bd145f5505a1ceaeec1` | 是 | 是 |
| `trello/SKILL.md` | 2956 | `dc524f73bd87b8089d061187bb26add41101ee82e288a1597a2d7b89fd934222` | 是 | 是 |
| `meme-maker/SKILL.md` | 2566 | `682db7cba34a3d3ca791f7cccaee9488810c731d6622d8886a9bcca77c59d2f3` | 是 | 是 |
| `meme-maker/references/templates.json` | 13128 | `414847dc28da8556bdd9a3ddf350f3d859d4668ecc237c1889b289d42d2879b8` | 是 | 是 |
| `meme-maker/scripts/meme.mjs` | 13362 | `6211a37d19d90498b01fc31302506af0c0021e9949038054e1f7c34e71c4e1fd` | 是 | 是 |
| `tmux/SKILL.md` | 2564 | `8aeaa6f3dfe06d58e09721778b8c9e654bcbd47590f26f442c4dc87c9349c572` | 是 | 是 |
| `tmux/scripts/find-sessions.sh` | 2983 | `8df6ac8e5824b0fa4d791235bd944ce86b0d12dcbf98af7abeb6d6de50e96823` | 是 | 是 |
| `tmux/scripts/wait-for-text.sh` | 2294 | `b7efb785d3f2a4f1194e2ae18d7191135ad5a2fff4f08e6a4c7ad8412f3a7309` | 是 | 是 |
| `mcporter/SKILL.md` | 1612 | `010ed9b265e58d45d1e95e6deac5e60b1e46e6ebab00fc3fe30429a1048e236e` | 是 | 是 |
| `peekaboo/SKILL.md` | 4340 | `4369238bd780adc502acc48eef83a41d1a5fb8e6369b6cd258e11779043bfcb4` | 是 | 是 |

共 10 个文件、9 个技能目录；`weather`/`trello`/`mcporter`/`peekaboo` 仅有 `SKILL.md`，`meme-maker` 与 `tmux` 各带 2 个附属文件。运行时已安装包内同名文件的哈希与上表逐字节相同，即 **OpenClaw 实例加载的就是固定提交内容**，不是"另一个版本但名字相同"。

样本清单原先的 `hash_scope: "SKILL.md only"` 与 `full_package_reverification: "pending"` 对 S04–S09 已经过期；字段修改权在 C-2A，本批只提供依据（见 §5）。

## 4. 原平台（OpenClaw）环境核验

### 4.1 安装与版本

| 项目 | 实际值 |
| --- | --- |
| OpenClaw | `2026.10.9 (8b18b55)`，`npm i -g openclaw@2026.10.9`（344 个依赖包，28 s） |
| Node / npm | v24.22.1 / 11.19.1（包声明 `engines.node: ">=24.22.1 <25 \|\| >=26.12.1"`） |
| 系统 | WSL2 Ubuntu 20.04，`Linux 6.6.87.2-microsoft-standard-WSL2` |
| 配置 | `~/.openclaw/`（无 `openclaw.json`，未做 onboarding），默认模型 `openai/gpt-6-astra` |

**文档漂移（记录为发现）**：甲组手册写"Node.js ≥ 22"，但 `2026.10.9` 的 engines 已是 `>=24.22.1 <25 || >=26.12.1`；按手册装 Node 22 会在 `npm i -g` 阶段失败（本机 Node 20.19.1 与 22 均不满足）。这只影响"是否能装"，不影响手册其余步骤。

### 4.2 技能加载状态

`openclaw skills check`：Total 55 / eligible 20 / model-visible 20 / command-visible 19 / missing requirements 35。

| 样本 | eligible | modelVisible | 缺失项（机器判定） | 平台不兼容 |
| --- | --- | --- | --- | --- |
| S04 weather | 是 | 是 | 无 | 否 |
| S05 trello | 否 | 否 | bin `jq`；env `TRELLO_API_KEY`、`TRELLO_TOKEN` | 否 |
| S06 meme-maker | 是 | 是 | 无（requires bin `node`，已满足） | 否 |
| S07 tmux | 是 | 是 | 无（requires bin `tmux`，已满足；os `darwin`/`linux`） | 否 |
| S08 mcporter | 否 | 否 | bin `mcporter` | 否 |
| S09 peekaboo | 否 | 否 | bin `peekaboo`；os 仅 `darwin` | **是** |

价值：L3 的三个"环境缺口"从纸面判断变成平台自己给出的判定——`peekaboo` 在 Linux 上被标 `platformIncompatible: true`（os 门控），`mcporter` 缺 CLI，`trello` 除了 jq 还要账号令牌。这三条可以直接写进 C-1 的障碍分类，并作为 S08/S09"原平台基线即便有模型也不可执行"的依据（与设备无关，是平台能力缺口）。

### 4.3 为什么仍不能跑用例

| 检查 | 结果 |
| --- | --- |
| `openclaw models status` | 默认 `openai/gpt-6-astra`，`effective=missing`，`Missing auth: openai …`，`Providers w/ OAuth/tokens (0)` |
| `openclaw agent --message "…"` | `gateway agent requires credentials before opening a websocket`（未配对，可本地解决） |
| 本地模型路线（Ollama） | OpenClaw 支持 ollama provider（`OLLAMA_DEFAULT_BASE_URL` 等），但 `ollama.com/install.sh` 与 `/download/ollama-linux-amd64.tgz` 均 307 跳转 `github.com/ollama/ollama/releases`，本机到 github.com 连接失败（HTTP 000），无法取得运行时与权重 |

即：**环境可装、技能可加载、模型不可用**。原平台基线的阻塞点由"没有 OpenClaw"缩小为"没有模型凭证"，后者是组内决策（谁出 key、用哪个模型、限额多少），不是技术环境问题。

### 4.4 鸿蒙侧（目标运行）复核

甲组手册与 C-2 契约给出的门槛是硬的，不因本批取证而改变：

- 甲组实测：HAP 构建成功、模拟器运行 Hello World 成功，但"Skill 系统调用"仍为待验证；判定表明确写"只有通过小艺开放平台导入 HAP 并在支持的真机上测试，才能证明端到端调用；模拟器运行不替代此项"。
- 契约 §6.3/§9：`skillProfiles` 在部分场景**仅对预置应用生效**，非预置应用能否上架开放 Skill 属未决项（实验 E7 未做）；`AGENT_SKILL` 权限亦未证实。
- 本机无 DevEco/SDK（`hdc`、`ohpm`、`hvigorw` 均不存在），无法本地构建 HAP。

结论：目标运行仍是"未测"，且其阻塞不只是"缺一台设备"，而是"缺设备 + 缺 ArkTS 入口 + 一个未决的契约问题（E7）"。

## 5. 这些证据改变了什么、没有改变什么

| 项目 | 批次 01 时 | 现在 | 依据 |
| --- | --- | --- | --- |
| S01–S03 原包 | 未取得，不进入实验 | 已取得，逐文件校验通过 | §2 |
| 完整包复核 | pending，仅 SKILL.md | S01–S09 全部逐文件核对通过（10 + 18 个文件） | §2、§3 |
| 原平台环境 | 无 | 已建成并核验（版本 + 加载状态） | §4.1–4.2 |
| 原平台基线（用例执行） | 未测（无环境） | **未测**（无模型凭证） | §4.3 |
| 目标运行 | 未测（无设备） | **未测**（无设备、无入口、E7 未决） | §4.4 |
| 工具链（SkVM/SkCC/SkillSmith） | 阻断 / 通过 / 阻断 | 本批不变；L1 的 SkCC 补测见 [批次 03](c-2b-toolchain-batch03.md) | 批次 01 |

明确不做的两处升级：**不把"环境建成"写成"基线通过"**（基线要求用例执行与原版表现记录）；**不把"包已取得"写成"S01–S03 已过工具链"**（SkCC 批次 01 未处理 L1，L1 的工具链状态仍是未测）。

## 6. 给 C-2A 的三条回填建议（字段修改权在 C-2A）

1. `c-2a-samples-v1.json` 中 S01–S09 的 `full_package_reverification` 可由 `pending` 改 `done`；`hash_scope` 由 `"SKILL.md only"` 改为 `"release inventory (all files)"`，依据为本文件 §2、§3。
2. 建议在记录模板第 4 节开头固定记录"原平台环境就绪"（版本、node、`skills check` 摘要、六样本可见性），再记用例结果——这样"环境坏了"与"技能失败"不会混为一谈。
3. 本批只追加本文件，未改 [预注册](c-2b-preregistration-v1.md) §4 的 27 例超时表；P1（参数确认）仍待 C-2A 签署。

## 7. 复现方式与附件

| 内容 | 位置 |
| --- | --- |
| ClawHub 样本取得与校验 | [`code/skill-vm/fetch-samples-clawhub.py`](../../../../code/skill-vm/fetch-samples-clawhub.py) |
| 包内容三方交叉校验 | [`code/skill-vm/verify-sample-package.py`](../../../../code/skill-vm/verify-sample-package.py) |
| OpenClaw 环境与加载核验 | [`code/skill-vm/openclaw-baseline.sh`](../../../../code/skill-vm/openclaw-baseline.sh) |
| 原始输出 | 本机 WSL `~/c2b/logs/`，哈希见下；未入库（含第三方技能内容与路径信息） |

| 文件 | 字节 | SHA-256 |
| --- | --- | --- |
| `oc-skills-check.json` | 15006 | `aab4d48bab12b68ae650916f2b2b1e4da407fcda2c38c8d105d7ec8cc846ad38` |
| `oc-info-weather.json` | 1133 | `ae1620753929315fb6cb9f3500230da8084872705fe5fb8a29ee77fd10854c36` |
| `oc-info-trello.json` | 1242 | `eb65bb5383452ff2d554f9e848c675403159ecc928f7adca49423aea67df768a` |
| `oc-info-meme-maker.json` | 950 | `df193902eaab051df9084e48754c10b93e2b2dd2231879a3c66d09a147999666` |
| `oc-info-tmux.json` | 1122 | `5788f252851a31d5c882f16f9357e90009749f32dac45e53be9eaedeffb91001` |
| `oc-info-mcporter.json` | 1165 | `c3143014b81dcd32c7c79055a4516054df5ef26b02950f1561b266e413bf2f83` |
| `oc-info-peekaboo.json` | 1016 | `e405cb2feb6376e9b66d5943427bb9255baef65ad4d72a3eef9a43b8f7f78661` |
| `oc-models-status.txt` | 716 | `b428c0b1825a843a682e3324ed8710b1ee70cd836900b188d17b3f52ed106771` |
| `install-openclaw.log`（Windows 侧） | 496 | `1ad1d11eedab6f266273e71348c1643f51856b2add3439dd4b87a8b42f051875` |

`openclaw-baseline.sh` 重跑可复现 §4 的全部结论（版本、55/20/35、六个样本的 visible/missing、哈希 `[OK]`）；`oc-*.json` 的哈希稳定，`oc-models-status.txt` 含时间无关的配置摘要。

## 8. 本批未测与限制

| 未测项 | 原因 | 谁能解除 |
| --- | --- | --- |
| 原平台用例执行（27 例任意一条） | 无模型凭证；Ollama 本地路线因 github 不可达未建立 | 组内决定 provider 与限额；或换到能访问 github 的网络 |
| `openclaw skills verify`（ClawHub 签名链路） | 未安装 ClawHub 认证 | 可选，与覆盖率无关 |
| ClawHub 版本历史（除 latest 版本外） | 只取样本清单固定的那一个版本 | 需要旧版本时再取 |
| S01–S03 的工具链处理 | 批次 01 的 SkCC 批次只覆盖 S04–S09；L1 未纳入 | 已于 [批次 03](c-2b-toolchain-batch03.md) 补测（validate + build 均通过） |
| 鸿蒙目标运行 | 无设备、无 ArkTS 入口、契约 E7 未决 | 甲组 |
| 第三方内容的入库与再分发 | S01–S03 为第三方作品（MIT-0 等），本批只在本机保存 | C-4 许可证与发布策略 |
