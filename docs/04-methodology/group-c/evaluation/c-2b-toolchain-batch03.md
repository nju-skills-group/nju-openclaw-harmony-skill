# C-2B 工具链验证批次 03：L1 三个样本的 SkCC 路径

> 类型：工具链实测。执行日期 2026-10-31（UTC 06:36），位置 WSL2 Ubuntu 20.04。
> 起因：批次 01 的 SkCC 只覆盖 S04–S09，S01–S03 记为"未测（原包未取得）"；[批次 02](c-2b-batch02-baseline-and-provenance.md) 取得原包后，这一项可以补测。
> 结论：三个 L1 样本 `validate` 与 `build` 全部成功，SkCC 的"未测 3/9"清零；但产物把 Markdown 结构整体压平（标题 `#` 25/38/11 → 1，列表项 55/62/33 → 0），S02 还出现源文没有的占位步骤名，codex 目标注入源文没有的通用段落。

## 1. 环境与输入

| 项目 | 实际值 |
| --- | --- |
| SkCC | `nexa-skill 0.1.0`，源码提交 `59faa3ac94bbfdaf5dcd8070ef6d1f1d31b0b3a6` |
| Rust | `rustc 1.99.1 (58cf8f9c3 2026-10-13)` |
| 系统 | `Linux 6.6.87.2-microsoft-standard-WSL2 x86_64` |
| 输入 | 批次 02 §2 取得的原包，`SKILL.md` 哈希与样本清单一致（S01 `61b6f221…`、S02 `cf44335f…`、S03 `b972afd7…`） |
| 命令 | 每个样本 `nexa-skill validate <dir>/SKILL.md`、`nexa-skill build <dir>/SKILL.md --claude -o out/Sxx-claude`；S03 另跑 `--all`（四目标） |

脚本：[`code/skill-vm/skcc-batch03.sh`](../../../../code/skill-vm/skcc-batch03.sh)。原始日志 `batch03-20261031T143654.log`（4763 B，SHA-256 `c42297fed93c59ebfacb235fe1aaa60e818d5ea78549126a93b2e7e1dd489b8a`），未入库。

## 2. 结果

| 样本 | validate | build --claude | 产物 `SKILL.md` SHA-256 | manifest `source_hash` |
| --- | --- | --- | --- | --- |
| S01 | 通过 | 通过 | `b65ab464ed046c3235f73cdb08f6f40f8227cecb1a758f6fb723c13d9fd05f0a` | `61b6f221…`（= 源哈希）；manifest `version` `1.1.0` |
| S02 | 通过 | 通过 | `96cc5d8b828cec8dce7235e5dde3d901aa7671900f59cc3db2a2120e3f0046f7` | `cf44335f…`（= 源哈希）；manifest `version` `0.1.0`（源文无 version） |
| S03 | 通过 | 通过（`--all` 四目标亦通过） | `41648cc2289a5302dc2a832d81f67a8c3cbc3a4584e7f5b6f60057cadc7304e7` | `b972afd7…`（= 源哈希）；manifest `version` `0.1.0`（源文无 version） |

S03 `--all` 产物：`SKILL.md`（claude）、`first-principles.md`（codex/gemini/kimi 共用名）、`assets/config.yaml`、`manifest.json`；manifest 为 `skill_name: first-principles`、`security_level: medium`、`hitl_required: false`、`targets: [claude]`（各目标目录各自的 manifest）。

## 3. 产物质量问题（比批次 01 更严重，逐条可核对）

### 3.1 Markdown 结构被整体压平

产物形态是 `<agent_skill><metadata/><intent/><execution_steps><step order="n">…</step></intent>…<section>…`，源文的标题与列表被改写为 step/section 包裹的**连续文本**：

| 样本 | `#` 标题 源 → 产物 | `- ` 列表项 源 → 产物 |
| --- | --- | --- |
| S01 | 25 → 1 | 55 → 0 |
| S02 | 38 → 1 | 62 → 0 |
| S03 | 11 → 1 | 33 → 0（codex 目标保留 9 个标题、2 个列表项） |

直接后果是条目之间的边界消失，例如 S01 的

