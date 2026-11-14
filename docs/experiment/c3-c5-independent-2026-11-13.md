# C3–C5 个人独立实验

使用本人 MatePad 11.5″S（`TGR-W00`，HarmonyOS `7.0.0.111 (SP18C00E111R2P2)`，API 26）和本人开发者账号。端侧工程基于个人 C2 工程的构建结构，新包名 `com.skilllab.c34agent089e5768`。签名 HAP 的 SHA-256 为 `175D25573ACC1C7EC08AFD6F80712B090154E2995A0EB5C30DE10FF648B014DC`，HDC 安装和启动均成功。

## C3 自建 Agent 路由

| 用例 | 输入 | 实测结果 |
| --- | --- | --- |
| Ability 回传 | `生成回执 C3-PAD-ABILITY-6KQ9` | 界面显示测试码及 UUID `c7c30810-bd76-4ed6-9d0a-2783ffbcb558` |
| 应用内处理器 | `生成回执 C3-PAD-LOCAL-2M5X` | 界面显示测试码及 UUID `e9a83c48-e353-474b-84f4-21b307025278` |
| 未匹配负例 | `查看天气` | 提示输入回执命令，日志 `agent_match` 为 `no_match` |

11 月 13 日 23:54:43.079–23:54:43.262（北京时间），Ability 路径的日志 `agent_match`、`ability_requested`、`ability_entered`、`ability_result`、`agent_result` 使用同一请求 ID `2553b901-0d1f-4764-8c54-c83cb70ad77d`，日志与界面 UUID 一致。应用内处理器直接执行本应用业务函数。C3 尚无自建 Agent 主动调用系统 Skill 的证据，外部回调需在端侧接入后采集。

## C4 端侧 A2A

小艺开放平台拒绝导入声明 `2in1` 的 AgentCard。修正为 `phone` 和 `tablet` 后可选中 Agent。新版签名 HAP（SHA-256 `0A3E0B0E13399CAC59A7138E10A0F35528DC8FA87EF2660C4A19F430A23B922F`）覆盖安装成功。11 月 14 日 01:41:04（北京时间），MatePad 日志记录 `a2a_connected`、`Execute`、`a2a_receipt` 和 `a2a_sent`。任务 `task-3d5e164d-932a-472b-b8cb-08411a30e2ec` 生成 `C4-PAD-01 fb52fd0e-91cb-4aea-9138-d8fa49f26002`，与小艺界面一致。[端侧 A2A 接入指南](https://developer.huawei.com/consumer/cn/doc/service/device-a2a-quickstart-0000002733266338/)

## C5 云侧 A2A

独立 Node.js 服务实现无状态 Header API Key 鉴权、连通性探测和 `message/stream` SSE 回包。本机回环测试确认缺少鉴权时返回 HTTP 401，带正确凭据的探测返回 HTTP 200，畸形 JSON 返回 `-32700`。正常请求 `c5-local-rpc-01` 的 SSE 产物带回原任务 ID `c5-local-task-01`，返回 `C5-LOCAL-7Q2M a2f76ad3-4249-4d11-b554-d11c98ce07c5`。

已校验 SSH 主机指纹并在本人华为云服务器部署服务。公网 HTTPS 无凭据返回 401，服务器经 HTTPS 反向代理验证成功返回 `C5-DEPLOY-01 057059bc-36e9-4133-9117-1112a2fa70e5`。11 月 14 日 02:32:01（北京时间）平台连通性探测的 GET 和 POST 均到达后端并返回 401。轮换密钥并改用 `X-API-Key` 后，11 月 14 日 02:40:31 平台的 `GET /a2a` 返回 HTTP 200，服务记录 `auth_probe_ok`。[云 A2A 基础配置](https://developer.huawei.com/consumer/cn/doc/service/a2a-basic-configuration-0000002746111014/)

11 月 14 日 02:43:58.764（北京时间），小艺发送 `生成回执 C5-CLOUD-01`。服务日志 `message_received` 和 `response_sent` 的请求 ID 与任务 ID 均为 `712ccb1d-e829-5d38-a3d3-aace7346&1`。返回的 `C5-CLOUD-01 c1dad151-d7c8-47fb-8c69-ce67f3032429` 与用户提供的界面回复一致，C5 云侧 A2A 对话验证通过。
