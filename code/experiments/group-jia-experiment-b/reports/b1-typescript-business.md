# B1 实验报告：ETS 入口调用 TypeScript 业务层

## 1. 实验信息

环境、Skill 注册和测试输入与 B0 相同。唯一变量是业务实现改为 `JsonToolkitServiceTs.ts`，入口仍为 `JsonToolkitSkill.ets`。

## 2. 步骤

1. 将 Skill 入口和自测页面的导入切换到 `JsonToolkitServiceTs.ts`。
2. 清理并编译 HAP。
3. 启动应用并执行同一组六项测试。

## 3. 结果

| 项目 | 实测结果 |
|---|---|
| 构建 | `BUILD SUCCESSFUL in 14 s 735 ms` |
| 应用启动 | 成功，2 s 109 ms |
| 功能测试 | `6/6 tests passed` |
| 编译器错误/警告 | 未观察到与 TS 业务层有关的错误或警告 |

## 4. 结论

在本工程和 API 26 环境中，`.ets` Skill 入口可以直接导入 `.ts` 业务模块，六项输入输出与 B0 一致。该结果支持把普通业务算法保留为 TypeScript，但系统注册入口仍需使用 `.ets`。

## 5. 限制

本次没有独立测量跨模块调用开销，也没有执行系统小艺/Agent 调度。构建和启动时间只用于记录，不作为性能结论。
