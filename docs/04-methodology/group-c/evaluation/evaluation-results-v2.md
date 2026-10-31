# SkillVM 评估结果 v2.0

日期：2026-10-31。依据[评估方法](evaluation-method-and-samples-v2.md)，评价完整SkillVM路线的静态覆盖能力。本文分别陈述实现事实、样本适用性推断与鸿蒙目标条件；不报告迁移成功率或性能收益。

## 1. 证据基线与核查范围

研究仓库基线HEAD：`0433d48378d9530feca124e433d6818c94fd71f5`；材料按工作区读取。SkVM固定提交：`632cefe42cdade636720d5ef97494d1e5431682b`。此前已核查编译、JIT和适配器代码，本次补查Skill加载器、能力画像、运行钩子和评测条件注册表。

| 检查项 | 结果 | 证据边界 |
| --- | --- | --- |
| 样本清单 | 9项、ID无重复、L1/L2/L3各3项 | 沿用既有样本，没有重选 |
| 与普查记录核对 | source_id对应的版本、正文哈希和层级9/9一致 | 元数据一致，不代表执行成功 |
| 此前原文复核 | S04–S09固定提交SKILL.md原始字节SHA-256全部匹配 | 仅6份正文；本次改写沿用该检查结果 |
| 材料限制 | S01–S03未独立重取正文；9项完整包复核仍pending | 对隐藏依赖和完整资源保留不能作保证 |
| 执行范围 | 未运行SkVM编译、模型任务或鸿蒙调用 | 本文结论为静态证据支持的路线判断 |

清单SHA-256：`e37e7aa4fc7a7a2b7591a3ea45d5d9ccbc92a401a1a0105d7e024a1748a4b489`。此前复核原始正文长度：S04=2905、S05=2956、S06=2566、S07=2564、S08=1612、S09=4340字节。完整来源及预期哈希见[L1]。

## 2. 完整机制与实现边界

路线可概括为：**接收Skill与资源 → 测量目标能力、识别需求差距 → 适配与准备 → 交给宿主执行 → 记录、评测和优化**。下表中的实现依据均固定到上述提交。

| 维度 | 实现事实 | 可以承接什么 | 边界 |
| --- | --- | --- | --- |
| D1 输入 | loadSkill读取SKILL.md，枚举附带文件；copySkillBundle保留目录复制资源；parseSkillMeta提取name/description [U8] | Skill正文、脚本、模板和references的材料组织 | 读取/复制不保证正确执行，也不证明OpenClaw的os/requires等门控被统一执行 |
| D2 能力分析 | profiler按model+harness运行能力测试、保存画像；rewrite-skill提取SCR并与TCP比较 [U9][U10] | 发现执行能力差距，为指令改写提供依据 | 已有模型/框架画像不是鸿蒙系统能力认证，也不能证明长流程质量 |
| D3 依赖处理 | bind-env产生依赖、准备脚本和simulation记录 [U2] | 识别并准备宿主可支持的依赖 | 不提供凭据、业务API、PTY或平台UI服务；准备脚本不是跨系统运行时 |
| D4 宿主衔接 | 注册bare-agent、openclaw等适配器；运行接口定义beforeLLM、afterLLM、afterTool和afterRun钩子 [U7][U11] | 将执行接入具体框架，并提供观察/替换执行的接口 | 不同适配器能力不同；类型接口不证明全部已接通，注册表没有HarmonyOS |
| D4 工作流 | 并行提取输出DAG与指令提示 [U3] | 标示步骤依赖与并行机会 | DAG提示不自动实现业务调度、持久会话或外部事务 |
| D5 反馈 | jit-optimize主循环执行基线、训练/测试和选轮；jit-boost由轨迹提取模板并通过钩子复用 [U4–U6] | 改善可由说明/代码修复的问题，减少稳定重复代码生成 | 内容改写不补系统能力；固化依赖sh/python3；CLI包装适配器钩子支持有限 |
| D6 评测 | 条件注册包括no-skill、original、aot-variant、jit-optimized、jit-boost；记录任务、轨迹和工作目录快照 [U12][U13] | 对照不同版本与追溯执行证据 | 不自带本样本集完整业务判据；评分与测试集选择影响结论 |

