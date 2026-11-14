# 甲组实验 C 执行记录

2026 年 11 月 12 日，北京时间。按[实验方案第 6 节](harmonyos-skill-runtime-comparison-plan.md#6-实验-c智能体调用路径)保留当日 C1 观测、G1-M1 历史证据和初测。本记录反映开始独立复测前的状态，后续个人结果见[实验 C 个人报告](experiment-c-independent-report-2026-11-14.md)。当日真机为 HUAWEI MateBook 14 MNTXM-24B，HarmonyOS `MNT-W72C 7.0.0.111(SP12C00E103R12P2)`，API 26，小艺 `11.7.9.300`。Windows 端通过 HDC USB 连接，DevEco Studio `26.0.0.851`，SDK `26.0.0.105`。

| 分组 | 进度 | 仍需取得的证据 |
| --- | --- | --- |
| C1 小艺 → 官方原生 Skill | MateBook 上华为时钟「启动计时器」通过。系统匹配 `CreateTimer`，调度返回 `code: 0`，计时服务收到约 23 秒启动参数，用户确认倒计时开始 | 调用类型为 Intents Kit。录屏由用户归档 |
| C2 小艺 → 自定义 Skill | MateBook 用正式名称复测。办公入口搜索本地技能目录，主对话返回通用拒答，两轮均未取得目标脚本执行证据。G1-M1 已有 Pura 70 正常调用证据 | 核对当前测试发布和账号资格，恢复平台所绑定的签名包。入口就绪后采集同一请求的调度、脚本进入、回包及界面结果 |
| C3 自建 Agent → Skill / Ability | G1-M1 结构检查、28 项核心检查及签名构建通过。MateBook 上独立测试包安装、启动及四项应用内调度用例通过 | 真实外部组件连接、鉴权、主动发起系统 Skill 调用及目标 Ability 链路待验证 |
| C4 端侧 A2A | 未联调 | 确认受支持的设备、关联应用及真实 A2A 协议适配。记录连接、鉴权、请求和返回。[华为端侧接入指南](https://developer.huawei.com/consumer/cn/doc/service/device-a2a-quickstart-0000002733266338/) |
| C5 云侧 A2A | 未联调 | 准备公网 HTTPS 服务及鉴权，在小艺开放平台完成调试，关联客户端与服务端同一请求。[华为云侧接入指南](https://developer.huawei.com/consumer/cn/doc/service/cloud-a2a-quickstart-0000002762825847/) |

## C1 官方原生 Skill 调用

在 MateBook 的小艺主对话输入「启动一个 23 秒的计时器」。系统时钟包为 `com.huawei.hmos.clock`，设备包管理器读回 `isSystemApp: true`，版本为 `17.0.0.130`。华为将启动计时器列为小艺技能，Intents Kit 的官方能力也包括经小艺对话发起技能调用。[华为小艺技能清单](https://consumer.huawei.com/cn/support/content/zh-cn16071005/)、[Intents Kit 官方说明](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/intents-introduction/)

| 检查点 | 观测 |
| --- | --- |
| 匹配 | `14:33:07.639`，`AIDispatch` 选择系统时钟的 `CreateTimer` 意图，模式为前台执行 |
| 目标调用 | `14:33:07.686`，系统执行 `CreateTimer`，目标模块为 `pc`，绑定的 UIAbility 为 `com.huawei.hmos.clock.phone` |
| 系统结果 | `14:33:07.927`，`AIDispatch` 记录 `callAms success` 和 `code: 0` |
| 业务和可见结果 | `14:33:08.412`，`TimerService.onRequest` 收到 `serviceType=Start`、`alarmAlertTime=22999`。用户确认屏幕启动 23 秒倒计时 |

**判定：官方原生计时器技能的 Intents Kit 路径通过。** 本轮设备日志对应 `CreateTimer` 意图及 `TimerService`。若验收专指 `skillProfiles` 注册的 ArkTS 应用 Skill，还需要采集该类型的脚本入口和回包。录屏由用户自行归档。[同轮真机日志](experiment-c-evidence/c1-official-timer-hilog.txt)

先前「打开计算器」用例保留为原生应用操作基线。13:44:27.834 小艺解析出 `com.huawei.hmos.calculator`，13:44:27.967 发出 `StartAbility`，13:44:28.133 计算器窗口获得焦点，用户确认应用打开。[基线日志](experiment-c-evidence/c1-calculator-hilog.txt)

## C2 发现与执行

以下为当日使用既有项目进行的早期排查。个人从零复测及结果见[C2 个人独立真机实验](c2-independent-2026-11-12.md)。

| 入口和版本 | 观察 | 判定 |
| --- | --- | --- |
| MateBook，小艺主对话，旧「回声测试」 | 输入「调用回声测试技能执行 C2-20261112-K7Q4」。用户报告回复「我无法满足您的该需求。如果您有关于日常问答或产品咨询的其他问题，我很乐意为您解答。」筛选日志未出现目标执行记录 | 该次调用未证明匹配或执行 |
| MateBook，小艺办公，旧「回声测试」 | 用户转述界面显示「任务已完成」，正文称当前设备可用技能列表中没有「回声测试」，因此无法执行 `C2-20261112-K7Q4`，并询问是否搜索远程技能库 | 记录为该入口报告未发现技能。账号资格、平台发布状态与客户端能力仍需核对 |
| MateBook，小艺主对话，测试入口检查 | 用户查看输入框上方，未看到「Skill真机测试中」 | 该设备的真机测试入口本轮未就绪，未用 G1-M1 发起新的正式系统调用 |
| MateBook，小艺办公，正式 `G1M1文本回显` | 14:42:16 `HwVA_FindSkillsTool` 发出 `CLAW_TYPE=LOCAL` 搜索。采集窗口未出现目标 Skill 调度、脚本进入或回包 | 已确认办公入口发起本地目录搜索。目标脚本执行未证实。[搜索日志](experiment-c-evidence/c2-matebook-work-hilog.txt) |
| MateBook，小艺主对话，正式 `G1M1文本回显` | 用户确认切换到「对话」后回复「我无法满足您的该请求。如果您有关于日常问答或产品咨询的其他问题,我很乐意为您解答。」14:52:17 从设备当前 HiLog 缓冲区查询测试串及目标调度、执行、回包标记，匹配 0 条 | 无同轮正向调用证据。该次日志为事后读取，缓冲区覆盖范围未确认 |
| Pura 70，小艺主对话，G1-M1 历史版 `ab9691f` | 包名 `com.g1m1.skillagent`。回显 `T8P2-鸿蒙-47` 与 UTF-16 长度 `42` 均有 `execCli2`、脚本入口、上报及小艺接收记录。本轮运行仓库 `verify-d-evidence.mjs`，两份已归档日志均通过一致性检查 | 历史手机环境的正常调用通过，无效参数分支待测。[手机原始证据](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/records/2026-11-07-D-system-skill/report.md) |

**当前设备部署。** 平台历史发布绑定 `com.yaorz26.g1m1.skillagent`。本轮 HDC 只查到 C3 用的 `com.yaorz26.g1m1.skillagent.c3test1112`。副本 HAP 包含 `2in1` 及两项 `skillProfiles`，其应用包名与原发布不同。原包名的本机签名 HAP 安装返回 `9568332 install sign info inconsistent`。[华为安装错误说明](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/bm-tool/)

**当前平台核对。** 在用户已登录的小艺开放平台进入 `Skill` 工作台。未填写搜索条件时列表显示「暂无数据」「共 0 条」，按正式中文名 `G1M1文本回显` 搜索仍为 0 条。当前登录的工作台范围内没有可打开的 G1-M1 项目，因此本轮无法从该账号读回原项目的当前发布入口、有效期和真机测试组。项目管理列表的可见性与设备账号是否已在测试组需要分别核实。

**入口未就绪的原因仍需核对。** 团队 11 月 8 日已在该型号及小艺 `11.7.9.300` 上验证了原包名签名安装、主对话真机测试重新发布和测试组激活，当时仍没有「Skill真机测试中」。该次发布配置读回 `availableOn=[cloud]`，保存 `pc` 的尝试返回 `100000112`。这说明恢复安装是当前部署所需，但仍需要核对 PC 端可见范围、当前发布入口及账号资格。[MateBook 平台排查](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/records/2026-11-08-A-platform-config-client/report.md)、[华为 Skill 配置规范](https://developer.huawei.com/consumer/cn/doc/service/skill-development-standards-0000002592931546/#availableon-字段)

下一轮由能打开 G1-M1 项目的成员核对平台注册名 `yaorz26-g1m1-echo-20261107` 和 `yaorz26-g1m1-text-length-20261107`、当前测试组成员、发布入口与有效期，准备匹配该发布的原包名签名 HAP。小艺显示「Skill真机测试中」后，以新测试串复测，核对 `execCli2`、`system_skill_entered`、`system_result_reported`、`replyCliResult` 及界面回复。[G1-M1 真机手册](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/system-skill-device-runbook.md)、[华为真机测试说明](https://developer.huawei.com/consumer/cn/doc/service/skill-real-machine-testing-0000002592771628/)

## C3 团队工程复测

工程固定为 G1-M1 `c2cbc3aa3019b241cc81eec15ca7e26d97383735`。用 DevEco 内置 Node `24.14.1` 执行 `tools/check-structure.mjs` 和 `tools/check-core.mjs`，分别通过工程结构检查和 28 项核心检查。运行工程自带的 `tools/build-hap.ps1`，初次未签名构建完成 34 项 Hvigor 任务。[固定源码](https://github.com/yaorz26/skill-for-harmony-G1-M1/tree/c2cbc3aa3019b241cc81eec15ca7e26d97383735)

用户完成调试签名后，本机将已有 `default` 签名配置关联到同名构建产品，重新生成 `entry-default-signed.hap`（162642 字节，SHA-256 `38B66C6D0E3736611FD33FD352070DA025A4E46CA7FDBB803E80C3BBB9D47A89`）。HAP 清单为 `com.yaorz26.g1m1.skillagent`、版本 1.0.0、含 `2in1` 和 `AgentExtensionAbility` 注册。`hdc install` 返回 `9568332 install sign info inconsistent`。HDC 未查询到可启动的同包名安装，既有签名冲突的具体来源未确认。[华为安装错误说明](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/bm-tool/)

为保留设备原有数据，已从固定源码导出单独的 C3 调试副本。副本在应用清单和 AgentCard 中使用 `com.yaorz26.g1m1.skillagent.c3test1112`，业务源码沿用固定版本。副本通过结构检查、签名构建和 HDC 安装，`EntryAbility` 已启动。签名 HAP 为 162311 字节，SHA-256 `4A9843F967BCA099F527623040BE155D39C65BD50CB8F8B2CE3A54BA2A5ABA8F`。C2 仍使用开放平台已登记的包名和 Skill 名称。

14:20:30 至 14:20:48，先回读每条 UI 输入，再执行并读取结构化结果。每条用例用同一 `requestId` 关联 UI 结果和 `[G1M1]` 日志。[C3 真机结果与逐请求日志](experiment-c-evidence/c3-g1m1-matebook.json)

| 用例 | 实际输入 | 实际结果 | 判定 |
| --- | --- | --- | --- |
| 回显 | `回显 你好，鸿蒙`（演示页内置示例） | `你好，鸿蒙`，`g1-echo` | 通过 |
| 文本长度 | `长度 你好ABC` | 5 个 UTF-16 码元，`g1-text-length` | 通过 |
| 未命中 | `查天气` | `ERR_NO_SKILL` | 通过 |
| 缺参数 | `回显` | `ERR_INVALID_PARAMS` | 通过 |

四条日志的 `executionPath` 都为 `in-app`。两条成功请求均有接收、匹配、业务开始、业务结束和回包。两条错误请求在业务开始前返回。完整 C3 仍需用具备资格的调用方验证 `AgentExtensionAbility` 连接、鉴权、数据和回传，并取得主动调用系统 Skill 及目标 Ability 的证据。团队在公共 SDK 中尚未找到普通应用可以用来主动执行系统 Skill 的接口。[G1-M1 接入边界核查](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/records/2026-11-08-A-call-boundaries/report.md)
