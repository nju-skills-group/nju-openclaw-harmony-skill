# C-2B 批次 04：静态机制核对与夹具自检

> 类型：静态分析 + 夹具自检。执行日期 2026-10-31（UTC 06:48–06:50），位置 WSL2 Ubuntu 20.04。
> 起因三件：① 覆盖率报告的"静态障碍"仍有 6 格空着；② [预注册 §5](c-2b-preregistration-v1.md) 要求夹具"在首次执行前保存路径与哈希"，而夹具此前并不存在；③ [批次 03](c-2b-toolchain-batch03.md) 留了一句"SkVM 对 S01–S03 未补跑"。
> 结论四件：① 九个样本的静态障碍全部落定，其中 **S01–S03 的依赖为零**，障碍只在运行时能力侧；② 六类夹具已成型并自检，5 个 PASS、1 个参数夹具、2 个需设备，哈希登记在 [`fixtures/manifest.json`](../../../../code/skill-vm/fixtures/manifest.json)；③ SkVM 的"未测 3/9"补跑后**同样是阻断**，口径变为阻断 9/9；④ 新增两处缺口，其中一处（S04-02 的夹具响应口径）必须由 C-2A 冻结。

本批**没有**推进的事：27 个用例仍 0 执行，目标运行仍 0/9，原平台基线仍未测。静态分析与夹具自检都不产生"能跑通"的证据。

## 1. 环境与输入

| 项目 | 实际值 |
| --- | --- |
| 系统 | `Linux 6.6.87.2-microsoft-standard-WSL2 x86_64` |
| Python（夹具自检） | `3.8.10`，仅标准库，只监听 `127.0.0.1` |
| Node / npm（SkVM） | `v20.19.1` / `10.8.2`；SkVM `@ipads-skvm/skvm 0.1.5` |
| 输入（S01–S03） | 批次 02 取得的原包，stage 在 `$WORK/skills-l1/<S0x>/` |
| 输入哈希 | S01 `61b6f2219b52b76b9266f9c435b2a355228ba4a86753e96c88e12c51f05f01aa`（12 文件）、S02 `cf44335ff427b91246ac9d9a44662ce6844f59310cdf25a1e4884fa55bd91a0f`（4 文件）、S03 `b972afd762a9a8557738d36f088e3d44cf612e8ddea3a3a8fb87793aa3bfdac3`（2 文件） |
| 不需要什么 | 不需要模型凭证、不需要鸿蒙设备、不需要外网 |

上表三个哈希与 [样本清单](c-2a-samples-v1.json) 的 `skill_md_sha256` 一致，因此本批的输入与批次 02/03 是同一份，不是重新取的包。

## 2. 静态障碍逐样本

口径：静态障碍 = **源文声明的能力里，目标端不能按原样表达的部分**。它不是"移植难度评分"，也不预测用例通过与否。依据一律引原文（`metadata.openclaw` 的 `requires`/`install`/`os`、正文里的命令与 URL），不从论文或印象推断。