上述机制共同构成适配与执行支撑体系。业务逻辑仍由模型、脚本、工具和宿主实际完成。源码中的模板执行成功依据包括进程退出码，不能仅凭退出码确认业务正确；JIT回退也不自动撤销外部写操作。

## 3. 逐样本六维分析

以下均为基于[L1–L3]及上表实现证据的适用性推断。D1–D6分别对应输入、能力适配、工具依赖、运行衔接、反馈优化、结果验证。“有承接路径”均以所列宿主条件成立为前提，不表示已完成样本测试。

### S01 adaptive-socratic-questioning：指令与资源承接为主

- **D1/D2**：正文、示例和evals可按Skill包处理；追问流程与JSON规则可作为需求分析和改写对象。资源已复制不代表其中evals会自动成为SkVM评测任务。
- **D3/D4**：现有材料未显示独立执行脚本；核心依赖模型及宿主保存学生回答、跨轮上下文。一次任务执行接口不证明完整教学会话管理已实现。
- **D5/D6**：可针对漏字段、忽略学生回答等问题调整说明；没有稳定代码固化收益的依据。核对追问是否利用前文、缺信息时是否澄清、输出结构是否保留。
- **结论**：在已有模型宿主中，主要适配问题有对应机制。鸿蒙应用仍须提供提示加载和会话承接；这是目标集成条件，并非需要新建完整VM。

### S02 academic-paper-writing-style：指令与资源承接为主

- **D1/D2**：正文与references有加载/复制路径，写作约束可用于能力分析与指令适配。完整references尚未重新核查，不能确认所有规则都被保留。
- **D3/D4**：依赖模型理解和宿主文件读取，无已知外部业务服务；资源路径与模型是否实际阅读资源仍由具体执行方式决定。
- **D5/D6**：反馈可改善规则遗漏和过度改写；不宜把开放式文本生成当作稳定代码固化任务。核心核对点是数值、事实、结论强度和引用不被擅改。
- **结论**：路线较匹配；鸿蒙侧缺口主要是模型与资源接入，而不是专用系统服务。通用评分不能单独证明写作语义保持。

### S03 first-principles：指令与资源承接为主

- **D1/D2**：五阶段说明可以进入加载、需求分析和改写链；可明确阶段和证据要求，但没有形式化推理正确性保证。
- **D3/D4**：现有材料无脚本、凭据或外部运行时需求；实际分析由模型完成，需保留阶段之间的信息依赖。
- **D5/D6**：反馈可以针对漏阶段、混淆事实与假设改写说明；并行和固化价值缺少依据。核对未知是否保留、示例是否被误当事实。
- **结论**：适合利用路线的指令适配部分；鸿蒙所需的是模型调用与输入输出衔接，不能从五阶段格式正确推导分析结论正确。

### S04 weather：工具绑定决定覆盖

- **D1/D2**：原文中的web_fetch优先、curl备用及解析约定可进入分析与改写；替换工具时须说明是否保留等价取数路径。
- **D3/D4**：真正天气能力来自网络工具和外部服务。在具备web_fetch或curl的宿主中有明确调用路径；换到鸿蒙时需现有HTTP能力或新增绑定，SkVM本身不提供该业务接口。
- **D5/D6**：稳定请求构造/解析可作为复用候选，反馈可改善异常处理。必须保留地点、单位、时效和失败语义，不能把缓存旧天气当作代码复用收益。
- **结论**：需求可由“SkVM适配＋宿主网络工具”组合承接。鸿蒙缺口可定位到网络/结果接口，无依据宣称已自动生成绑定。

### S05 trello：工具绑定决定覆盖

