# entry/src/main 非 ETS 构建探针

这是从本机 `D:/desk/HarmonyOS_skills` 复制出的独立 DevEco 工程实验副本。原工程不会被修改。此副本用于你在 DevEco Studio 中验证：把 `entry/src/main` 的 ArkTS 源文件改成 `.js` 普通 JavaScript 后，API 26 / Stage 工程是否接受这些入口。

## 当前变更

- `EntryAbility.ets` → `EntryAbility.js`：保留 Ability 生命周期逻辑，移除 TypeScript 类型标注。
- `EntryBackupAbility.ets` → `EntryBackupAbility.js`：保留备份 Ability 的生命周期逻辑，移除类型标注。
- `Index.ets` → `Index.js`：替换为普通 JavaScript 页面模块占位实现。
- `module.json5` 的 `srcEntry` 和 `pages` 配置已更新到 JS 文件。
- `entry/skills/harmonyos-skill-echo` 中的 Skill 入口仍保留 ETS，因为当前实验只针对 `entry/src/main`；这也能区分“应用主模块入口”与“Skill 脚本入口”的编译规则。

## 重要边界

原 `Index.ets` 使用 ArkUI 声明式语法（`@Entry`、`@Component`、`struct`、`build()`），它不是普通 JavaScript 语法，不能通过删掉类型标注得到等价 JS 页面。本实验中的 `Index.js` 只是最小模块占位，行为不等价于原页面。无论构建结果如何，都应区分主模块页面/Ability 与 Skill 执行入口；不要据此推断所有 HarmonyOS Agent 或所有 Skill 都必须使用 ETS。

## 本次构建实验结果（2026-11-01）

- DevEco Studio：`26.0.0.851`；Hvigor：`6.26.8`；HarmonyOS SDK：`26.0.0.105`（API 26）。
- 命令：`hvigorw assembleHap --no-daemon --stacktrace`。
- 结果：`BUILD SUCCESSFUL`，34 项任务完成；日志显示 `CompileArkTS`、`BuildJS`、`PackageHap` 均完成。
- 产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`（104087 bytes）。由于实验工程没有签名配置，Hvigor 跳过签名并生成 unsigned HAP，这是预期提示。
- 完整构建输出见 [`nonets-build.log`](./nonets-build.log)。

## 结果解释

本次结果证明：在此 DevEco / API 26 Stage 工程中，`entry/src/main` 的 Ability 入口和 JS 页面模块使用普通 `.js` 文件时，Hvigor 可以完成 HAP 构建；不要求这些主模块源文件必须全部是 `.ets`。

这个实验没有安装或运行 HAP。`Index.js` 是普通 JavaScript 占位模块，不是原 ArkUI 声明式页面的等价迁移；因此不能据此证明应用运行时页面行为正常。实验中的 `entry/skills/harmonyos-skill-echo` 仍使用 ETS Skill 入口，也没有验证非 ETS Skill 入口。此前独立实验里 Skill `srcEntries` 配置 `.js` 被构建器拒绝；应用主模块 JS 与应用 Skill 脚本入口是两类不同检查。

如需复现，可在 DevEco Studio 中打开本目录后执行 Build > Build Hap(s) > Build Hap。构建成功不代表系统智能体已发现或调用 Skill。
