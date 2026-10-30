# 入库整理后的复跑验证

日期：2026-10-30（北京时间）。这次验证针对可配置运行器和新目录布局，与早先历史基线分开保存。仍是在同一台 Windows 电脑运行，未宣称已在其他同学设备或其他系统验收。

| 检查 | 结果 |
| --- | --- |
| 显式参数 | OpenClaw 命令、Python、基础 models 配置和模型路由均由参数传入，无相邻 a1-week1 隐式依赖 |
| 配置生成 | OpenClaw config validate 通过；PrepareOnly 没有发起模型/API 请求 |
| Tavily 正常 | 2026-10-30 14:49（北京时间）开始，读取原 Skill，单次执行原脚本，SCRIPT_EXITCODE=0，返回 3 条结果，web_fetch 获取来源 HTTP 200 |
| Tavily 无效凭据 | 14:51 开始，单次原脚本调用得到认证失败，内部 exit=1，Agent 停止 |
| 环境恢复 | 调用前配置路径及合成 Tavily 环境值在 invalid 结束后一致，已用 PowerShell 检查 |
| 导出器 | 两次调用的候选轨迹、回执和回答成功导出；公开副本遮盖运行目录/用户目录 |
| 离线检查 | 已归档源码/证据核验和 12 项隔离模拟通过，PowerShell/Node 语法与文档链接检查通过 |

原始回答仍作为被测系统输出保留：本轮正常回答额外引用了未单独打开的 HOWTO 搜索片段，并对超时异常包装作扩展说明；本验证只确认搜索/来源读取链和返回字段，不把所有附加句子认定为已核实。这与历史报告的“调用成功不等于全部表述正确”口径一致。

新增正常复跑发生一次成功 basic 搜索，此外有一次无效凭据请求。实际计费以服务控制台为准。

证据：[核验摘要](evidence/migration/validation.json)、[正常轨迹](evidence/migration/normal-trace.json)、[正常回执](evidence/migration/normal-receipt.json)、[异常轨迹](evidence/migration/invalid-trace.json)、[异常回执](evidence/migration/invalid-receipt.json)。原始私有状态/配置未提交。
