# HarmonyOS 应用 Skill 格式要求与接口说明

> 适用范围：HarmonyOS 应用侧 Skill（`module.json5` 的 `skillProfiles`），不是小艺开放平台 Vibe Skill 包，也不是 AgentCard 中的 AgentSkill 描述。  
> 核对基准：华为《基于 ArkTS 脚本的应用 Skill 开发指导》（2026-09-30 更新）及当前本机 API 26 SDK 的 `@ohos.app.ability.scriptManager.d.ts`。  
> 结论先行：**Skill 的系统调用入口文件必须是 `.ets`；不是整个应用/业务实现中的每个源文件都必须是 `.ets`。**

## 1. `.ets` 要求究竟约束什么

官方将每项应用 Skill 定义为描述文件与 ArkTS 入口脚本的组合，并在 `module.json5` 的 `skillProfiles[].srcEntries` 中登记入口。当前 API 26 SDK 的 Hvigor 校验也实测拒绝 `.js` 作为 `srcEntries`，报错 `00303304`：“Only .ets source code files are supported.”

因此格式边界是：

| 文件/代码 | 是否必须 `.ets` | 说明 |
|---|---:|---|
| `skillProfiles[].srcEntries` 指向的 Skill 入口 | **是** | 当前官方规范和 API 26 工程校验均要求 `.ets` |
| Ability/ArkUI 等 HarmonyOS 组件入口 | 按对应组件规范 | 不要与 Skill 的 `srcEntries` 混为一个字段 |
| Skill 入口调用的应用业务模块 | **不一概要求** | 可放在独立模块；ArkTS Runtime 支持 ArkTS/TS/JS，具体混合导入仍须通过 SDK 编译与运行验证 |
| OpenClaw 原始 `SKILL.md`、参考资料、资源 | 不适用 | 它们不是 HarmonyOS 应用 Skill 的执行入口；迁移时应按应用 Skill 契约组织和适配 |

**本团队实测补充：**在隔离副本里，`EchoSkill.ets` 导入普通 JavaScript `EchoBusiness.js` 并调用其函数，`assembleHap` 构建成功；这是“JS helper 可被当前工程打包”的证据，不等于“JS 可作为 Skill 入口”，也不等于已通过系统小艺运行时调度。官方另说明 ArkTS Runtime 支持 ArkTS、TS、JS 字节码和互操作。

## 2. 工程目录与文件约定

官方示例结构：

```text
Application/
├── AppScope/
│   └── app.json5
└── entry/
    ├── skills/                                  # 当前模块的 Skill 根目录
    │   └── org-example-echo/                    # 与 SKILL.md name / 配置名保持一致
    │       ├── SKILL.md                         # 描述、场景、参数和返回值契约
    │       └── scripts/
    │           └── EchoSkill.ets                # 注册给系统执行的 ETS 入口
    └── src/main/
        ├── ets/entryability/EntryAbility.ets
        └── module.json5                         # skillProfiles 注册
```

官方指南在 `entry/src/main/module.json5` 示例中使用 `../../skills/org-example-echo/scripts/EchoSkill.ets` 这样的路径。按实际模块布局填写，并以当前 Hvigor 构建校验为准；不要把 `SKILL.md` 本身写进 `srcEntries`。

## 3. `module.json5` 注册格式

