---
name: skilllab-weather-app-089e5768
description: 通过已安装的个人实验 App 查询指定城市的当前气温和天气状况。
---

## 触发场景

用户明确要求使用个人实验 App 查询某个城市的当前天气时调用。城市缺失时先询问。

## 能力契约

调用 `getCurrentWeather`，只传一个城市名称。

```text
exec-cli(command: ohos-arkTSScript --skillName 'skilllab-weather-app-089e5768' --scriptPath 'scripts/WeatherSkill.ets' --functionName 'getCurrentWeather' --args '{"arg1":"南京"}')
```

```json
{
  "args": {
    "type": "object",
    "properties": { "arg1": { "type": "string", "description": "城市名称" } },
    "required": ["arg1"]
  }
}
```

结果为 `type: result`。`status: success` 时，`data` 包含地点、摄氏温度、天气描述和可用的原始观测时间。失败时按 `data.reason` 如实提示。
