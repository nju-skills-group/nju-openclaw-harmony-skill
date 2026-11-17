# ClawHub → 小艺 Work 移植汇总

官方内置与社区 Skill 的[八类功能候选总表](openclaw-xiaoyi-work-inventory.md)收录本页的 40 个社区候选和 42 个官方内置候选。本页同时保留小艺同名的 Notion 记录，供回查原对照。

2026-11-17。合并 **S2 原样本 24 项**、**全目录初筛入围 10 项**、**第二轮补充 7 项**，共 **41 条 ClawHub 来源与版本记录**。原分级是乙组对源 Skill 完整功能的静态判断。新增 17 项尚未纳入原分级，统一记为「未定」。本轮开工建议针对小艺 Work 云电脑可安装的独立 Skill 包和明确的首版子集。 [S2 原对照](clawhub-xiaoyi-skill-tool-mapping.md) · [全目录复筛和验收](clawhub-work-porting-shortlist-2026-11-17.md)

「未见 / 部分 / 相近 / 同名」在 S2 区块沿用**旧会话**判断。市场栏另记发现的条目或主题线索。新增区块根据旧会话和市场名称判断「可能部分覆盖」或「未见专项」，实际功能以同输入测试为准。`read`、`write`、`exec` 等是目标候选。「模型」表示首版可由 `SKILL.md` 和对话文本完成。`invoke` 需要实际注册的 Function、Schema 和权限，`exec` 需要核对执行位置、运行时及权限。 [历史会话 Skill 与工具](xiaoyi-capability-inventory.md) · [市场快照](xiaoyi-skill-market-snapshot.md) · [原市场交叉核对](xiaoyi-market-gap-review.md)

| 来源批次 | 条数 | 原分级 |
| --- | ---: | --- |
| S2 原样本 | 24 | L1 3，L2 5，L3 16 |
| 全目录初筛入围 | 10 | 未定 10 |
| 第二轮补充 | 7 | 未定 7 |

## S2 原样本 24 项

来源以 S2 固定版本普查为准。旧会话「未见」8 项、「部分」14 项、「相近」1 项、「同名」1 项。 [S2 版本、源码与依赖证据](skill-survey/clawhub/2026-10-31/README.md)

