# 重点样本复核记录

以下五项依据固定版本源码进行静态复核，未安装或执行 Skill。

## byungkyu/api-gateway@1.2.29

- 样本类别：HTTP 与云服务
- 文件数量：236
- 初步分类：L3
- 复核状态：本次已复核
- 主要结论：完整工作流依赖 Maton 平台与本机 CLI，且包含持续数据转发和本地事件处理。只读 API 调用可作为 L2 子集，但不能代表完整 Skill。
- 证据位置：SKILL.md L9-10、L23-44、L549-593、L670-846；version.json 文件清单（236项）。
- 本次修改：补充固定 CLI 版本、OAuth/系统凭据库、函数部署、持久 webhook 与 --exec 风险；L3 结论不变。
- SKILL.md SHA-256：`9e9a8f3a0403af88b1a03b375f4fb9c23ef0b0aff95dac9fb6016e4ffee13671`

## ivangdavila/word-docx@1.0.2

- 样本类别：文件与结构化数据
- 文件数量：2
- 初步分类：L2
- 复核状态：本次已复核
- 主要结论：文本规则本身易复用，但完整 DOCX 编辑需要 ZIP/XML、样式/修订关系维护和版式验证。Skill 未携带实现，也未声明可用库，因此仍需目标端工程适配。
- 证据位置：SKILL.md L17-76、L95-99；version.json 文件清单（2项）。
- 本次修改：确认源码只有说明与 skill-card，补充“未声明具体 OOXML/渲染引擎”的证据缺口；L2 结论不变。
- SKILL.md SHA-256：`c766da489810acf03290283780ba9d3be798678d689255ace34477caeb6d7541`

## ivangdavila/excel-xlsx@1.0.2

- 样本类别：文件与结构化数据
- 文件数量：2
- 初步分类：L3
- 复核状态：本次已复核
- 主要结论：CSV/简单数据子集可降级实现，完整 Excel 保真涉及公式、重算、模板、验证和渲染。仅复制说明无法提供这些能力。
- 证据位置：SKILL.md L17-21、L31-40、L61-68、L94-98；version.json 文件清单（2项）。
- 本次修改：补充正文依赖 pandas/openpyxl、重算和视觉复核，但元数据 bins 为空的内部不一致；L3 结论不变。
- SKILL.md SHA-256：`52421d9fba8fdb64124416c450849434f3639e7b95249ce10fecd209aa90f038`

## iahmadzain/home-assistant@1.0.0

- 样本类别：设备与局域网
- 文件数量：4
- 初步分类：L3
- 复核状态：本次已复核
- 主要结论：出站 REST 控制可通过目标端 HTTP/JSON 改写，属于 L2 子集；完整双向能力还要求可达 webhook 接收端、常驻处理和设备/局域网条件，因此整体维持 L3。
- 证据位置：SKILL.md L3-4、L13-35、L99-134；scripts/ha.sh L7-23、L38-137；version.json 文件清单（4项）。
- 本次修改：补充 Bash/curl/jq、令牌配置和实际控制脚本证据，并区分出站 REST 子集与入站 webhook 完整范围；L3 结论不变。
- SKILL.md SHA-256：`dc73a1a85ace02acd7d126db90a4e85975a05b396298170e036eb55df7a9ab2f`

## paudyyin/mcp-builder@1.1.0

- 样本类别：MCP 与工具协议
- 文件数量：11
- 初步分类：L3
- 复核状态：存在争议
- 主要结论：纯开发指南可作为 L1 文档子集；完整构建和评测会连接或启动 MCP 服务、调用模型并依赖开发工具链，整体维持 L3。许可字段存在需要进一步确认的证据冲突。
- 证据位置：SKILL.md L37-74、L78-177、L196-235；scripts/requirements.txt L1-2；scripts/connections.py L7-10、L83-109；package.json 与版本文件清单（11项）。
- 本次修改：补充 Python/MCP/Anthropic、stdio/HTTP/SSE 与子进程证据；发现 frontmatter 引用的 LICENSE.txt 未随版本提供，而 package.json/版本元数据标为 MIT/MIT-0。
- SKILL.md SHA-256：`0f4592dcb53cf2b5d6b7febee6b4152018b565551a1c29e3c612f57b218ab295`
