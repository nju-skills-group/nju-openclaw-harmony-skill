# SkVM / SkCC / SkillSmith 技术机制对比表

> C-1 技术机制对比 · 整合稿 v1.1（审核修订）· 2026-11-01  
> 由颜鑫的 SkVM / SkillSmith 草稿与同伴的 SkCC 分析整合，三方案均按同一九维比较。状态：**内容已整合，待 C-1 成员共同复核；尚未完成最终验收**。  
> **验证范围：论文与固定源码的静态研究。三套工具链的编译、运行、性能及 HarmonyOS 端调用均未实测。**

## 一、比较目标、版本与证据口径

比较三方案怎样在执行前处理 Skill、怎样利用运行反馈、复用什么，以及依赖哪些宿主能力，据此分析其对 OpenClaw → HarmonyOS 移植的价值和边界。沿用[组内九维模板][T1]及[验收计划][T2]，不要求三者都具有同类 AOT/JIT。

- **P（论文）**：作者描述的设计、实验或限制，注明章节；SkVM、SkillSmith 页码均指 PDF 文件页序。
- **S（源码）**：固定提交中查阅到的实现。源码存在、检查通过与任务实际成功是不同证据。
- **I（项目推断）**：结合乙组样本与组内鸿蒙契约提出的应用分析，尚待验证。
- **T（实测）**：须有环境、版本、输入、命令、产物、日志及验收结果。本稿没有 T；作者实验不计入本组实验。

AOT 在本表中泛指执行前处理；JIT 两行沿用模板，但**运行恢复、文件复用、分析缓存与在线代码固化分别记录**。“未发现”只针对文末列明的查阅范围，不代表全仓库审计。三个固定源码提交均未确认是各论文实验所用提交。


初读时可先按以下含义理解术语，源码中的具体字段和行为仍以引用为准：

| 术语 | 本文中的含义 |
| --- | --- |
| Harness / 宿主 | 给模型提供工具调用、执行循环、会话及调度的 Agent 框架。 |
| AOT / JIT | AOT 是执行前的处理；JIT 是利用运行中或跨次运行的信息优化。发生在运行期的操作不都属于 JIT。 |
| IR / AST / emitter | AST 是解析后的语法结构；IR 是便于后续处理的中间表示；emitter 把中间表示写成目标格式。 |
| 能力画像 / SCR | 能力画像记录目标测得的能力；SkVM 的 SCR 记录 Skill 的能力需求，二者用于比较差距。 |
| DAG / pass | DAG 是没有依赖环路的步骤图；pass 是编译链中的一轮专门处理。 |
| workflow / dispatcher / reference | 分别指有步骤依赖的工作流、供 Agent 按需选择的操作集合、可检索的参考指导。 |
| 边界契约 / artifact | 边界契约说明暴露哪些操作、输入输出和使用条件；artifact 是转换后供加载或执行的产物。 |
| guard / warning / HITL | guard 是具体检查或执行条件；warning 是告警，未必阻断；HITL 表示需要人参与确认，是否落实须核对宿主。 |

## 二、统一九维对比表

