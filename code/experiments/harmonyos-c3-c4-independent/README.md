# C3/C4 个人端侧实验

初次检出时复制 `build-profile.example.json5` 为 `build-profile.json5`，在 DevEco Studio 中为自己的设备生成调试签名。工程使用 API 26。个人签名配置留在本机。

安装后打开「个人实验智能体」，输入 `生成回执 C3-DEMO-01`，分别点「调用应用内处理器」和「调用回执 Ability」。用 HiLog 标签 `C34OwnAgent` 关联意图匹配、Ability 进入、回包和界面 UUID。以「查看天气」验证未匹配。

C3b 从 `entry/src/main/resources/rawfile/skills/weather-current/SKILL.md` 读取技能描述、触发规则和工具名。输入 `南京当前天气` 并点「执行天气 Skill」，核对同一请求 ID 的 `weather_skill_loaded`、`weather_skill_matched`、`weather_tool_start`、`weather_tool_http` 和 `weather_agent_result`。用「当前天气」、1 ms 超时按钮和禁用开关分别验证缺参、超时、禁用行为。小艺应用 Skill 使用独立的 `skilllab-weather-app-089e5768` 注册名，和 C3b 共用 `WeatherService.ets`。[三路线对照](../../../docs/experiment/weather-three-route-comparison.md)

C4 使用独立应用包名 `com.skilllab.c34agent089e5768`、模块 `entry`、应用服务 `LabAgentExtension` 和 `entry/src/main/resources/base/profile/agent_config.json`。在个人小艺开放平台建立端 A2A Agent，关联自己的同包名应用并向个人组发布真机测试。打开平板小艺中的测试 Agent，发送 `生成回执 C4-PAD-01`，对照 `a2a_connected`、`a2a_method`、`a2a_receipt` 和 `a2a_sent` 以及界面回执。`a2a_auth_requested` 仅记录收到认证回调，认证结果需要调用方或平台证据。[华为端 A2A 指南](https://developer.huawei.com/consumer/cn/doc/service/device-a2a-quickstart-0000002733266338/)
