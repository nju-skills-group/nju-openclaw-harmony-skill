---
name: a2-empty-skill
description: 用于验证 HarmonyOS 应用 Skill 注册、加载和 ArkTS 脚本调用链路
---

# A2 Empty Skill

## 触发场景

当用户明确要求检查测试 Skill 是否可用时调用，例如：

- “检查 A2 Skill”
- “测试鸿蒙 Skill”
- “确认 Skill 是否正常”

其他业务请求不调用本 Skill。

### 场景1：检查 Skill 连通性（ping）

#### 执行参数

exec-cli(command: ohos-arkTSScript --skillName 'a2-empty-skill' --scriptPath 'scripts/EmptySkill.ets' --functionName 'ping' --args '{}')

```json
{
  "args": {
    "type": "object",
    "properties": {},
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
  "data": {
    "message": "A2 Skill is ready"
  }
}
```

返回值约束：

```json
{
  "type": "object",
  "required": ["type", "status", "data"],
  "properties": {
    "type": {
      "type": "string",
      "const": "result"
    },
    "status": {
      "type": "string",
      "const": "success"
    },
    "data": {
      "type": "object",
      "required": ["message"],
      "properties": {
        "message": {
          "type": "string"
        }
      }
    }
  }
}
```