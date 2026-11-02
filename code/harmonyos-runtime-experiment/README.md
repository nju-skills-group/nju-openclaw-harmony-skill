# HarmonyOS Skill 运行时形态隔离实验

这是从 `D:\desk\HarmonyOS_skills` 拷贝出的实验副本，目的是避免影响原项目。原工程保持未修改。

## 实验 A：普通 JS 作为 Skill 直接入口

把 `entry/src/main/module.json5` 的 `skillProfiles[0].srcEntries` 指向 `EchoSkill.js`，执行 `assembleHap`。本机 DevEco/Hvigor（MatePad Pro 13，API 26）在 PreBuild 阶段报错：

```text
00303304 Configuration Error
The suffix of srcEntry value ...EchoSkill.js is invalid in skillProfiles.
Only .ets source code files are supported.
```

结论限定为：**当前 SDK 的 `skillProfiles.srcEntries` 配置校验拒绝 `.js` 直接入口。**这不是对所有 HarmonyOS 版本和所有 JS 运行方式的普遍结论。

## 实验 B：ArkTS Skill 入口调用普通 JS 业务函数

恢复 `srcEntries` 指向 `EchoSkill.ets`，由其导入 `EchoBusiness.js` 并处理回显业务。Hvigor `assembleHap` 构建成功，生成未签名 HAP。构建有 ArkTS 异常处理警告，需按实际业务补齐异常处理。

结论限定为：**ArkTS Skill 入口后面可以在本工程中打包一个普通 JS helper。**尚未安装/从系统小艺触发这份变体，不能据此认定 JS helper 已经通过 Skill 运行时调用。

## 未覆盖项

- ArkTS 入口 → WebView/ArkWeb 页面 JavaScript 的完整桥接和运行测量。
- 模拟器/真机通过小艺语义匹配并调用 Skill。
- 真机性能比较。

源工程目录为 `D:\desk\HarmonyOS_skills`。本实验副本中的 `local.properties`、`.hvigor/` 和构建目录属于本地/生成文件，不应提交。
