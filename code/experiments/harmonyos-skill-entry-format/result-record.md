# 实验 A：HarmonyOS 应用 Skill 入口文件格式

**实验日期：**2026 年 11 月 14 日  
**实验目标：**在同一 API 26 工程和工具链下，比较 `skillProfiles.srcEntries` 指向 `.ets`、`.ts`、`.js` 文件时的构建结果。

## 1. 实验环境

| 项目 | 配置 |
| --- | --- |
| 主机 | Windows 11 |
| DevEco Studio | 26.0.0.851 |
| HarmonyOS SDK | 26.0.0 Release，SDK 包版本 26.0.0.105，API 26 |
| Hvigor | 6.26.8 |
| 工程来源 | `openclaw-harmony-skill/code/harmonyos-runtime-experiment/`，提交 `2526edff097c695c149b2a684ecd7563c2bb2451` |
| 构建目标 | `product=default`，`assembleHap` |

DevEco、SDK 和 Hvigor 版本分别依据本机安装目录中的 `product-info.json`、`sdk-pkg.json` 和 `@ohos/hvigor/package.json` 核对。三组均由 DevEco 调用相同的构建命令：

```text
hvigorw.js --mode module -p product=default assembleHap --analyze=normal --parallel --incremental --daemon
```

## 2. 实验设计

从同一工程复制 A0、A1、A2 三个独立副本。`SKILL.md`、Skill 名称、Ability、产品配置和目标 SDK 保持一致。各组在 `entry/src/main/module.json5` 中配置以下入口：

| 组别 | `srcEntries` 指向 | 入口文件 |
| --- | --- | --- |
| A0 | `../../skills/harmonyos-skill-echo/scripts/EchoSkill.ets` | 原工程 ArkTS 入口 |
| A1 | `../../skills/harmonyos-skill-echo/scripts/EchoSkill.ts` | A0 入口文件的同内容副本 |
| A2 | `../../skills/harmonyos-skill-echo/scripts/EchoSkill.js` | 原工程已有的 JS 探测文件 |

三份工程分别位于本目录的 `a0-ets/`、`a1-ts/` 和 `a2-js/`。

## 3. 构建结果

| 组别 | 构建阶段与结果 | 错误码 | 产物 |
| --- | --- | --- | --- |
| A0 `.ets` | 构建成功，退出码 0；33 项任务中 15 项执行、18 项命中缓存 | 无 | `a0-ets/entry/build/default/outputs/default/entry-default-unsigned.hap` |
| A1 `.ts` | `PreBuild` 配置校验失败，退出码 -1；0 项任务执行 | `00303304` | 无 HAP |
| A2 `.js` | `PreBuild` 配置校验失败，退出码 -1；0 项任务执行 | `00303304` | 无 HAP |

A1 与 A2 的首条错误均指出 `srcEntries` 的文件后缀无效，当前配置仅接受 `.ets`，并排除 `.d.ets`。A0 构建时因工程未配置签名，生成未签名 HAP。构建产物保留在本机；仓库的 `.gitignore` 排除 `build/` 和 `*.hap`。

## 4. 结论与运行状态

在 **DevEco Studio 26.0.0.851、HarmonyOS SDK 26.0.0 Release、Hvigor 6.26.8** 组合下，该工程的应用 Skill 入口接受 `.ets`；`.ts` 和 `.js` 在 `PreBuild` 配置校验阶段被拒绝。A2 本机复测与仓库此前的 `.js` 入口记录一致。

本轮完成入口格式的构建层验证。当前手机未被 DevEco 识别，A0 的真机安装、小艺匹配、脚本执行和结果回传未开展。A3 其他后缀属于探索项，本轮未开展。

## 5. 证据

以下构建日志根据实验者提供的 DevEco Build 输出整理。

- [A0 构建日志](evidence/a0-build.log)
- [A1 构建日志](evidence/a1-build.log)
- [A2 构建日志](evidence/a2-build.log)
- 三组工程中的 `entry/src/main/module.json5` 与对应 `EchoSkill` 入口文件
- 仓库既有实验记录：`openclaw-harmony-skill/code/harmonyos-runtime-experiment/README.md`
