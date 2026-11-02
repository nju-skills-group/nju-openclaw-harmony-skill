# E2 实际依赖和问题清单

| 项目 | 观察与影响 | 处理/交接 |
| --- | --- | --- |
| OpenClaw 宿主工具 | 正常路径需要 read + web_fetch；备用路径需要 read + exec + curl | 无自带脚本不等于无宿主依赖；交 S1/S3 |
| 网络 | HTTPS 天气服务与模型服务分别参与执行 | 两类服务认证和故障分开记录 |
| 认证 | 天气 API 请求没有服务凭据；模型需要已有 DeepSeek 凭据 | 认证项记“天气端点无需认证”，不称已测令牌认证 |
| 第一周配置 | 当时仅允许 read/exec；Gateway 本轮检查时未启动 | 新建 E2 配置，采用 --local；未改 A1 配置 |
| 独立 curl 诊断 | 一次直连检查报 curl 35 / TLS handshake failure；之后 OpenClaw 内 curl 成功 | 只能说明一次失败，不能断言服务持续故障或根因已定位；诊断不当作 Skill 验收 |
| HTTP 证据 | web_fetch 明确返回 status=200；curl 只记录 JSON 和 EXITCODE=0 | 不把 curl 答复中声称的 200 当作直接观测 |
| 地点 | 输入 Shanghai，返回 nearest_area=Pootung | 记录服务定位结果，不声称全上海平均天气 |
| 时间解释 | observation_time 无显式时区；预报日期跨本地午夜 | 保留抓取时间、原始时间和日期；不把模型时区换算当事实 |
| 成本 | 天气样本未配置付费账号；模型调用使用原有账户 | 回执 cost=0 不是账单，未进行费用核算或购买服务 |
| 移植 | 已知要替换 web_fetch 或 curl、解析 JSON、处理网络异常 | ArkTS 等价实现和鸿蒙实测留给后续；不声称已完成移植 |

未处理范围：Tavily 凭据、OAuth、HTTP 401/403/429、服务准确性、完整预报功能、多模型比较、远端仓库提交。