| 维度 | SkVM | SkCC | SkillSmith | 依据与阅读位置 |
| --- | --- | --- | --- | --- |
| 论文/代码来源与固定版本 | **P**：Le Chen 等，*Skill VM: Write Once, Run Everywhere Efficiently*，SOSP 2026；DOI 10.1145/3830418.3843874。**S**：SJTU-IPADS/SkVM，提交 `632cefe42cdade636720d5ef97494d1e5431682b`，包版本 0.1.4。 | **P**：Yipeng Ouyang 等，*SkCC: Portable and Secure Skill Compilation for Cross-Framework LLM Agents*，arXiv:2605.03353v4，2026-06-03。**S**：Nexa-Language/Skill-Compiler，提交 `59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6`，工作区版本 0.1.0。 | **P**：Duling Xu 等，*SkillSmith: Compiling Agent Skills into Boundary-Guided Runtime Interfaces*，arXiv:2605.15215v1，2026-05-12。**S**：AetherHeart-AI/Aeloon，提交 `e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4`；具体模块为 `aeloon/plugins/SkillGraph/`。Aeloon 的 1.0.0 不作为独立 SkillSmith 版本。 | SkVM：[论文][P]、[快照][C0]、[包声明][CV]。SkCC：[论文 v4][KA]、[快照][K0]、[工作区][K15]。SkillSmith：[论文 v1][SP]、[快照][S0]、[模块][S1]、[项目声明][S14]。 |
| 输入 Skill / 目标输出形式 | **P/S**：源 Skill、脚本/资源及目标模型、Harness、主机环境信息；能力编译使用目标画像。输出目标专用 Skill 变体，以及 SCR、差距、依赖、环境脚本、并行结构等配套产物。 | **P/S**：YAML frontmatter + Markdown → RawAST → SkillIR（论文称 SkIR）→ 各目标文本及 manifest；目录编译另可生成路由清单。核心输出是框架可读文本，不是机器码或 ArkTS。 | **P**：Skill 包及工具、环境、编译策略 → 对外可调用边界；内部可用 workflow、dispatcher、reference。**S**：接收文件/目录并扫描资产与哈希，按形态生成 Python artifact、manifest、配置和工作目录；不推定所有路径均实现论文契约的全部字段。 | SkVM：§3–§5.1，第 5–8 页；[编译入口][C2]、[产物][C3]。SkCC：§3.1、§3.3；[入口][K1]、[IR][K2]、[路由清单][K22]。SkillSmith：§3.1–§3.3，第 4–6 页；[输入][S3]、[编译][S2]、[边界][S4]、[生成][S31]。 |
| AOT：能力差距与依赖处理 | **P**：26 种基本能力及熟练度画像 → 需求/供给差距 → 补偿或替代；提取依赖并生成可重复执行的环境脚本；分析脚本、工具、子智能体三个层次的并行机会。**S**：对应三个 pass；当前能力改写主要约束为局部补偿。 | **P**：通过解析、统一 IR、静态分析和目标格式生成来适配不同框架。**S**：MCP 检查主要核对内置名称 allowlist 和重复项，不安装依赖、不验证服务联通/API 签名；所查路径未发现 SkVM 式目标画像测评与差距补偿。 | **P**：按源包选择 workflow/dispatcher/reference；证据不足时产生 insufficient 诊断，并保留返回原文的路径。**S**：当前形态判定用本地规则；不可编译时公开入口抛出错误，不自动完成论文所述运行回退。workflow 后续图分析调用模型；manifest 提取依赖，工作目录准备按需运行 npm/检查 CLI，部分缺失不阻断。 | SkVM：§4.1–§4.3，第 5–8 页；[需求提取][C19]、[差距比较][C20]、[改写][C5]、[环境][C6]、[并行][C7]、[三轮处理注册][C4]。SkCC：§3.1–§3.3；[分析链][K3]、[MCP 默认行为][K4]。SkillSmith：§3.2/Table 1、附录 A.1，第 5、12 页；[分类][S5]、[分析][S6]、[依赖][S7]、[准备][S8]。 |
| AOT：类型/安全检查 | **P/S**：部分中间结构约束、DAG 检查、文本 guard、环境脚本预执行；源码用 Zod。未发现通用 Skill 静态类型系统或语义保持证明。检查结构和执行条件不等于证明功能正确或鸿蒙权限安全。 | **P**：以 typed IR 为基础进行结构校验、权限审计、约束注入和安全分级。**S**：Schema/权限检查产生的 blocking diagnostic 阻断编译；默认未知 MCP 为 warning，注入约束级别为 Warning。风险字段和 HITL 声明仍需宿主落实，不能据此保证任意脚本或业务逻辑安全。 | **P/S**：Pydantic/枚举、图结构、命令模板及 Python 语法检查；部分输入/guard 缺失仅 warning。默认 `strict_validate=False` 时，图校验 errors 可警告后继续；workflow codegen 的语法错误另行阻断。运行期参数/策略检查单独记录，不当作 AOT 或形式证明。 | SkVM：§4.3、§9，第 7、13 页；[结构][C8]、[guard][C9]、[调用结果][C23]。SkCC：§3.2、附录 E/F；[Schema][K5]、[权限][K6]、[注入][K7]、[阻断条件][K23]。SkillSmith：§3.3、附录 A.2–A.3，第 5–6、12 页；[模型][S9]、[校验][S10]、[模式][S12]、[语法][S11]。 |
| JIT：运行反馈与重新适配 | **P/S**：从重复的系统性失败与恢复轨迹定向改写 Skill。可重执行路径复跑后，按“提分，或在分数容差内降低成本”及逐任务退化门槛选择候选，必要时保留基线；**log-only 路径不复跑、不使用同一选优门槛**。 | **S**：在所查编译入口、IR、分析器、后端与 CLI build 中，未发现运行 trace → 自动改写/重编译 → 再部署的闭环。pre/post/fallback 字段是描述；重新手动编译不等于 JIT。 | **P/S**：受策略约束地执行、返回原始资料、让 Agent 继续；工作流可保存 blocked 状态，修复环境/补输入后 `resume_workflow` 继续既有产物。未在所查路径发现 SkVM 式源 Skill 改写、重编译与评分选优闭环。 | SkVM：§5.2.1、附录 A，第 8、16–17 页；[选优][C11]、[日志例外][C12]。SkCC：[入口][K1]、[字段][K2]、[CLI][K14]。SkillSmith：§3.4–§3.5、附录 A.3，第 6–7、12 页；[执行封装][S20]、[恢复][S21]、[恢复分派][S23]。 |
| JIT：缓存/稳定逻辑复用 | **P/S**：代码固化复用结构稳定、仅参数变化的代码；观察匹配后启用模板，执行失败时回退。复用的是逻辑，不是上一份答案；参数抽取仍可能调用模型。另有画像、提案与轮次持久化。 | **S**：复用统一 IR、emitter 和生成文件；source_hash 进入 manifest 用于追溯。未发现按哈希自动跳过编译的增量策略，也未发现观察热路径后晋升为本地模板的固化器。 | **S**：区分生成产物复用、编译分析缓存、执行步骤结果复用。存在旧 manifest 且包哈希变化时禁用图缓存；Analyzer 可读缓存；workflow 依 step_results 跳过已完成步骤，状态按会话/运行 ID 保存。输入或环境变化后的有效性仍需核查。 | SkVM：§4.1.2、§5.2.2/附录 B，第 6、8–9、17 页；[固化][C13]、[执行][C14]、[参数抽取][C25]。SkCC：[源哈希计算][K25]、[manifest][K12]。SkillSmith：§3.1、附录 A.3，第 4–5、12 页；[缓存判断][S24]、[分析缓存][S6]、[步骤模板][S25]、[状态][S22]。 |
| 对目标宿主或平台的依赖 | **P**：§5.3 还描述资源感知调度，按 API 延迟/限流、CPU 和内存压力节流或暂停子智能体。**S**：需要模型接口、Agent 适配器、原 Skill 运行时/工具；并行需调度支持，固化需调用钩子。注册 8 个适配器含 OpenClaw；本次确认 BareAgent 固化接入，但未据此确认资源调度及全部优化已在各框架接通。 | **S**：源码构建需要 Rust 工具链，声明 edition 2024 / rust-version 1.85。默认核心编译以解析、规则、模板为主；可选 semantic-check 涉及模型。内置 Claude/Codex/Gemini/Kimi 四类后端；运行仍靠目标 Agent、工具、MCP 与权限实现。 | **P**：在 AGENT-H、Codex、OpenCode 评测。**S**：当前核对的是 Aeloon 插件注册/加载链；Python ≥3.11，依赖 LangGraph/LangChain 等。具体产物还可能依赖模型、进程/CLI、文件、网络和原 Skill 环境；论文评测范围不等于当前公开接入范围。 | SkVM：§4.3、§5.3、§6，第 7–9 页；[适配器][C16]、[钩子][C17]、[BareAgent][C15]。SkCC：[工具链][K15]、[默认配置][K16]、[后端][K9]。SkillSmith：§3.5、§4.1，第 6–7 页；[项目依赖][S14]、[插件][S26]、[加载][S27]、[模板导入][S28]。 |
| HarmonyOS 移植可能性与限制 | **I，未测**：可参考目标能力画像、需求/依赖分析、适配改写及反馈优化。仍需目标注册、工具桥接、文件/网络/权限、运行时和调度绑定；环境安装脚本不能创造鸿蒙缺失的系统服务。 | **I，未测**：可参考平台无关元数据、I/O Schema、权限/约束与 emitter 架构。固定版本没有 HarmonyOS/ArkTS 后端；增加声明 emitter 仍不能自动完成业务/API 映射、授权和实际调用。 | **I，未测**：可参考操作边界、I/O、执行策略、证据和回退描述。当前生成路径以 Python 为主，未发现现成鸿蒙输出/接入；需合适宿主或重建目标绑定。reference、恢复或原文回退不能补足缺失的系统能力。 | SkVM：[环境策略][C6]；SkCC：[IR][K2]、[目标枚举][K8]；SkillSmith：§3.3–§3.5、§4.6，第 5–7、9 页，[边界][S4]、[生成器][S31]。共同参照[乙组交接][H1]、[组内鸿蒙契约][H2]；不是最新 SDK 验证。 |
| 实际工具链验证状态 | **未测**：未运行 profiling、AOT、JIT、benchmark 或鸿蒙调用；现有证据为会议论文与选定源码分析。 | **未测**：未执行 cargo build、Skill 编译、Agent 调用、性能或鸿蒙端实验；同伴材料及本次复核均为静态分析。 | **未测**：未安装或实际调用编译/模型/运行入口，未验证鸿蒙调用；现有证据为论文与选定源码分析。 | 三者均无本组 T 证据，不计算鸿蒙覆盖率；后续引用 C-2B 及甲乙组真实记录。 |

