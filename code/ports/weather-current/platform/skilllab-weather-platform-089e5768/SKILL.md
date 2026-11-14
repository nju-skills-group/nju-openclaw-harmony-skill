---
name: skilllab-weather-platform-089e5768
description: 根据明确给出的城市查询当前气温和天气状况。城市缺失时询问用户。
---

## 适用场景

用户要求查询当前天气时使用。只支持当前天气，城市由用户提供。

## 操作规程

1. 城市缺失时询问用户要查询哪个城市，此时无需网络请求。
2. 对城市名进行 URL 编码，调用 `web_fetch` 获取 `https://wttr.in/<城市>?format=j1`。南京使用 `Nanjing`。
3. 从返回的 `current_condition[0]` 读取 `temp_C`、`weatherDesc[0].value` 和可用的 `observation_time`，从 `nearest_area[0]` 获取匹配地点。返回地点、摄氏温度、天气描述和原始观测时间字段。
4. 请求失败、超时或返回字段缺失时如实说明。天气数据以本次工具响应为准。
