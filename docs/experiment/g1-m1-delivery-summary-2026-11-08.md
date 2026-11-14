# 甲组任务一 · G1-M1 鸿蒙自建 Agent 框架交付总结

交付日期为 2026 年 11 月 8 日。依据 G1-M1 主线固定提交 `c2cbc3aa3019b241cc81eec15ca7e26d97383735` 的最终交付索引、验收表和原始记录。以下成果由 G1-M1 四人小组完成，供甲组任务二对照。[源仓库固定版本](https://github.com/yaorz26/skill-for-harmony-G1-M1/tree/c2cbc3aa3019b241cc81eec15ca7e26d97383735) · [最终交付索引](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/delivery-index.md)

## 已交付成果

| 成果 | 实现和验证 |
| --- | --- |
| 自建 Agent 框架与 Demo | 基于 HarmonyOS Stage、ArkTS、API 26。应用页把输入交给 `AgentService`，经规则路由、技能目录、执行器和调用适配器进入业务函数。统一输入输出、错误码和请求 ID 日志。Demo 支持文本回显、UTF-16 长度、未匹配和无效参数。 |
| 两个 ArkTS 应用 Skill | `g1-echo` 和 `g1-text-length` 各有 `SKILL.md`、ArkTS 入口和 `skillProfiles` 映射，系统入口与 App 内演示复用业务实现。 |
| Agent 组件和桥接 | 实现并注册 `AgentExtensionAbility`，提供 AgentCard、连接隔离、JSON 请求处理和重复请求处理。组件保持非导出，编译与本地替身检查已有记录。 |
| 工程验证与交接 | DevEco／SDK 26 构建成功。结构、共享核心、A 入口、C 执行器及证据工具五组主机检查通过，其中共享核心 28 项、A 入口 32 项、C 执行器 18 项。已归档调度图、构建与换设备手册、验收表、版本和证据索引。 |

[架构与调度流程](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/architecture.md) · [交付审查](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/reviews/2026-11-08-final-delivery-review.md)

## 真机验证

- **Pura 70，小艺主对话。** 2026 年 11 月 7 日，HarmonyOS `7.0.0.111`、API 26、小艺 `11.7.8.339`。源码 `ab9691f`，应用包名 `com.g1m1.skillagent`。组员在主对话启用「Skill真机测试中」后，回显正例返回原文，长度正例返回 `42` 个 UTF-16 码元。两条 HiLog 都记录了小艺 `execCli2`、对应脚本、同一请求的 `system_skill_entered` 与 `system_result_reported`，以及小艺收到 `replyCliResult`。系统无效参数分支未取得脚本入口证据。[手机报告](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/records/2026-11-07-D-system-skill/report.md)
- **MateBook 14，应用内运行。** 源码 `c7d23d7`、应用包名 `com.yaorz26.g1m1.skillagent`。签名安装、13 笔应用内请求和 9 项自检断言通过。超时和异常注入使用执行器测试替身，连续请求为顺序测试。小艺端已重新发布测试并更新客户端，设备仍未出现测试快捷方式，也未采集到该版本的系统脚本执行证据。[PC 运行记录](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/records/2026-11-07-A-account-bundle-device/report.md) · [PC 小艺排查](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/records/2026-11-08-A-platform-config-client/report.md)

## 交付边界

框架、Demo、调度图和构建与运行记录已经交付。自建 Agent 默认适配器执行本应用业务函数。真实外部连接与认证（A01）、自建 Agent 主动发起系统 Skill 调度（A02）、真实外部并发和重复请求（A03）、完整链路及连续录屏（E01）仍待验证。G1-M1 在已核查的公共 API 26 范围内未找到可用于 A02 的发起接口，真实调用适配器未交付。[验收表](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/acceptance.md) · [调用边界调查](https://github.com/yaorz26/skill-for-harmony-G1-M1/blob/c2cbc3aa3019b241cc81eec15ca7e26d97383735/docs/records/2026-11-08-A-call-boundaries/report.md)
