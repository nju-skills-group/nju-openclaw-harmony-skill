# 甲组阶段成果报告 · 鸿蒙智能体与 Skill 机制

截至 2026 年 11 月 14 日。甲组完成了 API 26 接入资料、自建 Agent 框架、应用 Skill 构建与运行对照、小艺和 Agent 调用路径实验，以及同一负载下的 ArkTS／WebView 性能测量。报告以主仓库已归档记录、G1-M1 交付和个人实验 C 的来源为准。各通过结论保留实际设备、版本、入口和用例的范围。[实验方案](harmonyos-skill-runtime-comparison-plan.md) · [11 月 1 日阶段记录](../../notes/meetings/progress-report-2026-11-01-甲组.md)

## 1. 工程与方法资料

| 成果 | 交付物和证据 |
| --- | --- |
| 环境与应用 Skill 接入 | 沉淀了 DevEco／SDK 26、Stage 工程和最小 Demo 的准备方式，以及技能描述、`skillProfiles`、Ability 绑定、脚本入参和结果回传的操作说明。[鸿蒙环境](../03-environment/harmony-setup.md) · [接入教程](../03-environment/deveco-skill-e2e-tutorial.md) · [格式与 API](../05-protocols/harmonyos-app-skill-format-and-api.md) · [模板](../05-protocols/harmonyos-app-skill-template.md) |
| 音乐助手接入示例 | 整理了华为官方示例的 `SKILL.md`、ArkTS 入口和项目内模拟业务服务，覆盖按歌名匹配和播放状态控制。服务使用内存曲库。[工程说明](../../code/ports/harmonyos-official-music-assistant/README.md) |
| G1-M1 自建 Agent 框架 | 四人完成规则路由、目录、执行器、桥接组件、两项应用 Skill、Demo 和验收材料。MateBook 签名安装及应用内执行通过，Pura 70 小艺调度两个 ArkTS Skill 的正常用例通过。[任务一交付总结](g1-m1-delivery-summary-2026-11-08.md) |
| OpenClaw 移植选型 | 给出平台 Skill、ArkTS 应用 Skill、自建 Agent 的适用场景、格式、工具绑定和验收要求。以 `weather` 当前天气子集保存三条路线的实现和真机记录。[移植指南](../05-protocols/openclaw-to-harmonyos-skill-porting-guide.md) · [weather 对照](weather-three-route-comparison.md) |

## 2. 实验 A 与 B · 入口格式和业务运行

| 实验项 | 已证实的结果 | 验证范围 |
| --- | --- | --- |
| A0 ArkTS 入口 | `.ets` 可按 `skillProfiles` 注册并构建。G1-M1 的 Pura 70 记录覆盖小艺到 ArkTS 脚本、业务执行与回传。 | 两个技能的正常输入，绑定固定版本和设备。 |
| A2 JS 直接入口 | 将 `srcEntries` 指向 `.js` 后，Hvigor `PreBuild` 报 `00303304`，要求 `.ets`。 | 当前 API 26 工程的构建层。本轮归档暂无 `.ts` 直接入口和其他后缀的独立结果。 |
| B0 ArkTS 业务基线 | 应用内执行通过。G1-M1 也以 ArkTS 实现回显和长度，用同一实现完成手机系统正常调用。 | 性能 Demo 与 G1-M1 是两套工作负载。 |
| B2 普通 JS helper | ArkTS 入口导入 `EchoBusiness.js`，隔离副本成功构建 HAP。另一个探测工程将普通 Ability 和页面换成 JS 也构建通过。 | JS helper 变体的系统调度尚未验证。普通应用主模块单独记录。 |
| B3 本地 WebView JS | ArkTS 应用通过 ArkWeb 桥接调用本地页面 JS，真机记录含正常查询和五种异常场景。缺失函数和页面抛错在本轮均观察到 Promise 仍 resolve。 | 完整小艺调度至 WebView 的系统路径未取证。远端页面和 Native/C++ 暂无本轮实测结论。 |

[实验记录与构建错误](harmony-skill-experiment-record.md) · [非 ETS 主模块探测](../../code/experiments/harmonyos-main-nonets-probe/README.md) · [WebView 真机记录](../../code/harmonyos-runtime-experiment/bench/RESULTS.md)

## 3. 实验 C · 智能体调用路径

