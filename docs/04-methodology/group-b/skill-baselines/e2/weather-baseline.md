# E2：OpenClaw Skill 基线测试记录

测试日期：2026-10-30，北京时间。执行者角色：E2。测试范围是指定城市的当前天气查询及备用/异常路径，不覆盖 Skill 所有功能。

## 样本与环境

| 字段 | 记录 |
| --- | --- |
| Skill | weather，官方 bundled |
| 来源 | https://github.com/openclaw/openclaw/blob/d79ab6195d8d0566b285008bcc30c01a6ce368e2/skills/weather/SKILL.md |
| 版本 | commit d79ab6195d8d0566b285008bcc30c01a6ce368e2 |
| 源码一致性 | Git blob e84bbea68bae7416d27eede03154b7acd29b3559，与普查包一致；见 evidence/source-manifest.json |
| 文件结构 | 单个 SKILL.md，没有自带执行脚本；运行时仍依赖宿主工具及网络 |
| 环境 | Windows、Node 24.16.0、OpenClaw 2026.10.3 (59cb447)；详情见 evidence/environment.json |
| 模型 | a1-deepseek/deepseek-flash；回执记录无 fallback/reroute |
| 运行方式 | OpenClaw agent --local 嵌入式执行；未经过 Gateway RPC |
| 安装配置 | 固定源码复制到独立 workspace/skills/weather；正常配置允许 read、exec、web_fetch；备用/异常配置仅允许 read、exec |
| 认证 | 天气请求没有配置 API Key 或 Authorization；模型服务使用既有凭据，未公开密钥 |
| 备选 | jacky1n7/openclaw-tavily-search@0.2.1，仅登记，未配置服务凭据、未执行 |

## N1：正常 web_fetch 路径

- 调用提示词：`normal-prompt.txt`；输入城市 Shanghai，要求温度、天气描述、湿度和地点。
- 事先预期：读取目标 Skill，使用 web_fetch 请求 JSON，从真实返回字段组织回答；失败时明确报告。
- 请求：HTTPS GET `https://wttr.in/Shanghai?format=j2`；工具参数 extractMode=text、maxChars=12000。
- 实际响应：HTTP 200，contentType=text/plain，truncated=false；抓取时间 2026-10-29T16:13:16.226Z，即北京时间 10 月 30 日 00:13:16。
- 实际数据：temp_C=18、weatherDesc=Smoky haze、humidity=82，nearest_area 为 Pootung / Shanghai / China。此处是测试时返回的历史快照，不是报告阅读时的实时天气。
- 输出核对：上述要求字段与模型回答相符；核验脚本通过。没有独立核实气象数据的真实性或新鲜度。
- Skill 使用确认：已确认。轨迹 seq 5 请求读取固定 workspace 的 SKILL.md，seq 6 返回源码；seq 8 调用 web_fetch，seq 10 保存服务结果。
- 测试状态：成功，限所测当前天气查询子集。
- 证据：`evidence/weather/normal-trace.json`、`normal-receipt.json`、`normal-answer.txt`、`http-response-metadata.json`、`weather-response.json`、`verification.json`。

## N2：curl 备用路径

- 实验条件：单独配置有意禁用 web_fetch；按原 Skill 的条件启用 curl。未修改 Skill 源文档。
- 提示词：`fallback-prompt.txt`；请求同一城市及 format=j2。
- 实际调用：读取 SKILL.md 后执行 curl.exe --fail --silent --show-error --max-time 20，并打印 CURL 的退出码（该次标签为 EXITCODE）。
- 实际输出：取得天气 JSON，明确输出 EXITCODE=0。没有尝试备用域名。
- Skill 使用确认：已确认；有目标文件读取和 exec 参数/结果。
- 测试状态：查询功能成功；解释文字存在局部证据不足，见下文。
- 证据：`evidence/weather/fallback-trace.json`、`fallback-receipt.json`、`fallback-answer.txt`。

原始模型回答声称“HTTP 200”，但本次 curl 未打印响应头或状态码，只能直接证明 curl 返回 0 且收到有效 JSON。回答还把 observation_time 换算为本地时间，原始字段没有时区说明，本报告不采纳该推断。保留原回答便于评审，不修改为看似完全正确的输出。

## E1：受控异常路径

提示词：`error-prompt.txt`。实验明确禁用 web_fetch，并把 curl --max-time 从 20 秒改为 0.001 秒，只发起一次请求。这是测试者施加的超时条件，不代表原 Skill 默认参数，也不代表服务自然故障。

- 实际错误：`curl: (28) Resolving timed out after 11 milliseconds`；明确输出 `CURL_EXITCODE=28`。
- 请求结果状态：功能未完成（人为注入超时）；没有获得天气 JSON 或 HTTP 状态码。
- 异常处理验收：通过。模型准确报告解析阶段超时，说明人为注入条件，没有编造天气或声称服务自然故障。
- Skill 使用确认：已确认读取目标源码后执行指定命令；没有重试。
- 重要区别：exec 外层进程退出 0（末尾打印退出码成功），内部 curl 退出 28。CLI 或工具层“成功”不代表业务请求成功。
- 证据：`evidence/weather/error-trace.json`、`error-receipt.json`、`error-answer.txt`。

## 验收边界

- 使用确认与业务结果分别记录，CLI 返回 0 不保证 API 查询成功。
- 正常查询已完成，不据此宣称所有异常类型、所有天气功能通过。
- 无令牌认证、401/403、配额/限流专项测试；无鸿蒙端验证。
- 原静态分类 L2 可以保留为候选；本次只提供真实依赖与输入输出基线。
