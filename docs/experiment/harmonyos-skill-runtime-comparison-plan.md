# 鸿蒙智能体与 Skill 运行形态对比实验方案

**适用范围：**甲组“鸿蒙原生机制组”  
**目标：**回答“鸿蒙原生机制如何运作、Skill 以何种形态运行、性能代价几何”，并形成可复现的实验记录。

## 1. 实验范围与术语

本方案将四个容易混淆的维度分开验证：

1. **Skill 入口格式：**`skillProfiles.srcEntries` 接受哪些源文件形态。
2. **业务逻辑形态：**ArkTS Skill 入口后面的业务逻辑使用 ArkTS、TS、JS、WebView 页面 JS 或其他实现。
3. **智能体调用路径：**小艺、自建 Agent、A2A 如何发现/匹配并调用能力。
4. **运行性能：**冷启动、页面加载、业务执行、桥接和内存开销。

准确称呼 WebView 这组为：**“ArkTS Skill 入口调用本地 WebView/ArkWeb 页面中的 JavaScript 业务逻辑”**。这组实验保留 ArkTS Skill 入口，测试的是业务实现形态；它不测试系统是否接受 JS 作为 Skill 入口。

华为应用 Skill 指南描述了声明文件、ArkTS 入口脚本、`skillProfiles` 注册及结果回传。ArkTS Runtime 对 ArkTS、TS、JS 的支持，不代表 Skill 注册配置必然接受这些文件作为入口。[应用 Skill 开发指导](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-skill-development-guide)、[ArkTS Runtime 概述](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-runtime-overview)

## 2. 研究问题

| 编号 | 研究问题 | 需要回答的内容 |
|---|---|---|
| RQ1 Skill 机制 | 应用 Skill 如何描述、注册、执行和返回结果？ | `SKILL.md`、`skillProfiles`、Ability、Skill 入口及回调的关系 |
| RQ2 入口格式 | Skill 入口能否直接配置为 `.ets`、`.ts`、`.js` 或其他文件？ | 各文件后缀在目标 DevEco/SDK 下的构建结果、错误信息和官方支持依据 |
| RQ3 业务实现 | ArkTS Skill 入口后可调用哪些非 ArkTS 业务模块？ | TS/JS helper、WebView JS、可选 Native 模块的构建、运行和互操作情况 |
| RQ4 调用路径 | 小艺、自建 Agent、A2A 的能力发现、意图匹配、认证和调用过程有何区别？ | 各路径逐段的调用方、执行组件、返回方式和环境限制 |
| RQ5 自建 Agent | `AgentExtensionAbility` 能否组成自建 Agent 服务入口，并串起意图匹配、Skill 和 Ability？ | 组件回调由谁触发；意图路由由系统提供还是应用自行实现；Ability 在链路何处执行 |
| RQ6 性能 | 纯 ArkTS 与 ArkTS 入口 + WebView JS 的开销有何差异？ | 启动/加载延迟、业务耗时、桥接耗时、内存和成功率 |

## 3. 总体实验结构

```text
入口契约实验
  └─ Skill srcEntries 接受哪些源文件后缀？

业务形态实验
  ├─ ArkTS 入口 + ArkTS 业务（基线）
  ├─ ArkTS 入口 + TS/JS helper
  └─ ArkTS 入口 + WebView 页面 JS

调用路径实验
  ├─ 小艺 → 官方 Skill
  ├─ 小艺 → 自定义 Skill
  ├─ 自建 Agent → 意图分发 → Skill/Ability
  └─ Agent ↔ Agent：端侧或云侧 A2A

性能实验
  └─ 同一业务、同一设备条件下测启动、执行、回传和内存
```

每个结论均标记为以下阶段之一：**构建通过、安装通过、应用内运行通过、Skill 被系统匹配、Skill 执行通过、端到端调度通过**。不可用较低阶段的证据替代较高阶段的结论。

## 4. 实验 A：Skill 入口文件格式

**目标：**确认当前工程配置与 SDK 对 `skillProfiles.srcEntries` 的约束。

| 组别 | Skill 入口 | 测试要求 |
|---|---|---|
| A0 基线 | `.ets` | 保持已知可用的 Skill 配置，确认构建和运行基线 |
| A1 | `.ts` | 只改入口文件和配置路径，记录构建器是否接受 |
| A2 | `.js` | 只改入口文件和配置路径，复核当前已有 `00303304` 失败结果 |
| A3 探索项 | 其他文件后缀/模块格式 | 仅在 SDK 或官方资料显示值得验证时尝试，并注明探索性质 |