| ClawHub 来源与版本 | 原分级 | 小艺旧会话覆盖 | 市场线索 | Work 可尝试的工具 | 首轮功能或开工条件 |
| --- | --- | --- | --- | --- | --- |
| `perpetualhui/adaptive-socratic-questioning@1.1.0` | L1 | 未见固定的两轮追问与 JSON 规程 | 数学教育助手、智能老师辅导系统 | 模型、多轮上下文 | **可开工**。复用 E1 的学习目标和学生回答，验追问衔接、缺参和 JSON。市场对照可并行。 [E1](skill-baselines/e1/README.md) |
| `aircraft06/academic-paper-writing-style@1.0.0` | L1 | 未见专用论文风格规程 | 写作风格学习、小艺Word专家 | 模型、按需 `read` | **可开工**。用同一摘要比较固定风格约束、修改理由与事实保留。 |
| `clawdiri-ai/davinci-first-principles@1.0.0` | L1 | 未见固定五阶段分析规程 | 计划方案拷问助手、产品思维风暴 | 模型，计划工具可辅助 | **可开工**。核五阶段结构、证据与假设。原 frontmatter 名为 `first-principles`。 |
| `steipete/notion@1.0.0` | L2 | 同名 `notion` | 市场快照未见明确展示名 | 现有 `notion`，有接口时 `invoke` | **先复核现有 Skill**。读授权页面并核列表分页，记录版本和权限。 |
| `byungkyu/api-gateway@1.2.29` | L3 | 未见 Maton 连接管理与事件链 | 腾讯云开发平台、飞书等有相邻功能 | `invoke` | **等已授权接口**。先试单个只读接口，完整 OAuth 和事件处理另评。 |
| `jacky1n7/openclaw-tavily-search@0.2.1` | L2 | 部分，`xiaoyi-web-search` 提供网页搜索 | 小艺联网搜索、多引擎搜索 | 现有搜索 Skill，有接口时 `invoke` | 可先比对标题、链接和摘要。**复现 Tavily 等已配置接口**。 [E2](skill-baselines/e2/tavily-baseline.md) |
| `oswalpalash/ontology@1.0.4` | L2 | 未见带约束的实体关系与图查询，已有记忆工具 | 个人知识库、知识管理 | `read`、`write`、确定性校验逻辑 | **等持久读写和校验验证**。做 Project–Task 关系、非法关系拒绝和跨会话查询。 [E3](skill-baselines/e3/baseline-record.md) |
| `ivangdavila/word-docx@1.0.2` | L2 | 部分，`xiaoyi-doc-convert`、`markitdown` 可对照转换 | WPS办公、小艺Word专家 | 现有文档 Skill、`read`、`write`，保结构编辑需文档引擎 | **先复核现有 Skill**。用含修订、字段、样式的合成文档核转换与格式。 |
| `ivangdavila/excel-xlsx@1.0.2` | L3 | 部分，已有 `xiaoyi-xlsx` | 小艺表格专家、WPS办公、专业数据分析工具 | 现有表格 Skill、受支持的表格引擎 | **先复核现有 Skill**。查公式重算、日期类型和模板格式保留。 |
| `steipete/peekaboo@1.0.0` | L3 | 部分，`xiaoyi-gui-agent` 有鸿蒙界面相近能力 | 有头浏览器、浏览器控制 | `browser` 或可用的小艺 GUI | 可做网页只读子集。**原 macOS 操作等宿主及权限**。 |
| `steipete/apple-notes@1.0.0` | L3 | 部分，有设备笔记工具 | 个人知识库、知识管理 | `get_note_tool_schema`、`call_device_tool` | **等设备工具可达**。先测一条授权测试笔记。Apple Notes 数据另需授权服务或导出。 |
| `steipete/things-mac@1.0.0` | L3 | 部分，有日历与计划能力 | 主动任务管理、智能跟进 | `get_calendar_tool_schema`、`call_device_tool`，导出用 `read` | 先试本地导出只读转换，或验证测试日程。Things 项目库和同步需原服务。 |
| `steipete/openai-whisper@1.0.0` | L3 | 部分，`markitdown` 有相近文档化路径 | Skill化的MarkItDown CLI | 现有转换 Skill，离线路径需模型和运行时 | 先对照短音频转写。**完整离线移植等模型和宿主**。 |
| `steipete/nano-banana-pro@1.0.1` | L2 | 部分，`seedream-image-gen` 覆盖生成主题 | 小艺图像创作、美图技能包 | 现有生成 Skill，原服务有接口时 `invoke` | 先比对多图输入和编辑结果。**复现 Google GenAI 等接口**。 |
| `steipete/nano-pdf@1.0.0` | L3 | 相近，`xiaoyi-pdf` 待核指定页编辑 | 小艺PDF专家、PDF全能处理专家、PDF工具包Pro | 现有 PDF Skill、按需 `send_file_to_user` | **先复核现有 Skill**。验合成 PDF 指定页编辑及输出文件。 |
| `seanford/coding-agent@1.0.0` | L3 | 部分，有会话和代理调度工具 | OpenCode | `sessions_spawn`、`subagents` | 可测静态仓库说明整理与结果回传。ACP/acpx、PTY、外部编码宿主另测。 |
| `maximeprades/auto-updater@1.0.0` | L3 | 未见 OpenClaw 或 ClawHub 宿主更新链 | 自我进化、自我进化引擎仅作相近主题参考 | `web_fetch` | 可做公开版本只读比较。**宿主升级等平台支持**。 |
| `halthelobster/proactive-agent@3.1.0` | L3 | 部分，有计划、记忆、定时工具 | 主动任务管理、主动任务预测&规划 | `update_plan`，授权测试后可试 `cron` | 可试显式进度记录和一次性提醒，Heartbeat 与持久工作区另测。 |
| `steipete/mcporter@1.0.0` | L3 | 未见动态 MCP 发现、OAuth 和 stdio | 未见明确 MCP 工具条目 | `invoke`，需已注册测试 Function | 已注册 Function 可验证只读调用。**完整移植等协议、Schema 与鉴权**。 |
| `paudyyin/mcp-builder@1.1.0` | L3 | 未见 MCP 开发与评测链，有 `skill-creator` | 技能创建仅作近邻对照 | 模型、按需 `read`，完整构建需 SDK 与运行时 | 可做无副作用工具的 Schema 和验收用例。源码复用前核许可。 |
| `liuboacean/agent-comm-hub@3.0.25` | L3 | 部分，会话工具支持同宿主交接 | 未见明确跨宿主 Hub 条目 | `sessions_send` | 授权测试会话中核编号消息收发。**跨宿主等 MCP、服务和 SQLite**。 |
| `iahmadzain/home-assistant@1.0.0` | L3 | 部分，鸿蒙智家提供相近设备功能 | 鸿蒙智家、智慧化场景 | `invoke` | **等授权实例、注册 Function 和网络可达**。先做单实体状态只读。 |
| `steipete/sonoscli@1.0.0` | L3 | 部分，智家有相近控制模式 | 鸿蒙智家、智慧化场景 | `invoke` | **等实际 Sonos 与授权接口**。先验一条状态查询。 |
| `steipete/openhue@1.0.0` | L3 | 部分，智家有相近灯光能力 | 鸿蒙智家、智慧化场景 | `invoke` | **等已配对 Hue Bridge 与注册 Function**。先读一盏测试灯状态。 |