| 样本 | 静态障碍（判定） | 源文依据 | 输出契约 | 机制可表达性 |
| --- | --- | --- | --- | --- |
| S01 | **无外部依赖** | `metadata.openclaw` 只有 `emoji`/`homepage`，无 `requires`、无 `install`、无脚本文件；12 个文件全是 Markdown | `## Output Format` 固定 JSON：`followup_questions[]`（含 `type`/`question`/`purpose`/`level_adaptation`）、`reasoning_path`、`misconception_flags[]`、`teacher_guidance` | **高**：单文件提示 + 固定 JSON 契约，字段可机检；但 `evals/evals.json` 的 5 条 `expected_output` 是自然语言（如"4–6 个问题…应指出…误解"），**内容不可机检**，只能由模型或人判 |
| S02 | **多文件按需加载**（无脚本、无网络） | 4 个文件：`SKILL.md` + `references/expression_examples.md`（8353 B）+ `references/journal_formats.md`（4479 B）+ `skill-card.md`；正文按主题引用 references | 无。散文式写作规范，37 个标题但**没有编号步骤、没有输出格式** | **中低**：结构可拆成章节，但无步骤编号可对齐 IR 的 step，也无契约可断言；SkCC 因此自造了 `Follow the skill instructions`（[批次 03 §3.2](c-2b-toolchain-batch03.md)） |
| S03 | **命令式触发**（无脚本、无网络） | `## Trigger`：`Activate on /firstprinciples <topic>`；`Process` 固定 5 个 Phase（Assumption Extraction → …）；仅 2 个文件 | 无。Phase 有固定顺序，但每阶段产出为自由文本 | **中**：5 个 Phase 可表达为有序 step，但"阶段是否做到"无客观断言 |
| S04 | **外部 HTTP + JSON 解析 + 降级分支** | 正文：`Use web_fetch first when the tool is available`，fallback `curl --fail --silent --show-error --max-time 20 "https://wttr.in/London?format=j1"`；`install` 为 brew `curl` | 隐含：取 `format=j2`/`j1` 的天气 JSON 后转述 | 中：请求/解析可表达，但 `web_fetch` 是宿主工具、`curl` 是 shell 程序，鸿蒙侧都没有同形物 |
| S05 | **网络 + 文本管道 + 凭据** | `requires: {bins:["curl","jq"], env:["TRELLO_API_KEY","TRELLO_TOKEN"]}`；正文 6 条 `curl … \| jq …` 管道 | 隐含：看板/列表/卡片的 JSON 转述 | 中：REST 可表达为 HTTP 调用，但 `jq` 管道与 env 注入需要替代实现 |
| S06 | **Node 运行时**（+ 可选远程） | `requires: {bins:["node"]}`；`{baseDir}/scripts/meme.mjs render …`；本地 SVG 分支无网络，PNG 需浏览器，`--service imgflip` 需 `IMGFLIP_USER`/`IMGFLIP_PASS` | 产物是文件（`.svg`/`.png`） | 中：脚本逻辑可重写，但"执行 `.mjs`"在鸿蒙上无直接等价物 |
| S07 | **PTY / 外部进程** | `os: ["darwin","linux"]`、`requires: {bins:["tmux"]}`；`scripts/find-sessions.sh`、`scripts/wait-for-text.sh`；正文 `tmux ls`、`tmux list-windows -t shared` | 隐含：捕获的终端文本 | 低：会话/伪终端是宿主能力，不是文本可表达的部分 |
| S08 | **MCP 协议 + 子进程生命周期** | `requires: {bins:["mcporter"]}`；`mcporter call --stdio "bun run ./server.ts" scrape url=…` | 协议消息（JSON-RPC） | 低：需协议栈与子进程管理 |
| S09 | **平台 UI + 系统权限** | `os: ["darwin"]`、`requires: {bins:["peekaboo"]}`；正文要求 `--foreground` 的前台交互授权 | 隐含：截图/坐标/点击结果 | 低：依赖 macOS 辅助功能授权，鸿蒙无同形能力 |

三点结论：

1. **九个样本没有一个因为"文本无法解析"而不可表达。** 静态障碍全部落在运行时能力侧（网络、进程、协议、UI、凭据），这与 [报告 §5](coverage-evaluation-v1.md) 的"工具链目标集合不含鸿蒙"是同一判断的两个侧面：**语义层可表达，绑定层必须另做**。
2. **S01–S03 的依赖为零**，是唯一"只靠提示 + 模型"就能成立的一组；它们的薄弱点不是依赖，而是**断言**（S02、S03 无输出契约，S01 的预期输出是自然语言）。这直接解释了为什么 L1 三例仍全部未执行：缺的不是环境，是凭证与判定口径。
3. 覆盖率报告原来 9 行里"静态障碍"只有 S07/S08/S09 有值，等于把最容易判的一类漏了；本表已按上表替换，判定依据就是本节的原文引用。

## 3. 夹具自检