**控制要求：**每次只改变入口后缀或必要路径；每种形态使用独立分支/副本。记录 DevEco、SDK、Hvigor 版本、配置、构建命令、完整日志、首条错误、错误码和产物路径。

**解释规则：**构建失败说明当前工程构建层不接受本次配置；构建成功只说明该配置可以构建，不代表系统智能体发现或调用了该入口。

## 5. 实验 B：Skill 内部业务逻辑形态

固定 `SKILL.md`、`skillProfiles`、Skill 入口、Ability、输入和返回契约，只替换入口后面的业务逻辑实现。

| 组别 | 实现方式 | 重点观察 |
|---|---|---|
| B0 基线 | ArkTS Skill 入口 + ArkTS 业务函数 | 端到端功能与性能基线 |
| B1 | ArkTS Skill 入口 + TS helper | TS 模块解析、参数/返回值互操作和运行结果 |
| B2 | ArkTS Skill 入口 + JS helper | 普通 JS 模块导入、调用和返回；当前已有构建通过证据 |
| B3 | ArkTS Skill 入口 + 本地 WebView/ArkWeb 页面的 JS | 页面加载、桥接、异步结果、失败处理及性能 |
| B4 可选 | ArkTS Skill 入口 + 远端页面 JS | 网络开销与远端加载；和本地 WebView 结果分开报告 |
| B5 探索项 | ArkTS 入口 + Native/C++ 等业务模块 | 仅在团队需要研究此形态时开展；单独记录互操作条件，不纳入 B0/B3 主性能结论 |

### B3 WebView/JS 实验流程

1. 保留 ETS `srcEntries` 和 Skill 参数契约。
2. 将与 B0 相同的业务逻辑放在本地 HTML/JS 资源中，不加载在线页面。
3. ETS 入口收到参数后，通过 ArkWeb 调用页面 JS。
4. JS 执行同一业务，将结果返回 ArkTS。
5. ArkTS 入口统一调用 `completeArkTSScriptInApp` 上报结果。
6. 分别验证正常调用、页面未加载、桥接异常、JS 抛错、返回格式错误和超时。
7. 单独记录页面加载耗时和桥接耗时，避免只比较一个不透明的总时间。

华为文档提供应用侧通过 ArkWeb 调用前端页面函数的方式，可作为 B3 桥接实现参考。[应用侧调用前端页面函数](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/web-in-app-frontend-page-function-invoking)

## 6. 实验 C：智能体调用路径

每条路径均检查：**入口可用 → 能力被发现/匹配 → 目标组件被调用 → 业务完成 → 结果返回**。

| 组别 | 路径 | 证据要求 |
|---|---|---|
| C1 | 小艺 → 官方原生 Skill | 录屏、设备/系统信息、匹配证据、入口日志、结果 |
| C2 | 小艺 → 自定义 Skill | 同一设备和版本下的用户输入、匹配、执行及返回证据 |
| C3 | 自建 Agent → 意图匹配 → Skill/Ability | `AgentExtensionAbility` 回调日志、意图结果、Skill 调用点、Ability 调用点和回传结果 |
| C4 | 端侧 A2A | Agent 间连接、认证、消息往返、设备和组网信息 |
| C5 | 云侧 A2A | 服务地址、认证、请求/响应、网络和服务端条件 |

自建 Agent 需分别记录两种验证：

- **组件验证：**`AgentExtensionAbility` 能否在目标工程构建、启动和接收连接/数据回调。
- **调度验证：**意图由哪个组件匹配，匹配结果如何选择 Skill，Skill 如何调用 Ability，以及结果通过何种方式返回。