## 三、影响结论的实现细节

本节只保留会改变比较结论的细节；基础流程已在九维表说明，不再逐篇重复。

| 对象 / 问题 | 已核对的依据与差别 | 对比较或后续验证的影响 |
| --- | --- | --- |
| SkVM：补偿与替代 | 论文 §4.1.3 提出两者；当前 Pass 1 主要要求局部补偿，需求中有 alternativePaths 不等于已实现任意跨语言替代。[提取][C19]、[改写约束][C5] | 保留论文的替代思路，但不据字段存在宣称可自动完成任意平台移植。 |
| SkVM：guard 与 JIT 准入 | 编译入口在 guard 失败时仍可返回结果和 guardPassed/guardViolations；不代表所有下游均放行。JIT 复跑选优与 log-only 分支不同；附录 A 允许提分，或在分数容差内降成本，另以 ρ=0.09 限制逐任务退化，不是严格零退化。源码的成本比较还要求数据可比且有有效成本记录。[guard 调用][C23]、[选优][C11]、[日志][C12] | 编译返回、guard 通过、提案入选和独立功能验收分别记录。日志优化不能写成已通过复跑评估。 |
| SkVM：画像与结果确认 | 附录 A.2 提供目标画像，但当前独立 jit-optimize 文档/日志路径无同一依赖；不能要求所有 JIT 先 profiling。附录 B 的 Accept 语义确认与所查 BareAgent 模板成功后 replace/end_turn 路径不完全相同。[架构][C22]、[日志][C12]、[固化][C14]、[BareAgent][C15] | 固化命中或进程退出成功均不能独立证明任务正确；需功能验收。不能据支持 OpenClaw 推出其固化钩子已接通。[OpenClaw 适配器][C18]、[接入文档][C21] |
| SkCC：MCP 检查与风险字段 | 论文 §3.2 强调依赖校验与安全分级；默认 Analyzer 使用 strict=false 的 MCP checker，未知名称仅 warning。build_ir 从元数据读取 security_level，缺省 Medium；字段存在不证明已按风险自动重算或在宿主强制 HITL。[分析链][K3]、[MCP][K4]、[分级字段构建][K17] | 名称可信、服务在线、权限声明、授权执行分别核验；不能把默认告警写成阻断，也不把风险标记当成运行控制。 |
| SkCC：输出以实现为准 | CodexEmitter 渲染模板，generate_assets 返回空；模板实际含 frontmatter 和 XML 标签。backend/CLI 的部分旧注释仍提 JSON Schema 产物。[Codex 实现][K10]、[模板][K19]、[旧注释所在枚举][K8] | 记录实际生成形式；不写“必定额外生成 JSON Schema 文件”，也不因注释称纯 Markdown 就忽略 XML 标记。 |
| SkCC：多目标输出与可选模型检查 | emit_outputs 把目标文件写入同一目录；Claude/Kimi 固定名同为 SKILL.md，Codex/Gemini 则都按 skill 名 + .md 写入。静态可推断多目标同目录有覆盖风险，未复现。默认 semantic_check=false，CLI build 用 Compiler::new()；启用可选检查才另涉及模型。[写入逻辑][K11]、[命名规则][K18]、[默认配置][K16]、[CLI][K14]、[feature][K20] | 实验时按目标隔离输出目录；确认实际配置及产物。不能把所有编译路径概括为依赖模型或完全不依赖模型。 |
| SkillSmith：分类与边界接入 | 论文 §3.2 描述结构信号与编译期模型结合；当前 assess_compilability 为本地规则，workflow 后续分析调用模型。论文的 insufficient 原文回退与公开 compile() 的不可编译抛错分支应分别记录。[编译入口][S2]边界 dataclass/运行模块存在，不证明所有生成路径都完整接通相同公共契约或回退胶囊。[分类][S5]、[图分析][S6]、[边界][S4]、[运行模块][S29]、[原文回退元数据][S30] | 分开描述论文接口设计和各生成/加载路径，避免凭模块存在声称完整端到端支持。 |
| SkillSmith：检查与缓存边界 | 宽松图校验、workflow 语法阻断、运行期参数/网络策略是不同机制；网络策略依赖标注风险，不是全面网络行为检测。恢复时按已有 step_results 跳过，输入变化后的失效规则尚待验证。[模式][S12]、[语法][S11]、[参数][S13]、[网络][S19]、[恢复模板][S25] | 不能将“产物生成”“有工作目录”“有状态”写成全部检查通过、系统级沙箱或缓存结果必然有效；.sandbox 准备代码主要证明复制/安装/检查。[环境准备][S8] |

