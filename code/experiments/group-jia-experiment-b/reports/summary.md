# 实验 B 总结：HarmonyOS Skill 业务逻辑运行形态对比

## 1. 实验问题

在 `skillProfiles` 保持 `.ets` 入口的前提下，比较 ETS、TypeScript、普通 JavaScript 和 ArkWeb 页面 JavaScript 四种业务逻辑形态是否能够完成同一 JSON Toolkit 功能。

## 2. 统一条件

- Skill：JSON Toolkit，版本 `1.1.0`
- 入口：`JsonToolkitSkill.ets`
- 环境：DevEco Studio 26.0.0.851，HarmonyOS 7.0.0 / API 26.0.0，Mate 90 Pro Phone 模拟器
- 测试：format、minify + sortKeys、validate + UTF-8 size、query、sort、invalid JSON
- 通过条件：HAP 构建成功、应用启动成功、六项结果全部符合预期

## 3. 结果矩阵

| 实验 | 业务形态 | 构建 | 应用内测试 | 主要条件/问题 |
|---|---|---|---|---|
| B0 | ETS | 成功，42.771 s | 6/6 | 基线；首次部署遇到 HDC 残留离线目标 |
| B1 | TypeScript | 成功，14.735 s | 6/6 | 可直接导入 TS 业务模块 |
| B2 | JavaScript | 成功，11.142 s | 6/6 | 需要 `.d.ts`；避免直接照搬 ArkTS Kit 导入 |
| B3 | ArkWeb 页面 JS | 成功，18.581 s（全量） | 6/6；异常路径 5/5 | 依赖 Web 组件已创建且页面已就绪 |

构建时间来自不同缓存状态，仅作过程记录，不能据此比较性能。

## 4. 结论

1. API 26 工程中的 Skill 注册入口仍保持 `.ets`，但入口后的业务代码不必全部写成 ETS。
2. TypeScript 业务层的迁移成本最低，与 ETS 基线接口基本一致。
3. 普通 JavaScript helper 可以运行，但 ArkTS 静态检查需要类型声明文件，平台 API 的导入与运行时兼容性也需要逐项验证。
4. ArkWeb 页面 JavaScript 可以通过序列化桥接完成同等功能，但它引入页面加载、控制器绑定和异步调用条件，不等价于无界面的后台 Skill 运行时。
5. B3 实测页面加载 2051 ms，六次桥接平均 3.17 ms；数据量不足，只作为运行记录，不用于四种形态的性能比较。
6. B3 的五类异常均已转换为明确错误码；其中 ArkWeb 页面脚本抛错可能以 `undefined` 拒绝值传播，必须在 ArkTS 桥接边界统一归一化。
7. 四项结果均为应用内模拟器证据；没有系统小艺/Agent 真实调度证据，不能表述为端到端 Skill 调用成功。

## 5. 建议

- 普通算法迁移优先选择 B1 的 TypeScript 业务层。
- 已有纯 JS 模块可采用 B2，但应补 `.d.ts`，并避免未经验证的 ArkTS Kit 导入。
- 只有确实依赖 DOM、浏览器 API 或现有 Web 页面时才采用 B3，并显式处理页面未就绪、超时和返回值校验。
- 真机到位后补测系统调度、冷启动、后台状态及至少 30 次热调用延迟；在此之前不比较四种形态的性能优劣。

## 6. 产物

- Demo：[甲组实验 B 工程](../demo/README.md)
- [B0 报告](b0-ets-business.md)
- [B1 报告](b1-typescript-business.md)
- [B2 报告](b2-javascript-business.md)
- [B3 报告](b3-arkweb-javascript.md)