- **D1/D2**：curl/jq指令和REST读写流程可被分析与改写；功能范围包含查询、创建、更新、评论和归档，不能只保留读取。
- **D3/D4**：凭据和Trello服务由外部提供；受支持宿主仍须具备命令执行或等价HTTP/JSON工具。鸿蒙需网络、凭据管理与业务调用绑定；未在所查机制中确认可自动提供这些能力。
- **D5/D6**：可优化参数、解析和错误说明；重试需识别已发生的写入，回退不能视作事务回滚。核对权限失败、限流、分页及重复副作用，不仅看最终文本。
- **结论**：路线有条件承接，核心价值是流程适配和复用；认证及写操作正确性依赖工具与业务实现，不能算VM自动补齐。

### S06 meme-maker：工具绑定决定覆盖

- **D1/D2**：Node脚本、模板JSON和说明可按包组织；还需保留模板选择、本地SVG、浏览器PNG及Imgflip分支。PNG与下载依赖见普查指向正文第21、43行的证据。
- **D3/D4**：具备Node、文件、网络和相关浏览器能力的宿主有承接方向；“local”分支仍涉及模板下载与缓存。鸿蒙需复用现有渲染/文件能力或改造脚本，不能仅翻译说明。
- **D5/D6**：稳定SVG组装和参数处理可作优化候选，但样本已自带脚本，额外固化是否有收益证据不足。核对文本转义、产物可读性和各输出分支。
- **结论**：组合工具决定完整范围。只做SVG可作为明确子集方案，不能覆盖PNG与远程分支；本轮不能保证所有脚本依赖均已识别。

### S07 tmux：专门宿主能力决定覆盖

- **D1/D2**：说明与bash辅助脚本可以进入处理链；可识别darwin/linux、tmux及终端依赖并调整调用说明。
- **D3/D4**：实际功能依赖宿主的持久PTY、tmux进程和会话/窗格状态。已有Linux/macOS环境可提供这些能力，SkVM运行接口本身不提供PTY；普通一次性shell也不等价。
- **D5/D6**：有终端服务后才可能优化等待、定位与输入流程。核对输入目标、状态连续性、超时和重连；单次返回日志不足以证明持久交互正确。
- **结论**：在配备tmux的宿主中有条件承接；对鸿蒙，核心障碍是终端服务。远程Linux是一种架构选择，增加网络/会话管理条件，不能称为鸿蒙本机终端覆盖。

### S08 mcporter：专门宿主能力决定覆盖

- **D1/D2**：可以分析命令及HTTP、stdio、OAuth、发现/schema与代码生成需求；需逐分支处理，不能把“支持MCP”作为单一判据。
- **D3/D4**：在具备mcporter及所需Node/服务端环境的宿主，可通过CLI承接；协议业务由mcporter和MCP服务完成。鸿蒙HTTP子集有绑定方向，stdio还涉及进程生命周期、输入输出通道及凭据衔接。
- **D5/D6**：工具选择、参数处理和重复格式转换可改善；schema变化时固定模板可能失效。核对发现、调用、授权、错误传播与生成代码，不以一次HTTP调用代表全部功能。
- **结论**：上游宿主可依赖已有mcporter工具；鸿蒙完整覆盖需要复合协议/进程环境，超出通用适配机制本身。HTTP子集与完整Skill须分开判断。

### S09 peekaboo：专门宿主能力决定覆盖

- **D1/D2**：说明及darwin/Bridge依赖可以被读取、分析；不能因为能读到os门控就断言加载器已强制执行该门控。
- **D3/D4**：业务由macOS的Peekaboo CLI、Bridge、屏幕与辅助功能权限支撑。具备这些条件的macOS宿主有执行方向；鸿蒙必须有等价UI读取、定位、输入及权限机制，现有证据未提供。
- **D5/D6**：有实际UI执行能力后，反馈才可能改善定位与恢复；界面状态变化限制固定代码复用。核对作用窗口、动作后的真实状态和权限拒绝，不能只看工具返回成功。
- **结论**：核心迁移障碍是平台能力与交互语义。远程macOS控制的仍是macOS界面，不等于能控制鸿蒙界面；SkVM无法仅凭适配说明补足这一差别。

## 4. 综合判断与共性缺口