共同边界：typed IR、Pydantic/Zod、语法、图及文本规则检查都只有各自覆盖范围，不能由此推出自然语言任务的语义保持、完整权限安全或鸿蒙功能正确。SkVM 的 TypeScript typecheck 检查自身源码，不是输入 Skill 的通用类型证明。SkCC 论文附录 E/F 也限定了规则覆盖与语义安全。[SkVM 包声明][CV]、[SkCC 论文][KP]、[SkillSmith 模型][S9]

SkVM 会议 PDF 的附录 A/B 标为未经同行评审的补充材料。本稿使用其算法细节时保留这一限制，不把该说明套用到另外两篇论文，也不推测论文与代码差异的成因。

## 四、综合结论与给乙组的反馈

### 4.1 三者各自解决什么问题

- **SkVM：目标差距适配。**长处是把模型、Harness、环境差异转成可分析和可反复优化的问题，适合研究补偿改写、依赖绑定和重复执行成本；仍受模型改写质量、宿主能力和结果验收限制。[需求提取][C19]、[环境][C6]、[反馈][C11]
- **SkCC：统一结构与目标格式。**长处是分离源内容、IR、静态分析和 emitter，减少逐框架重复维护，并统一部分声明检查；输出文本的运行效果、安全约束执行及外部依赖仍靠宿主。[IR][K2]、[分析链][K3]、[后端注册][K9]
- **SkillSmith：可调用边界与运行产物。**长处是按源形态选择 workflow/dispatcher/reference，明确暴露的操作及约束，并保留执行恢复路径；当前 Python 运行栈、边界接入和缓存有效性仍是落地条件。[分类][S5]、[边界][S4]、[恢复][S21]

以上按机制定位比较，不按不同论文的成功率或 token 数直接排名。论文样本、模型、Harness、评分与成本口径未统一；作者报告的跨方法比较也不等于本组已完成公平对照。

### 4.2 有依据的适用场景与验收条件

