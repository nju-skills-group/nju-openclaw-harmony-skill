# OpenClaw Skill 普查 v1

本目录是乙组“Skill 普查与移植”的课程首版交付，日期为 2026-10-25。范围为内置全量＋生态代表样本源码精查，以及公开目录的自动摘要初筛。

## 交付与覆盖

本次公开目录遍历为 83,265 个 owner/slug 条目，36/36 个分区均到达游标末尾，全部完成自动摘要初筛。源码静态分类覆盖 50 个官方内置 Skill，以及 8 类、24 个 ClawHub 代表样本。其余 83,241 个 ClawHub 条目的源码等级保留“待分类”，不属于本版逐一精查范围。目录数量描述本次动态遍历，不代表全量历史生态或全部已验证能力。

- `reviewed-skills.csv` / `reviewed-skills.json`：50 个官方内置 Skill 和 24 个 ClawHub 代表样本的源码静态分析，包含名称、来源、类型、脚本语言、系统依赖、宿主依赖、分类依据、源码版本和运行验证状态。
- `classification.md`：便于在 GitHub 浏览的分类表。
- `clawhub-catalog.csv.gz`：83,265 条公开目录登记与自动摘要初筛，可解压后筛选。初筛信号和源码分级是独立字段。未压缩 CSV/JSONL 可用工具重放生成。
- `coverage.json`：准确条数、36 个首字符分区的分页结束状态、重复记录和版本变化记录。
- `screening-summary.md`：全量初筛、主题和样本范围的统计说明。
- `methodology.md`：字段含义、L1/L2/L3 判定口径与复现方法。
- `handoff.md`：移植候选、原平台对照与鸿蒙验证用例，供甲／乙／丙组协作。
- [skill-survey.xlsx](skill-survey.xlsx)：74 条源码静态分析记录的分类和依赖视图；公开目录完整登记另见压缩 CSV。
- `sampling-plan.json`、`clawhub-review.json`：选样范围与逐项判读。
- `source-manifest.json`：输入、输出和 593 个来源文件的哈希。
- [普查工具与复现说明](../../../../tools/skill-survey/README.md)：只读采集、固定数据重放、边界测试；原始公开目录输入以压缩形式保存在工具 data 目录。

“目录遍历完成”“静态分类完成”“在原平台运行”“在鸿蒙运行”是四个独立状态。此版原平台、鸿蒙运行记录均为零，不计入六个可运行移植样例的验收。

## 两个 GitHub 仓库

1. [nju-openclaw-harmony-skill](https://github.com/nju-skills-group/nju-openclaw-harmony-skill)：研究文档与团队协作仓库。本普查建议提交到 `docs/04-methodology/group-b/skill-survey/`，走功能分支与 PR，不直接改 main。
2. [openclaw-skills-for-harmony](https://github.com/nju-skills-group/openclaw-skills-for-harmony)：飞书方案指定的移植 Skill 开源仓库。本次检查时为空；真实移植工程、来源标注和演示应在验证后另提 PR。

## 研究发现

50 个内置 Skill 的静态候选分类为 L1 1 个、L2 6 个、L3 43 个。额外审阅的 24 个 ClawHub 代表样本覆盖 8 类，因此精查集合共 74 条，L1/L2/L3 为 4/11/59。L3 比例反映“保留完整原始功能、本机原生执行”的保守判据，不能外推为整个生态的不可移植率。

- 无脚本不等于无执行依赖。`weather` 依赖网络工具，`healthcheck` 依赖系统命令，`visualize` 依赖 `show_widget`。
- `diagram-maker` 的 L1 有前提：已具备通用文件读写和资源读取。缺少这些桥接时应降为 L2 适配任务。
- `requires.bins`、`requires.anyBins`、`requires.env`、`primaryEnv` 和 `install` 的含义不同，不能把推荐安装器或首选密钥直接当作必选加载门控。
- L3 表示显著适配障碍或依赖未确认，不能写成“永远不可移植”。缩小功能范围、远程宿主与 Native 桥接应单独登记。
- ClawHub 的 `davinci-first-principles` 注册 slug 对应 frontmatter `name: first-principles`。去重必须保留 owner＋slug，不能只按 name。

## 来源和版本

- [官方内置 Skill 固定快照](https://github.com/openclaw/openclaw/tree/d79ab6195d8d0566b285008bcc30c01a6ce368e2/skills)：commit `d79ab6195d8d0566b285008bcc30c01a6ce368e2`，75 个文件，50 个 SKILL.md。逐文件核对 Git blob SHA-1。
- [ClawHub HTTP API](https://github.com/openclaw/clawhub/blob/main/docs/http-api.md)：公开只读端点、游标和限流规则。
- [ClawHub slug 校验规则](https://github.com/openclaw/clawhub/blob/main/convex/lib/skillSlugValidator.ts)：首字符为小写字母或数字，按 36 个不重叠分区采集。
- 每条精查记录有固定版本来源、SKILL.md SHA-256 和证据位置。ClawHub 版本文件按 API 返回的 SHA-256 校验。

## 本次未计入完成的事项

本版范围以外的 ClawHub 条目正文精查、OpenClaw 基线调用、鸿蒙注册与真机运行、性能数据、移植工程和录屏均需后续完成。本交付完成普查工具、全量目录初筛和 74 条源码静态分析，不代替乙组全体后续实验任务。

## 后续原平台基线（2026-10-30）

[E2：Tavily 与 weather 基线](../skill-baselines/e2/README.md)补充真实认证、调用轨迹和错误处理记录。本页“运行记录为零”保留 2026-10-25 交付时的历史口径；后续实验范围与状态见独立记录，未计为鸿蒙验证。
