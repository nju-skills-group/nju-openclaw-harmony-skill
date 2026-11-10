# B0 实验报告：ETS 入口调用 ETS 业务层

## 1. 实验信息

| 字段 | 记录 |
|---|---|
| 日期 | 2026-11-10 |
| 实验编号 | B0 |
| 实验对象 | JSON Toolkit |
| DevEco Studio | 26.0.0 Release，内部版本 26.0.0.851 |
| 模拟器 | Mate 90 Pro Phone，HarmonyOS 7.0.0 / API 26.0.0 |
| Skill 注册 | `json-toolkit`，版本 `1.1.0`，入口 `JsonToolkitSkill.ets` |
| 安装方式 | DevEco Studio 安装未签名 Debug HAP 到本地模拟器 |

## 2. 目的与控制变量

建立纯 ETS 基线。固定 `SKILL.md`、`skillProfiles`、入口类、参数、返回结构和六项测试，只让 `JsonToolkitSkill.ets` 调用 `JsonToolkitService.ets`。

## 3. 步骤

1. 将 Skill 入口和自测页面导入指向 `JsonToolkitService.ets`。
2. 清理并编译 HAP。
3. 在模拟器启动应用，执行 format、minify、validate、query、sort、invalid JSON 六项测试。

## 4. 结果

| 项目 | 实测结果 |
|---|---|
| 构建 | `BUILD SUCCESSFUL in 42 s 771 ms` |
| 应用启动 | 成功，457 ms |
| 功能测试 | `6/6 tests passed` |
| 结论 | ETS Skill 入口可直接调用 ETS 业务实现 |

## 5. 异常记录

首次运行停留在 `Waiting for emulator online`。`hdc list targets -v` 同时出现 Connected 和 Offline TCP 目标；关闭模拟器并执行 `hdc kill -r` 后只保留一个 Connected 目标，第二次部署成功。该问题发生在 HDC/模拟器部署阶段，不是业务代码或 HAP 构建失败。

## 6. 限制

本次只验证应用内自测，没有通过小艺或 Agent 实际触发系统 Skill。42.771 秒包含首次完整构建成本，不能直接当作与其他变体的性能优劣比较。
