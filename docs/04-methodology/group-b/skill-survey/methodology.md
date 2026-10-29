# 普查方法与字段定义

## 范围与判定单位

内置范围是固定 commit 下 `skills/*/SKILL.md` 的全部 50 个条目，不包括插件自行提供的 Skill、用户私有 Skill 和其他目录。ClawHub 范围是公开 `/api/v1/skills` 端点可见的原生 Skill 条目，不声称包含私有、隐藏、删除条目、插件及其他注册表家族。

每条记录以“来源＋owner/slug＋版本”定位。内置条目用目录名＋commit。相同名字出现在两个来源时分别保留；不能因名称相同认定内容相同。

分级默认保留原 SKILL.md 的完整主要功能，并以鸿蒙本机执行为目标。若只保留一个子功能，须创建新的 scope 记录，例如 `model-usage/offline-json`；不能用该子集覆盖原 Skill 的完整分级。

## 分级口径

| 等级 | 静态判据 | 必须核对的前提 |
|---|---|---|
| L1 候选 | 业务主要由文本指令／静态引用组成，无业务执行脚本或平台专用能力 | 目标 Agent 能正确加载提示和静态引用，已有通用输入／输出能力；描述型 Skill 也仍需鸿蒙注册或通用解释入口 |
| L2 候选 | 逻辑主要可归约为 HTTP、JSON、通用文件／字符串处理，存在可明确描述的 ArkTS 替代路径 | 认证、文件选择、网络权限、服务约束、失败处理与输入输出等价性仍待实测 |
| L3 困难／待验证 | 平台专用应用、外部 CLI／Native 运行时、复杂进程／调试／媒体能力、MCP stdio 或 OpenClaw 专用调度 | 说明具体缺口；区分本机适配、功能子集、远程执行，不推导永久不可能 |

静态分类是研究判断，不是自动评分。`bundled-review.json` 保存逐项判读；`build_inventory.py` 从结构化判读和原始源文件生成表格，不根据“有没有 scripts 目录”自动赋级。

## 字段含义

- `script_languages` / `script_files`：实际附带执行资源。正文的 bash、curl 等命令也是依赖，即使没有独立脚本。
- `declared_os`：frontmatter 明示的操作系统约束。未声明不等于支持所有平台。
- `requires_bins_all`：全部需要的可执行文件；`requires_bins_any`：至少一种可执行文件。
- `requires_env`：明确的环境变量门控；`primary_env`：首选配置键，不能擅自升级为门控。表中只记录键名。
- `requires_config`：宿主配置门控。
- `host_tools_text_hits`：预设工具词的正文命中索引；可能有漏检或普通词误命中，不能单独用它证明真实调用。依赖判定以 reason、完整正文及固定版本证据为准。
- `frontmatter`：JSON 中保留原始解析结果，包括 install、allowed-tools 等，供复查。
- `evidence`：精查 JSON 中的源码行、短片段、来源链接；ClawHub 的行号指固定版本原文的本地行号。
- `classification_status`、`original_runtime_status`、`harmony_runtime_status`：分别登记判断与两端运行结果。

## ClawHub 采集与完整性

1. 使用 `limit=200&sort=name&prefix=<0-9a-z>`，六个并发读取不同前缀。
2. 每个分区内部顺序跟随 API 返回的 opaque cursor，不推测下一页。
3. 即使某页 items 为空，只要 cursor 非空就继续；只有 nextCursor=null 才标记该分区结束。
4. 将响应原文逐页缓存，保存分区 checkpoint。HTTP 429 遵循 Retry-After，遇到错误保留最后成功游标。
5. 按 owner/slug 去重，保留观察到的较新 updatedAt，记录重复与版本变化。
6. 全部 36 分区结束，才将目录遍历标为完成。公开目录动态变化，跨页读取不是原子快照。旧数据不符合当前 slug 规则时可能落在范围之外，故结果称“公开 API 当前 slug 范围目录”，不称所有历史生态总量。
7. 不根据 summary 或 topics 推断脚本、系统、宿主依赖和等级。没有正文审阅的记录保留“待分类”。

## 复现

在研究仓库根目录使用 Python 3.10+，详细说明见 [普查工具](../../../../tools/skill-survey/README.md)：

```powershell
python -m pip install -r tools/skill-survey/requirements.txt
$env:SKILL_SURVEY_OUTPUT = Join-Path (Get-Location).Path 'docs/04-methodology/group-b/skill-survey'
python tools/skill-survey/scripts/fetch_bundled.py
python tools/skill-survey/scripts/fetch_candidates.py
python tools/skill-survey/scripts/build_inventory.py
python tools/skill-survey/scripts/verify_inventory.py
```

脚本只读取公开目录／源码和写本地缓存，不安装、不执行下载的 Skill。已完成的采集会复用缓存；若要另做新日期快照，请复制一份干净目录再开始，保留本次数据以便追溯。网络暂时失败时重复运行，按 checkpoint 继续。

工作簿和提交包为上述结构化数据的展示／交付视图，目录登记优先使用 CSV/JSONL 便于代码审查。日期与版本从当前数据文件读取，不采用随打开日期变化的 TODAY()。

## 复核记录

已执行：官方 Git blob 哈希核对、24 个 ClawHub 样本版本全部文件 SHA-256 核对、50 项内置判读与源码集合一一匹配、24 项生态判读与选样计划匹配、ID 唯一性及表格记录数核对、初筛规则边界测试。模型服务调用、OpenClaw 加载与鸿蒙端执行尚未发生。上游包内的 tests/test-report.md 是作者材料，未作为本次实测证据。

## 课程首版范围与初筛边界

源码分类覆盖全部 50 个内置 Skill 与 8 类、24 个目的性选样的 ClawHub Skill。其余生态目录执行 catalog_triage.py 中的可复现规则，只标记线索，摘要证据不足不推为 L1。所有初筛记录包含规则版本与命中字段／短语。相同标题／摘要可能跨主题，主题取首个命中，属于检索辅助。

旧 Skill 可能使用 metadata.clawdbot 或 metadata.clawdis；解析器依次检查 openclaw、clawdbot、clawdis 并记录实际 namespace，不能把旧字段遗漏解释为无依赖。样本索引与判读分别见 sampling-plan.json、clawhub-review.json。
