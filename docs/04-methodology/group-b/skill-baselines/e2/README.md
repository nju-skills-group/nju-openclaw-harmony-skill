# E2：外部服务调用基线

日期：2026-10-30（北京时间）。个人职责：E2 原平台基线；主测 Tavily，备选 weather。源于周 2–3 分工：记录认证、请求、响应、错误处理与目标 Skill 使用证据。

| 样本 | 结果 | 报告/证据 |
| --- | --- | --- |
| jacky1n7/openclaw-tavily-search@0.2.1 | 有效认证、搜索及来源读取成功；无效凭据如实报错；解释文字仍有局部偏差 | [主测记录](tavily-baseline.md)、[问题清单](tavily-issues.md)、[核验结果](evidence/tavily/verification.json) |
| 官方 weather（固定 commit） | 当前天气查询、curl 备用路径成功；受控超时如实报错 | [备选记录](weather-baseline.md)、[问题清单](weather-issues.md)、[核验结果](evidence/weather/verification.json) |

[工具与复跑说明](../../../../../tools/skill-baseline/e2/README.md)包含可配置的运行器、只读证据核验和 12 项离线模拟测试。[交接与汇报](handoff.md)说明如何交给 S1/S2/S3。

[入库后复跑验证](migration-validation.md)记录新运行器的正常/无效凭据实测与环境恢复检查。

本目录补充已有[静态普查](../../skill-survey/README.md)，不覆盖其 2026-10-25 的历史统计。原平台成功、错误处理验收、最终文本准确性、鸿蒙验证是独立状态。两个样本的鸿蒙验证均未执行，L2 仍是静态候选。

## 证据阅读与脱敏

- tavily/normal-clean-trace.json：修正复测的 read → exec → web_fetch；normal-trace.json 保留初轮路径错误与偏差，不能混为无误通过。
- tavily/invalid-trace.json：实际认证失败，脚本 exit=1，Agent 停止；不是限流模拟。
- tavily/offline-boundaries.json：12 项离线模拟；不称为服务真实 429/TLS/大响应。
- weather/normal、fallback、error：分别对应正常工具、备用 curl 和人为极短超时。
- trace 是工具日志的选取视图，省略系统提示与推理；保留工具调用和返回。原始私有数据留本机。
- 公开副本将本机路径替换成 `<USER_HOME>`、`<TAVILY_RUN_ROOT>`、`<WEATHER_RUN_ROOT>`、`<A1_ROOT>`、`<PROJECT_ROOT>`。这些是历史数据标记，不是可执行路径。
- `publication-manifest.json` 记录脱敏后文件的 LF 换行规范化哈希，兼容 Git 的 Windows 换行转换；第三方源码原始字节哈希单独严格校验，未随脱敏修改。

报告中的 source/ 指向工具目录下对应样本；证据文件名位于 evidence/tavily/ 或 evidence/weather/。截图/录屏不是本次证据形式，验收以已保存的实际调用轨迹、响应与回执为准。
