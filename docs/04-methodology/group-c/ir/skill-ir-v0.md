# SkillIR 规范草案（v0，A/B 整合候选）

> 最终成果 C-3；状态：**阶段草稿，待 A/B 互审，未完成最终验收**。
> 成员 A：主笔 §3.1–3.5 平台无关字段定义，并完成九个示例的字段交叉验证（2026-10-31）。成员 B：吴禹成（按本人声明；推荐分工中的姓名写法不用于推定身份）：主笔 §3.6 目标绑定设计、§4 样本表示与 §5 交接清单。全部鸿蒙绑定均为**待验证**，不是可构建工程或已运行 Skill。

## 1. 目的与非目标

SkillIR 表达来源、任务语义、依赖、权限、副作用、功能范围和证据，支持移植分析及后续生成器消费。核心层不包含 HarmonyOS 字段；目标投影单独描述注册、入口与能力实现路线。

本草案不实现 VM、编译器、生成器、模型服务或鸿蒙业务模块；不保证提示词能自动编译为 ArkTS。本文的函数名、目标名称和错误码是设计建议，不能当作甲组实测结论。SkVM/SkCC 的具体 IR、AOT/JIT 术语由 C-1 核对后引用，不把本草案称为其原生格式。

## 2. 输入依据与证据边界

研究仓库固定版本为 `a924ddea1d78c89d42cce8acdf5badc8b7d3ac02`（读取于 2026-10-31）；乙组 PR #13 已合并。GUIDE 中“未合并期间引用 126d80…”的前提已变化，现使用合并后的固定版本：

