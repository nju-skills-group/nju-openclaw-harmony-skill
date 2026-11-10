---
name: json-toolkit
description: 提供 JSON 格式化、压缩、验证、键排序和点号路径查询能力
---

# JSON Toolkit

## 触发场景

当用户明确要求处理 JSON 数据时调用，例如：

- “格式化这段 JSON”
- “验证 JSON 是否正确”
- “压缩这段 JSON”
- “把 JSON 的键排序”
- “查询 JSON 中的 data.users.0.name”

不调用的情况：

- 用户只是在讨论 JSON 概念，没有提供待处理数据。
- 用户要求处理 XML、YAML、CSV 等其他格式。
- 用户要求读取或写入本地文件。本版本只接收字符串，不操作文件。
- JSON 可能包含密码、令牌或其他敏感信息时，应先提醒用户确认。

## 操作说明

支持以下操作：

| operation | 功能 | 额外参数 |
| --- | --- | --- |
| `format` | 格式化 JSON | `arg4` 为缩进数，`arg5` 表示是否排序键 |
| `minify` | 压缩 JSON | `arg5` 表示是否排序键 |
| `validate` | 验证 JSON 并返回结构信息 | 无 |
| `query` | 使用点号路径查询 | `arg3` 为查询路径 |
| `sort` | 递归排序对象键并格式化 | `arg4` 为缩进数 |

### 场景1：格式化 JSON（run）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'json-toolkit' --scriptPath 'scripts/JsonToolkitSkill.ets' --functionName 'run' --args '{
  "arg1": "format",
  "arg2": "{\"b\":2,\"a\":1}",
  "arg3": "",
  "arg4": 2,
  "arg5": false
}')
```

### 场景2：验证 JSON（run）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'json-toolkit' --scriptPath 'scripts/JsonToolkitSkill.ets' --functionName 'run' --args '{
  "arg1": "validate",
  "arg2": "{\"name\":\"Alice\",\"items\":[1,2]}",
  "arg3": "",
  "arg4": 2,
  "arg5": false
}')
```

### 场景3：压缩 JSON（run）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'json-toolkit' --scriptPath 'scripts/JsonToolkitSkill.ets' --functionName 'run' --args '{
  "arg1": "minify",
  "arg2": "{\"b\": 2, \"a\": 1}",
  "arg3": "",
  "arg4": 2,
  "arg5": true
}')
```

### 场景4：查询 JSON（run）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'json-toolkit' --scriptPath 'scripts/JsonToolkitSkill.ets' --functionName 'run' --args '{
  "arg1": "query",
  "arg2": "{\"data\":{\"users\":[{\"name\":\"Alice\"}]}}",
  "arg3": "data.users.0.name",
  "arg4": 2,
  "arg5": false
}')
```

### 场景5：排序 JSON 键（run）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'json-toolkit' --scriptPath 'scripts/JsonToolkitSkill.ets' --functionName 'run' --args '{
  "arg1": "sort",
  "arg2": "{\"z\":1,\"data\":{\"b\":2,\"a\":1}}",
  "arg3": "",
  "arg4": 2,
  "arg5": false
}')
```

## 参数约束

五个场景共用以下参数结构：

```json
{
  "args": {
    "type": "object",
    "required": ["arg1", "arg2"],
    "properties": {
      "arg1": {
        "type": "string",
        "enum": ["format", "minify", "validate", "query", "sort"],
        "description": "要执行的 JSON 操作"
      },
      "arg2": {
        "type": "string",
        "minLength": 1,
        "description": "待处理的 JSON 字符串"
      },
      "arg3": {
        "type": "string",
        "description": "query 操作使用的点号路径"
      },
      "arg4": {
        "type": "integer",
        "minimum": 0,
        "maximum": 8,
        "default": 2,
        "description": "格式化缩进空格数"
      },
      "arg5": {
        "type": "boolean",
        "default": false,
        "description": "是否递归排序对象键"
      }
    },
    "additionalProperties": false
  }
}
```

`query` 操作必须提供非空的 `arg3`。其他操作忽略 `arg3`。

## 执行返回值

### 成功示例

```json
{
  "type": "result",
  "status": "success",
  "data": {
    "operation": "format",
    "valid": true,
    "result": "{\n  \"b\": 2,\n  \"a\": 1\n}"
  }
}
```

验证操作成功示例：

```json
{
  "type": "result",
  "status": "success",
  "data": {
    "operation": "validate",
    "valid": true,
    "jsonType": "object",
    "itemCount": 2,
    "size": 32
  }
}
```

### JSON 非法

```json
{
  "type": "result",
  "status": "failed",
  "errCode": "ERR_INVALID_JSON",
  "errMsg": "JSON parse failed",
  "suggestion": "请检查 JSON 的引号、逗号和括号是否正确"
}
```

### 参数非法

```json
{
  "type": "result",
  "status": "failed",
  "errCode": "ERR_INVALID_PARAMS",
  "errMsg": "Unsupported operation",
  "suggestion": "请选择 format、minify、validate、query 或 sort"
}
```

### 查询失败

```json
{
  "type": "result",
  "status": "failed",
  "errCode": "ERR_QUERY_PATH",
  "errMsg": "Key or array index not found",
  "suggestion": "请检查查询路径是否与 JSON 结构一致"
}
```

### 返回值约束

```json
{
  "type": "object",
  "required": ["type", "status"],
  "properties": {
    "type": {
      "type": "string",
      "const": "result"
    },
    "status": {
      "type": "string",
      "enum": ["success", "failed"]
    },
    "data": {
      "type": "object",
      "properties": {
        "operation": {
          "type": "string"
        },
        "valid": {
          "type": "boolean"
        },
        "result": {
          "type": "string"
        },
        "jsonType": {
          "type": "string"
        },
        "itemCount": {
          "type": "integer"
        },
        "size": {
          "type": "integer"
        }
      }
    },
    "errCode": {
      "type": "string",
      "enum": [
        "ERR_INVALID_PARAMS",
        "ERR_INVALID_JSON",
        "ERR_QUERY_PATH",
        "ERR_INTERNAL"
      ]
    },
    "errMsg": {
      "type": "string"
    },
    "suggestion": {
      "type": "string"
    }
  },
  "oneOf": [
    {
      "properties": {
        "status": {
          "const": "success"
        }
      },
      "required": ["data"]
    },
    {
      "properties": {
        "status": {
          "const": "failed"
        }
      },
      "required": ["errCode", "errMsg", "suggestion"]
    }
  ]
}
```