```text
- Accuracy: Is the basic answer correct?
- Depth: Did the student show understanding or just memorization?
```

在产物里变成

```text
Determine:Accuracy: Is the basic answer correct?Depth: Did the student show understanding or just memorization?Gaps: …
```

这与批次 01 §4.4 记录的行内代码丢失是同一类缺陷的更强版本：批次 01 丢的是反引号（工具名/字段名），这里丢的是**分段语义**。对移植而言，"哪些是并列的检查项"直接决定 ArkTS 侧要拆成几个分支，压平后无法判定。

### 3.2 S02 出现源文没有的占位步骤名

S02 的源文是散文式写作规范（37 个标题，但没有编号步骤）。产物第一步是：

```text
<step order="1">Follow the skill instructions
```

即编译器在缺少显式步骤时**自己造了一个通用步骤名**，把整篇正文塞进该步。这不是源文内容，也不是明确的"未能解析"标记；下游若按 step 生成 ArkTS 方法，会得到一个名为 `Follow the skill instructions` 的能力。

### 3.3 codex 目标注入通用段落

同一份 S03，codex 产物 `first-principles.md` 中出现源文没有的三行：

```text
## Context Gathering
- Verify all required dependencies are available
- Check system state and prerequisites
```

claude 产物中不出现。这属于跨目标的不一致注入，且内容与技能无关。

### 3.4 `version` 字段被写成默认值

S01 源 frontmatter 有 `version: 1.1.0`，产物 `<metadata><version>1.1.0</version>` 保留；S02、S03 源文没有 `version`，产物却写 `0.1.0`（codex frontmatter 亦为 `version: 0.1.0`）。"缺省"被渲染成看似真实的版本号，与批次 02 强调的"版本必须可追溯"冲突。

## 4. 判定

按 [预注册第 6 节](c-2b-preregistration-v1.md)：**通过**（S01/S02/S03），范围严格限定为"离线编译成 Claude 提示格式"，S03 另含四目标。判据逐条：工具与版本已记、输入哈希与样本清单一致、命令完整、产物可哈希、manifest `source_hash` 与源一致。

但要记两件事：

1. 按批次 01 的口径，"通过"只表示工具完成了声明的转换，**不表示产物可交付**；3.1–3.4 的四条缺陷使 L1 产物同样不能直接用于移植。
2. 若 C-2A 认为"注入源文没有的内容"（3.2、3.3）属于关键检查项失败，则 S02 应降为**部分通过**，SkCC 口径随之变为"通过 4/9、部分通过 5/9"。本批按批次 01 口径判通过，并把该分歧列为 [预注册](c-2b-preregistration-v1.md) 第 8 节待确认项（P7）。

## 5. 对覆盖率口径的影响

| 指标 | 批次 01 | 本批后 |
| --- | --- | --- |
| 工具链处理覆盖（SkCC） | 通过 2/9，部分通过 4/9，未测 3/9 | 通过 5/9，部分通过 4/9，**未测 0/9** |
| 工具链处理覆盖（SkVM） | 阻断 6/9，未测 3/9 | 不变（S01–S03 亦缺 TCP profile，未补跑）；后由 [批次 04](c-2b-batch04-static-and-fixtures.md) 补跑，结论同为阻断，口径变为阻断 9/9 |

仍未改变的部分：**完整本机覆盖 0/9**、**目标运行 0/9**。工具链覆盖从 6/9 变成 9/9 只说明"九个样本都被同一条离线编译路径处理过"，不构成任何鸿蒙可运行证据。

## 6. 复现

```bash
# 1) 取原包（批次 02 的脚本）
python code/skill-vm/fetch-samples-clawhub.py \
  --samples docs/04-methodology/group-c/evaluation/c-2a-samples-v1.json \
  --out "$WORK/samples-clawhub"
# 2) 需要已安装的 nexa-skill（cargo install --path nexa-skill-cli）
WORK=$HOME/c2b bash code/skill-vm/skcc-batch03.sh
```

脚本会把原包复制到 `$WORK/skills-l1/<S0x>/`（不修改原包），产物落在 `$WORK/out-l1/`，并对每个样本打印标题数、列表数、字段命中数与 `version` 行，便于复核 §3 的结论。
