# ADR Extraction · 小艺 Work 移植

ADR Extraction（架构决策提取）来自 ClawHub `anderskev/adr-decision-extraction@1.0.2`。上架包标识为 `adr-extraction`，版本为 `0.1.3`。它从用户粘贴的讨论文字提取技术决策与待定事项，附原文证据，在单个 JSON 代码块中返回结果。 [ClawHub 源 Skill](https://clawhub.ai/anderskev/skills/adr-decision-extraction) · [移植对照与测试](port-record.md)

## 打包与试跑

在本目录运行以下 PowerShell 命令。如果本地已有同版 ZIP，可以直接使用。

```powershell
Compress-Archive -LiteralPath .\adr-extraction -DestinationPath .\adr-extraction-v0.1.3.zip
```

1. 在小艺开放平台导入 ZIP。应用/元服务包名选 `personal`，中文映射填「架构决策提取」，英文映射填 `ADR Extraction`。在 Work 云电脑复测时，按新标识 `adr-extraction` 安装。
2. 在新会话发「请使用 `adr-extraction`，从下面的会议纪要提取已定决策和待定事项。」然后粘贴用例 A 的文字。 [用例 A](port-record.md#用例-a-重复决定和待定提案)
3. 核对代码块内的 JSON 字段、决定数量和原文引用。有可见的 Skill 调用记录时一并保存。 [验收预期](port-record.md)

用同一输入对照默认 Work 和能够取得的社区 Write Adr，比较决定准确性、去重、待定判别和原文依据。Write Adr 若输出 MADR 文档，单独核其业务结果。仅在实际需要结构化接入时比较固定 JSON 字段。

v0.1.2 的 Work 用例 A、B 和普通模式 C 已通过输出内容检查。v0.1.3 移除了试验版的包验证模式及输出字段，待在开放平台复测。 [历史验收](port-record.md#验收记录)
