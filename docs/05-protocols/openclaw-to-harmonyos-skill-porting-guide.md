# OpenClaw Skill 迁移到鸿蒙：格式、选型与验收

适用范围：本项目将 OpenClaw Skill 的任务和工具能力迁移到小艺平台 Skill、鸿蒙 ArkTS 应用 Skill 或鸿蒙 App 内的自建 Agent。官方资料核对日期为 2026 年 11 月 14 日。本文的 `weather` 配置是移植设计示例。

## 1. 先确定谁发起调用、代码在哪里执行

| 目标形态 | 用户入口和执行链 | 最小交付物 | 何时选用 | 主要代价 |
| --- | --- | --- | --- | --- |
| **小艺平台 Skill** | 用户从支持该 Skill 的小艺入口提出请求 → 平台 Agent 读取技能指令 → 平台工具或插件执行 | 符合平台规范的技能目录、实际依赖的资源和工具配置 | 提示词、参考资料、平台已有工具或可接入的 HTTP/MCP 服务足以完成任务，希望从小艺 Skill 渠道分发 | 工具和运行时受目标渠道、设备、授权和沙箱约束，公开上架需审核 |
| **鸿蒙应用 Skill** | 系统智能体匹配技能 → 鸿蒙 Skill 框架调用已安装 App 的 ArkTS 入口 → 脚本回传结果 | `SKILL.md`、`.ets` 入口、`module.json5` 中的 `skillProfiles`、可部署的签名 HAP | 需要系统智能体直接调用 App 内的一项明确能力，例如查 App 私有数据，或验收明确要求证明系统 Skill 调度 | 需要 App 工程、签名安装、设备适配及平台真机联调 |
| **鸿蒙 App 内自建 Agent** | 用户进入自家 App → 自建 Agent 加载指令或按代码路由 → 函数、Ability 或外部工具执行 → App 展示结果 | Agent 工程、工具契约和实现，文件加载方式另外交付技能目录和加载器 | 主要服务 App 自己的用户，或需要控制模型、工具权限和日志，方便对照 OpenClaw 行为 | 需要自行维护路由、工具注册和错误处理。直接导入原包时还要实现加载机制 |

