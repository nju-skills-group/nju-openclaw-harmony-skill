# C5 个人云 A2A 服务

使用 Node.js 20 运行 `server.mjs`。通过部署环境设置 `C5_API_KEY` 为至少 24 字符的随机密钥。默认监听 `127.0.0.1:8787`，可用 `C5_BIND` 和 `PORT` 配置监听地址。通过现有 HTTPS 反向代理公开 `/a2a`，保留 `Authorization` 并关闭响应缓冲。

小艺云 A2A 基础配置选无状态通信、API Key、Header，键名为 `X-API-Key`，值使用部署环境中的密钥。服务也接受 `Authorization` 中的原始密钥或 Bearer 形式。API URL 填部署后的公网 HTTPS `/a2a`，先点测试连接。随后发 `生成回执 C5-CLOUD-01`，用日志的 `id`、`taskId` 和回执 UUID 对照小艺页面。服务实现了鉴权探测 GET 和 `message/stream` SSE 回包，供文本回执实验使用。[华为 A2A 基础配置](https://developer.huawei.com/consumer/cn/doc/service/a2a-basic-configuration-0000002746111014/) · [云 A2A 发起会话](https://developer.huawei.com/consumer/cn/doc/service/message-stream-0000002763022677/)
