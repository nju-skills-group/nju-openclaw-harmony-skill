# 甲组实验 B Demo：HarmonyOS Skill 业务逻辑运行形态

本工程使用同一个 JSON Toolkit Skill，对比 `.ets` Skill 入口后的四种业务执行形态。当前活动代码为 B3；`variants/` 保存了四个实际测试状态的入口与页面快照。

## 实验矩阵

| 编号 | Skill 入口 | 业务执行体 | 模拟器结果 |
|---|---|---|---|
| B0 | `JsonToolkitSkill.ets` | `JsonToolkitService.ets` | 6/6 通过 |
| B1 | `JsonToolkitSkill.ets` | `JsonToolkitServiceTs.ts` | 6/6 通过 |
| B2 | `JsonToolkitSkill.ets` | `JsonToolkitServiceJs.js` | 6/6 通过 |
| B3 | `JsonToolkitSkill.ets` | 本地 ArkWeb 页面 JavaScript | 6/6；异常路径 5/5 通过 |

公共测试覆盖 format、minify、validate、query、sort 和非法 JSON 六条路径。`module.json5` 始终注册 `.ets` Skill 入口，`SKILL.md`、输入和预期输出保持不变。

## 环境

- DevEco Studio 26.0.0 Release（内部版本 26.0.0.851）
- HarmonyOS 7.0.0 / API 26.0.0
- Mate 90 Pro Phone 本地模拟器
- 未签名 Debug HAP，由 DevEco Studio 安装到本地模拟器

## 运行当前 B3

用 DevEco Studio 打开本目录，等待同步完成后编译并运行。页面显示 `ArkWeb runtime ready` 后：

1. 点击 `Run self-test`，预期得到 `6/6 tests passed`。
2. 点击 `Run failure-path tests`，预期得到 `5/5 failure paths handled`。

异常路径覆盖页面未加载、控制器未绑定、页面 JavaScript 抛错、返回值损坏和执行超时。页面同时显示页面加载时间及桥接调用统计。

## 切换实验变体

在工程根目录执行以下 PowerShell 命令，将 `<variant>` 替换为 `b0`、`b1`、`b2` 或 `b3`：

```powershell
Copy-Item "variants\<variant>\JsonToolkitSkill.ets" `
  "entry\skills\json-toolkit\scripts\JsonToolkitSkill.ets" -Force
Copy-Item "variants\<variant>\Index.ets" `
  "entry\src\main\ets\pages\Index.ets" -Force
```

切换后执行“清理项目 → 编译 Hap(s) → 运行”。业务实现文件均已保留在 `entry/skills/json-toolkit/scripts/`。

## 关键文件

- `entry/skills/json-toolkit/SKILL.md`：统一 Skill 契约
- `entry/skills/json-toolkit/scripts/JsonToolkitService.ets`：B0
- `entry/skills/json-toolkit/scripts/JsonToolkitServiceTs.ts`：B1
- `entry/skills/json-toolkit/scripts/JsonToolkitServiceJs.js`：B2
- `entry/skills/json-toolkit/scripts/JsonToolkitServiceJs.d.ts`：B2 静态类型契约
- `entry/skills/json-toolkit/scripts/JsonToolkitWebRuntime.ets`：B3 ArkWeb 桥接
- `entry/src/main/resources/rawfile/json_toolkit_web.html`：B3 页面 JavaScript

## 证据边界

本工程证明四种业务形态能够构建并在应用内模拟器自测中运行。尚未通过系统小艺或自建 Agent 触发 `skillProfiles` 中的 Skill，因此不能把本结果表述为系统端到端 Skill 调度成功。B3 还要求应用页面已经创建 Web 组件并完成本地页面加载；无页面的后台/冷启动调度尚未验证。

完整报告见 [`../reports/`](../reports/summary.md)。
