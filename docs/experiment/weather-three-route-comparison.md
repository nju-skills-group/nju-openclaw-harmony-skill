# OpenClaw weather 三路线移植对照

本轮使用本人设备、账号和新采集的数据。源样本是固定提交 `d79ab6195d8d0566b285008bcc30c01a6ce368e2` 的 OpenClaw bundled `weather`。仓库源文件的 Git blob 为 `e84bbea68bae7416d27eede03154b7acd29b3559`。原 Skill 优先使用 `web_fetch`，备用为 `curl`。本轮移植范围为单城市当前天气。三条路线统一请求 `wttr.in` 的 `format=j1`，该参数来自源 Skill 的 `curl` 示例。预报、其他提供方及备用工具链均在范围之外。[原始 Skill](https://github.com/openclaw/openclaw/blob/d79ab6195d8d0566b285008bcc30c01a6ce368e2/skills/weather/SKILL.md)

## 路线与证据

| 路线 | 交付物与修改 | 通过条件 | 当前状态 |
| --- | --- | --- | --- |
| 小艺平台 Skill | [平台包说明](../../code/ports/weather-current/platform/skilllab-weather-platform-089e5768/SKILL.md)，`module.json`。保留天气指令，在技能规程中声明使用 `web_fetch`。 | 个人测试组内触发已发布的技能，获得工具执行记录与符合响应的数据。 | 小艺 Work 已有安装报告及苏州查询界面证据。界面回复的四个字段符合技能规程。Skill 加载与工具调用尚缺独立记录。小艺主对话也返回过天气，实际自定义 Skill 调用待核实。 |
| 鸿蒙应用 Skill | [应用 Skill 描述](../../code/experiments/harmonyos-c3-c4-independent/entry/skills/skilllab-weather-app-089e5768/SKILL.md)，`WeatherSkill.ets`、`skillProfiles`、共享网络实现。 | 目标 HAP 安装且发布到个人组，从小艺主对话捕获 `weather_app_skill_entered`、请求结果、`weather_app_skill_reported` 及界面输出。 | 签名 HAP 已安装到 MatePad，用户确认已向个人组发布。首次测试未见入口，主对话返回其他路径的天气，未取得脚本执行证据。 |
| C3b 自建 Agent | [独立技能目录](../../code/experiments/harmonyos-c3-c4-independent/entry/src/main/resources/rawfile/skills/weather-current/SKILL.md)，App 读取资源包中的文件，按其触发规则绑定 `get_current_weather`，调用相同的鸿蒙网络实现。 | 看到同一次调用的文件加载、匹配、HTTP 响应与界面结果。禁用技能后重新提交相同输入，确认无工具请求。 | MatePad 实测 W1–W4 均符合预期。[HiLog](experiment-c-evidence/c3b-weather-matepad-hilog.txt) |

C3b 使用随 HAP 分发的独立技能目录和确定性路由。`tool` 与 `trigger-suffixes` 是本实验加载器使用的字段，正文供阅读。此版本支持预先配置的天气技能，记录的是文件驱动的技能加载及工具执行。C3a 的原有回执路径仍用于本地函数和 Ability 对照。[自建 Agent 工程](../../code/experiments/harmonyos-c3-c4-independent/README.md)

## 用例

| 编号 | 输入或条件 | 预期与判定 |
| --- | --- | --- |
| W1 | 查询南京当前天气 | 真实 GET，返回匹配地点、摄氏温度、天气描述，提供观测时间时保留原值。应用 Skill 可在同一业务输入前加「请调用 skilllab-weather-app-089e5768」。 |
| W2 | 查询当前天气 | 请求用户补充城市。观察是否发出查询。 |
| W3 | 查询南京当前天气，执行环境设置 1 ms 超时 | 记录真实网络错误和界面输出。C3b 有专用对照按钮；平台或应用 Skill 无法控制超时注入时登记未测。 |
| W4 | 禁用 C3b 的天气技能，再发送 W1 | 界面提示已禁用，同一请求无 HTTP 调用。仅用于 C3b。 |

天气值随观测时间改变。核对每次界面与当次响应的字段，以及三条路线的语义、工具选择和失败行为。Windows 侧本人已发起一次独立的 `curl` 请求，确认 `Nanjing?format=j1` 当时返回匹配地点 Nanjing、`temp_C=14`、`weatherCode=266`、`observation_time=08:10 PM`。这是提供方连通性参考，OpenClaw Agent 的实际原平台运行仍待本轮独立复测。工作站当前 PATH 未发现 `openclaw` 命令。

## 小艺平台路线初测

2026 年 11 月 14 日，用户提交截图。输入为「请使用 skilllab-weather-platform-089e5768 查询南京当前天气」。小艺显示「执行查询未来天气」和「生成回复」，报告南京当日预报及当前阴、14 °C。界面未显示技能加载、`web_fetch` 或 `wttr.in` 调用记录。读取 MatePad 可见 HiLog 缓冲，未检出对应技能标识或数据源。当前记录为天气问答有结果，自定义平台 Skill 执行待核实。后续从对应测试入口查看实际命中的 Skill 和工具，或用能够关联到自定义工具调用的测试记录复核。[界面截图](experiment-c-evidence/weather-platform-w1-reply.png)

同日约 04:38，在 MatePad 小艺主对话点名要求加载技能并通过 `web_fetch` 读取 `wttr.in/Nanjing?format=j1`。该轮仅显示「生成回复」。小艺自报无法使用 `web_fetch`，并引用前一轮天气结果。04:45 提取的可见 HiLog 中未找到本技能标识或数据源。该轮未取得自定义 Skill 加载或工具执行证据。现有观察限于主对话这一轮，具体能力限制和发布状态仍需按实际测试渠道核对。下一轮可检查该项目是否提供小艺 Work／Claw 真机测试入口，再验证加载与工具执行。[复测截图](experiment-c-evidence/weather-platform-w1-explicit-retry.jpg) · [华为 Skill 真机测试说明](https://developer.huawei.com/consumer/cn/doc/service/skill-real-machine-testing-0000002592771628/)

同日约 04:50，苏州复测 `WX-WORK-7K2M` 的截图显示左侧选中「小艺」。本轮归入主对话对照。展开步骤显示「执行查询未来天气」和「生成回复」，界面返回小雨、16 °C 和当日预报。读取 MatePad 可见 HiLog，在 04:50 的 2,066 行中未检出测试编号、Skill 注册名、`web_fetch` 或 `wttr.in`。本轮证据仅支持主对话返回了天气，实际自定义 Skill 调用仍待验证。[苏州复测截图](experiment-c-evidence/weather-platform-suzhou-main-dialog.jpg)

## 小艺 Work 真机测试

用户通过平台真机测试生成的安装提示词，在 MatePad 的小艺 Work 安装天气 Skill。Work 回复报告平台下载包为 982 B，含 `SKILL.md` 和 `module.json`，版本 `0.1.0`，安全扫描为 `Benign / ACCEPT`（退出码 0，回复中的截断哈希为 `32fb0981…c259bf2a2`）。回复给出的安装目录为 `~/.openclaw/workspace/skills/skilllab-weather-platform-089e5768/`。

Work 报告南京查询结果为 `Nanjing, Jiangsu, China`、14 °C、`Light drizzle`、`08:10 PM`。观测时间仅登记原始字段。该轮的安装、扫描和执行信息均来自 Work 回复。Work 同时指出已有同用途的 `weather` 技能，因此需要用实际读取的技能路径和工具调用详情确认执行归属。平台下载包与本地提交 ZIP 的字节数不同，平台产物仅按 Work 报告登记。

2026 年 11 月 14 日 04:53–04:54，用户提交的截图确认会话位于「小艺Work」。截图对应 `WX-WORK-7K2M`，与 04:50 的主对话复测共用编号，以页面标题和时间区分。本轮返回地点 `Fengchiaochen, Jiangsu, China`（31.313, 120.561）、16 °C、`Light drizzle` 和原始观测时间 `08:23 PM`。回复称通过 `web_fetch` 请求 `https://wttr.in/Suzhou?format=j1` 并取得 HTTP 200。界面展开区和最终回复均为文本，未见可独立核验的技能文件读取或工具调用记录。MatePad 可见 HiLog 在 04:52–04:55 共 9,095 行，未检出两轮 Work 测试编号、Skill 注册名、`web_fetch` 或 `wttr.in`。本轮通过输出字段检查，工具执行归属待核验。`WX-WORK-8F3N` 仅收到完成反馈，结果字段以 `WX-WORK-7K2M` 的截图为依据。[展开区截图](experiment-c-evidence/weather-platform-suzhou-work-expanded.jpg) · [回复截图](experiment-c-evidence/weather-platform-suzhou-work-reply.jpg)

## 鸿蒙应用 Skill 构建核对

已检查签名 HAP 的 `module.json`，包名为 `com.skilllab.c34agent089e5768`，Skill 注册名为 `skilllab-weather-app-089e5768`，承载组件为 `EntryAbility`，`srcEntries` 指向 `skills/skilllab-weather-app-089e5768/scripts/WeatherSkill.ets`。编译后的 `ets/modules.abc` 中可找到脚本类名、入口函数名和应用 Skill 日志标记。MatePad 包管理能查到应用包名。签名 HAP 的 SHA-256 为 `1A3D07EABA0FDCD956B6B63EA0E1A745282B1112ECA55B9F8947E85544969A7A`。

### 小艺主对话真机复测

2026 年 11 月 14 日，用户确认已向个人测试组发布。约 05:06，用户反馈重新打开小艺后未看到 Skill 测试入口，在主对话发送 `WX-APP-4M8Q` 点名查询南京当前天气，小艺通过其他路径返回了天气。05:06:00–05:06:25 的 1,612 行可见 HiLog 未找到测试编号、Skill 注册名、`weather_app_skill_entered`、`weather_tool_start` 或 `weather_app_skill_reported`。05:06:15.311 仅有一条 `HwVA_SkillListenerStub: remote is null`，其中无请求 ID、Skill 名或底层错误码。现有证据无法将这条错误与应用 Skill 关联，也无法区分测试版本下发、语义匹配或后续调度环节。下一步核对本次发布的渠道、测试组和包名，再以明确指向个人实验 App 的输入复测。[华为 Skill 真机测试说明](https://developer.huawei.com/consumer/cn/doc/service/skill-real-machine-testing-0000002592771628/)

用户提供的真机测试面板显示已选中一个名称以 `C2 MateBook 个…` 开头的测试组，并提供「取消发布」「重新发布」。截图可确认面板上的发布状态与所选组，渠道标题和组内账号未显示。[平台面板截图](experiment-c-evidence/weather-app-test-publish-panel.png)

面板展开后的设备校验要求 HarmonyOS 7、小艺 11.7.x 或以上，并以小艺主对话快捷方式中出现「Skill真机测试中」作为环境就绪标志。通过 HDC 读回 MatePad `TGR-W00` 的系统版本 `7.0.0.111 (SP18C00E111R2P2)`、API 26 和小艺应用版本 `11.7.9.301`。两个版本条件均满足。用户检查后确认快捷方式仍未出现，设备端测试环境就绪校验未通过。待核对当前发布渠道和测试组内账号，再请平台按设备构建和 Skill 注册名查测试配置下发与入口启用状态。[设备校验说明截图](experiment-c-evidence/weather-app-test-device-check.png)

## C3b 真机结果

2026 年 11 月 14 日，北京时间。设备为 MatePad `TGR-W00`，HarmonyOS 7.0.0.111，API 26.0.0。通过 HDC 安装和启动后，从 App 的输入框和测试按钮触发，逐项读取界面结果及相同请求 ID 的 HiLog。[同轮日志](experiment-c-evidence/c3b-weather-matepad-hilog.txt)

| 用例 | 开始时间 | 界面与执行证据 |
| --- | --- | --- |
| W1 正常查询 | 04:26:40.677 | `weather_skill_loaded` 和 `weather_skill_matched` 后真实发出 GET，返回 HTTP 200。界面及日志均为 `Nanjing · 14 °C · Light drizzle · 08:10 PM` 对应字段。观测时间为服务原值。 |
| W2 缺城市 | 04:28:39.953 | 显示「请提供要查询的城市」，相同请求 ID 无 `weather_tool_start`。 |
| W3 受控超时 | 04:27:52.048 | HTTP 连接与读取超时配置为 1 ms，日志返回网络错误 `2300028`，界面提示「查询超时」。 |
| W4 禁用对照 | 04:27:57.686 | 同样输入南京天气，界面显示「天气 Skill 已禁用」，日志无该请求的工具执行。 |