## 全目录初筛入围 10 项

来源是乙组归档再筛选。前六项有可读 `SKILL.md`，末四项依据归档元数据，固定源码仍待核。 [筛选和证据边界](clawhub-work-porting-shortlist-2026-11-17.md)

| ClawHub 来源与版本 | 原分级 | 小艺覆盖程度 | 市场线索 | Work 可尝试的工具 | 首轮功能或开工条件 |
| --- | --- | --- | --- | --- | --- |
| [`anderskev/adr-decision-extraction@1.0.2`](https://clawhub.ai/anderskev/skills/adr-decision-extraction) | 未定 | 未见专项，通用报告可覆盖摘要 | 小艺研究报告专家、计划方案拷问助手 | 模型 | **可开工**。从粘贴纪要提取已定方案、备选及证据，输出 JSON，验重复和未决提案。 |
| [`niracler/nini-anki-card-generator@0.3.0`](https://clawhub.ai/niracler/skills/nini-anki-card-generator) | 未定 | 未见 Anki 导入格式，有辅导类相近能力 | 数学教育助手、智能老师辅导系统 | 模型，文件交付可试 `write` | **可开工**。把粘贴材料生成 `simple-anki-sync` Markdown。实际导入和同步另测。 |
| [`gechengling/prompt-engineering-lab@3.0.3`](https://clawhub.ai/gechengling/skills/prompt-engineering-lab)（可读正文 3.0.0） | 未定 | 未见固定用例、逐项评分和版本回归的明确契约 | 自我进化、PRD生成测试用例 | 模型，读取结果文件时可试 `read` | **可开工**。比对两版已有输出并引用差异证据。首版依据可读正文的 A/B 与量规思路。 |
| [`papersareflowing/citation-verifier@0.1.0`](https://clawhub.ai/papersareflowing/skills/citation-verifier) | 未定 | 可能部分覆盖，已有文献搜索，已知引文逐字段查证待核 | 小艺研究报告专家、论文文献搜索、aminer数据搜索 | `web_fetch`，原检验工具接口待适配 | **等公开元数据抓取**。以 DOI 或 arXiv 对照匹配、字段错配和不存在三种结果。 |
| [`newageinvestments25-byte/nai-rss-digest@1.0.0`](https://clawhub.ai/newageinvestments25-byte/skills/nai-rss-digest) | 未定 | 可能部分覆盖，网页与新闻摘要已有，自选源和去重待核 | 网页阅读器、每日早报、论文每日速递 | `web_fetch`，读 OPML 可试 `read` | **等短订阅可稳定抓取**。用两条公开 feed 验来源、过滤、去重与单源失败。 |
| [`baptiste00001/icalendar-events-parser@1.0.2`](https://clawhub.ai/baptiste00001/skills/icalendar-events-parser) | 未定 | 未见本地 `.ics` 周期展开，已有设备日历能力 | 营销日历生成器、效率管理工具可对照 | `read`、经验证的脚本运行能力（如 `exec`） | **等读取和确定性脚本**。以合成 `.ics` 的简单周重复核实例数、开始结束时间。 |
| `sunny0826/release-notes-generator@1.0.0` | 未定 | 未见粘贴提交记录后固定分组生成版本说明的专用规程 | GitHub CLI、Gitee命令行助手 | 模型，文件版可试 `read` | **先复核源码**。小样本按破坏性变更、新功能和修复分类。 |
| `52yuanchangxing/incident-postmortem-assistant@1.0.0` | 未定 | 未见按故障时间线区分观察、诱因和根因的规程 | 小艺研究报告专家、标准化SOP一键生成 | 模型，文件版可试 `read` | **先复核源码**。用合成故障材料验时间线及证据标注。 |
| `phy041/phy-api-changelog-gen@1.0.3` | 未定 | 未见两版 OpenAPI 契约的语义差异报告 | GitHub CLI、Web应用测试可对照 | `read`、确定性解析和兼容规则 | **等源码和脚本核验**。比较两份合成接口契约并核破坏性变更。 |
| `matthewyin/subtitle-converter@1.0.0` | 未定 | 可能部分覆盖，已有视频制作，字幕文件互转和时间轴校验待核 | 小艺视频创作2.0、一键成片 | `read`、`write`、可验证的字幕解析 | **等源码、许可和文件交付核验**。先做短 SRT 至 VTT 转换。 |

## 第二轮补充 7 项

来源是 14 组补充主题的复筛。时区条目已查正文，其他条目根据归档、发布者摘要或相关规范给出首版范围。 [第二轮复筛详情](clawhub-work-porting-shortlist-2026-11-17.md#第二批补充候选)

| ClawHub 来源与版本 | 原分级 | 小艺覆盖程度 | 市场线索 | Work 可尝试的工具 | 首轮功能或开工条件 |
| --- | --- | --- | --- | --- | --- |
| [`tobewin/timezone-helper@1.0.0`](https://clawhub.ai/tobewin/skills/timezone-helper) | 未定 | 可能部分覆盖，已有 UTC+8 转换，共同可用时段待核 | 效率管理工具、腾讯会议 | 模型，扩展后核可靠时区数据 | **可开工**。用明确 UTC 偏移和可用时段求交集，验跨日与无交集。 |
| [`avegancafe/semver-helper@1.0.1`](https://clawhub.ai/avegancafe/skills/semver-helper) | 未定 | 未见根据兼容性证据建议升版的独立规程 | GitHub CLI、Gitee命令行助手 | 模型与 SemVer 规则 | **可按标准自行实现**。验破坏性变更、兼容新增、修复和事实缺失。原包复用前核许可。 [SemVer](https://semver.org/) |
| [`cnoder-wgh/doc-diff@1.0.0`](https://clawhub.ai/cnoder-wgh/skills/doc-diff) | 未定 | 可能部分覆盖，已有文档处理，逐条前后证据待核 | 小艺Word专家、WPS办公、小艺格式转化 | 模型，工作区文件版可试 `read` | **可先打样**。用两版粘贴 Markdown 验新增、删除、数字变化和纯排版变化。固定正文待核。 |
| [`kofna3369/axiom-cron-whisperer@0.1.2`](https://clawhub.ai/kofna3369/skills/axiom-cron-whisperer) | 未定 | 可能部分覆盖，有 `cron` 调度，表达式校验与试算待核 | 主动任务管理 | 模型可解释，精确计算需确定性解析器 | **解释子集可打样**。先核五字段和非法值，试算获得确定性实现后再做。固定正文待核。 |
| [`mtsatryan/accessibility-auditor@1.0.0`](https://clawhub.ai/mtsatryan/skills/accessibility-auditor) | 未定 | 可能部分覆盖，已有设计辅助，可复现对比度计算待核 | 前端项目优化、专业UX设计 | 经验证的计算逻辑（如受支持脚本） | **等计算工具**。输入两个 HEX，核对比度、正常文字 AA 判定和非法输入。 |
| [`freedompixels/cn-regex-tester@1.2.7`](https://clawhub.ai/freedompixels/skills/cn-regex-tester) | 未定 | 可能部分覆盖，已有开发入口，指定引擎的匹配契约待核 | 前端项目优化、OpenCode | 经验证的脚本运行能力（如 `exec`） | **等运行时与源脚本核验**。核匹配、无匹配和语法错误，用同一引擎复现。 |
| [`harrylabsj/json-formatter-pro@1.0.3`](https://clawhub.ai/harrylabsj/skills/json-formatter-pro) | 未定 | 可能部分覆盖，已有格式与数据工具，语法错误定位待核 | 小艺格式转化、专业数据分析工具 | 确定性 JSON 解析，文件版 `read`、`write` | **等解析工具和源码核验**。测合法数组、末尾多逗号和数值类型是否保留。 |

## 认领时优先看的项目

- **纯文本首版**可从苏格拉底追问、架构决策提取、Anki 闪卡、提示词回归对照和跨时区共同窗口中选。苏格拉底追问已有 E1 原端证据，市场辅导项的同用例对照可以与独立包并行。
- **用平台工具的首版**可选引文核验或多源 RSS 摘要，分别验证 `web_fetch` 是否保留公开元数据或可解析订阅正文。需持久状态的 `ontology` 另测跨会话读写与确定性校验。
- **已有同名或主要功能相近的项**先用相同输入比较。记录安装与加载，只有工具在 Work 当轮确实运行并取得返回时，再更新工具验证状态。