[预注册 §5](c-2b-preregistration-v1.md) 冻结了 8 行夹具口径，并要求"脚本、响应文件与测试应用工程须在首次执行前保存路径与哈希"。本批把**不依赖设备与模型**的 6 个做成可执行件，并新增自检脚本对照冻结口径：

| 夹具 | 冻结口径 | 自检判定 | 观测值（原始日志可核对） |
| --- | --- | --- | --- |
| S04-03a 超时服务 | 固定延迟 30s；T_timeout=10s；容差 +5s | PASS | 响应在 **29.40s** 后到达，`/health` 0.003s；`temperature` 正常返回 |
| S04-03b 缺字段响应 | 固定 JSON 缺 `temperature`；HTTP 200 | PASS | `temperature` 缺失、其余字段齐备；`data.get("temperature", 0)` 会静默得到 `0`——正是断言要禁止的填充 |
| S05-01 分页服务 | L1=Todo/L2=Doing/L3=Done；两页，每页 2 条 | PASS | 三列 `Todo/Doing/Done`；page0=2、page1=2、page2=0，去重后 4 张卡 |
| S05-02 无效凭据 | 固定 401；日志中不含 token | PASS | HTTP 401；访问日志含 `***` 且不含哨兵令牌（`leaked=False`） |
| S06-03 缺模板 | 模板 ID `__missing_template__` | REGISTERED | 参数夹具，无本地可执行产物；执行时须留 stdout/stderr 与退出码 |
| S08-03 stdio 异常 | 服务进程启动后立即退出 | PASS | 退出码 7、用时 0.005s、首行 JSON-RPC 错误 `fixture S08-03: server exited at startup` |
| S09-02 隐藏控件 | 测试应用隐藏"保存"按钮 | BLOCKED | 需鸿蒙测试应用与设备，本机无法成型 |
| S09-03 权限撤销 | 撤销界面读取权限后运行 | BLOCKED | 需鸿蒙测试应用与运行时权限撤销 |

登记文件：[`code/skill-vm/fixtures/manifest.json`](../../../../code/skill-vm/fixtures/manifest.json)，含每个文件的 `sha256`、自检观测值与 `selfcheck_sha256`。

| 文件 | SHA-256（前 16 位） |
| --- | --- |
| `s04-timeout-service.py` | `75f9e0515fcaf8e5` |
| `s04-missing-temperature.json` | `c4b60c50e0e450bf` |
| `s05-trello-paged.py` | `6ce8fcba74807762` |
| `s05-unauthorized.py` | `87436c11535b750f` |
| `s08-stdio-exit.sh` | `a456c2dd8f8ead02` |
| `selfcheck.py` | `eccbe906813ad560` |

两条判读纪律：

1. **夹具自检通过 ≠ 用例通过。** 自检只证明夹具"如约失败"（迟到、缺字段、401、秒退），被测客户端是否在 `T_timeout` 内给出正确错误，仍由用例记录判定，且仍需 P1 冻结。
2. **29.40s 不是夹具违约。** WSL2 的 `sleep` 有约 0.6s 的提前抖动；冻结断言是"客户端须在 ≤15s 内报超时"，与 30s 相差近 20s，抖动不影响故障分支的判定。若将来要求 ±5% 级精度（例如计时容差用于通过/失败），须改由客户端侧单调时钟计时，不能沿用本夹具的 wall-clock 观测值。

## 4. SkVM 的 L1 补跑

批次 03 的 SkVM 一列写作"阻断 6/9，未测 3/9（S01–S03 未补跑）"。本批在同一环境对三个 L1 样本各跑一次 `--pass=1 --dry-run`：

| 样本 | 退出码 | 关键原文 | 判定 |
| --- | --- | --- | --- |
| S01 | 1 | `Missing profiles: anthropic/claude-sonnet-4.6--openclaw` / `Run 'skvm profile' first.` | 阻断 |
| S02 | 1 | 同上 | 阻断 |
| S03 | 1 | 同上 | 阻断 |
| S01（`--adapter=harmonyos`） | 1 | `Invalid adapter: harmonyos. Valid: bare-agent, openclaw, opencode, hermes, jiuwenclaw, pi` | 失败（目标不被接受） |

