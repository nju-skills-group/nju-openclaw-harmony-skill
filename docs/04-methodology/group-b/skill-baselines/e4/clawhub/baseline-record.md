# clawhub 基线测试记录

测试日期：2026-10-31。角色：E4，备选样本。

1. **Skill 名称与来源**

   **clawhub**，OpenClaw 官方 bundled Skill，随 2026.10.2 安装。[固定源码](https://github.com/openclaw/openclaw/blob/d79ab6195d8d0566b285008bcc30c01a6ce368e2/skills/clawhub/SKILL.md)与本机所测文件的 Git blob 哈希一致。原文见 [SKILL.md](source/SKILL.md)，哈希及来源见 [source-manifest.json](source-manifest.json)。这是管理 ClawHub 发现/安装流程的 Skill，不等同于独立 clawhub CLI。

2. **测试环境**

   WSL 2 / Ubuntu 24.04.5 LTS；OpenClaw **2026.10.2 (b8952d4)**；Node.js **v24.21.0**；模型提供方 **DeepSeek**，实际模型 **deepseek-v4-pro**，thinking=off。通过现有 Gateway 运行，两个案例各用独立会话。见 [environment.json](environment.json)和各案例运行回执。

3. **安装与配置**

   Skill 已内置且对模型可见，本次未安装 Skill、插件或独立 clawhub CLI。沿用既有 Gateway 和模型认证，未新增 ClawHub 凭据，未读取或输出密钥。测试前后配置文件哈希及两个默认 Skill 目录的文件清单哈希一致；会话和日志正常产生。限制来自提示词，不是强制工具白名单。

4. **调用方法**

   使用 `openclaw agent --agent main --session-id <独立会话> --message-file <输入文件> --thinking off --timeout 240 --json`，明确要求先读取 clawhub 原文，再按原文选择发现入口；未直接指定应选择插件或 Skill 的具体工具命令。实际命令、会话和耗时见 [案例 A 运行记录](evidence/plugins/run-metadata.json)及[案例 B 运行记录](evidence/skills/run-metadata.json)。

5. **测试输入**

   **案例 A：**“Help me find a Notion integration capability in ClawHub.”，只要求发现 Notion 能力，没有明确指定搜索 Skill。**案例 B：**“Explicitly search ClawHub for a weather Skill, not a plugin.”，明确要求搜索 weather Skill。共同约束：返回最多三个真实候选，有版本才报告；只搜索，不安装、更新、卸载、发布或同步，不使用外部网页搜索代替 OpenClaw 发现入口。完整英文输入见 [A](evidence/plugins/input.txt)、[B](evidence/skills/input.txt)，用户目录已脱敏。

6. **预期行为**

   先实际读取 SKILL.md。A 按原文默认搜索插件，优先使用原生 `plugins` 工具；B 使用 OpenClaw 的 Skill 搜索入口。读取真实返回后报告标识和可用版本，不编造候选，不把“搜索到”说成“已安装可用”，不执行管理变更。

7. **实际输出**

   **A：**原生 `plugins(action="search", query="notion")` 返回两个候选：`@openclaw/notion` **1.0.1**、`notion-workspace-plugin` **1.0.0**；模型正确列出，说明未安装/验证。

   **B：**实际执行 `openclaw skills search weather`，退出码 **0**，返回十条目录记录。模型选出 `@steipete/weather`、`@azizbrownint/weather`、`@paudyyin/weather` 三条真实候选，并说明输出未提供版本。但这三条位于原始结果第 **1、4、5** 位，模型称其为“搜索前三条”不准确；未带 `--limit 3`，尽管最终只展示三条。该偏差保留，不判作回答完全正确。

   实际返回见 [A 工具输出](evidence/plugins/tool-output.txt)、[B 工具输出](evidence/skills/tool-output.txt)；模型回答保留在各案例 `agent-result.json` 的 `result.payloads` 中。以上是测试时的目录快照。

8. **执行证据**

   [A 调用轨迹](evidence/plugins/events.jsonl)：seq **11–12** 首次 read 失败，**18–19** 经桥接成功返回原文，**33–34** 原生插件搜索及真实结果。[B 调用轨迹](evidence/skills/events.jsonl)：seq **11–12** 同样出现 read 入口失败，**18–19** 成功读取，**75–76** 读取命令执行桥接说明，**84–85** 执行 Skill 搜索并返回结果。未使用截图；参数和异常索引见 [A 核验记录](evidence/plugins/verification.json)、[B 核验记录](evidence/skills/verification.json)。

9. **测试状态**

   **成功——限两个只读发现分支的调用链。** 两案例最终读取目标 Skill、选对搜索类别、取得真实结果并结束；均存在一次初始 read 入口失败后恢复。B 另有结果顺序和请求数量控制偏差。未出现持续环境阻塞，不能据此宣称整个 Skill 全部功能通过。

10. **实际依赖**

    目标 Skill 文件读取、OpenClaw 工具桥接、原生 `plugins` 搜索工具、宿主 `exec` 和 `openclaw skills search`、ClawHub registry 网络，以及模型服务。本次无需额外编码代理、特殊硬件或独立 clawhub CLI；没有自带脚本执行。候选插件说明中的第三方凭据是候选运行要求，不是本次搜索的前置条件。

11. **后续问题**

    确认当前 code-mode 环境下直接调用 read 为何报 `Tool read not found`，以及如何稳定选择桥接入口；改进 B 的结果顺序表述及 `--limit` 参数遵循。分类时保留宿主发现工具/CLI 和 registry 依赖，区分“搜索成功”“安装成功”“候选可用”。未实施上述修复。

12. **测试范围**

    仅覆盖默认插件发现和明确 Skill 搜索。未测试安装、校验、更新、卸载、发布、同步、watcher 刷新、候选实际运行、网络故障注入或鸿蒙移植。原生插件工具可用，因此未单独测试其 CLI 降级分支。

13. **skill 使用确认**

    **已确认——限显式要求使用的两个发现流程。** 有成功返回目标原文的 read 记录，以及随后对应的宿主工具调用、搜索结果和模型回答。判定依据是实际轨迹，不是模型自称或 Ready 状态。本次没有验证无人提示时自动发现该 Skill，也未用对照实验证明行为完全由 Skill 引起。
