# HarmonyOS 应用 Skill 接入模板

> 将 `org-example-echo`、能力描述、参数和业务代码替换为自己的实现。目标是 API 26+、Stage 模型的 HarmonyOS 应用 Skill。

## 1. 目录模板

```text
entry/
├── skills/
│   └── org-example-echo/
│       ├── SKILL.md
│       └── scripts/
│           └── EchoSkill.ets
└── src/main/module.json5
```

## 2. `entry/src/main/module.json5`

把以下字段合并进现有 `module`，不要覆盖工程其它 `abilities`、权限和配置：

```json5
"skillProfiles": [
  {
    "name": "org-example-echo",
    "abilityName": "EntryAbility",
    "srcEntries": [
      "../../skills/org-example-echo/scripts/EchoSkill.ets"
    ],
    "version": "1.0.0"
  }
]
```

若 Skill 需要网络等权限，按应用权限规范在 `module` 中声明最小必要权限；不要为了构建而添加未使用权限。

## 3. `entry/skills/org-example-echo/SKILL.md`

````markdown
---
name: org-example-echo
description: 将用户提供的文本原样回显；不翻译、不改写、不保存或发送文本。
---

## 触发场景
用户明确要求回显或原样复述一段文本时调用。

典型话术：
- “回显 hello”
- “原样返回这句话：今天天气很好。”

不调用的情况：
- 用户要求翻译、摘要或改写。
- 用户要求保存、分享或发送文本。

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
      "arg1": {
        "type": "string",
        "description": "需要原样回显的文本"
      }
    },
    "required": ["arg1"]
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
````

## 4. `entry/skills/org-example-echo/scripts/EchoSkill.ets`

```ts
import { scriptManager } from '@kit.AbilityKit';

export default class EchoSkill {
  public async run(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    const input = argv.length > 0 ? argv[0].trim() : '';

    let result: scriptManager.ExecuteResult;
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
      result = {
        code: 0,
        result: {
          type: 'result',
          status: 'success',
          data: { message: input }
        }
      };
    }

    try {
      await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
    } catch (error) {
      console.error(`completeArkTSScriptInApp failed: ${String(error)}`);
    }
  }
}
```

## 5. 需要抽出业务模块时

入口依旧使用 ETS；把业务实现放到单独的 `.ets`、`.ts` 或 `.js` 模块，并从入口导入。HarmonyOS Runtime 支持多语言运行，但每个模块是否能被当前 SDK 编译、类型是否匹配、运行时是否安全，都要单独验证。当前团队已经验证“ETS 入口导入简单 JS helper”可以构建；这不改变 `srcEntries` 必须指向 `.ets` 的要求。

```js
// entry/skills/org-example-echo/scripts/EchoBusiness.js
export function echoMessage(message) {
  return String(message).trim();
}
```

```ts
// EchoSkill.ets 中
import { echoMessage } from './EchoBusiness';
```

## 6. 复制后逐项替换

1. 修改目录名与 `SKILL.md` 的 `name`、`module.json5` 的 `skillProfiles[].name`，确保三者一致。
2. 修改 `abilityName` 为工程真实 Ability 名称。
3. `srcEntries` 始终填 `.ets` 入口路径。
4. 每个 `functionName` 必须对应 ETS 类中的同名 `public async` 方法。
5. 保持 Schema 中参数顺序与 `argv` 的读取顺序一致。
6. 按实际业务补齐成功、失败、异常返回分支，并申请最小权限。
7. 构建 HAP；之后单独验证 HAP 安装与小艺/系统智能体实际调度。

完整字段解释、接口类型、调用边界和验收表见[格式要求与接口说明](harmonyos-app-skill-format-and-api.md)。
