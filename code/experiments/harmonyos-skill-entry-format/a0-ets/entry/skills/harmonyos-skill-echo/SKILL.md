---
name: harmonyos-skill-echo
description: 验证鸿蒙应用 Skill 接入链路，接收一段文本并原样返回。
---

## 触发场景
当用户要求验证应用 Skill 是否接入，或要求回显一段文本时调用。

典型话术：
- “回显 hello”
- “验证 HarmonyOS Skill 接入”

不调用的情况：
- 用户要求执行实际业务操作时，本示例不承担该业务。

### 场景 1：回显文本（echo）

#### 执行参数
```text
exec-cli(command: ohos-arkTSScript --skillName 'harmonyos-skill-echo' --scriptPath 'scripts/EchoSkill.ets' --functionName 'echo' --args '{"arg1":"hello"}')
```

参数 Schema：
```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": { "type": "string", "description": "要原样返回的文本" }
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