| 主要条件 | 样本 | 数量 | 路线判断 |
| --- | --- | --- | --- |
| 指令与资源承接为主 | S01–S03 | 3 | 主要适配需求与加载、画像、改写、评测机制匹配；仍依赖模型、资源与会话 |
| 工具绑定决定覆盖 | S04–S06 | 3 | 可与现有工具组合；完整功能范围取决于网络、凭据、文件及渲染等能力 |
| 专门宿主能力决定覆盖 | S07–S09 | 3 | 在匹配宿主中有条件承接，鸿蒙核心缺口需专门环境/平台服务 |
| 整体暂无法判断 | 无 | 0 | 不表示所有分项均已确认；完整包、语义保持和优化收益仍有未知 |

这是9项样本的静态适用性分布，分类结果恰与现有分层一致，依据是逐项需求而非标签。没有汇总为“6/9支持”或“0/9成功”；鸿蒙端运行覆盖率不在本轮范围内。

六维汇总：D1有输入材料承接机制，但完整语义保留未证实；D2有适配机制，但没有九项具体画像/改写结果；D3/D4的决定性条件主要落在外部工具和宿主；D5存在优化入口但样本收益未知；D6有记录/对照设施，但需另定义业务判据。任何一维的机制存在都不能替代其余维度。

## 5. 实践含义

- 优先考虑S01–S03：适合判断已有指令适配路线是否值得采用，分析重点是规则、资源与上下文保留。
- S04–S06先列公共工具需求，再判断SkVM能减少多少逐项适配工作；已有脚本是否还需固化应单独论证。
- S07–S09先确定所需服务是否由项目采用的宿主提供。若没有，不宜继续把提示改写视为核心解决办法；若选择远程执行，应说明实际执行对象和新增架构条件。
- 当前即可审阅源码和完整包、核对功能分支，形成路线选型依据。未来如需减少某项不确定性，可在上游支持环境做定点实验；无需为完成本评估构建鸿蒙VM。

## 6. 证据索引

- [L1 样本清单](c-2a-samples-v1.json)：逐项来源、版本与正文哈希。
- [L2 普查记录](../../group-b/skill-survey/reviewed-skills.json)：按 source_id 对应 id；reason、evidence、script_files。
- [L3 乙组交接](../../group-b/skill-survey/handoff.md)：L1/L2 候选与三个L3宿主缺口。
- [L4 鸿蒙接入契约](../../Group_C2/harmony-skill-contract.md)：第7、9章说明真机实验及未决问题。
- [L5 SkillVM 论文笔记](../../../02-research/papers/2026-chen-skillvm.md)：机制背景；不是本轮复现结果。
- [U1 编译 pass 注册表](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/registry.ts)：ALL_PASSES。
- [U2 环境绑定 pass](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/bind-env/index.ts)：bindEnvPass。
- [U3 并行提取 pass](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/extract-parallelism/index.ts)：extractParallelismPass。
- [U4 JIT 优化循环](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/jit-optimize/loop.ts)：runLoop、pickBestRound；本表描述主训练/测试路径，不将其外推为所有输入模式都有独立验收。
- [U5 JIT-boost 文档](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/docs/jit-boost.md)：Runtime、Integration、适用范围。
- [U6 固化执行器](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/jit-boost/solidifier.ts)：Solidifier、executeTemplate。
- [U7 宿主适配器注册表](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/adapters/registry.ts)：ALL_ADAPTERS、createAdapter。

- [U8 Skill加载器](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/core/skill-loader.ts)：loadSkill、parseSkillMeta、copySkillBundle、buildSkillBundle。
- [U9 能力画像](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/profiler/index.ts)：profile及缓存/运行调用。
- [U10 需求与画像差距处理](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/rewrite-skill/index.ts)：rewriteSkillPass，SCR/TCP输入输出。
- [U11 运行钩子接口](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/runtime/types.ts)：RuntimeHooks；接口存在不等于所有适配器均实现。
- [U12 评测条件注册](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/bench/conditions/index.ts)：CONDITION_RUNNERS。
- [U13 执行证据记录](https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/jit-optimize/record.ts)：writeEvidenceRecord、readEvidenceRecord。
