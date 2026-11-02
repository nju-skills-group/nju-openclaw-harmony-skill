# Tavily 运行问题与实际依赖

| 项目 | 证据与含义 | 处理 |
| --- | --- | --- |
| Python 与命令名 | 原 Skill 要求 python3，Windows 现有解释器名为 python.exe | 提供本地 python3.cmd；原源码不改 |
| 路径 | 首轮模型把 scripts/tavily_search.py 写错为 skills/tavily_search.py | 记录首轮失败；绝对路径复测通过 |
| 环境凭据 | 缺少 Key 在本地失败；无效 Key 得到认证失败；有效 Key 返回结果 | 密钥加密保存，按案例独立进程注入 |
| 服务依赖 | POST api.tavily.com/search，TLS 默认验证开启 | 未关闭证书验证；未安装远程依赖 |
| 可选依赖 | 源码在证书问题时可尝试 certifi CA；成功请求不能证明走过该分支 | TLS 行为以离线测试说明，不冒充现场故障 |
| 宿主依赖 | OpenClaw read/exec；来源验证使用 web_fetch | 不是单纯复制提示词即可移植 |
| 页面读取 | 初轮使用 Python 抓取，未遵循实验指定工具；复测使用 web_fetch | 保留两次轨迹，复测结果作为标准基线 |
| 长结果 | 来源正文被工具截断，关键 timeout 段仍可见 | 只核验实际可见段落；从嵌套工具记录读取结构化元数据 |
| 最终文字 | 回答存在 install_opener 对象混淆和异常类型表述过度概括 | 不认定全句准确，不修改原始回答 |
| CLI 与业务状态 | 无效 Key 时 CLI 0，脚本 1 | 以脚本退出码与诊断判断业务状态 |
| SQLite 清理 | 正常复测结束日志有清理 Worker 警告，最终 clean-close receipt written | 轨迹及正常回复完整；记录为宿主日志现象，未证明影响业务结果 |
| 费用 | 本轮有 3 次成功 basic 搜索：脚本层、初轮 Agent、修正 Agent | 不购买/升级服务；实际消耗以 Tavily 控制台为准，模型账单另计 |

源包包含发布方的自动安全扫描结论且不同扫描器意见不一致。本次以实际源码检查为依据：凭据仅用于指定 Tavily 请求，没有执行安装钩子或读取凭据文件。扫描标签不是本实验的运行结论。

Notion 未执行：任务要求一个主测、一个备选，现为 Tavily 与 weather。Notion 曾是候选，不是额外必交项。
