# OpenClaw Skill 普查表 v0.1 — 交付说明

## 数据来源与固定版本

本交付覆盖原始 `input/skill-survey.zip` 中的 50 项 bundled Skill，并保留以下历史基线：

- `skill-survey/bundled-review.json`：原始 50 项分类、理由与建议；
- `skill-survey/bundled-tree.json`：固定源码树及 Git blob SHA；
- 官方源码 commit：`d79ab6195d8d0566b285008bcc30c01a6ce368e2`；

## 普查与复核范围

- 50 项均完成身份、来源、功能、文件结构、脚本语言、依赖摘要、系统能力、分类及状态字段的基础完整性整理。
- 对 `diagram-maker`、`weather`、`meme-maker`、`skill-creator`、`healthcheck` 进行了重点源码复核；五项原始 L1/L2/L3 分类均维持。
- 其余 45 项完整静态评审结论沿用原始调查，但保留此前依赖专项核对的事实和入口。

## 正式输出与阅读方式

- CSV 适合程序处理和二次筛选。
- XLSX 是主要阅读版本，含“普查表”和“五项重点复核”两张工作表；表头可筛选，并冻结识别列和表头。
- 主表仅展示影响理解的关键依赖、必要条件和未核实事项。

## 验证状态与局限

- 静态复核状态：5 项“本次已复核”，45 项“沿用已有评审”。
- 原平台测试状态：50 项均“未测试”。
- 鸿蒙验证状态：50 项均“未验证”。
- 表内 L1/L2/L3 是静态初步分类，不代表迁移成功率或实际可运行性；外部 CLI、服务和目标主机能力仍可能需要后续动态验证。

## 复现与验收

在普通 Python 3.11 环境中安装固定依赖并生成：

```powershell
py -3.11 -m venv .\.venv-phase2r311
$env:PIP_CACHE_DIR = 'D:\skill-survey-s1\.pip-cache'
.\.venv-phase2r311\Scripts\python.exe -m pip install -r .\skill-survey\requirements-phase2r.txt
.\.venv-phase2r311\Scripts\python.exe .\skill-survey\scripts\build_phase4_outputs.py
.\.venv-phase2r311\Scripts\python.exe .\skill-survey\scripts\verify_phase4.py
```