以下均为 **I，未测**。乙组 L1/L2/L3 是移植难度，SkVM 的 L1/L2/L3 是能力熟练度，二者不互换。

| 项目问题/样本 | 可借鉴的机制 | 需要另行确认的条件 |
| --- | --- | --- |
| L1 说明/规范类 Skill | SkVM 的要求明确化；SkCC 的元数据/正文整理；SkillSmith 的 reference 形态。 | 提示能被目标加载并正确使用，输出仍满足原任务。reference 生成不等于完成鸿蒙注册。 |
| L2 网络/文件/通用逻辑，如 weather | SkVM 的依赖与差距分析；SkCC 的 I/O、权限及声明整理；SkillSmith 的操作边界/dispatcher。 | 实际网络、文件和业务 API 可调用；输入、错误、结果与权限正确。更换服务须保留差异记录。 |
| 固定步骤或独立操作集合 | SkCC 的统一 IR 与多个 emitter；SkillSmith 对 workflow/dispatcher 的分流；SkVM 的依赖与并行提取。 | 先区分工具集合与有依赖流程，再验证目标调度、工具实现及副作用；不能只验证生成文件。 |
| 重复代码/长流程部分失败 | SkVM 对稳定代码固化；SkillSmith 保存状态、修复条件后恢复。两者解决不同的重复工作。 | 固化要独立检查输出；恢复要核验上游结果仍有效、是否需要重跑，以及输入变化后的缓存失效。 |

上述建议依据统一表中的编译、复用与依赖机制，并结合[乙组交接][H1]和[组内鸿蒙契约][H2]形成。

### 4.3 不能单靠 VM/编译补足的能力

| 障碍 | 三方案共同边界 | 应补充的目标端证据 |
| --- | --- | --- |
| tmux 的 PTY、shell、持久会话 | 改写说明、表达流程或恢复状态不会创造底层会话服务。 | 目标服务、会话生命周期及真实交互日志。 |
| mcporter 的 MCP 连接方式 | 名称检查或工具边界不等于服务可用；远程 HTTP 与本地 stdio 子进程分开判断。 | 逐传输方式记录运行位置、服务、调用与失败结果。 |
| peekaboo 的 macOS UI/权限 | 发射文本或返回原文无法替代目标 UI 自动化与授权能力；远程 Mac 执行不记作鸿蒙本机移植。 | 目标替代接口及授权/拒绝路径，或明确远程方案的功能范围。 |
| 业务/API、账号、私有数据和网络 | 编译不提供业务实现、账号凭据、数据授权或服务可达性；依赖声明/安装只覆盖其中一部分。 | API 语义映射、可调用实现、受控环境和功能结果。 |
| 注册、ArkTS 入口、权限及结果回传 | 文本/manifest/Python artifact 不等于完成鸿蒙工程与调用链；权限标记/提示不等于宿主强制执行。 | 与甲组确认契约，提供工程、构建、实际调用及成功/失败分支证据。 |

样本障碍来源为[乙组交接][H1]，目标接入前提参考[组内鸿蒙契约 §§3–6][H2]；表中是静态分析和项目推断，不是本次运行结果。本文未独立验证最新鸿蒙 SDK。

### 4.4 给乙组分类与 C-3 SkillIR 的建议

建议乙组在移植难度之外，记录四类障碍：**模型执行差距、Harness 工具/调度差距、宿主运行时/服务差距、平台权限与应用绑定**。前三项参照 SkVM 的目标失配，最后一项是本项目的补充观察维度，不当作论文已验证分类。

再增加一个与难度并行的“源形态”观察：**说明/参考、独立操作集合、有依赖的流程**，借鉴 SkillSmith 的处理形态。SkCC 的结构化字段可用于统一记录；这不是把三套分类强行换算。

移植档案可补记原始功能/I-O、源依赖与目标提供方、实际执行位置、补偿/替代/桥接/删减方式、检查状态及证据。功能删减或改为远程执行后按实际范围报告，不能当作原功能完整本机移植。这些是讨论建议，不新增乙组硬性交付要求。[需求提取][C19]、[SkCC IR][K2]、[SkillSmith 形态][S5]

对 C-3，可分别参考 SkVM 的能力需求/依赖/流程关系、SkCC 的元数据/Schema/权限与 emitter 分离、SkillSmith 的操作边界/策略/证据/回退。通用 SkillIR 与 HarmonyOS 特有绑定分开，明确字段语义及功能验收；这里只提出设计参考，**未实现三套工具链的组合或自动互转**。[产物][C3]、[SkIR][K2]、[边界][S4]、[项目契约][H2]

## 五、开放问题与后续回填

