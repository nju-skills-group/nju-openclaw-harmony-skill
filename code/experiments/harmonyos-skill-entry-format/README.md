# 实验 A 文件索引

完整实验方法、结果和结论见 [实验报告](result-record.md)。

| 目录或文件 | 内容 |
| --- | --- |
| `a0-ets/` | `.ets` 入口基线工程 |
| `a1-ts/` | `.ts` 入口实验工程 |
| `a2-js/` | `.js` 入口实验工程 |
| `evidence/a0-build.log` | A0 构建输出 |
| `evidence/a1-build.log` | A1 构建输出 |
| `evidence/a2-build.log` | A2 构建输出 |

三个工程副本来自仓库提交 `2526edff097c695c149b2a684ecd7563c2bb2451` 的 `code/harmonyos-runtime-experiment/`。A1 的 `EchoSkill.ts` 与基线 `EchoSkill.ets` 内容相同。每组使用独立的 `module.json5` 注册路径，在 DevEco Studio 26.0.0.851 中构建。