三条路线可以共用业务实现。例如 App 内 Agent 和应用 Skill 入口都可以调用同一个天气查询函数。选型时先确定用户从哪里发出请求，再确定必须保留哪些数据、权限和执行位置。需要让小艺把对话交给完整的自建 Agent 时，可以加端侧 A2A，见第 5 节。[小艺开放平台简介](https://developer.huawei.com/consumer/cn/doc/service/platform-concepts-0000002625401382/) · [方舟智能开发框架](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkaf-overview/)

### 按场景选型

1. **用小艺的工具完成任务。** 例如根据一份写作规则修改摘要，或用平台已支持的天气工具回答查询。选平台 Skill。
2. **让小艺经鸿蒙 Skill 框架调用 App。** 例如「我的充电宝放哪了」，位置只保存在自己开发的 App 里，系统匹配后由该 App 查本地数据库并回传。目标 App 已注册这项能力，或你能修改并重新发布该 App 时，才具备走应用 Skill 路线的注册条件。第三方 App 的接入边界见第 4 节。
3. **在自己的 App 里运行，或由自己控制工具编排。** 例如实验 App 加载一批移植 Skill，逐项记录匹配、工具调用和输出。选自建 Agent。需要小艺对话入口时，可在相同业务代码上加端侧 A2A。
4. **关键依赖只能在别处运行。** 例如 `tmux` 需要访问 Linux 上的持久终端会话。可通过平台插件或自建 Agent 请求远端服务，记录远端执行位置。若只移植一部分功能，单独列出保留与省略的操作。[项目样本与功能范围](../04-methodology/group-c/ir/skill-ir-v0.md#43-l3只记录能力缺口与受限路线)

## 2. 从 OpenClaw 源包提取什么

固定原始来源、版本或提交、许可证与测试输入。先跑一次原环境，记录实际工具调用、输出、异常分支和副作用。原包可能只有 `SKILL.md`，它仍可依赖 OpenClaw 注入的工具或宿主程序。[OpenClaw Skill 文档](https://docs.openclaw.ai/tools/skills) · [乙组移植交付要求](../04-methodology/group-b/README.md)

| 源内容 | 迁移时如何处理 |
| --- | --- |
| `name`、`description`、触发语和正文步骤 | 保留任务语义，按目标规则调整标识、触发边界、步骤与调用示例。登记原名和目标名的对应关系。 |
| `scripts/`、`references/`、`assets/` 及 `{baseDir}` | 检查每个引用是否会被目标加载。保留兼容资源，改写路径或打包方式，确认执行器能读到文件。 |
| `metadata.openclaw.requires.bins/anyBins/env/config`、`os`、安装指引 | 逐项判断是必需、备用还是安装建议。在目标环境实现对应检查或替代能力。把命令可用性、服务凭据和应用权限分别核对。 |
| `user-invocable`、`disable-model-invocation`、`command-dispatch` 等 | 按目标入口实现相应的手动调用、自动匹配或直达工具行为。无法保持的行为登记为差异。 |
| 工具名、参数、返回、超时、读写动作 | 将原调用映射到实际可用的工具，保留正常及失败语义。涉及文件、数据库或外部服务时，核验实际读写结果。 |

例如 `weather` 的首选路径是 `web_fetch`，`curl` 是备用路径，源码中的安装建议不构成所有查询必须具备的二进制依赖。可先移植“当前天气摘要”，把预报等未覆盖能力写入交付范围。[原始 weather Skill](https://github.com/openclaw/openclaw/blob/d79ab6195d8d0566b285008bcc30c01a6ce368e2/skills/weather/SKILL.md) · [项目 weather 移植设计](../04-methodology/group-c/ir/skill-ir-v0.md#42-l2weather--trello--meme-maker)

## 3. 转换为小艺平台 Skill

### 3.1 目录和字段

华为平台 V6 格式规范中的完整技能目录包含 `SKILL.md` 和平台侧 `module.json`。按需添加脚本、参考资料、静态资源。平台界面也支持通过 Vibe Coding 生成或通过导入入口提交技能包。导入、生成和导出时以相应入口的校验和实际产物为准。[华为 Skill 开发规范](https://developer.huawei.com/consumer/cn/doc/service/skill-development-standards-0000002592931546/) · [平台导入指南](https://developer.huawei.com/consumer/cn/doc/service/import-skill-0000002592931542/) · [Vibe Coding 创建指南](https://developer.huawei.com/consumer/cn/doc/service/vibe-skill-0000002623211165/)

```text
weather-current/
├── SKILL.md
├── module.json
├── scripts/        # 有实际可执行脚本时添加
├── references/     # 按需加载的参考资料
└── assets/         # 模板、静态数据等
```

| 位置 | 要求 |
| --- | --- |
| `SKILL.md` frontmatter | 必填 `name` 和 `description`，名称与目录一致。`name` 为 1–64 字符，使用小写字母、数字和连字符，连字符只能出现在中间且不能连续。V6 对 `description` 的上限为中文 512 字符或英文 1024 字符。可选字段包括 `license`、`compatibility`、`metadata` 和 `allowed-tools`。 |
| `SKILL.md` 正文 | 描述触发边界、操作步骤、输出和失败处理。依赖已注册工具时，在「工具定义」中逐项写对应条目。函数工具写清名称、参数及语义，CLI 工具说明可用命令和参数，私有脚本写清相对路径、用途及调用参数。平台注册函数的 Schema 由平台注入，私有函数的 Schema 由作者在正文声明。 |
| `module.json` | `version` 必填，使用语义化版本。可选 `availableOn` 由系统自动填充，也可按规范声明目标运行环境。平台注册的业务工具通过 `toolDependencies` 声明，并在正文工具定义中对应。平台预置工具和 Skill 私有工具不写入该列表。 |
| 脚本和运行时 | 引用的脚本、工具实现和资源都要在目标环境可用。脚本语言支持取决于设备或沙箱。涉及 ETS 脚本时，按规范核对 `abilityName`、`srcEntries`、`requestPermissions` 及构建生成的 API 版本字段。调用权限按实际发布形态配置。 |

以上为平台技能包约定。App 工程中注册 ArkTS Skill 使用的是 `module.json5` 中的 `skillProfiles`。平台包的 `availableOn` 描述技能运行环境，App 模块的 `deviceTypes` 描述应用模块支持的设备。实际发布还要验证所选渠道的下发和调度。[华为 Skill 开发规范](https://developer.huawei.com/consumer/cn/doc/service/skill-development-standards-0000002592931546/) · [App 模块配置](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/module-configuration-file/)

工具的迁移分三种情况。平台预置工具可在目标渠道验证后直接复用。现有的远程业务 API 可以接成平台支持的云插件或 MCP 插件，再引用实际配置的工具。原脚本若依赖 Shell、Python、Node 或宿主二进制，要验证目标执行环境和沙箱，或将该步骤改为调用远程服务。[华为 Skill 开发规范](https://developer.huawei.com/consumer/cn/doc/service/skill-development-standards-0000002592931546/) · [平台插件类型](https://developer.huawei.com/consumer/cn/doc/service/skill-plugin-0000002592771624/)

### 3.2 weather 示例和发布步骤

以下为使用平台预置 `web_fetch` 的简化示意。仅当目标渠道实际允许该工具访问天气服务时采用。

```markdown
---
name: weather-current
description: 按用户给出的城市查询当前气温、天气状况和数据更新时间。
---

用户要查当前天气时启用。城市缺失时先询问城市。
将城市进行 URL 编码，用 web_fetch 请求 https://wttr.in/<城市>?format=j1。
回复城市、气温（摄氏度）、天气状况及数据时间（接口提供时）。
查询超时、数据缺失或地点无法匹配时，说明失败或请用户澄清。
```

```json
{
  "version": "0.1.0"
}
```

原 `curl` 备用分支可接到已验证的云插件或 MCP 工具。若首版只实现主查询，在移植档案记录备用分支未覆盖。替换天气提供方时，核对字段、单位、数据时间和错误语义。真实查询失败时返回失败信息。对于需要密钥的工具，使用平台提供的认证配置，技能正文和附件中仅引用工具名。[平台插件文档](https://developer.huawei.com/consumer/cn/doc/service/skill-plugin-0000002592771624/)

1. 在小艺开放平台通过「新建 Skill」创建或导入，检查识别后的名称、描述、依赖工具和资源。
2. 确认预期的小艺渠道、测试账号和设备支持。向测试组发布真机测试，发正常输入和失败用例，核对工具日志和结果。
3. 需要公开分发时，提交正式上架审核，并在预定入口验证实际可搜索和调用。[Skill 真机测试指南](https://developer.huawei.com/consumer/cn/doc/service/skill-real-machine-testing-0000002592771628/) · [上架流程](https://developer.huawei.com/consumer/cn/doc/service/skill-process-introduction-0000002623211171/)

## 4. 转换为鸿蒙 ArkTS 应用 Skill

### 4.1 工程格式

采用 API 26.0.0 起支持该能力的 Stage 工程。以下以 `entry` 模块和已有的 `EntryAbility` 为例。将配置片段合入实际工程。[华为应用 Skill 开发指南](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-skill-development-guide/) · [仓库应用 Skill 模板](harmonyos-app-skill-template.md)

**先确认谁能注册这项 Skill。** `skillProfiles` 把技能名、ArkTS 入口和承载它的 Ability 绑定到目标应用模块。自有 App 尚无该配置时，可以在开发应用 Skill 时加入，再随新版签名 HAP 构建和安装。若第三方 App 尚未注册所需的 Skill，且你无法修改它，单独编写 `SKILL.md` 和 `.ets` 脚本无法为该 App 添加系统调用入口。此时可请 App 提供方接入，或通过它已开放的 API 等受支持接口，用平台 Skill 或自建 Agent 实现相应功能。[华为模块配置规范](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/module-configuration-file/)

```text
entry/
├── skills/weather-current/
│   ├── SKILL.md
│   └── scripts/WeatherSkill.ets
└── src/main/
    ├── ets/service/WeatherService.ets
    └── module.json5
```

```json5
{
  "module": {
    "skillProfiles": [
      {
        "name": "weather-current",
        "version": "0.1.0",
        "abilityName": "EntryAbility",
        "srcEntries": ["../../skills/weather-current/scripts/WeatherSkill.ets"],
        "visibility": "system"
      }
    ]
  }
}
```

- **名称。** 目录名、`SKILL.md` 的 `name` 和 `skillProfiles[].name` 一致。模块内唯一，最多 64 字节，使用小写字母、数字和单个连字符，首尾为字母或数字。平台若提示重名，同步更新正文调用示例和配置。
- **Ability 与路径。** `abilityName` 指向模块中声明的 UIAbility 或符合配置规范的 ServiceExtension。上例 `srcEntries` 采用官方工程示例的路径写法。构建后包管理器呈现的路径可能已规范化，分别以工程布局与实际产物为准。`srcEntries` 注册的脚本为 `.ets`，业务实现可以调用兼容的 ArkTS、TS、JS 或其他经验证的模块。
- **权限。** `visibility` 控制可见范围，默认 `system`。模块规范中的 `private` 限本应用，`system` 限系统应用和本应用，`public` 向所有应用可见。Skill 的 `permissions` 描述调用方所需权限，应用的 `requestPermissions` 描述业务执行需要的系统权限。对 `weather`，应用发起网络请求时按网络权限规则配置。跨应用主动调度还需可用的执行接口和调用资格。[模块配置规范](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/module-configuration-file/) · [仓库格式说明](harmonyos-app-skill-format-and-api.md)

### 4.2 调用和回传

应用版 `SKILL.md` 写清正反触发场景、每项操作的参数 Schema、命令示例、成功和失败返回约定。下例将城市定义为必填字符串 `arg1`，返回城市、气温、天气状况及可用的数据时间，失败时返回可区分的业务错误。以下调用示例置于技能正文。

```text
exec-cli(command: ohos-arkTSScript --skillName 'weather-current' --scriptPath 'scripts/WeatherSkill.ets' --functionName 'getCurrentWeather' --args '{"arg1":"南京"}')
```

```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": { "type": "string", "minLength": 1, "description": "城市名称" }
    },
    "required": ["arg1"]
  }
}
```

定义成功与失败输出时，可以沿用仓库模板的业务信封。成功用 `status: "success"` 与 `data`，失败用 `status: "failed"` 与 `errCode`、`errMsg`。这些字段由技能正文和实现共同约定。外层的 `ExecuteResult.code` 与 `ExecuteResult.result` 按系统接口填写。两层状态均纳入验收。[仓库回包模板](harmonyos-app-skill-template.md#3-entryskillsorg-example-echoskillmd)

`WeatherSkill.ets` 以 `export default class` 导出。入口可写为 `public async getCurrentWeather(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void>`。按声明的参数位置读取和校验 `argv`，调用 `WeatherService`，将 `ExecuteResult` 交给 `scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result)`。业务失败也要按契约回传。测试时记录参数映射、业务结果和回传是否成功。[华为 scriptManager 文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-scriptmanager/) · [可复制入口和返回样例](harmonyos-app-skill-template.md)

1. 构建并签名 HAP，核对包名、模块、Skill 名、脚本和设备支持范围。把对应的 HAP 安装到目标设备。
2. 按官方应用 Skill 指南在小艺开放平台导入 HAP，核对关联应用、测试渠道、测试组和发布版本。
3. 从预定的小艺入口发送唯一测试输入。核对小艺匹配、应用脚本进入、业务执行、回传和界面结果。`getSkillInfoForSelf` 可补充注册证据，实际执行以脚本日志和结果为准。[华为应用 Skill 开发指南](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-skill-development-guide/) · [skillManager 文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-skillmanager/)

## 5. 转换为鸿蒙 App 内自建 Agent

自建 Agent 的格式由自己选用的加载器和工具运行时定义。先明确要交付 **能加载 Skill 文件的 Agent**，还是 **把原 Skill 功能实现为 Agent 内置工具**。

| 做法 | 需要交付 | 适合场景 |
| --- | --- | --- |
| **文件加载** | 技能目录、`SKILL.md` 和资源，加载器负责发现、解析、读取附件、把指令提供给模型或路由器。若宣称兼容 OpenClaw，还需列出支持的元数据、门控、同名优先级、手动调用和工具分派行为。 | 要批量导入源 Skill、复用提示词，或研究 Skill VM。 |
| **内置工具** | App 内的任务路由或模型工具定义、参数校验、处理函数、权限和返回约定。仅执行少数确定功能时，可直接在代码中路由到业务函数。 | 要复用原任务，但 App 已有自己的对话和工具机制。 |

以 `weather` 为例，Agent 内部可以注册如下工具。由你们在运行时将工具名绑定到真正的 HTTP 查询函数。下例是项目可采用的工具描述，所用模型 SDK 如有额外的包装字段，按该 SDK 转换。

```json
{
  "name": "get_current_weather",
  "description": "按城市查询当前天气",
  "inputSchema": {
    "type": "object",
    "properties": {
      "city": { "type": "string", "minLength": 1 }
    },
    "required": ["city"],
    "additionalProperties": false
  }
}
```

工具实现应把输入校验、服务请求、单位转换和错误返回固定下来。文件加载版还要核对工具指令使用的是 `get_current_weather`，并提供可读到的模板和引用资源。验收从 App 对话开始，记录实际路由、工具参数和结果，覆盖正常输入、缺城市、超时和无关请求。使用真实外部服务时，凭据由执行环境管理。[Agent Skills 规范](https://agentskills.io/specification) · [OpenClaw 创建 Skill 指南](https://docs.openclaw.ai/tools/creating-skills) · [C3/C4 个人工程](../../code/experiments/harmonyos-c3-c4-independent/README.md)

**需要小艺入口时，可另接端侧 A2A。** 在 `module.json5` 注册 `type: "agent"` 的 `AgentExtensionAbility`，通过 metadata 绑定 `resources/base/profile/agent_config.json`。AgentCard 描述 Agent 身份、能力、输入输出和 `skills` 列表，按平台校验核对包名、模块、Ability 和支持设备。小艺开放平台关联 App，填写与 Extension 名称一致的应用服务名称，导入 AgentCard 并做真机测试。运行时由 Extension 接收任务、调用现有处理器、按 A2A 协议回包。`AgentCard.skills` 描述 Agent 能做的事，鸿蒙应用 Skill 的注册入口仍是 `skillProfiles`。服务器端执行则可按云侧 A2A 接入。[华为应用内 Agent 开发接入](https://developer.huawei.com/consumer/cn/doc/service/agent2agent-inapp-0000002735604994/) · [端侧 A2A 指南](https://developer.huawei.com/consumer/cn/doc/service/device-a2a-quickstart-0000002733266338/) · [云侧 A2A 指南](https://developer.huawei.com/consumer/cn/doc/service/cloud-a2a-quickstart-0000002762825847/)

## 6. 怎样判断移植完成

| 检查 | 要保存的证据 |
| --- | --- |
| 来源和范围 | 源提交或版本、许可证、目标入口、执行位置、保留功能、替代依赖、未实现功能。 |
| 工程和注册 | 平台导入校验、HAP 构建与安装，或自建 Agent 加载结果。记录包名、版本、设备、系统和客户端。 |
| 入口调用 | 在选定的真实用户入口触发。记录命中的 Skill、工具或 Extension，以及对应的请求 ID 或唯一测试输入。 |
| 业务结果 | 工具或脚本确实执行，实际返回数据、产物或完成操作。对有副作用的动作核验业务状态。 |
| 回传结果 | 调用方界面结果与工具、端侧日志或服务端日志一致。 |
| 对照与失败 | 用同一组输入跑原平台和目标路径，比较关键字段、操作效果、超时、权限拒绝等相关失败路径。分别记录各阶段状态。 |

对于已在自建 Agent 里跑通的 `weather`，若后来增加平台 Skill 或应用 Skill 入口，要用各自的入口重新取证。对于 Skill VM，通用 IR、生成器、目标工具适配、实际执行也分别记录进度。[项目验收定义](../experiment/harmonyos-skill-runtime-comparison-plan.md#8-统一成功判定) · [移植档案模板](../../templates/skill-port-template.md) · [SkillIR 目标绑定](../04-methodology/group-c/ir/skill-ir-v0.md#36-harmonyos-目标绑定投影层成员-b-主笔全部待验证)