| 编号 | 来源 | 用途与边界 |
| --- | --- | --- |
| S1 | [C 组 GUIDE](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-c/GUIDE.md)、[plan](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-c/plan.md) | C-3 统一入口、共同复核、证据要求 |
| S2 | [methodology](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-b/skill-survey/methodology.md)、[handoff](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-b/skill-survey/handoff.md)、[classification](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-b/skill-survey/classification.md) | 样本、静态分级、门控语义与功能子集规则 |
| S3 | [reviewed-skills.json](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-b/skill-survey/reviewed-skills.json)、[source-manifest.json](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/group-b/skill-survey/source-manifest.json) | 身份、版本、SKILL.md 哈希、声明依赖、许可登记；许可登记不等于发布许可审查 |
| S4 | [鸿蒙接入契约 v1.0](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/04-methodology/Group_C2/harmony-skill-contract.md) | §3–6 注册/回包/权限；§7 E1–E7 仍待做，§9 尚有疑问，不能替代真机契约 |
| S5 | [生命周期源码地图](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/blob/a924ddea1d78c89d42cce8acdf5badc8b7d3ac02/docs/02-research/openclaw-skill-lifecycle-source-map.md) | 分析 OpenClaw `520302d8ee6` 的发现/加载/指令/工具链；版本与乙组样本不同，不能混为同一次运行证据 |
| S6 | [OpenClaw 固定版 skills](https://github.com/openclaw/openclaw/tree/d79ab6195d8d0566b285008bcc30c01a6ce368e2/skills) | 本稿直接核对六个内置样本的 SKILL.md；三个 L1 以 S2/S3 的固定版本普查记录为依据，未重新下载其全部源文件 |

本文只有资料核对与结构一致性检查。原平台和鸿蒙运行状态全部为“未运行”；无构建、实际调用、录屏、延迟、内存或覆盖率数据。九个样本不是 C-4 的首批五个正式发布成果，也不是 C-2 的统计分母。

## 3. 规范内容

### 3.1 身份、来源、版本与范围（成员 A 主笔）

核心字段是附带 `examples/skill-ir-examples-v0.json` 的**候选接口**，尚未冻结；字段如需改名，须同步九个示例与检查脚本。

**身份与来源字段：**

| 字段 | 类型/取值 | 语义与约束 |
| --- | --- | --- |
| `id` | string，IR 内唯一 | 本记录 ID。完整记录沿用普查 `id`（如 `bundled:weather`）；子集/远程记录在其后追加范围后缀（如 `bundled:weather/current-summary`）。子集有独立 ID，不覆盖原记录 |
| `source.record_id` | string | 乙组普查 reviewed-skills.json 的权威记录键（S3） |
| `source.registry_slug` | string \| null | ClawHub 注册表 slug；bundled 来源为 `null`。slug、frontmatter name 与普查 ID 三者不能合并 |
| `source.frontmatter_name` | string | 源 frontmatter `name` 原文；可与 slug 不同（davinci 的 slug=`davinci-first-principles`、name=`first-principles`） |
| `source.version` | string | bundled 为固定 commit，ClawHub 为发布版本号；源 commit 不硬填 SemVer |
| `source.skill_md_sha256` | string | SKILL.md 单文件哈希（64 位十六进制），不是全包哈希 |
| `source.url` | string | 固定版本的源链接 |
| `source.license_record` | string | 沿用 S3 登记原文；许可登记不等于发布许可审查（C-4 另行验收） |
| `source.resource_inventory` | object[] | 随包静态资源清单（`path` + `sha256`），供 L1 资源加载与许可核对；可为空数组 |
| `source.invocation_policy` | object \| null | 源调用策略原文（`user-invocable`、`disable-model-invocation` 等，见 S5 §3.5）；`null` = 源未声明。目标端不得把 `disable-model-invocation` 自动变成可自动触发，也不据此映射 visibility |

**scope 规则（纳入乙组"功能子集须另立 scope 记录"）：**

| 字段 | 语义与约束 |
| --- | --- |
| `scope.mode` | `full`（拟保留原完整主要功能，是设计目标）、`subset`（仅保留子功能，**须另立 scope 记录**，不得覆盖原记录分级）、`remote-host`（业务在鸿蒙外宿主执行）；描述的是**本记录的设计范围**，不表示已经实现 |
| `scope.parent_record` | `subset`/`remote-host` 必填，指回原普查记录；`full` 为 `null` |
| `scope.included / excluded` | 功能增删清单；`subset` 的 `excluded` 必须非空，且与 `task.negative_trigger` 一致 |
| `scope.execution_location` | 业务实际运行位置；`remote-host` 必须以 `remote-` 开头（如 `remote-linux`、`remote-macos`），混合位置写组合值（如 `harmony-client-and-remote-mcp-server`） |
| `scope.implementation_status` | 实现状态（v0 取 `not-implemented`）；与 `portability` 分开登记，不因可移植性推断已实现 |

"完整功能 + 远程执行"在 v0 以 `mode=remote-host` 且 `included` 覆盖全部主要功能的方式表达；是否拆为"功能范围 × 执行位置"两个正交字段，列于 §5.2 开放问题。示例中三个 L1 使用 `full` 表达拟保留原主要业务，仍待确认源内容与模型行为；L2 登记可独立开展的子集。原 Skill 保持乙组原分级，不以子集重写其等级。

### 3.2 任务与调用语义（成员 A 主笔）

| 字段 | 语义与约束 |
| --- | --- |
| `task.trigger` | 触发条件与任务描述，源自源 description 与正文；保留功能边界 |
| `task.negative_trigger` | 禁用/排除边界；`subset` 记录须与 `scope.excluded` 一致 |
| `task.operations[].operation` | 操作名；须与 `binding.entry.functions` 一致 |
| `task.operations[].parameters[]` | 语义输入：`semantic_name`（语义参数名，不从对象属性顺序推断位置）、`target_arg`（`argN` 目标占位，从 1 起）、`argv_index`（目标 argv 下标，从 0 起）、`encoding`（`string` 或 `json-string-proposed`）、`required` |
| `task.operations[].output_contract` | 输出约定；无法给出精确 Schema 时显式标注待复核来源，不虚构字段 |
| `task.operations[].errors[]` | 该操作可发生的业务错误分支（候选码见 §3.6.4；L1 缺输入可声明 `needs-clarification` 数据分支，由目标执行器协调，不新增系统状态） |
| `invocation.mode` | `prompt-guided`（提示执行器消费指引）、`function-adapter`（函数适配器调用）、`host-service`（宿主服务） |
| `invocation.status` | `proposed` / `confirmed`；改 `confirmed` 须有甲组契约证据 |

规则：
- 读取指令不等于执行工具，也不授予权限。
- L1 的提示、引用与上下文必须由目标端明确的模型/Agent 执行器消费；注册一个 ArkTS 空方法不会获得推理能力；没有执行器就登记 `gaps`，不能把固定文本输出当作模型行为等价。
- `required` 取值 `true` / `false` / `"pending-contract"`：源文与目标参数契约（Q4）复核前必填性未定的，用 `"pending-contract"` 占位，不虚构布尔值。
- `encoding: "json-string-proposed"` 表示复杂对象以 JSON 字符串编码的候选方案，须待 Q4 确认后冻结。

### 3.3 工具与依赖（成员 A 主笔）

`dependencies.source_declared` 抽象乙组普查的 `requires.*` / `primary_env` 字段，**区分门控与推荐**：

| IR 字段 | 普查字段 | 语义 | 门控性 |
| --- | --- | --- | --- |
| `bins_all` | `requires_bins_all` | 全部必需的可执行文件 | 门控：须全部满足 |
| `bins_any` | `requires_bins_any` | 至少一种可执行文件 | 门控：任一满足即可 |
| `env_all` | `requires_env` | 环境变量键名 | 显式门控 |
| `config_all` | `requires_config` | 宿主配置键 | 显式门控 |
| `primary_env` | `primary_env` | 首选配置键 | **推荐，不是门控**；不得升级（S2 规则） |
| `os` | `declared_os` | 源 OS 约束 | 约束记录；未声明 ≠ 支持所有平台 |
| `metadata_namespace` | `metadata_namespace` | frontmatter 命名空间 | 解析回退链 `openclaw → clawdbot → clawdis`；保留实际命名空间，旧字段遗漏 ≠ 无依赖 |

- 未声明一律 `null`；`null` ≠ 已验证无依赖。
- **安装建议不是门控**：frontmatter `install` 条目（如 weather 的 brew/curl）是安装建议，不生成全局 `bins_all`。weather 的 `curl` 属于正文备用分支，`bins_all` 保持 `null`；meme 的 Imgflip 凭据属于远程分支条件，不填成全局 `env_all`。
- `dependencies.semantic_requirements[]` 记正文/业务依赖：`basis` ∈ `frontmatter`（元数据声明）/ `source-body`（正文行为）/ `design-requirement`（移植设计所需）；`branch` 记适用分支：`all`（无条件）、具体分支名（条件适用，如 `local-svg/local-png`、`imgflip`）、`preferred` / `fallback-…`（首选与备用，如 weather）、`selected-scope`（仅所选范围需要）。
- `dependencies.target_replacements[]` 记录源依赖到目标实现的替代关系（`provider` + `status`）；CLI/宿主工具须有替代能力或登记缺口，不能把工具名替换成空 import。
- 普查 `host_tools_text_hits` 只是预设工具词的正文命中线索（有漏检/误检），IR 不直接采纳为依赖；依赖判定以 reason、完整正文及固定版本证据为准（S2）。

### 3.4 权限与副作用（成员 A 主笔）

`effects` 使用**封闭词汇表**（v0）；新增词须经 A/B 共同确认后加入，不在示例中即兴造词：

| 词 | 语义 |
| --- | --- |
| `network-read` | 读取网络资源 |
| `network-io` | 双向网络通信 |
| `credential-use` | 使用凭据 |
| `file-write` | 写入本地/沙箱文件 |
| `remote-process-input` | 向远程进程发送输入 |
| `remote-tool-effects` | 触发远端工具副作用 |
| `remote-ui-write` | 操作远端 UI |
| `screen-read` | 读取屏幕内容 |
| `model-inference` | 调用模型推理 |

`authorization` 记录授权设计：`credential_references` 只存凭据键名/引用（API key、token 不存值）；`policy` 描述数据主体、写入确认与资源范围；`status` ∈ `proposed` / `confirmed`。

三层权限**分别处理、不互相推导**：
1. 业务授权（本节）：Skill 语义层的数据主体、写入确认与资源范围；
2. 目标应用权限（`binding.app_permissions` → `module.requestPermissions`）：如网络读候选 `ohos.permission.INTERNET`；
3. 调用者权限（`binding.registration.permissions` → profile）：与 requestPermissions 分离，待 E5。

`model-inference` 不必然产生网络权限：取决于执行器位置（本机推理/远程 API），在甲组执行器契约（Q3）确认前既不添加也不断言无。

### 3.5 可用性、缺口与证据（成员 A 主笔）

`assessment` 对齐乙组三 status，逐字保留原文：

| 字段 | 普查字段 | 语义 |
| --- | --- | --- |
| `portability` | `portability` | L1/L2/L3 静态候选；沿用乙组原分级，子集不重写其等级 |
| `classification_status` | `classification_status` | 判断与验证状态 |
| `original_runtime_status` | `original_runtime_status` | 原平台运行状态 |
| `harmony_runtime_status` | `harmony_runtime_status` | 鸿蒙运行状态 |

`gaps[]` 每项含 `kind`（v0 取 `target-capability-or-evidence`：目标能力或证据缺失）、`capability`（具体能力缺口）、`impact`（影响范围）、`resolution_evidence`（解除证据）。

`test_plan.cases[]` 须覆盖正常、边界与失败用例；`execution_status` 登记执行状态。`evidence` 登记 `kind`、`research_commit`、`survey_record`、`source_review` 及 `target_logs[]` / `reviewers[]`（空数组 = 尚无实测或复核证据）。

区分规则：
- "IR 可描述"、"目标适配器缺失"、"目标尚未测"分别登记，不合并；
- 失败、权限拒绝、业务未命中、结构错误与回包失败不合并成一个"不可用"；
- L3 或缺少实验不推断为永久不可实现；
- `binding.status` 统一 `pending-verification`（待验证），按 §5.1 单项流程解除，不因某一条证据清除其他条目标注。

### 3.6 HarmonyOS 目标绑定/投影层（成员 B 主笔，全部待验证）

#### 3.6.1 层次、输入与输出

```text
核心 IR（任务、依赖、授权、范围、来源）
  → 目标能力解析（提示执行器 / HTTP / 文件 / 协议 / 宿主进程）
  → Harmony 绑定计划（所有条目待验证）
  → 拟生成：module.json5 补丁 + SKILL.md + scripts/*.ets + 业务适配器
  → 甲组注册/构建/调用证据 → A/B 交叉复核 → 更新单项验证状态
```

以上是设计流程，当前没有实现生成器。`binding` 只是一份投影计划，不直接混入核心层。缺少目标能力时可以产出诊断，不能静默删除功能或生成假成功。

#### 3.6.2 字段映射表

| IR 输入 | 目标位置 | 投影规则与风险 | 状态/依据 |
| --- | --- | --- | --- |
| `source`、`id` | 溯源清单，不直接写 profile | 保留源身份；同名不同来源分开 | 待验证；S2/S3 |
| `binding.registration.name` | profile.name、目录名、frontmatter.name | 三处一致；小写字母/数字/连字符，禁止连续连字符，≤64 字节；模块内唯一 | 待验证；S4 §2–3 |
| 原版本与目标版本 | source.version；profile.version | 源 commit 不可硬填 SemVer；目标独立 `0.1.0`，变更记录保留源版本 | 待验证；S4 §3 |
| 目标宿主组件 | profile.abilityName | 样例使用拟建 EntryAbility；必须验证组件实际存在，skill 类型模块不支持该字段 | 待验证；S4 §3 |
| 目标调用范围 | profile.visibility | 样例显式 system；可见性不等于来源优先级、业务授权或调用成功 | 待验证；S4 §6 |
| `binding.entry.module_file` | profile.srcEntries[] | 先保存模块相对逻辑路径；编码为配置相对路径的规则暂不冻结，见 Q1 | 待验证；S4 §3 内部冲突 |
| task 描述/触发/边界 | SKILL.md description/触发场景 | 保留功能范围；子集不能继续宣称完整能力 | 待验证；S4 §4 |
| operation、输入输出 | SKILL.md functionName / args / 返回 Schema | 与类方法名一致；语义输入名显式映射到 argN/argv，不能只靠对象属性顺序 | 待验证；S4 §4–5 |
| 调用模型、HTTP、文件等依赖 | ArkTS 业务模块 | 需实际可用适配器，不能将工具名替换成空 import | 待验证；S4 §5 |
| 网络/文件等 effect | module.requestPermissions + 运行时资源授权 | 网络候选 INTERNET；文件选择/URI 另测，不假设通用文件权限 | 待验证；S4 §6 |
| 调用者门槛 | profile.permissions | 与 requestPermissions 分离；样例空列表仅设计建议，待 E5 | 待验证；S4 §6、§9 |
| 源 bins/env/config/os | 目标依赖与能力诊断 | 不等同权限；CLI/宿主工具须有替代能力或记录阻断 | 待验证；S2、S5 |
| 加载优先级/用户调用策略 | IR 保留来源策略；目标差异记录 | 无依据映射为 visibility；不能自动把 disable-model-invocation 变成可自动触发 | 待验证；S5 |

#### 3.6.3 目录与注册计划

以天气“当前天气摘要”子集为贯穿示例（**待验证，非可直接构建工程**）：

```text
entry/
  skills/nju-weather-current/
    SKILL.md
    scripts/WeatherSkill.ets
  src/main/
    module.json5
    ets/service/WeatherService.ets  # 待乙组实现
```

绑定记录保存：name=`nju-weather-current`，version=`0.1.0`，abilityName=`EntryAbility`，visibility=`system`，permissions=`[]`；入口模块相对路径=`skills/nju-weather-current/scripts/WeatherSkill.ets`，Skill 相对路径=`scripts/WeatherSkill.ets`，方法=`getCurrentWeather`。

**不提供已定稿的 srcEntries 配置片段**：S4 §3.1 说其相对 skills 目录，§3.2 的示例却使用 `../../skills/...`。将两种表述并列提交甲组 E1，以实际 SDK、构建器和注册结果确定路径基准；不得任选一个宣称正确。

#### 3.6.4 参数与回包投影

候选天气输入为 `{location: 非空字符串}`；声明 `arg1 → location → argv[0]`，不从设备定位取得城市。请求只面向声明的天气服务，位置需 URL 编码。输出成功数据包含解析后的 location、condition、temperatureC、windKmph；缺少必要字段走响应结构错误。单位须显式保留，不能把字符串温度或风速未经解析就当数字。

建议 SKILL.md 参数片段（待验证，项目语法沿用 S4）：

```text
exec-cli(command: ohos-arkTSScript --skillName 'nju-weather-current'
  --scriptPath 'scripts/WeatherSkill.ets' --functionName 'getCurrentWeather'
  --args '{"arg1":"南京"}')
```

下列是接口级伪代码，不是已编译 ArkTS：

```text
export default class WeatherSkill
  public async getCurrentWeather(info: ArkTSScriptInfo, ...argv: string[]): Promise<void>
    校验 argv[0]：空值 → failed / ERR_INVALID_PARAMS，停止业务
    通过 WeatherService 请求并解析真实天气 JSON
    正常 → {type: result, status: success, data: ...}
    超时/拒绝/结构错误 → {type: result, status: failed, errCode: ..., errMsg: ...}
    使用 info.context、info.requestCode、ExecuteResult 回传一次
```

按照 S4 §5，API 候选为 `scriptManager.completeArkTSScriptInApp`。`ExecuteResult.code` 为传输层数值；`result.status/errCode` 为业务层结果，数值映射须甲组确认，不能把 code=0 当业务成功。业务失败不得先抛出再重复回包；回包 API 本身失败需另记日志，不能当业务完成。超时、取消和迟到回包如何处理仍待运行契约。

候选统一业务分支为 success 与 failed；failed 的项目级错误包括 `ERR_INVALID_PARAMS / ERR_AUTH / ERR_PERMISSION / ERR_TIMEOUT / ERR_RESPONSE_SCHEMA / ERR_NOT_FOUND / ERR_DEPENDENCY / ERR_INTERNAL`。这些是本稿建议，不是系统官方错误码。每项 operation 需声明实际可发生的分支及 schema；L1 缺输入可返回业务 `needs-clarification` 数据，由目标执行器协调，不能擅自新增系统状态。

#### 3.6.5 权限与依赖解析

网络读能力候选申请应用侧 `ohos.permission.INTERNET`，不据此生成 profile.permissions，也不自动授予 Trello 账号权限。手工输入城市不需要定位权限。L1 仅在确实调用远程模型时才新增网络需求；当前 executor 路线未确认，因此不能断言 L1 无权限。

Trello 凭据从安全存储引用读取，报告和日志不得回显完整 URL 查询凭据。meme SVG 文件以沙箱文件与受控 URI 返回；具体 URI 授权及 flags 待测，不能直接把 `/tmp/meme.svg` 暴露给鸿蒙调用方。禁止添加无依据的 `AGENT_SKILL` 权限。

## 4. 样本表示与交叉验证

完整结构记录见 [skill-ir-examples-v0.json](examples/skill-ir-examples-v0.json)。它是候选结构实例，不是已通过核心 Schema 验证的正式 IR；所有函数名与目标 name 都是成员 B 的新设计。保留源 SKILL.md 哈希、源门控、scope、目标入口、依赖替代、缺口、用例及证据状态。三个 L1 的精确源输出字段需 A 对照缓存原文继续核验。

### 4.1 L1：handoff 首批三个

| 源身份与固定版本 | 设计投影（全部待验证） | 语义与资源 | 验证用例 |
| --- | --- | --- | --- |
| perpetualhui/adaptive-socratic-questioning@1.1.0 | nju-adaptive-socratic-questioning / SocraticSkill.ets / generateQuestions | 模型执行器加载追问指引；输入概念、学生回答、目标与上下文，返回符合源约定的 JSON；示例/evals 为静态资源，不当实测 | 正常回答生成追问链；缺学生回答先澄清；普通事实问答不误触发；多轮上下文不丢失 |
| aircraft06/academic-paper-writing-style@1.0.0 | nju-academic-paper-writing-style / WritingSkill.ets / reviseAbstract | 模型执行器加载指引及 expression_examples.md、journal_formats.md；以用户原文为事实边界；reviseAbstract 仅演示一个入口，完整范围须继续补齐操作 | 给摘要返回修改和理由；不添加实验结果；当前期刊规则不得据静态引用冒充已核验；缺参考资料应显式报缺口 |
| clawdiri-ai/davinci-first-principles@1.0.0 | nju-davinci-first-principles / PrinciplesSkill.ets / analyzeAssumption | frontmatter_name=first-principles，保留 slug 与 name 差异；执行五阶段与假设检验指引 | 非高风险产品假设；证据不足标未知；不将示例当事实；五阶段完整性待对照源文 |

完整范围的声明是设计目标，操作清单尚不能作为完整等价证明。若乙组只交付 reviseAbstract 等子功能，应另立 subset scope；不得继续用 full 记录验收。L1 没有业务脚本不代表鸿蒙可直接消费原文，三项均有“提示执行器与资源加载契约待甲组确认”的缺口。

### 4.2 L2：weather / trello / meme-maker

三项均来自 OpenClaw `d79ab6195d8d0566b285008bcc30c01a6ce368e2`；保持原记录 L2 静态候选状态。

**weather/current-summary（新子集）**：使用 getCurrentWeather，目标网络/JSON 替代首选 web_fetch 与备用 curl 的业务目的。输入城市；网络读取 wttr.in 的结构化结果，必要时按源说明评估 wttr.is 备用；超时和响应限制显式声明。只含当前摘要，不含完整预报/历史/专业告警；更换提供商须另记语义差分。源 frontmatter 没有 requires.bins，不能误填 curl 必需。正常、空城市、城市未命中、20 秒超时、字段缺失均需测；不能用硬编码天气验收。

**trello/read-only（新子集）**：TrelloSkill.ets 的 listBoards/listLists/listCards；curl+jq 在业务层替换成 HTTP+JSON，TRELLO_API_KEY/TRELLO_TOKEN 的认证要求保留为目标凭据引用。只读已授权测试看板，源创建、移动、评论、归档均列 excluded。测试分页与读完条件（以届时服务协议核对）、401/403、限流和错误 JSON；首轮不执行任何写入。之后添加写能力须新增操作/副作用/授权用例，不能因只读成功宣称整个 Trello 已通过。

**meme-maker/local-svg（新子集）**：MemeSkill.ets 的 searchTemplates/renderSvg；保留 templates.json、文本框与模板来源规则，Node fs/path 用受限文件适配器替换，URL 下载和缓存由目标服务完成。这里的 local 指生成位置，**不等于离线**；没有缓存时仍可能联网。排除 PNG 的 Playwright/Chromium、Imgflip 托管和 refresh，suggest 排名也未在该最小子集声明。完整原记录仍需表达这些分支，不能悄悄删除。测试模板未知、文本数量/长度、XML 转义、资源下载失败、缓存命中与文件不可写；输出必须是实际 SVG 与可读取 URI，不是虚构路径。模板图片不随包再分发；本稿仅记录来源约束，未完成素材许可审查。

### 4.3 L3：只记录能力缺口与受限路线

| 样本 | IR 可表达部分 | 目标能力缺口/候选路线（均待验证） | 必须独立验证 |
| --- | --- | --- | --- |
| tmux | 会话/窗格标识、读取屏幕、发送输入、等待条件 | 原 darwin/linux + tmux；缺 PTY、shell、持久会话。候选 remote-host 指向 Linux，原本机完整路线仍缺能力 | 跨断线会话、取消/超时、目标授权、退出状态、nonce 完成标记；远程比例和网络开销未测 |
| mcporter | 工具 schema、输入输出、传输、认证 | 完整记录含 HTTP、stdio、OAuth、配置、daemon、codegen。候选 subset 只做 HTTP 工具发现/调用；缺真实协议适配器 | HTTP/SSE 等具体协议按服务版本核对；HTTP 成功不能证明 Node/Bun 子进程、stdio、daemon 或代码生成可用 |
| peekaboo | 感知→定位→输入→动作后验证 | darwin + peekaboo + Bridge；鸿蒙 UI 感知、定位、输入及授权未提供。候选 remote-host 指向 macOS | 正确设备/应用/窗口、截图权限、敏感操作授权、动作后验证；远程 macOS 不算鸿蒙本机移植 |

这些路线并未部署。L3 能被 IR 描述只说明能登记需求和缺口，不代表 VM 或鸿蒙已具备其宿主能力。

### 4.4 A/B 共同交叉复核矩阵

A 于 2026-10-31 完成九个示例的字段交叉验证：可表达性成立，来源、scope、条件依赖、操作参数、效果、评估、缺口、测试与证据均有对应字段，未发现需新增结构字段的缺口；下表第三列为 A 的静态核对结果。

| 样本/检查点 | B 本地静态核对结果 | A 静态核对结果（2026-10-31） | 解除限制证据 |
| --- | --- | --- | --- |
| 九项来源/版本/哈希 | 与 S3 逐项匹配 | 身份字段、`null` 未声明语义与 slug/name/普查 ID 不合并规则已定义（§3.1） | 固定源材料复核 |
| L1 ×3 | 来源、输入意图、资源、绑定名称均已表达；精确输出 schema 待补 | `full` 范围声明、`resource_inventory`、`prompt-guided` 调用与 `model-inference` 效果均可表达（§3.1–3.4）；精确输出 Schema 与完整操作清单仍须固定原文复核（Q3） | 乙组固定原文 + 甲组提示执行器契约 |
| weather | 源 requires 不误添 curl；子集与超时/结构错误已表达 | `bins_all=null` 与"安装建议不是门控"一致；web_fetch/curl 首选与备用以 `branch: preferred / fallback-…` 表达（§3.3） | 原平台/鸿蒙同输入真实结果 |
| trello | all-bins 与 env 门控分别保留；只读 scope 独立 | `bins_all` 门控、`env_all` 凭据门控与只读子集 scope 规则均成立（§3.1、§3.3） | 已授权测试环境、失败分支日志 |
| meme | local 仍可能联网；PNG/Imgflip 另记；子集独立 | 条件分支 `branch` 取值语义已定义，"local 仍可能联网"由 `effects` 表达；素材许可限制已登记（§3.3、§3.4） | 真 SVG、URI、缓存和失败用例证据 |
| L3 ×3 | 本机缺口、子集/远程及执行位置显式 | "可描述 / 缺适配器 / 未测"三分与 gaps 结构已定义（§3.5）；`remote-host` 的 `execution_location` 与 INTERNET 约束一致；缺口枚举是否足够仍可复核 | 宿主/协议/设备真实轨迹 |
| profile/入口/权限 | 三处名称和 functionName/参数位置已定义；全部待验证 | `argN`/`argv_index` 映射、`required` 三值与 `encoding` 已定义（§3.2）；三层权限分离已定义（§3.4）；源策略由 `source.invocation_policy` 保留（§3.1，示例待补值） | E1/E3/E4/E5/E7 对应证据 |
| 示例规范化 | 检查脚本通过 | 参数 `required` 占位值由 `"pending-source-and-contract-review"` 统一为 `"pending-contract"`（26 处），重跑 verify-examples.py 通过；`source.invocation_policy` 具体值待乙组普查补充或样例补录 | 甲组契约到达后按 §5.1 单项解除 |

本表为 B 自检与 A 静态核对的汇总，待互审确认；结构检查脚本仅核对固定样本及内部关联，不产生运行覆盖率。

## 5. 开放问题、交接与修订记录

### 5.1 待甲组交接：成员 B 跟进

| ID | 问题 | 需交付证据 | 更新位置 |
| --- | --- | --- | --- |
| Q1 | srcEntries 的真实相对基准；S4 内部示例冲突 | SDK/构建工具版本、最小工程 commit、成功注册配置及构建日志；E1 | 3.6.2–3 与所有 binding.entry |
| Q2 | skillProfiles 生效范围、第三方/非预置、SDK/API、签名 | 设备/系统/SDK、预置及签名条件、E1/E7 正反例 | binding 环境条件 |
| Q3 | L1 提示执行器、静态资源与多轮上下文如何加载 | 一个 L1 真实调用闭环、模型与资源版本、输入输出和失败日志 | 3.2、4.1、executor 依赖 |
| Q4 | argN/argv 空值、可选参数、复杂对象、长度/编码 | E3：正常、空值、非法 JSON/类型、中文参数的实际轨迹 | operation 参数编码与 Schema |
| Q5 | ExecuteResult 与业务 schema、回包失败、超时/取消 | E4：成功/业务失败/回包失败；是否可重入、唯一回包策略 | 3.6.4、错误分支 |
| Q6 | 两类 permissions、visibility 与真实调用者关系 | E5：当前应用/系统/第三方，授权和拒绝的对照轨迹 | 权限映射；当前暂用的空列表 |
| Q7 | HTTP/文件/凭据/URI 能力及副作用授权 | 真 HTTP、凭据脱敏、文件读取、URI/flags、失败路径 | L2 替代项与结果 |

收到证据后按**单项**更新：绑定字段 → 关联样本 → 运行状态 → 证据链接 → A/B 审阅。只有某条已获得可复现证据并共同复核，才清除该条“待验证”；不能因 E1 成功清除网络、权限或 L1 执行器的标注。

### 5.2 待成员 A / 乙组 / C-1 共同确认

1. A 已于 2026-10-31 主笔 §3.1–3.5 并完成九个示例的字段交叉验证（见 §4.4 补充）；示例 `required` 占位值已统一为 `"pending-contract"`。字段如再改名，同步九个 JSON 示例与检查脚本。
2. 与乙组确认 all/any 门控、primary_env 推荐、namespace 回退、分支依赖；区分来源元数据未声明与业务确认不需要。L1 完整操作与输出结构由固定原文复核。
3. 讨论 scope.mode 是否改为“功能范围 × 执行位置”两个正交字段，以表达完整功能远程执行与部分功能远程执行；本稿暂以 mode + included/excluded + execution_location 联合表达。
4. C-1 核对 SkVM/SkCC/SkillSmith 的 IR、运行时与宿主适配术语；在没有工具链实验前不写 AOT/JIT 性能或覆盖结论。
5. S4 §8 将 requires 映射权限、优先级映射 visibility 的简表只能视为粗略线索；本稿分别保留依赖解析与源选择策略，待各组确认语义差分。

### 5.3 修订记录与最终验收门槛

| 日期 | 修订者/范围 | 影响字段与示例 | 证据/状态 |
| --- | --- | --- | --- |
| 2026-10-31 | 成员 B 本地候选：3.6、4、5；3.1–3.5 提供最小对接建议 | 九个样本、scope、分支依赖、名称映射、参数和权限分层 | S1–S6；未运行、待 A/B 审阅 |
| 2026-10-31 | 成员 A 主笔 §3.1–3.5 正式字段定义并交叉验证九个示例：`source.invocation_policy` 与 `effects` 词汇表为新增定义，`required` 占位值统一为 `"pending-contract"` | id/source/scope、task/invocation、dependencies（门控 vs 推荐）、effects/authorization、assessment/gaps/test_plan/evidence | 九个示例重跑 verify-examples.py 通过；仅静态核对，仍无运行证据 |

最终验收仍需：成员 A 合并平台无关定义；A/B 共同复核全文及示例；标明甲组未验证范围和解除证据；协调人确认统一术语、来源和限制。至少一名其他成员 Review，通过后按研究仓库流程合并。当前只能提交**阶段性 Draft PR**，不能将 C-3 或 C-4 状态更新为已验收。