在模块对象 `module` 下增加 `skillProfiles`。最小示例：

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "skillProfiles": [
      {
        "name": "org-example-echo",
        "abilityName": "EntryAbility",
        "srcEntries": [
          "../../skills/org-example-echo/scripts/EchoSkill.ets"
        ],
        "version": "1.0.0"
      }
    ],
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets"
      }
    ]
  }
}
```

字段核对：

| 字段 | 含义/约束 |
|---|---|
| `name` | Skill 唯一名称；与 Skill 目录名、`SKILL.md` frontmatter 的 `name` 一致。 |
| `abilityName` | 与 Skill 关联的 Ability 名称，应对应模块中实际声明的 Ability；官方示例使用 `EntryAbility`。 |
| `srcEntries` | 实现入口文件路径列表；官方接口字段指向 Skill 实现逻辑 `.ets` 文件。每个文件名需以 `.ets` 结尾，`.d.ets` 也不支持。 |
| `version` | Skill 版本，示例使用语义化版本字符串，如 `1.0.0`。 |
| `permissions` | 可选的 Skill 调用权限列表；只声明执行该 Skill 所需的权限，并按平台权限机制处理。 |

技能所需系统权限仍应按实际业务在模块权限配置中声明，例如访问网络时按 HarmonyOS 权限文档配置 `requestPermissions`。权限不是 Skill 描述文件里的自然语言承诺；需按平台权限机制申请并在运行时遵守授权边界。

### 名称规则

至少保证：`skills/<name>/`、`SKILL.md` 的 `name`、`skillProfiles[].name` 三者完全一致。官方指南建议使用组织/项目名前缀以减少重名。当前 SkillProfileInfo 文档对 name 有小写字母/数字/连字符及长度限制；团队命名建议使用 `org-purpose` 形式的小写 kebab-case，并以实际 API 版本的模块配置校验为准。

## 4. `SKILL.md` 格式与契约

文件由 YAML frontmatter 和 Markdown 正文构成。最低限度包含 Skill 名称、用途范围、触发场景、明确的不触发场景、每个能力的方法名、参数 Schema、执行示例、成功/失败返回样例和返回 Schema。

````markdown
---
name: org-example-echo
description: 接收用户给出的短文本并原样回显；不执行外部写操作。
---

## 触发场景
当用户明确要求回显、复述或验证传入文本时调用。

典型话术：
- “回显 hello”
- “把这段文字原样返回：……”

不调用的情况：
- 用户要求翻译、总结或改写文本。
- 用户要求发送、保存或发布文本；本 Skill 不执行这些副作用。

### 场景 1：回显文本（run）

#### 执行参数
```text
exec-cli(command: ohos-arkTSScript --skillName 'org-example-echo' --scriptPath 'scripts/EchoSkill.ets' --functionName 'run' --args '{
  "arg1": "hello"
}')
```

参数 Schema：
```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": { "type": "string", "description": "需要原样回显的文本" }
    },
    "required": ["arg1"],
    "additionalProperties": false
  }
}
```

#### 执行返回值
成功示例：
```json
{
  "type": "result",
  "status": "success",
  "data": { "message": "hello" }
}
```

失败示例：
```json
{
  "type": "result",
  "status": "failed",
  "errCode": "ERR_INVALID_PARAMS",
  "errMsg": "arg1 is required",
  "suggestion": "请提供要回显的文本。"
}
```

返回 Schema：
```json
{
  "type": "object",
  "required": ["type", "status"],
  "properties": {
    "type": { "const": "result" },
    "status": { "enum": ["success", "failed"] },
    "data": { "type": "object" },
    "errCode": { "type": "string" },
    "errMsg": { "type": "string" },
    "suggestion": { "type": "string" }
  }
}
```
````

格式要点：

1. `name` 与工程注册名一致；`description` 应具体说明能做什么及边界，供语义匹配使用。
2. 正文按能力场景组织；标题括号中的 `functionName` 必须和 ETS 入口公开方法名逐字一致。
3. `exec-cli` 示例固定使用 `command: ohos-arkTSScript`；`skillName`、`scriptPath`、`functionName` 与工程实际值一致。
4. 参数结构用 JSON Schema 描述，并和入口方法按位置取得的字符串实参一一对应。
5. 返回值至少给出成功和失败样例；复杂能力应覆盖参数错误、未命中、权限/业务失败、内部错误等实际分支。
6. Schema 中的 `additionalProperties: false` 是本模板用于严格校验的建议，并非本文引用的官方强制字段；若平台解析器或官方例子不接受该约束，需按实际 Skill 解析规范调整。

## 5. ETS 入口脚本接口约定

### 5.1 类型定义

当前本机 API 26 SDK 的 `@ohos.app.ability.scriptManager.d.ts` 定义：

```ts
interface ArkTSScriptInfo {
  readonly requestCode: string;
  readonly context: Context;
}

interface ExecuteResult {
  code: number;
  result?: Record<string, Object>;
  uris?: Array<string>;
  flags?: number;
}

function completeArkTSScriptInApp(
  context: Context,
  requestCode: string,
  result: ExecuteResult
): Promise<void>;
```

以上签名摘自本机 API 26 SDK 声明；以项目实际安装 SDK 和官方 API 参考为最终依据。接口自 API 26.0.0 提供，Stage 模型限定，系统能力标注为 `SystemCapability.Ability.AgentRuntime.Core`。

### 5.2 入口类约定

- 从 `@kit.AbilityKit` 引入 `scriptManager`。
- 使用 `export default class` 导出入口类。
- 一个 Skill 能力对应一个 `public async` 方法。
- 方法名与 SKILL.md 中的 `functionName` 严格一致。
- 第一个参数固定接收 `scriptManager.ArkTSScriptInfo`；后续参数按顺序接收字符串，例如 `...argv: string[]`。
- 方法返回 `Promise<void>`，通过 `completeArkTSScriptInApp` 上报结果。
- 从 `info` 取 `context` 和 `requestCode`，不得伪造或复用别的请求值。

### 5.3 参数映射

官方调用示例将 JSON 参数按顺序传入字符串实参。示例中 `arg1` 对应 `argv[0]`，`arg2` 对应 `argv[1]`。所以每项能力都要：检查参数个数、去除/处理空白、验证类型语义与枚举范围、对异常输入返回明确失败结果。不要只依赖模型遵循 Schema。

### 5.4 返回接口和数据

- `ExecuteResult.code` 是整数结果码；官方示例成功用 `0`，失败示例用负数。团队应固定自己的映射并在文档中保持一致。
- `ExecuteResult.result` 可放系统智能体消费的结构化结果；其内部结构需和 SKILL.md 返回样例/Schema一致。
- `uris`、`flags` 是可选字段，用于需要向调用方授权 URI 访问的场景；一般回显/纯文本能力不需要填。
- 对 `completeArkTSScriptInApp` 做异常处理，记录可诊断错误，避免吞掉回调失败。
- 每次路径（成功、参数错误、业务异常）都必须收敛到一次明确的结果回传；不要既成功回传又在 catch 中再次回传。

## 6. 最小可复用 ETS 模板

```ts
import { scriptManager } from '@kit.AbilityKit';
import { echoMessage } from './EchoBusiness'; // 可换为已验证可被工程导入的业务模块

