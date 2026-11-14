---
name: harmonyos-weather
description: 查询指定地点的实时天气及服务提供的未来数日最高最低气温，适用于气温、湿度、降水、风速、天气预报查询。
---
## 触发场景
用户询问某城市、地区、机场代码或经纬度对应的天气时调用。没有地点时先追问，不默认使用用户当前位置。
不用于历史天气、官方灾害预警、航空或海洋决策。不请求定位权限。
### 场景：查询天气（query）
#### 执行参数
```text
exec-cli(command: ohos-arkTSScript --skillName 'harmonyos-weather' --scriptPath 'scripts/WeatherSkill.ets' --functionName 'query' --args '{"arg1":"Shanghai"}')
```
参数 Schema：
```json
{"args":{"type":"object","properties":{"arg1":{"type":"string","description":"地点，如Shanghai、南京、LHR或31.2,121.5"}},"required":["arg1"]}}
```
#### 执行返回值
成功：`{"type":"result","status":"success","data":{"requestedCity":"Shanghai","resolvedLocation":"服务实际解析地点","temperatureC":"服务实际返回值","condition":"服务实际返回描述","forecast":[]}}`。
data还包含feelsLikeC、humidityPercent、windKmph、precipitationMm、observationTimeRaw、fetchedAt及source。forecast各项含date、mintempC和maxtempC。
失败：`{"type":"result","status":"failed","errCode":"ERR_WEATHER_UNAVAILABLE","errMsg":"Weather services did not return usable data.","suggestion":"Check the location and network, then retry."}`。
参数缺失或为空时返回ERR_INVALID_PARAMS。不得用模型知识补写天气数值；展示实际解析地点和来源；不擅自推断observationTimeRaw的时区。主服务失败后自动尝试备用服务。
返回 Schema：
```json
{"type":"object","required":["type","status"],"properties":{"type":{"const":"result"},"status":{"enum":["success","failed"]},"data":{"type":"object"},"errCode":{"type":"string"},"errMsg":{"type":"string"},"suggestion":{"type":"string"}}}
```