| 路径 | 当前验收 |
| --- | --- |
| C1 小艺 → 华为原生计时器 | 本人 MateBook 上，`CreateTimer` 意图及 `TimerService` 对应 23 秒倒计时。通过范围是官方原生 Intents Kit 路径。 |
| C2 小艺 → 自定义 ArkTS 应用 Skill | 团队 Pura 70 的 `g1-echo` 和 `g1-text-length` 正常调用通过。个人 MatePad 回执 Skill 已核对包管理注册，但小艺加载未通过，工单待平台给出请求级记录。 |
| C3a 自建 Agent → App 函数／Ability | 本人 MatePad 的本地函数与 `startAbilityForResult` 调用均返回正确 UUID，未匹配用例也通过。 |
| C3b 自建 Agent → Skill 文件 → 工具 | 本人 MatePad 上天气文件加载、规则匹配、HTTP 200 和结果有同请求日志，缺城市、超时和禁用对照通过。 |
| C4 小艺 → 端侧 A2A | 本人 MatePad 上 `LabAgentExtension` 收到 `Execute`、生成并回传 UUID。实际任务往返通过，认证握手待单独取证。 |
| C5 小艺 → 云侧 A2A | 本人部署的 HTTPS 服务通过 API Key 鉴权，接收 JSON-RPC `message/stream` 并以 SSE 回传，界面与服务端 UUID 一致。 |

天气三路线中，自建 Agent 已有独立执行链路证据。小艺 Work 的平台 Skill 返回了符合规程的字段，工具实际执行归属待核验。ArkTS 天气应用 Skill 已安装并发布真机测试，MatePad 的「Skill真机测试中」仍未出现，主对话探测未捕获目标脚本执行。OpenClaw 原端已固定源码和数据源请求形态，运行基线仍待复测。[个人实验 C 报告](experiment-c-independent-report-2026-11-14.md) · [天气对照明细](weather-three-route-comparison.md)

## 4. 实验 D · MateBook 运行性能

2026 年 11 月 4 日，使用同一 HarmonyOS PC、同一 50,000 项排序与累加负载，比较应用内 ArkTS 和通过 ArkWeb 执行的本地 JS。两轮热路径各实现均有 30 个有效样本且校验和一致。下表报告第二轮，第一轮用于检查复现性。[测量方法、两轮数据和原始日志](../../code/harmonyos-runtime-experiment/bench/RESULTS.md)

| 指标 | ArkTS | ArkTS → WebView JS |
| --- | ---: | ---: |
| 热路径中位数 | 79 ms | 22 ms |
| 热路径 P95 | 94 ms | 23 ms |
| 成功样本 | 30/30 | 30/30 |
| 桥接耗时中位数 | 0 ms | 1 ms |

WebView 从组件创建到页面加载完成为约 362 ms，其中页面自身加载约 9–10 ms。应用进程 PSS 约从 40.2 MB 上升至 96.7 MB，300 次调用期间峰值约 97.1 MB。在本设备和该负载下，WebView JS 热路径更快，同时存在冷加载和常驻内存成本。现有样本支持应用内运行对比。小艺完整调度延迟、模拟器对照和跨设备性能仍缺数据。[测量口径](harmonyos-skill-runtime-comparison-plan.md#7-实验-d性能对比协议)

## 5. 尚待验收的项目

| 项目 | 完成条件 |
| --- | --- |
| 个人应用 Skill | 平台核查 MatePad 测试版本下发和入口启用。环境就绪后，按同一请求核对小艺调度、ArkTS 入口和结果回传。 |
| 自建 Agent 主动调度系统 Skill | 确认可用的发起接口、调用资格与回传契约，再接入真实适配器。G1-M1 的真实外部连接、认证、并发和完整 E01 链路按各自用例补证。 |
| 移植对照 | 取得小艺 Work 的目标技能加载和工具调用证据，在 OpenClaw 原端复测同一业务输入，核对各路线正常和异常行为。 |
| 入口和性能覆盖 | 若继续扩展实验，分别补测 `.ts` 入口、普通 JS helper 的系统运行、完整系统调用延迟与多设备对照。 |

现阶段交付包括可复现工程、测试操作、可公开的日志及截图和未通过项记录。各报告中的签名 HAP 哈希用于标记被测版本。使用自己的调试签名和测试账号可重新构建与复测。
