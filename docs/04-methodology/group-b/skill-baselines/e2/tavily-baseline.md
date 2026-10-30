# E2 主测：Tavily 完整基线记录

日期：2026-10-30（北京时间）。本记录覆盖分工要求的认证、请求、响应、错误处理、Skill 使用确认和可复现证据。测试使用原平台 OpenClaw；没有实施鸿蒙移植。

## 身份、安装与环境

| 字段 | 实际记录 |
| --- | --- |
| 注册身份 | jacky1n7/openclaw-tavily-search@0.2.1 |
| Skill 内部 name | tavily-search；不与注册 slug 混淆 |
| 来源 | https://clawhub.ai/jacky1n7/openclaw-tavily-search |
| 源码 | source/SKILL.md、source/scripts/tavily_search.py、source/skill-card.md |
| 固定版本 | 发布元数据、owner 和全部 3 个文件 SHA-256 已核对，见 evidence/source-manifest.json |
| 安装 | 将原始 SKILL.md 和脚本复制到独立 workspace/skills/tavily-search；字节一致，无源码改写 |
| 运行环境 | Windows；OpenClaw 2026.10.3 (59cb447)；Node 24.16.0；历史 Python 使用本机解释器；新复跑通过 run-case.ps1 的 PythonPath 参数指定 |
| 模型 | a1-deepseek/deepseek-flash，终端回执未发生 reroute |
| 运行方式 | openclaw agent --local 嵌入式 Agent；包含真实模型和工具调用，不经过 Gateway RPC |
| Python 命令 | 本地 python3.cmd 映射已有 Python，适配 Windows 命令名；未修改目标 Python 脚本 |
| 凭据 | 用户自行取得 Tavily Key；历史实验使用本机 Windows 用户加密保存；新复跑直接从调用进程注入环境变量；未放入源码或公开证据 |

## 认证、请求和响应

原脚本读取 TAVILY_API_KEY，构造 HTTPS POST 到 https://api.tavily.com/search，使用 Authorization: Bearer [REDACTED]。有效 Key 真实请求返回结构化结果，无效 Key 走认证失败分支，缺少 Key 在发请求前拒绝。

请求契约：query 为公开技术查询，max_results=3，search_depth=basic，topic=general，include_domains=[docs.python.org]；include_answer/include_images/include_raw_content 均为 false。输出使用 brave 格式，即 query、results[].title/url/snippet/score。

`evidence/tavily/request-contract.json` 来源是已核验的源码和离线请求捕获，**不是线上抓包**。原脚本不输出成功 HTTP 状态码，所以不把脚本退出 0 写成“直接观测到 Tavily HTTP 200”。真实无效 Key 的错误文本由源码的 HTTP 401 专门分支产生，证据保留该诊断；没有独立保存原始 401 响应头。

## 测试矩阵

| 编号 | 层级与输入 | 预期 | 真实结果与状态 | 证据 |
| --- | --- | --- | --- | --- |
| T1 | 原脚本，无 Key | 拒绝执行 | exit=1，Missing TAVILY_API_KEY；通过 | script-missing.json |
| T2 | 原脚本，合成无效 Key | 服务拒绝认证 | exit=1，Tavily authentication failed；通过 | script-invalid.json |
| T3 | 原脚本，有效 Key，basic 搜索 | JSON 搜索结果 | exit=0、3 条 Python 文档结果；通过，但仅脚本层 | script-valid.json |
| T4 | OpenClaw，首次正常案例 | 读取 Skill、搜索、核验来源 | 最终搜索成功，但首次相对路径错误，随后纠正；来源用 Python 获取而未遵循实验指定的 web_fetch，标记有偏差 | normal-trace.json、normal-answer.txt |
| T5 | OpenClaw，路径明确的正常复测 | 单次搜索并用 web_fetch 核验来源 | 原脚本 exit=0，3 条 docs.python.org 结果；原始页面 HTTP 200；调用链通过 | normal-clean-trace.json、normal-clean-receipt.json |
| T6 | OpenClaw，无效 Key | 报错并停止 | 原脚本 exit=1，认证失败；未使用其他搜索渠道；通过 | invalid-trace.json、invalid-answer.txt |
| T7 | 离线模拟边界 | 明确诊断/参数映射 | 12 项通过；不冒充线上服务结果 | offline-boundaries.json |

T7 覆盖：请求方法/地址/Bearer 与域名参数、401、429、500、无效 JSON、非对象 JSON、响应超过 2 MiB、网络错误、TLS 证书错误、空查询、country/topic 冲突和域名数量上限。没有为了触发 429 实际耗尽额度。

## 正常复测的完整证据链

- 输入：`normal-clean-prompt.txt`。固定公开查询，basic、3 条结果，只运行一次搜索。
- Skill 读取：轨迹 seq 5 请求目标 SKILL.md，seq 6 返回原文。
- 脚本执行：seq 8 使用绝对路径调用原始 tavily_search.py，seq 9 返回 JSON 与 SCRIPT_EXITCODE=0。
- 结果核对：3 条结果均来自 docs.python.org，具备 title/url/snippet 字段；另存 search-response.json。
- 来源核验：seq 11 调用 web_fetch 获取 https://docs.python.org/3/library/urllib.request.html；seq 12 的嵌套工具记录保存 HTTP 200 和正文。
- 页面较长，工具返回正文有截断。可见部分已包含 timeout 的说明，因此可核验本题核心信息；不能声称阅读了全页。
- 模型回答已给出来源链接。自动核验确认数据和执行链，不等同于对每一句解释的正确性背书。

## 输出质量复核与限制

正常复测回答的核心解释“timeout 以秒为单位，作用于连接等阻塞操作，省略时使用默认设置”有来源支持。但末尾把相同参数/返回值的说明联系到 install_opener，存在对象混淆；关于固定时限内未响应必然抛 TimeoutError 的表述也过于概括，原始异常可能经过封装。保留原回答，不篡改证据；报告不采纳这些额外表述。因此“API 与调用链成功”和“解释文字完全正确”分别评价。

首轮相对路径失败产生 exit=2，修正后搜索成功；正常复测用明确绝对路径消除此问题。源代码本身未被修补。

无效凭据案例中外层 CLI 返回 0，仅表示 Agent 正常结束；内部脚本 exit=1 才是业务失败状态，不能混为一谈。

## 范围与交接

已完成一个带认证主测和一个免认证备选的基线。主测验证 general/basic/brave、域名筛选、正常响应、真实认证拒绝及模拟边界；不宣称测试了所有 news/finance/advanced/md/raw 参数组合。

交 S2：固定版本、来源哈希、动态依赖、主测证据。交 S3：沿用静态 L2 候选，但补充 Python、宿主 exec、HTTPS、环境凭据、JSON 和来源读取的真实依赖。鸿蒙状态为未验证；不能因原平台成功就认定移植成功。