不能因为组件构建通过就得出“系统已经完成意图匹配和 Skill 调度”。端侧 A2A 与云侧 A2A 需要分别记录，不能合并性能数据或机制结论。云 A2A 的服务地址和鉴权配置可参考[小艺开放平台 A2A 基础配置](https://developer.huawei.com/consumer/cn/doc/doccenter-celia/a2a-basic-configuration-0000002746111014)；两类 A2A 的方向见[Harmony Intelligence 开放能力介绍](https://developer.huawei.com/consumer/cn/harmonyos-ai)。

## 7. 实验 D：性能对比协议

### 主对比组

- **D0：**纯 ArkTS Skill 入口 + ArkTS 业务逻辑。
- **D1：**ArkTS Skill 入口 + 本地 WebView/ArkWeb 页面 JS 业务逻辑。

TS/JS helper、远端 Web 页面和 A2A 可作为扩展组单独报告，不能混入 D0/D1 主对比。

### 控制变量

两组使用相同的业务算法、输入、输出结构、错误处理、Skill 参数契约、Ability、设备、系统版本、SDK、签名及运行条件。WebView 组先加载本地资源，避免网络波动干扰。

### 指标和计时边界

| 指标 | 起止边界 |
|---|---|
| 系统链路总延迟 | Agent/用户发起请求 → 最终结果返回；只有实际测到系统链路时才填写 |
| Skill 执行耗时 | Skill 入口开始 → `completeArkTSScriptInApp` 上报 |
| 业务执行耗时 | 业务函数开始 → 业务结果生成 |
| WebView 冷加载 | 创建 WebView → 本地页面加载完成 |
| JS 桥接耗时 | ArkTS 发起页面函数调用 → JS 结果返回 ArkTS |
| 内存占用 | 应用基线、WebView 创建后、页面加载后、调用峰值及空闲恢复后 |

WebView 需分别报告首次页面加载与已加载页面上的后续调用，不能隐去首次加载成本，也不能把每次调用都算成冷启动。

### 采样和统计

- 模拟器和真机结果分开统计；无真机时只报告模拟器基线。
- 冷启动与热调用分别测量，预热样本不并入正式样本。
- 每组建议至少 30 次有效样本，同时记录失败、超时和异常。
- 报告中位数、P95、成功率，并保留原始样本和测量日志。
- 固定应用前后台、屏幕、设备状态和网络条件；本地页面实验关闭不必要的网络访问。
- 结论需注明设备型号、系统版本、SDK、DevEco 和 Hvigor 版本及业务负载。

## 8. 统一成功判定

| 阶段 | 判定条件 | 证据 |
|---|---|---|
| 配置/构建通过 | 工程接受配置并构建完成 | 配置、构建日志、产物 |
| 安装通过 | HAP 成功安装 | DevEco 部署记录或设备安装日志 |
| 应用运行通过 | Ability 启动并进入可观察状态 | 截图、运行日志 |
| WebView/JS 运行通过 | 页面加载、JS 执行且结果返回 ArkTS | 页面日志、桥接参数和返回值 |
| Skill 匹配通过 | 调用方选择了目标 Skill | 可辨识的调度记录或录屏 |
| Skill 执行通过 | 指定脚本及业务代码已运行 | 入口日志、业务日志、返回结果 |
| 端到端通过 | 输入到结果回传链路闭合 | 全程录屏、时间戳、结构化结果 |
| 性能结论有效 | 计时边界、样本数、环境完整 | 原始数据表和统计方法 |

## 9. 记录模板

### 9.1 环境与实验配置

| 实验编号 | 日期 | DevEco | Hvigor | SDK/API | 设备/模拟器 | 系统版本 | 工程提交/版本 | 分组 |
|---|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |  |

### 9.2 构建与调用结果

| 分组 | 配置/入口形态 | 构建 | 安装 | 运行 | 匹配 | 执行 | 返回正确 | 错误码/日志/证据路径 |
|---|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |  |

### 9.3 性能原始数据

| 分组 | 冷/热 | 样本序号 | 页面加载 ms | 业务耗时 ms | 桥接耗时 ms | Skill 总耗时 ms | 内存 MB | 成功/失败 | 备注 |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
|  |  |  |  |  |  |  |  |  |  |




## 12. 官方参考

- [基于 ArkTS 脚本的应用 Skill 开发指导](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-skill-development-guide)
- [ArkTS Runtime 概述](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-runtime-overview)
- [应用侧调用前端页面函数（ArkWeb）](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/web-in-app-frontend-page-function-invoking)
- [AgentExtensionAbility API 参考](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/js-apis-app-ability-common)
- [Harmony Intelligence 开放能力与服务](https://developer.huawei.com/consumer/cn/harmonyos-ai)
- [小艺开放平台 A2A 基础配置](https://developer.huawei.com/consumer/cn/doc/doccenter-celia/a2a-basic-configuration-0000002746111014)