新发现一条，比"缺密钥"更准确：`skvm config doctor` 显示 `~/.skvm/skvm.config.json not found`、`Providers · not configured`，而 `skvm profile` 的语义是**对模型实测原语能力**（`- Profile a model's primitive capabilities`，默认 `--instances=3`）。也就是说 SkVM 的阻断是三层叠加：

1. 没有 provider 路由配置；
2. 没有可用凭证；
3. 即便前两者就绪，`profile` 也需要**真的向模型发请求**跑原语电池，才允许后续 pass。

因此"给一个 key 就能跑"是不成立的说法，解除成本比此前记录的高一档。六项 `Valid` adapter 也再次确认：这个工具的目标集合里没有鸿蒙，缺的不是适配器配置。

## 5. 口径变化

| 指标 | 批次 03 后 | 本批后 |
| --- | --- | --- |
| 工具链覆盖（SkVM） | 阻断 6/9，未测 3/9 | **阻断 9/9，未测 0/9** |
| 工具链覆盖（SkCC） | 通过 5/9，部分通过 4/9 | 不变（S02 仍待 P7 裁决） |
| 样本"静态障碍"列 | 6 格待填 | **0 格待填**（依据本文件 §2） |
| 故障注入夹具 | 0 个成型 | 5 个可机检 + 1 个参数夹具；2 个需设备 |
| 完整本机覆盖 / 目标运行 / 原平台基线 | 0/9、未测 | **不变** |

SkVM 从 6 变 9 只说明"九个样本都在同一处被同一原因拦住"，不增加任何可移植性证据。反过来，它把"SkVM 路线"的环境结论钉死了：**该工具的输入要求（provider 路由 + 实测 profile）与输出目标（六种 agent 宿主）都与鸿蒙无关**。

## 6. 新增缺口

1. **S04-02 的夹具口径缺失。** [预注册 §4](c-2b-preregistration-v1.md) 把 S04-02（不存在城市）的依据写成"固定 fixture 返回，本地判定"，但 §5 的 8 行夹具表里没有它，响应内容、错误形态、"未知城市"与"服务错误"如何区分都未冻结。本批**没有**擅自补造该响应，改为登记为待确认项（P8）。在口径冻结前，S04-02 只能记"未测"。
2. **S09-02/S09-03 无法本机成型。** 它们需要的是一个鸿蒙测试应用（隐藏按钮、撤销权限），与 P3/E7 是同一条依赖链。
3. **夹具位置仍未定（P5）。** 现放在 `code/skill-vm/fixtures/`；若最终改放研究仓库附件，目录整体迁移后须用 `selfcheck.py --write-manifest` 重算登记，不能只搬文件。
4. **S08-03 只覆盖了"启动即退出"这一种异常。** 预注册只冻结了这一种；"握手成功但调用中途崩溃"未被覆盖，若要加，必须先在预注册追加变更记录（P6 允许的范围）。

## 7. 复现

```bash
# 夹具自检（无需网络与凭证，约 35s，其中 30s 是 S04-03a 的固定延迟）
python3 code/skill-vm/fixtures/selfcheck.py --write-manifest

# SkVM 对 L1 三个样本补跑
WORK=$HOME/c2b bash code/skill-vm/skvm-batch04.sh
```

原始日志（未入库，哈希可核对）：

| 日志 | 大小 | SHA-256 |
| --- | --- | --- |
| `batch04-fixtures-20261031T144840.log` | 1480 B | `5fb86c42f8f2ab42dcdb33b2985eae2aab26c643c56957a0102ccbcb48c7c3fc` |
| `batch04-skvm-20261031T144934.log` | 3985 B | `7f853acc19471c1a750df70ba1d7c84f7b04be817e6bb81fc4c2026b18b36215` |
