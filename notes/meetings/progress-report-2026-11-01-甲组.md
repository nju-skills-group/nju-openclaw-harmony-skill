# 甲组阶段进度汇报

**汇报日期：2026 年 11 月 1 日**  
**方向：HarmonyOS Agent / 应用 Skill 接入与运行形态验证**  
**环境：DevEco Studio 26.0.0.851、Hvigor 6.26.8、HarmonyOS SDK 26.0.0.105（API 26）**

## 一、阶段目标

甲组最终交付《鸿蒙智能体与 Skill 机制实验报告》，回答“鸿蒙原生机制如何运作、Skill 以何种形态运行、性能代价几何”，包括：

1. 实验小艺调用官方原生 Skill、自定义 Skill，以及自建智能体中Skill调度链路。
2. 对比小艺直调、自建智能体调用路径。
3. 对比纯 ArkTS Skill 入口与非 ArkTS Skill可行性和性能，报告启动延迟、内存占用、执行耗时及测量方法。

## 二、当前进度摘要

| 工作项 | 状态 | 已有证据 | 当前边界                                               |
|---|---|---|----------------------------------------------------|
| API 26 / Stage 工程配置核对 | 已完成 | 官方接口与工程配置对照表；本机 API 26 SDK | 官方版本升级后需复核                                         |
| 自建应用 Skill 接入教程与模板 | 已完成初稿 | 全链路教程、格式接口说明、可复制模板 | 真实系统调度步骤需目标设备补证                                    |
| 官方音乐助手 Skill 示例整理 | 已接入项目 | `SKILL.md`、ArkTS 入口、模拟业务服务已加入 `D:\desk\HarmonyOS_skills`； | 曲库只模拟，不播放音频                                        |
| Skill 入口直接使用 `.js` | 已验证构建层不接受 | 先前隔离实验返回 `00303304`，提示 `skillProfiles.srcEntries` 仅支持 `.ets` |                                                    |
| ArkTS Skill 入口调用 JS helper | 已验证构建通过 | 隔离实验 HAP 构建成功 | 尚无系统调度和运行时结果证据                                     |
| `entry/src/main` 普通 JS 构建 | 已验证构建通过 | 本次 34 个 Hvigor 任务完成，生成 unsigned HAP |                          |
| 模拟器启动 | 已完成基础验证 | 原 Echo 应用在 API 26 模拟器显示 `Hello World` | 只能证明应用启动                                           |
| 小艺原生 Skill 调用 | 暂未完成 | 当前模拟器未发现可见的小艺入口 | 需要真机或具备该入口的测试环境                                    |

## 三、可展示的成果与文件

### 汇报时建议优先展示

