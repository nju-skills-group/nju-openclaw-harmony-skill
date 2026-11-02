# HarmonyOS Skill 调用与运行时形态实验记录

> 用于记录小艺调用、非 ArkTS 业务形态与性能实验。请填真实观察，不要把计划/推测填成结果。

## A. 实验元信息

| 字段 | 记录 |
|---|---|
| 实验编号 |  |
| 日期/时间 |  |
| 操作人/复核人 |  |
| DevEco Studio 版本 |  |
| 工程 Git commit / HAP 构建标识 |  |
| 目标设备/模拟器型号 |  |
| HarmonyOS 版本 / API 版本 |  |
| 签名方式 / 安装方式 |  |
| `SKILL.md` 与 `skillProfiles` 版本 |  |

## B. 原生小艺调用记录

| 次数 | 输入话术 | 小艺入口可用 | Skill 被匹配 | ArkTS 入口执行 | 返回结果正确 | 截图/日志文件 | 观察与异常 |
|---:|---|---|---|---|---|---|---|
| 1 |  |  |  |  |  |  |  |
| 2 |  |  |  |  |  |  |  |
| 3 |  |  |  |  |  |  |  |

**负例测试：**输入不应触发该 Skill 的话术：____；是否误触发：____；证据：____。

### 调用判定

- **入口可用**：能进入/唤起系统小艺交互。
- **Skill 被匹配**：有可辨识证据表明选择了目标应用 Skill。
- **入口执行**：日志/结果/调用反馈证明目标脚本已运行。
- **结果呈现**：小艺或应用显示与约定契约一致的结果。
- 单纯安装 HAP、打开应用、构建成功，均不等于上述调用成功。

## C. 非 ArkTS 形态实验边界

需要分别回答两个问题：

1. **非 ArkTS 业务实现是否可在应用中运行？** 可做 ArkTS 入口 → ArkWeb/WebView → JS 业务逻辑的应用内实验。官方 ArkWeb 文档描述了 ArkTS 侧调用页面 JavaScript 的方式。
2. **非 ArkTS 文件能否直接作为系统 Skill 入口？** 这是另一项系统入口契约实验。当前官方 ArkTS Skill 指南展示的是 ArkTS 入口；WebView/JS 在应用内可运行，不等于系统允许它直接注册为 Skill 入口。应以构建/API接受情况和系统实际调度证据分别判定。

| 实验支路 | 入口 | 业务执行体 | 构建通过 | 应用内执行 | 系统 Skill 调度 | 结论 |
|---|---|---|---|---|---|---|
| 基线 | ArkTS Skill 入口 | ArkTS 函数 |  |  |  |  |
| 混合实现 | ArkTS Skill 入口 | ArkWeb 中的 JS 函数 |  |  |  |  |
| 直接非 ArkTS 入口尝试 | JS/其他非 `.ets` 文件（仅在隔离实验副本中尝试） | JS/其他 |  |  |  |  |

**直接入口尝试规则：**先保留可构建基线，使用单独分支/副本改动 `srcEntries` 或入口形态；记录完整错误，不要覆盖唯一可工作的基线。若构建阶段拒绝，结论写“构建/声明层不接受本次形态”；若构建成功但无调度证据，只能写“已构建，调度未证实”。

## D. 性能测量协议（模拟器基线）

- 同一模拟器/API、同一输入、同一业务逻辑、同一返回结构。
- 分开记录冷启动与热调用；每种条件至少重复 30 次，报告中位数、P95、成功率和异常数。
- 记录计时边界：入口开始、业务开始、业务结束、结果回调；统一使用单调时钟。
- 记录内存工具/采样方式和采样时点；若当前环境无法稳定读取，标记“未测”，不要估值。
- 结果只代表该模拟器环境；真机性能结论待设备到位复测。

| 运行形态 | 冷/热 | 样本数 | 成功率 | 延迟中位数 | P95 | 峰值/采样内存 | 测量工具及备注 |
|---|---|---:|---:|---:|---:|---:|---|
| ArkTS 基线 | 冷 |  |  |  |  |  |  |
| ArkTS 基线 | 热 |  |  |  |  |  |  |
| ArkTS→WebView/JS | 冷 |  |  |  |  |  |  |
| ArkTS→WebView/JS | 热 |  |  |  |  |  |  |

## E. 本次状态（首次建档）

- 时间：2026-11-01，约 12:05–12:10（本机/模拟器显示时间）。
- 工程静态配置：已读取原 Echo 工程的 `SKILL.md`、`EchoSkill.ets` 与 `module.json5`。
- 模拟器：DevEco 设备选择器显示 `MatePad Pro 13 7.0.0 (26.0.0)`；设备启动后进入桌面。
- HAP/应用启动：DevEco 部署原 Echo 工程后，模拟器显示 `Hello World`。这证明应用可以启动，不证明 Skill 被调用。
- 小艺入口：检查当前模拟器桌面/可见应用列表时没有发现小艺入口；未能发起原生小艺调用。结论为“当前模拟器环境未提供可见调用入口，待真机或支持该能力的环境”，不是 Skill 调度成功/失败。
- 直接非 ArkTS Skill 入口：在隔离副本中把 `skillProfiles.srcEntries` 改为 `.js` 后执行 `assembleHap`，Hvigor 在 `PreBuild` 报 `00303304 Configuration Error`：仅支持 `.ets` 源文件，并明确提示改回 `.ets`。因此本 SDK 的工程配置/构建层不接受本次 `.js` 直接入口尝试。
- 非 ArkTS 业务模块：恢复 `.ets` Skill 入口，让入口导入普通 JavaScript `EchoBusiness.js` 处理文本；隔离副本 `assembleHap` 成功，产出 HAP。此结果只证明该工程可将 JS 业务模块打包在 ArkTS 入口后面，不证明系统调度器直接执行 JS Skill，也未证明入口运行时调用结果。
- ArkTS→WebView/JS：尚未做 WebView 页面和 JSBridge 运行对照；前述普通 JS 导入实验与 WebView 实验不是同一项。
- 性能：尚未测量。

实验副本位于研究仓库 `code/harmonyos-runtime-experiment/`，原始 `D:\desk\HarmonyOS_skills` 工程未修改。

### 本次产物与日志摘录

| 实验 | 操作 | 结果 | 证据/限制 |
|---|---|---|---|
| 模拟器应用启动 | DevEco 选择 MatePad Pro 13 7.0.0（API 26），Run 原 Echo 应用 | 模拟器显示 `Hello World` | 只证明应用启动；模拟器无可见小艺入口 |
| JS 直接作为 Skill 入口 | `srcEntries` 指向 `EchoSkill.js`，执行 Hvigor `assembleHap` | 构建失败，错误 `00303304` | 官方/工具提示 `skillProfiles` 仅支持 `.ets` 源文件 |
| ArkTS 入口 + JS 业务 helper | `EchoSkill.ets` 导入 `EchoBusiness.js`，执行 `assembleHap` | `BUILD SUCCESSFUL`，签名配置缺失时跳过签名 | 有 ArkTS 编译警告“函数可能抛异常”；未安装并从小艺触发该变体 |

## 参考

- [基于 ArkTS 脚本的应用 Skill 开发指导](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-skill-development-guide)
- [应用侧调用前端页面函数（ArkWeb）](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/web-in-app-frontend-page-function-invoking)
