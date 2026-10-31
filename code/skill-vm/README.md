# code/skill-vm

C-2B（工具链验证）用到的可复现脚本。这里只放**我们自己的脚本**，不放第三方工具源码，也不放第三方 Skill 的编译产物：

- 第三方工具按上游仓库固定提交检出，版本与命令写在 [C-2B 工具链验证记录](../../docs/04-methodology/group-c/evaluation/c-2b-toolchain-batch01.md)。
- 编译产物留在本机工作目录（默认 `$WORK`），不入库；原因见该记录第 7 节（第三方 Skill 再分发边界由 C-4 的许可证策略决定）。

## 目录约定

脚本默认工作目录为 `$WORK`（`WORK` 环境变量可覆盖，默认 `$HOME/c2b`）：

```
$WORK/
  skills/<name>/SKILL.md      # 固定样本，取自 c-2a-samples-v1.json 的 S04-S09
  Skill-Compiler/             # SkCC 源码检出（cargo install --path nexa-skill-cli）
  out/<target>/               # SkCC 产物
  oc/                         # OpenClaw 技能加载状态快照（批次 02）
  logs/                       # 每次运行的原始日志（含时间戳）
```

固定样本来源：`https://github.com/openclaw/openclaw` 提交 `d79ab6195d8d0566b285008bcc30c01a6ce368e2` 下的 `skills/<name>/`。取文件后先核对 `c-2a-samples-v1.json` 里的 `skill_md_sha256`，不一致就不要继续。S01–S03 为 ClawHub 样本，用 `fetch-samples-clawhub.py` 按 release inventory 取，不要手工下载。

## 脚本

| 脚本 | 作用 | 前置 |
| --- | --- | --- |
| [`skvm-batch01.sh`](skvm-batch01.sh) | SkVM：适配器枚举、6 样本 dry-run、bind-env 实跑、`config doctor` | Linux/WSL2（无 win32 构建）+ Node ≥ 18 + `npm i -g @ipads-skvm/skvm` |
| [`skcc-batch02.sh`](skcc-batch02.sh) | SkCC：CLI 目标集合、6 样本 validate、四目标编译、产物哈希 | Rust 工具链 + `cargo install --path nexa-skill-cli` |
| [`skcc-verify-loss.sh`](skcc-verify-loss.sh) | 核对产物是否丢失行内代码标识与依赖声明 | 先跑 `skcc-batch02.sh` |
| [`skcc-batch03.sh`](skcc-batch03.sh) | L1（S01–S03）单样本 validate + claude 构建 + S03 四目标，并输出结构丢失统计 | `fetch-samples-clawhub.py` 已取包、`nexa-skill` 已安装 |
| [`skvm-batch04.sh`](skvm-batch04.sh) | SkVM 对 L1（S01–S03）补跑：profile 能力核对、每样本 pass-1 dry-run、`harmonyos` 适配器探测 | Node + `npm i -g @ipads-skvm/skvm`、样本已 stage 到 `$WORK/skills-l1` |
| [`fixtures/`](fixtures/README.md) | 故障注入夹具（S04-03a/b、S05-01/02、S08-03）+ 自检与哈希登记 | Python 3.8+，无需网络与凭证 |
| [`fetch-samples-clawhub.py`](fetch-samples-clawhub.py) | 按 ClawHub v1 API 取 S01–S03 原包，逐文件比对 release inventory 的 `sha256` | Python 3 + 网络 |
| [`verify-sample-package.py`](verify-sample-package.py) | 本地技能目录 vs git tree blob `sha1` vs 乙组 `source-manifest.json`，三方交叉校验 | 乙组两份数据文件 |
| [`openclaw-baseline.sh`](openclaw-baseline.sh) | 原平台核验：OpenClaw 版本、`skills check` 汇总、六个样本的可见性与缺失项、内容哈希 | Node ≥ 24.22.1；不配模型也能跑 |

## 运行注意

- SkVM 在 Windows 原生安装会报 `unsupported platform win32-x64`；脚本里的 Node 路径示例为 WSL 内安装位置，按本机实际改 `PATH`。
- SkCC 的 npm 包 `nexa-skill-compiler` 只是壳，未构建 Rust CLI 时会报 `'nexa-skill.exe' is not recognized`。
- OpenClaw `2026.10.9` 的 `engines.node` 是 `>=24.22.1 <25 || >=26.12.1`，Node 20/22 会在安装阶段被拒；`openclaw-baseline.sh` 不调用模型，缺的只是 `OPENCLAW_INSTALL=1` 时的安装动作。
- 三个 `.sh` 脚本都会 `tee` 出带时间戳的日志；引用证据时优先引用日志里的原文与哈希，而不是转述。
