---
name: nju-ontology
description: 在应用本地创建和查询 Project、Task、Note 等结构化实体；不访问网络，不保存密码或令牌。
---

## 触发场景

当用户明确要求在本应用中记录一个结构化实体，或按 ID、类型查询此前记录的实体时调用。

典型话术：

- “记住一个 ID 为 note_harmony_e3 的 Note，内容是 HarmonyOS E3 port。”
- “查询 ID 为 note_harmony_e3 的实体。”
- “列出所有 Note。”

不调用的情况：

- 用户要求保存密码、令牌或其他秘密。
- 用户要求创建关系、更新、删除、导入/导出或执行跨应用文件操作；本轮子集未实现这些能力。
- 用户只是在询问 ontology 概念，没有要求读写实体。

### 场景 1：创建实体（createEntity）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'nju-ontology' --scriptPath 'scripts/OntologySkill.ets' --functionName 'createEntity' --args '{
  "arg1": "note_harmony_e3",
  "arg2": "Note",
  "arg3": "{\"content\":\"HarmonyOS E3 port\",\"tags\":[\"e3\",\"harmonyos\"]}"
}')
```

参数 Schema：

```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": { "type": "string", "description": "实体 ID，1-64 个字母、数字、下划线或连字符" },
      "arg2": { "type": "string", "enum": ["Person", "Project", "Task", "Goal", "Event", "Document", "Message", "Thread", "Note", "Action", "Policy"] },
      "arg3": { "type": "string", "description": "实体 properties 的 JSON 对象字符串，最大 16 KiB" }
    },
    "required": ["arg1", "arg2", "arg3"],
    "additionalProperties": false
  }
}
```

成功示例：

```json
{
  "type": "result",
  "status": "success",
  "data": {
    "entity": {
      "id": "note_harmony_e3",
      "type": "Note",
      "properties": { "content": "HarmonyOS E3 port", "tags": ["e3", "harmonyos"] }
    }
  }
}
```

失败分支：`ERR_INVALID_PARAMS`、`ERR_INVALID_JSON`、`ERR_REQUIRED_PROPERTY`、`ERR_FORBIDDEN_PROPERTY`、`ERR_CONFLICT`、`ERR_LIMIT`、`ERR_INTERNAL`。

### 场景 2：按 ID 查询实体（getEntity）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'nju-ontology' --scriptPath 'scripts/OntologySkill.ets' --functionName 'getEntity' --args '{"arg1":"note_harmony_e3"}')
```

参数 Schema：

```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": { "type": "string", "description": "要查询的实体 ID" }
    },
    "required": ["arg1"],
    "additionalProperties": false
  }
}
```

未找到时返回 `ERR_NOT_FOUND`，不得虚构实体。

### 场景 3：按类型列出实体（listEntities）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'nju-ontology' --scriptPath 'scripts/OntologySkill.ets' --functionName 'listEntities' --args '{"arg1":"Note"}')
```

参数 Schema 与创建场景中的实体类型枚举一致，`arg1` 为必填类型。成功返回 `data.entities` 和 `data.count`；没有匹配项时返回空数组，不返回错误。

## 返回值约定

所有方法均返回：

```json
{
  "type": "result",
  "status": "success 或 failed",
  "data": {},
  "errCode": "失败时存在",
  "errMsg": "失败时存在",
  "suggestion": "失败时存在"
}
```