| 问题 | 当前结论 | 需要的核验或协作 |
| --- | --- | --- |
| 源码是否等同论文实验版本？ | 三者均已固定阅读版本，尚未确认实验版本等同。 | C-1 共同复核版本；C-2B 记录其实际运行提交与配置。 |
| 编译产物能否被正确发现、加载、调用？ | 三者仅静态核对，生成成功不能代替调用。SkCC 多目标同目录有静态覆盖风险，尚未复现。 | C-2B 按目标隔离目录，保存输入、产物、环境、命令和日志。 |
| 检查失败怎样影响运行，约束是否被落实？ | 已区分 error/warning、宽松/严格检查及宿主责任；没有运行验证。 | 核验合法/非法输入、告警/拒绝、实际授权及副作用；不将规则命中率当安全保证。 |
| 反馈优化、固化和恢复是否保持任务功能？ | SkVM 日志与复跑路径不同；SkillSmith 恢复不等于重编译；两者均需结果校验。 | C-2A/C-2B 确定独立验收、退化条件和缓存失效案例，C-1 回填机制解释。 |
| 收益何时能抵消测评/编译/优化成本？ | 不同论文的数据不能直接给本项目排序或结算。 | 同 Skill、模型、Harness 和环境下比较功能、延迟、token 与前期成本，注明调用次数和口径。 |
| 鸿蒙目标缺口具体由谁提供？ | 固定版本均未提供已验证的完整鸿蒙移植链；L3 底层能力缺口尚在。 | 甲组确认目标契约，乙组提供语义映射与工程/调用证据；C-2 据实判定覆盖。 |

C-1 的后续工作是共同复核整合稿、形成有依据的反馈，并在实际结果到达后更新比较；可行工具链实验由 C-2B 主推。未实测不会被写成成功；静态机制对比也不直接计算覆盖率。最终状态按[组内验收计划][T2]更新。

## 六、证据索引与查阅范围

下列为可直接复查的位置。链接均固定提交；函数与行号指对应快照，不是运行记录。

### 6.1 SkVM

论文以本地会议 PDF 为页码依据，共 17 页，印刷页码为 482–498；已重新核对第 1、5–9、13、16–17 页。第 1 页印有[会议 DOI][P]，编号与表内一致，但本次浏览工具无法访问其在线页面，因此不标为“在线访问已验证”。可另读[早期 arXiv v3][PV]，其标题不同，不能拿该预印本的页码替代本文会议版页码。

| 内容 | 论文位置 | 固定源码位置 |
| --- | --- | --- |
| 输入输出与能力画像 | §3–§4，第 5–7 页，Figure 5–6；Table 1 是基本能力的代表例子，不是完整 26 项。 | [compileSkill()][C2]：src/compiler/index.ts:36；[ArtifactBag][C3]：artifacts.ts:14；[extractSCR()][C19]：extractor.ts:18；[analyzeGaps()][C20]：gap-analyzer.ts:15。 |
| 改写、依赖、并行 | §4.1–§4.3，第 5–8 页。 | [runPass1Agentic()][C24]：agent.ts:412，约束在[第 206 行][C5]；[安装策略][C6]；[simulateAndRepairScript()][C10]：:114，:36 实际启动 bash；[runPass3()][C7]：parallelism.ts:36，:126 规范化、:249 检查环。 |
| 结构与 guard | §4.3、§9，第 7、13 页。 | [SCRSchema][C8]：core/types.ts:357；[validateGuard()][C9]：guard.ts:17；[guard 结果处理][C23]：compiler/index.ts:150。 |
| 反馈与固化 | §5.2，第 8–9 页；附录 A/B，第 16–17 页。 | [pickBestRound()][C11]：loop.ts:1808，逐任务门槛在 :1896 后；[runLogOnly()][C12]：:1046，:1106 后无重评估；[createBoostHooks()][C13]：jit-boost/index.ts:56；[createBeforeLLMHook()][C14]：solidifier.ts:175；[参数抽取][C25]：:266；[executeTemplate()][C26]：:402。 |
| 资源调度设计 | §5.3，第 9 页。 | 本稿仅记录论文设计，未核验该动态资源调度在固定源码和目标 Harness 中完整接通；不能以编译出的并行图代替运行调度证据。 |
| 目标接入 | §6，第 9 页。 | [适配器表][C16]：registry.ts:22；[RuntimeHooks][C17]：runtime/types.ts:69；[BareAgent 接入][C15]：:193 后；[OpenClaw 适配器][C18]与[JIT 文档][C21]。 |

95% 的“覆盖”指 26 种能力对论文语料中需求的描述覆盖，不是 95% Skill 在鸿蒙运行成功；作者在所选模型/Harness 的实验也不作为本组实测。全文将适配器、检查分支和论文设计与真实运行分开。

### 6.2 SkCC

论文以[arXiv v4 原文][KP]为准，方法见 §3.1–§3.3，评测见 §4，局限见附录 E/F。2026-11-01 对同伴材料所涉及的核心路径补做静态复核，并与其 2026-10-31《SkCC 证据索引》的 C01–C12 逐项对照。下表保留原编号对应关系，源码链接可直接访问，不依赖另行提供的本地归档。

