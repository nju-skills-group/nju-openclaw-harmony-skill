# 甲组实验 C 报告 · 鸿蒙智能体调用路径个人复测

**实验时间** 2026 年 11 月 12 日至 14 日，以下时间均为北京时间（UTC+8）。
**实验范围** 使用本人 MateBook、MatePad、华为开发者账号、个人真机测试组和华为云服务器。C2–C5 使用独立实验工程和本轮采集的结果。C1 使用本人 MateBook 上的华为预装时钟。验收依据为甲组实验方案的 C1–C5 调用路径和证据要求。[实验方案](harmonyos-skill-runtime-comparison-plan.md#6-实验-c智能体调用路径)

## 1. 摘要

本轮比较小艺调用系统原生能力、调度自定义鸿蒙应用 Skill、自建 Agent 在应用内执行，以及端侧和云侧 A2A。C1 通过华为时钟计时器验证 Intents Kit 调用。C2 完成个人应用构建、安装、平台真机测试发布及设备包管理侧注册自查，主对话仍报告加载失败。C3a 跑通本地函数和 Ability 回传，C3b 跑通技能文件加载与天气工具执行。C4 与 C5 均完成对话往返，界面回执与各自执行端日志一致。

| 分组 | 本轮验收结论 | 关键证据及范围 |
| --- | --- | --- |
| **C1 小艺 → 官方原生 Skill** | **通过，Intents Kit 路径** | `CreateTimer` 调度成功，华为时钟收到启动参数，用户看到 23 秒倒计时。 |
| **C2 小艺 → 自定义应用 Skill** | **端到端未通过，已提交工单** | MatePad 可查询注册信息。小艺主对话报告加载失败，可见日志无 `skill_entered`，界面无 UUID。 |
| **C3a 自建 Agent → 本地函数／Ability** | **应用内路径通过** | 两个正例有 UUID，一个无关请求走未匹配分支。 |
| **C3b 自建 Agent → 独立 Skill → 工具** | **W1–W4 通过** | 同一请求关联技能文件加载、规则匹配、HTTP 200 和界面结果，缺参、超时和禁用对照均符合预期。 |
| **C4 小艺 → 端侧 Agent** | **端到端通过** | MatePad 上的 `LabAgentExtension` 接收 `Execute` 并生成 UUID。认证握手未单独验证。 |
| **C5 小艺 → 云侧 Agent** | **端到端通过** | 小艺通过 HTTPS 和 Header API Key 发起请求，云端以 SSE 回传，界面 UUID 与服务日志一致。 |

## 2. 环境与取证方法

| 环境 | 本轮配置 | 用途 |
| --- | --- | --- |
| Windows 开发主机 | DevEco Studio `26.0.0.851`、SDK `26.0.0.105`，HDC USB 连接 | 构建、个人调试签名、安装与读取 HiLog |
| HUAWEI MateBook 14 | `MNT-W72C`，HarmonyOS `7.0.0.111 (SP12C00E103R12P2)`，API 26。C1 记录小艺 `11.7.9.300`，C2 后续核对为 `11.7.9.301` | C1 原生计时器、C2 电脑初测 |
| HUAWEI MatePad 11.5″S | `TGR-W00`，HarmonyOS `7.0.0.111 (SP18C00E111R2P2)`，API 26.0.0。C2 初测小艺 `11.7.8.339`，天气应用 Skill 复核读回 `11.7.9.301` | C2 平板交叉验证、C3 应用内路由与天气 Skill、C4 端侧 A2A |
| 本人华为云服务器 | Ubuntu 24.04，Node.js 22，Nginx HTTPS 反向代理，`/a2a`，无状态通信 | C5 云 A2A，后端接收 JSON-RPC `message/stream` 并用 SSE 回传 |

每条路径按「触发 → 匹配或路由 → 目标执行 → 返回结果」取证。C1 将系统调用时间、目标意图、启动参数与用户观察到的倒计时对应。C2–C5 使用带测试码的回执。成功用例以请求或任务 ID 关联日志，再核对测试码和 UUID。C2 同时记录包管理侧注册查询和小艺侧加载结果。C5 用连通性探测和真实对话分别验证鉴权与业务回传。[统一成功判定](harmonyos-skill-runtime-comparison-plan.md#8-统一成功判定)

## 3. 分项实验

### C1 · 小艺调用华为原生计时器技能

**操作** 在 MateBook 小艺主对话输入「启动一个 23 秒的计时器」。华为将「启动计时器」列为小艺技能。设备包管理器确认时钟包 `com.huawei.hmos.clock` 为系统应用，版本 `17.0.0.130`。[华为小艺技能说明](https://consumer.huawei.com/cn/support/content/zh-cn16071005/) · [Intents Kit 简介](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/intents-introduction/)

| 11 月 12 日 | 观测 |
| --- | --- |
| 14:33:07.639 | `AIDispatch` 匹配时钟的 `CreateTimer` 意图，采用前台执行。 |
| 14:33:07.686 | 系统执行 `CreateTimer`，目标模块为 `pc`，绑定 `com.huawei.hmos.clock.phone`。 |
| 14:33:07.927 | `callAms success`，`code: 0`。 |
| 14:33:08.412 | `TimerService.onRequest` 收到 `serviceType=Start`、`alarmAlertTime=22999`。用户确认 23 秒倒计时启动。 |

**判定** 华为原生计时器技能的 Intents Kit 路径通过。若验收指定 `skillProfiles` 注册的官方 ArkTS 应用 Skill，需另取该类型的脚本入口与回传证据。先前的「打开计算器」保留为系统应用启动对照。计时器录屏由用户自行归档，仓库保存同轮日志摘录。[计时器 HiLog](experiment-c-evidence/c1-official-timer-hilog.txt) · [计算器对照日志](experiment-c-evidence/c1-calculator-hilog.txt)

### C2 · 小艺调度自定义 ArkTS 应用 Skill

**操作** 用个人账号为独立包 `com.skilllab.c2pc089e5768` 签名，随 HAP 打包回执技能的 `SKILL.md` 和编译后的 ArkTS 入口。将签名包安装到目标设备，导入个人开放平台并向个人测试组发布。平板版注册名为 `tablet-test-receipt-089e5768`，目标方法为 `ReceiptSkill.issueReceipt`。期望小艺传入测试码，脚本记录进入事件，生成 UUID 并回传。[C2 工程](../../code/experiments/harmonyos-c2-independent/README.md) · [构建、签名与复测记录](c2-independent-2026-11-12.md)

| 检查 | 本轮结果 |
| --- | --- |
| MateBook 主对话 | 个人组发布成功，设备快捷区未见「Skill真机测试中」。普通对话探测无可归因于该脚本的回执。 |
| 小艺 Work | MateBook 复制至技能目录时出现只读错误。平板 Work 后来报告安装成功，其下载 ZIP 只含 `SKILL.md`。另行核验的签名 HAP 含已编译的脚本入口，两份产物分别记录。 |
| MatePad 注册 | 11 月 13 日 22:14:49，同包名、同签名及同 Skill 声明的诊断 HAP 调用 `getSkillInfoForSelf` 成功，返回 `EntryAbility`、`visibility=system` 和预期 `srcEntries`。诊断后恢复实验 HAP。 |
| MatePad 主对话 | 使用显示名和唯一注册名复测，界面显示调用步骤，随后报告加载失败。22:27 复现以及重启后 22:44 复测均无可见 `skill_entered` 日志和 UUID 回执。 |
| 错误与工单 | 同期有 `remote is null`。重启后还出现 `SkillLoad.json` 的 `Invalid relative path`，同一时段其他工具资源也有类似警告。用户已提交华为工单，等待请求级证据确认失败环节。 |

**判定** 签名部署和包管理侧注册自查有证据，主对话端到端调度未通过。客户端界面的「调用执行」表明尝试调用。现有错误日志缺少该次请求的 ID 和底层错误码，具体故障点、`availableOn` 下发值及候选错误码 `16000050` 均待华为核实。复查时可用重启后用例 `PAD7-RCPT-REBOOT-K6R9` 和 11 月 13 日 22:44:16–22:44:36 的窗口检索对应的加载及调度记录。[C2 复测日志摘录](c2-independent-2026-11-12.md#matepad-重启后复测)

### C3a · 自建 Agent 应用内路由

**操作** 在本人 MatePad 上安装独立包 `com.skilllab.c34agent089e5768`，从 App 的测试页面分别触发本地处理器和回执 Ability。应用按回执指令格式做本地匹配。Ability 路径用 `startAbilityForResult` 传入请求，由 `ReceiptAbility` 执行业务并回传。[C3/C4 工程与操作说明](../../code/experiments/harmonyos-c3-c4-independent/README.md)

| 用例 | 输入 | 实测结果 |
| --- | --- | --- |
| 本地函数 | `生成回执 C3-PAD-LOCAL-2M5X` | 界面显示测试码与 `e9a83c48-e353-474b-84f4-21b307025278`。 |
| Ability | `生成回执 C3-PAD-ABILITY-6KQ9` | 界面显示测试码与 `c7c30810-bd76-4ed6-9d0a-2783ffbcb558`，与日志一致。 |
| 未匹配负例 | `查看天气` | 界面提示输入回执指令，日志记录 `agent_match` 为 `no_match`。 |

**判定** 本地匹配、两条执行路径和负例通过。11 月 13 日 23:54:43，Ability 用例从 `agent_match` 到 `agent_result` 共用请求 ID `2553b901-0d1f-4764-8c54-c83cb70ad77d`，其中包含 `ability_requested`、`ability_entered` 和 `ability_result`。普通第三方 Agent 主动调度鸿蒙注册 Skill 的公开执行接口仍待确认。对这条扩展路径，需要先核对支持的调用接口和权限，再用入口日志和回传做验收。[C3 请求记录](c3-c5-independent-2026-11-13.md#c3-自建-agent-路由)

### C3b · 自建 Agent 加载独立天气 Skill

以 OpenClaw bundled `weather` 为源样本，将单城市当前天气移植为相同业务目标下的三种实现。MatePad 的自建 Agent 从 HAP 资源读取独立技能目录中的 `SKILL.md`，将匹配的请求交给已注册的 `get_current_weather` 工具。鸿蒙网络实现请求 `wttr.in`。自建 Agent 使用本项目定义的工具绑定与触发规则。

| 路线 | 本轮结果 |
| --- | --- |
| 自建 Agent | 正常查询由同一请求 ID 关联文件加载、匹配、实际 HTTP 200 和结果。南京返回 14 °C、`Light drizzle`，观测时间保留原值。缺城市时询问，1 ms 受控用例返回超时，禁用后无工具请求。 |
| 小艺平台 Skill | 小艺 Work 报告安装，苏州结果符合四字段规程。工具名称、HTTP 状态来自界面文字，实际加载和工具执行仍缺独立证据。 |
| 鸿蒙应用 Skill | 签名 HAP 已安装，个人组已发布。小艺主对话缺「Skill真机测试中」快捷方式，普通对话探测无脚本执行或回传记录。 |

OpenClaw 原端只核对了固定源码。另有 `curl` 的数据源连通性记录，原端 Agent 调用仍待复测。[三路线对照与用例](weather-three-route-comparison.md) · [W1–W4 真机日志](experiment-c-evidence/c3b-weather-matepad-hilog.txt)

### C4 · 小艺调用 MatePad 端侧 Agent

**操作** 在小艺开放平台选择端 A2A，关联个人 App，服务名填 `LabAgentExtension`，导入 `agent_config.json`。导入时平台拒绝 AgentCard 的 `appInfo.deviceTypes` 包含 `2in1`。调整为 `phone` 和 `tablet` 后，平台可选中 Agent，测试继续在 MatePad 进行。初测日志已有 `Execute`，部分请求没有生成回执，界面未显示回复。新版改用 `getUserInput` 读取输入，并通过 `addArtifact` 返回文本产物，再发任务完成状态。构建并覆盖安装签名包后复测。[端侧接入指南](https://developer.huawei.com/consumer/cn/doc/service/device-a2a-quickstart-0000002733266338/) · [C4 部署与结果](c3-c5-independent-2026-11-13.md#c4-端侧-a2a)

| 11 月 14 日 | 成功请求的 MatePad 日志 |
| --- | --- |
| 01:41:04.121 | `a2a_connected`，端侧扩展接到连接。 |
| 01:41:04.133 | `a2a_data`，随后 `a2a_method` 记录 `Execute`，任务 ID 为 `task-3d5e164d-932a-472b-b8cb-08411a30e2ec`。 |
| 01:41:04.139–01:41:04.141 | `a2a_receipt` 生成 `C4-PAD-01 fb52fd0e-91cb-4aea-9138-d8fa49f26002`，随后记录 `a2a_sent`。 |

**判定** 用户确认小艺显示同一测试码和 UUID，连接、执行与回包通过。成功请求的留存日志覆盖实际任务往返。若需要独立证明协议认证握手，仍须采集相应的认证事件及结果。[C4 个人记录](c3-c5-independent-2026-11-13.md#c4-端侧-a2a) · [同轮日志摘录](experiment-c-evidence/c4-matepad-a2a-hilog.txt)

### C5 · 小艺调用华为云上的 Agent

**操作** 将独立回执服务部署在本人华为云服务器，使用 Nginx 提供公网 HTTPS。在小艺开放平台配置无状态通信、API Key Header 鉴权和静态开场语。服务用 JSON-RPC `message/stream` 接收任务并返回 SSE `artifact-update`。按「无密钥拒绝 → 带密钥探测 → 真实对话」验证。[C5 服务代码与配置](../../code/experiments/cloud-c5-independent/README.md) · [华为云 A2A 会话协议](https://developer.huawei.com/consumer/cn/doc/service/message-stream-0000002763022677/)

| 检查 | 观测 |
| --- | --- |
| 服务自测 | 无凭据返回 `401`，正确凭据的 GET 返回 `200`，畸形 JSON 返回 `-32700`，有效请求可收 SSE 回执。 |
| 平台初测 | 11 月 14 日 02:32:01，小艺 GET 与 POST 到达后端，均返回 `401`。旧日志未记录凭据头的情况。 |
| 平台复测 | 轮换密钥并改用 `X-API-Key` 后，02:40:31 平台 GET 返回 `200`，服务记录 `auth_probe_ok`。两项同时变更，原 401 的具体原因未单独确认。 |
| 真实对话 | 02:43:58.764，`生成回执 C5-CLOUD-01` 触发 `message_received` 和 `response_sent`。请求 ID 和任务 ID 均为 `712ccb1d-e829-5d38-a3d3-aace7346&1`。 |

**判定** 小艺界面显示 `C5-CLOUD-01 c1dad151-d7c8-47fb-8c69-ce67f3032429`，与服务端日志一致。云侧 A2A 的平台鉴权、业务执行和结果回传通过。[C5 日志核对记录](c3-c5-independent-2026-11-13.md#c5-云侧-a2a) · [华为 A2A 基础配置](https://developer.huawei.com/consumer/cn/doc/service/a2a-basic-configuration-0000002746111014/)

## 4. 结论与剩余验证

C1 提供了小艺经系统意图执行预装应用功能的对照。C3、C4 和 C5 均能产生相同形式的 UUID 回执，执行入口依次是 App 内部、MatePad 上的端侧 Agent、华为云上的服务。对移植样例，应按照所选入口核验对应执行日志。若交付要求经鸿蒙应用 Skill 框架触发，则需像 C2 一样观察系统调度、ArkTS 入口及回传三段证据。

- **C2** 根据工单反馈核对目标设备下发记录、Skill 加载及 ArkTS 调度的首个失败步骤。修复后在同一版本用三个不同测试码和一个非触发用例复测，逐条核对入口日志、UUID 和界面结果。
- **天气对照** 补采小艺 Work 的技能加载与工具调用证据、应用 Skill 的系统调度与回传，以及 OpenClaw 原端 Agent 基线。普通第三方 Agent 主动调度鸿蒙已注册 Skill 的接口继续作为平台能力调研项。
- **C1 和 C4 的附加验收** 若课题验收明确要求官方 ArkTS 应用 Skill 或独立认证握手证据，分别补采相应链路。C1 录屏由用户归档，提交完整材料时可附上。

本报告是功能与调用路径验证。每条路径的通过范围限于所列设备、版本、测试入口和用例。样本量、网络环境与冷启动条件未按性能实验控制，因此耗时对比留在独立性能实验中开展。[性能对比协议](harmonyos-skill-runtime-comparison-plan.md#7-实验-d性能对比协议)

团队成员在 Pura 70 上采集的小艺应用 Skill 成功日志，以及最初沿用 G1-M1 的 MateBook 验证，均为有独立来源和版本的历史记录。本报告的个人验收使用上述独立工程和本轮数据。[G1-M1 团队交付](g1-m1-delivery-summary-2026-11-08.md) · [11 月 12 日历史执行记录](experiment-c-2026-11-12.md)