| 展示项 | 文件/位置 | 展示方式 |
|---|---|---|
| 官方 Skill 接入结构 | `D:\desk\HarmonyOS_skills\entry\skills\example-org-music-assistant\` | 
| 自建 Skill 全链路教程 | [deveco-skill-e2e-tutorial.md](../../docs/03-environment/deveco-skill-e2e-tutorial.md) |
| Skill 格式、接口与模板 | [harmonyos-app-skill-format-and-api.md](../../docs/05-protocols/harmonyos-app-skill-format-and-api.md)、[harmonyos-app-skill-template.md](../../docs/05-protocols/harmonyos-app-skill-template.md) | 
| 非 ETS 主模块构建实验 | [实验说明及结果](../../code/experiments/harmonyos-main-nonets-probe/README.md) | 


## 四、已确认的技术结论

当前实验将两类入口分开观察：

```text
应用 Skill 链路：SKILL.md / skillProfiles → ArkTS Skill 脚本 → 业务逻辑 → completeArkTSScriptInApp
普通应用主模块：module.json5 Ability srcEntry / pages → ETS 或 JS 源文件 → Hvigor 构建与 HAP
```

- 在当前 DevEco / API 26 工程中，`entry/src/main` 的 Ability 与页面模块改用 `.js` 后，Hvigor 可以构建并打包。此结果只说明主模块当前源文件形态被构建链接受。
- 当前应用 Skill `srcEntries` 直接指向 `.js` 时构建失败；ArkTS Skill 入口导入 JS helper 则可以构建。两项结果不矛盾，因为检验的是不同入口契约。
- `Index.ets` 使用 ArkUI 声明式语法，不能通过改扩展名或删除类型标注变成等价普通 JS 页面。非 ETS 构建副本中的 `Index.js` 只用于构建接受性探测。


## 五、当前未完成项与限制


1. **小艺调用待设备支持** 现有模拟器没有发现可见的小艺入口，不能据此断言 Skill 不可调用。
2. **运行时行为待验证：** JS 主模块构建通过，但尚未安装启动该实验 HAP；页面占位内容不等同原 UI。
3. **Skill 运行时和非 ETS 入口待分开验证：** 已有构建证据，尚无系统调度调用证据。
4. **性能数据待采集：** 当前没有可复现的 Skill 调用数据；没有真机，因此不能给出真机结论。
5. **音乐示例是模拟服务：** 只验证入口和业务模块组织方式，不调用真实音乐服务或播放音频。

## 六、下一阶段计划

| 需要完成的事情                                                           | 预期成果                                   |
|-------------------------------------------------------------------|----------------------------------------|
| 验证小艺调用官方原生 Skill 和自定义 Skill 的完整链路                                 | 真机/支持环境到位后补做系统级调用                      |
| 基于 `AgentExtensionAbility` 搭建自建智能体，并验证意图匹配、Skill 调用和 Ability 调度关系 | 自建智能体 Demo 工程、调度流程图、构建与运行记录            |
| 对比小艺直调、自建智能体调用、跨应用/跨端 A2A 三种接入方式                                  | 三种接入方式对比分析文档，说明机制、适用条件和限制              |
| 对比纯 ArkTS Skill 与 Skill 经 WebView 加载 JS 逻辑的运行形态、测量两种运行形态的启动延迟、内存占用和执行耗时                  | 可复现实验工程及非 ArkTS 形态可行性结论、性能数据表、测量方法和测试环境说明；模拟器数据与真机数据分开标记               |
| 汇总实验过程、结果和证据                                                      | 《鸿蒙智能体与 Skill 机制实验报告》，附调用录屏、日志和可复现文件清单 |

没有真机期间，先完成 Demo 构建、模拟器可验证部分和接入方式分析；小艺系统级调用及真机性能数据待具备相应设备和测试环境后补充。`AgentExtensionAbility` 的 SDK 声明已在本机 API 26 SDK 中找到，但端到端调用能力仍须实测确认。

## 七、汇报结论建议

> 甲组已完成 API 26 应用 Skill 接入资料、官方音乐示例接入和若干隔离构建实验。当前证据显示普通 JavaScript 可通过应用主模块构建，当前 Skill 注册入口要求 `.ets`；ArkTS Skill 调用 JS helper 可构建。小艺调用、自建智能体端到端调度、WebView/JS Skill 形态和性能对比仍待开展。下一阶段先在模拟器完成可复现的工程与应用内验证，设备到位后补齐系统级调度、A2A 联调和真机数据。

## 八、官方依据与实验环境

- [AgentExtensionAbility API 参考](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/js-apis-app-ability-common)：Agent 相关类型属于 Stage 模型能力；本机 API 26 SDK 中可见 `AgentExtensionAbility` 声明，声明可见不代表设备权限已验证。
- [HarmonyOS 2026 年 5 月开发者月刊](https://developer.huawei.com/consumer/cn/monthly/202605?ha_source=202605yk&ha_sourceId=89000503)：列出基于 AgentExtensionAbility 的智能体开发指导入口。
- [Harmony Intelligence 开放能力与服务一览](https://developer.huawei.com/consumer/cn/harmonyos-ai)：介绍端 A2A 与云 A2A 两类接入方向；后续报告应按选定模式分别描述。
- [小艺开放平台 A2A 基础配置](https://developer.huawei.com/consumer/cn/doc/doccenter-celia/a2a-basic-configuration-0000002746111014)：云 A2A 需要配置服务地址与鉴权；不应将其与端侧 A2A 的实验数据合并。
- 本机 SDK 声明文件：`D:\software\DevEco Studio\sdk\default\openharmony\ets\api\@ohos.app.agent.AgentExtensionAbility.d.ts`。