export default class EchoSkill {
  public async run(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    let result: scriptManager.ExecuteResult;

    const input = argv.length > 0 ? argv[0].trim() : '';
    if (input.length === 0) {
      result = {
        code: -1,
        result: {
          type: 'result',
          status: 'failed',
          errCode: 'ERR_INVALID_PARAMS',
          errMsg: 'arg1 is required',
          suggestion: '请提供要回显的文本。'
        }
      };
    } else {
      try {
        const message: string = echoMessage(input) as string;
        result = {
          code: 0,
          result: {
            type: 'result',
            status: 'success',
            data: { message: message }
          }
        };
      } catch (error) {
        result = {
          code: -2,
          result: {
            type: 'result',
            status: 'failed',
            errCode: 'ERR_INTERNAL',
            errMsg: String(error),
            suggestion: '执行失败，请稍后重试。'
          }
        };
      }
    }

    try {
      await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
    } catch (error) {
      console.error(`completeArkTSScriptInApp failed: ${String(error)}`);
    }
  }
}
```

示例业务 helper：

```js
export function echoMessage(message) {
  return String(message).trim();
}
```

该 helper 只是说明语言边界；在当前团队实验中它与 ETS 入口一起通过 HAP 构建，但仍应在目标设备、SDK 和业务数据类型下单独验证行为。

## 7. 构建与接入验收清单

### 静态/构建检查

- [ ] 工程为 Stage 模型，SDK 支持应用 Skill（API 26.0.0 起）。
- [ ] Skill 目录名、frontmatter `name`、`skillProfiles.name` 完全一致。
- [ ] `abilityName` 指向模块中真实 Ability。
- [ ] `srcEntries` 路径正确，并且每个入口均为 `.ets` 文件。
- [ ] 所有 SKILL.md `functionName` 都能在默认导出的入口类中找到同名公共异步方法。
- [ ] `arg1...argN` 顺序和入口 `argv[0...N-1]` 读取一致，并处理非法/空参数。
- [ ] 每一种执行路径都返回符合契约的 `ExecuteResult`。
- [ ] 按业务声明/申请实际权限，处理外部数据和异常。
- [ ] DevEco/Hvigor 构建 HAP 成功；保留完整构建日志和 HAP 标识。

### 运行检查

- [ ] 在目标环境安装 HAP 并确认应用启动。
- [ ] 确认小艺/目标系统智能体入口实际可用。
- [ ] 用正例验证匹配、参数传入、入口执行、结果呈现四个阶段。
- [ ] 用负例验证不应触发的表达不会调用 Skill。
- [ ] 对成功、参数错误、业务失败和异常分别留证。
- [ ] 清楚区分模拟器与真机结果；应用启动成功不代表系统智能体调度成功。

## 8. 官方资料与本地证据

- [基于 ArkTS 脚本的应用 Skill 开发指导](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-skill-development-guide)
- [HarmonyOS 拆包工具中的 SkillProfileInfo 配置字段说明](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/unpacking-tool)
- [ArkTS 运行时概述（支持 ArkTS/TS/JS）](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-runtime-overview)
- [ArkTS 简介与 TS/JS 互操作](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-overview)
- 本机接口声明：`D:\software\DevEco Studio\sdk\default\openharmony\ets\api\@ohos.app.ability.scriptManager.d.ts`
- 本团队实验记录：[HarmonyOS Skill 调用与运行时形态实验记录](../experiment/harmony-skill-experiment-record.md)

## 9. 版本边界说明

本文严格区分了：官方文档/SDK 明确约束、团队在 API 26 本机工程实测、模板中的团队建议。HarmonyOS SDK 和小艺开放平台会更新；对新 API 版本、不同系统形态、特定 Skill 包格式，接入前应按目标版本重新构建和实机验证。