| 内容 | 同伴 SkCC 索引编号 | 固定源码位置与核对对象 |
| --- | --- | --- |
| 编译流程 / 输出 | C01 | [Compiler::compile_file][K1]：nexa-skill-core/src/lib.rs:97；[emit_outputs][K11]：:196；[generate_manifest][K12]：:263；[路由生成调用][K22]：:357。 |
| IR / 来源追溯 | C03、C12 | [SkillIR][K2]：ir/skill_ir.rs:60，I/O、权限、pre/post/fallback、流程与 source_hash；[ASTBuilder::build_from_content][K13]：frontend/ast.rs:55；[compute_hash][K25]：:74，计算源内容 SHA-256，不据此推定增量缓存；[等级字段构建][K17]：ir/builder.rs:142。 |
| 规则与阻断 | C02、C07、C08 | [Analyzer::new][K3]：analyzer/mod.rs:76，装配默认分析器；[Analyzer::analyze][K23]：:91，:107 后按 blocking diagnostic 判定失败；[is_blocking][K21]：error/diagnostic.rs:23；[SchemaValidator::validate][K5]：schema.rs:34；[PermissionAuditor::audit][K6]：permission.rs:162。 |
| MCP / 文本约束 | C06、C09 | [MCPDependencyChecker::new/check][K4]：mcp.rs:75/102；[load_default_patterns][K24]：anti_skill.rs:31，包含 HTTP、解析、破坏性数据库操作和循环四组关键词规则；[AntiSkillInjector::inject][K7]：:54 扫描 procedure 文本，:71–75 注入 Warning 级约束。 |
| 后端 / 文件命名 | C04、C05 | [TargetPlatform][K8]：backend/mod.rs:28；[注册四类 emitter][K9]：registry.rs:25；[固定文件名][K18]：backend/mod.rs:95；[CodexEmitter][K10]：codex.rs:44/58；[实际模板][K19]：codex_md.j2:18。 |
| 默认配置 / 构建条件 | C10、C11 | [CompilerConfig 默认值][K16]：lib.rs:64；可选调用在 :129 后；[CLI build][K14]：commands/build.rs:50，:62 创建默认 Compiler；[工具链声明][K15]：Cargo.toml:21；[semantic-check feature][K20]：nexa-skill-core/Cargo.toml:72。 |

补查了 Claude/Gemini/Kimi emitter 实现及 IR builder；未穷尽 CLI 配置、可选语义检查或安全规则的全部路径。未执行编译或复现覆盖风险。

### 6.3 SkillSmith

论文以[arXiv v1 PDF][SPDF]为准，共 18 页；方法 §3.1–§3.5 见第 4–7 页，执行设置 §4.1 见第 7 页，局限 §4.6 见第 9 页，附录 A.1–A.3 见第 12 页。沿用 2026-10-31 的核对结果。下列未写前缀的 skillgraph 文件位于 `aeloon/plugins/SkillGraph/skillgraph/`。

| 内容 | 固定源码位置与核对对象 |
| --- | --- |
| 包输入 / 编译 / 形态 | [resolve_skill_input/build_skill_package][S3]：package.py:48/80；[compile][S2]：__init__.py:61；[assess_compilability][S5]：compilability.py:84；[Analyzer.analyze][S6]：analyzer.py:334，:349 后读缓存、:391 调模型。 |
| 产物与依赖准备 | [workflow 生成][S31]：codegen.py:15；[dispatcher][S16]：dispatcher_codegen.py:153；[reference][S17]：reference_codegen.py:150；[extract_manifest][S7]：manifest.py:77；[bootstrap_sandbox][S8]：sandbox.py:20，:185 后限定 hard failure。 |
| 边界与检查 | [ArtifactBoundarySpec][S4]：boundary.py:26；[模型][S9]：models.py:26，图检查在 [:133][S18]；[validate_graph][S10]：validator.py:70；[宽松/严格模式][S12]：__init__.py:223；[语法检查][S11]：codegen.py:64；[运行期参数][S13]：boundary_runtime.py:1320，网络策略在 [:1397][S19]。 |
| 恢复与缓存 | [WorkflowTool._run_and_wrap][S20]：tools.py:166；[ResumeWorkflowTool.execute][S21]：:483；[状态存储][S22]：workflow_state.py:52；[恢复分派][S23]：workflow_loader.py:126；[编译缓存判断][S24]：__init__.py:122；[执行模板][S25]：codegen.py:654/696/735。 |
| 宿主接入与回退模块 | [插件注册][S26]：plugin.py:88；[动态加载][S27]：workflow_loader.py:143；[项目依赖][S14]：pyproject.toml:6、:50 后；[生成模板导入][S28]：codegen.py:248；[边界运行模块][S29]：boundary_runtime.py:30；[_lossless_reference()][S30]：:395，读取原文回退元数据。 |

查阅范围包含包扫描、路由、分析/规范化、模型/校验、依赖准备、三种生成器及部分边界运行、插件加载、恢复和状态持久化；没有做 Aeloon 全仓库安全审计，也没有运行其模型服务或产物。

### 6.4 项目资料与证据维护

[九维基线][T1]、[验收计划][T2]、[乙组交接][H1]和[组内鸿蒙契约][H2]均固定团队提交 `a924ddea1d78c89d42cce8acdf5badc8b7d3ac02`。这些资料用于保持比较前提一致，不代表所有静态候选已移植或鸿蒙接口已由本稿实测确认。

后续新增实测时保留其实际提交、输入包、目标模型/Harness/设备、命令、原始产物、失败日志和独立验收依据；版本变化或与当前分析冲突时分别记录。本文是可提交评审的静态机制整合稿，最终验收及覆盖率结论仍按组内流程和实际证据确认。

