---
name: test-code-receipt-089e5768
description: 为用户输入的非敏感测试码在鸿蒙应用内生成随机编号，并将测试码和编号显示在当前对话。
---

仅处理本轮输入的测试码。脚本不访问网络、文件或账号数据。

## 触发场景

用户明确要求调用「测试编号」或要求为测试码生成「测试编号」时使用。普通聊天、询问测试步骤或要求生成其他类型的回执时，无需触发。用户未提供测试码时，请先询问测试码。

### 场景 1：签发测试回执（issueReceipt）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'test-code-receipt-089e5768' --scriptPath 'scripts/ReceiptSkill.ets' --functionName 'issueReceipt' --args '{"arg1":"DEMO-EXAMPLE-01"}')
```

```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": { "type": "string", "pattern": "^[A-Za-z0-9-]{6,32}$", "description": "用户提供的测试码，保留原始大小写" }
    },
    "required": ["arg1"],
    "additionalProperties": false
  }
}
```

#### 执行返回值

成功结果示例：

```json
{"type":"result","status":"success","data":{"nonce":"DEMO-EXAMPLE-01","receiptId":"b1931a35-793e-4fa2-89b7-6b54d73fe157"}}
```

失败结果示例：

```json
{"type":"result","status":"failed","errCode":"ERR_INVALID_NONCE","suggestion":"请输入由英文字母、数字或连字符组成的 6 到 32 位测试码。"}
```

```json
{
  "type": "object",
  "required": ["type", "status"],
  "properties": {
    "type": { "const": "result" },
    "status": { "enum": ["success", "failed"] },
    "data": {
      "type": "object",
      "properties": {
        "nonce": { "type": "string" },
        "receiptId": { "type": "string", "format": "uuid" }
      },
      "required": ["nonce", "receiptId"]
    },
    "errCode": { "type": "string" },
    "suggestion": { "type": "string" }
  },
  "oneOf": [
    { "properties": { "status": { "const": "success" } }, "required": ["data"] },
    { "properties": { "status": { "const": "failed" } }, "required": ["errCode", "suggestion"] }
  ]
}
```

成功后在回复里原样展示实际返回的 `nonce` 和完整 `receiptId`。收到失败结果时向用户展示 `suggestion`。