[T1]: https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-c/research/mechanism-comparison.md
[T2]: https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-c/plan.md
[P]: https://doi.org/10.1145/3830418.3843874
[C0]: https://github.com/SJTU-IPADS/SkVM/tree/632cefe42cdade636720d5ef97494d1e5431682b
[CV]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/package.json
[KA]: https://arxiv.org/abs/2605.03353v4
[K0]: https://github.com/Nexa-Language/Skill-Compiler/tree/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6
[K15]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/Cargo.toml#L21
[SP]: https://arxiv.org/abs/2605.15215v1
[S0]: https://github.com/AetherHeart-AI/Aeloon/tree/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4
[S1]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/README.md#L1
[S14]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/pyproject.toml#L1
[C2]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/index.ts#L36
[C3]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/artifacts.ts#L14
[K1]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/lib.rs#L97
[K2]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/ir/skill_ir.rs#L60
[K22]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/lib.rs#L357
[S3]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/package.py#L48
[S2]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/__init__.py#L61
[S4]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/boundary.py#L26
[S31]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/codegen.py#L15
[C19]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/rewrite-skill/extractor.ts#L18
[C20]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/rewrite-skill/gap-analyzer.ts#L15
[C5]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/rewrite-skill/agent.ts#L206
[C6]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/bind-env/install-policy.ts
[C7]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/extract-parallelism/parallelism.ts#L36
[K3]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/analyzer/mod.rs#L76
[K4]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/analyzer/mcp.rs#L75
[S5]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/compilability.py#L84
[S6]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/analyzer.py#L334
[S7]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/manifest.py#L77
[S8]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/sandbox.py#L20
[C8]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/core/types.ts#L357
[C9]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/guard.ts#L17
[C23]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/index.ts#L150
[K5]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/analyzer/schema.rs#L34
[K6]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/analyzer/permission.rs#L162
[K7]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/analyzer/anti_skill.rs#L54
[S9]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/models.py#L26
[S10]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/validator.py#L70
[S12]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/__init__.py#L223
[S11]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/codegen.py#L64
[C11]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/jit-optimize/loop.ts#L1808
[C12]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/jit-optimize/loop.ts#L1046
[K14]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-cli/src/commands/build.rs#L50
[S20]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/tools.py#L166
[S21]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/tools.py#L483
[S23]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/workflow_loader.py#L126
[C13]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/jit-boost/index.ts#L56
[C14]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/jit-boost/solidifier.ts#L175
[C25]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/jit-boost/solidifier.ts#L266
[K13]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/frontend/ast.rs#L55
[K12]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/lib.rs#L263
[S24]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/__init__.py#L122
[S25]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/codegen.py#L654
[S22]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/workflow_state.py#L52
[C16]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/adapters/registry.ts#L22
[C17]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/runtime/types.ts#L69
[C15]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/adapters/bare-agent.ts#L193
[K16]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/lib.rs#L64
[K9]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/backend/registry.rs#L25
[S26]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/plugin.py#L88
[S27]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/workflow_loader.py#L143
[S28]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/codegen.py#L248
[K8]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/backend/mod.rs#L28
[H1]: https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-b/skill-survey/handoff.md
[H2]: https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/Group_C2/harmony-skill-contract.md
[C22]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/docs/architecture.md
[C18]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/adapters/openclaw.ts
[C21]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/docs/jit-boost.md
[K17]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/ir/builder.rs#L142
[K10]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/backend/codex.rs#L44
[K19]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-templates/templates/codex_md.j2#L18
[K11]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/lib.rs#L196
[K18]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/backend/mod.rs#L95
[K20]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/Cargo.toml#L72
[S29]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/boundary_runtime.py#L30
[S30]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/boundary_runtime.py#L395
[S13]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/boundary_runtime.py#L1320
[S19]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/boundary_runtime.py#L1397
[KP]: https://arxiv.org/html/2605.03353v4
[C24]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/rewrite-skill/agent.ts#L412
[C10]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/passes/bind-env/simulate-and-repair.ts#L114
[K21]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/error/diagnostic.rs#L23
[K23]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/analyzer/mod.rs#L91
[K24]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/analyzer/anti_skill.rs#L31
[K25]: https://github.com/Nexa-Language/Skill-Compiler/blob/59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6/nexa-skill-core/src/frontend/ast.rs#L74
[S16]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/dispatcher_codegen.py#L153
[S17]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/reference_codegen.py#L150
[S18]: https://github.com/AetherHeart-AI/Aeloon/blob/e5afaa1c27eb8fa2f7c1e76545aa92291eeaf4e4/aeloon/plugins/SkillGraph/skillgraph/models.py#L133
[C4]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/compiler/registry.ts#L11
[C26]: https://github.com/SJTU-IPADS/SkVM/blob/632cefe42cdade636720d5ef97494d1e5431682b/src/jit-boost/solidifier.ts#L402
[SPDF]: https://arxiv.org/pdf/2605.15215v1
[PV]: https://arxiv.org/abs/2604.03088v3
