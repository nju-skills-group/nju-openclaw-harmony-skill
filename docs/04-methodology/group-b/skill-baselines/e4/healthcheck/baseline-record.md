# healthcheck 基线测试记录

测试日期：2026-10-31。职责：E4，宿主工具或进程协作。

1. **Skill 名称与来源**

   **healthcheck**，官方 **bundled** Skill，随 OpenClaw 2026.10.2 安装。所测 SKILL.md 与[固定源码版本 d79ab6195d8d0566b285008bcc30c01a6ce368e2](https://github.com/openclaw/openclaw/blob/d79ab6195d8d0566b285008bcc30c01a6ce368e2/skills/healthcheck/SKILL.md)中的对应文件哈希一致。源码副本：[source/SKILL.md](source/SKILL.md)；版本核对：[source-manifest.json](source-manifest.json)。

2. **测试环境**

   WSL 2，发行版 Ubuntu-24.04，系统 Ubuntu 24.04.5 LTS；OpenClaw **2026.10.2 (b8952d4)**；Node.js **v24.21.0**；模型提供方 **DeepSeek**，实际模型 **deepseek-v4-pro**，thinking=off。通过现有 Gateway 运行。见[环境记录](evidence/source-environment/environment.json)及[实际模型回执](evidence/agent-result.json)。

3. **安装与配置**

   Skill 已内置，**本次没有执行安装命令**。沿用现有 Gateway 和模型认证，未新增凭据。所需条件：OpenClaw/Node 可运行、模型服务可访问、read/exec/process 工具可用。没有安装额外代理或修改配置；测试前后配置文件哈希一致。命令范围由提示词约束，未设置强制工具白名单。

4. **调用方法**

   在独立会话 `e4-healthcheck-20261031-baseline-01` 中显式要求读取并使用 healthcheck。使用 `openclaw agent --session-id e4-healthcheck-20261031-baseline-01 --message-file <输入文件> --thinking off --timeout 240 --json`；`<输入文件>`保存下方完整测试输入，历史实际命令见[运行记录](evidence/run-metadata.json)。未测试自动触发。

5. **测试输入**

   下方附**实际英文输入的脱敏原文**：要求读取目标 SKILL.md，只执行安全审计、Gateway 状态和只读诊断三条命令，汇报真实结果，禁止修改与修复。原文文件：[historical-prompt.txt](evidence/historical-prompt.txt)。

6. **预期行为**

   模型实际读取 Skill，通过宿主工具执行三条检查命令；命令在后台运行时查询进程并取得结果；根据真实输出报告发现与缺口。`doctor --lint` 退出 1 时读取发现项，不误判为命令启动失败；不执行修复或输出密钥。

7. **实际输出**

   **安全审计：**退出 0，0 个严重项、3 个警告、1 个信息项；深度探测报 `missing scope: operator.read`。**Gateway 状态：**退出 0，服务运行、监听 `127.0.0.1:18789`、连接探测成功，但 operator scope 受限。**只读诊断：**退出 1，执行 36 项、跳过 30 项，报告 2 个警告。模型生成中文报告，列出检查结果和权限缺口，正确说明 lint 退出 1 属于发现问题。见[模型原始回答（回执中的 result.payloads）](evidence/agent-result.json)及下列工具输出。

8. **执行证据**

   [真实工具轨迹](evidence/events.jsonl)：seq 12–13 读取 Skill；seq 50 启动审计，65、80 查询后台任务，81 返回审计结果；89–90 执行并返回 Gateway 状态；98–99 执行并返回只读诊断。[安全审计输出](evidence/security-audit-tool-output.txt)、[Gateway 输出](evidence/gateway-status-tool-output.txt)、[诊断输出](evidence/doctor-lint-tool-output.txt)、[参数与退出码索引](evidence/verified-evidence-index.json)。本次以日志和文件为证据，未录制截图。

9. **测试状态**

   **成功——限本次三命令调用与报告流程。** 三条命令均实际执行并取得输出；其中深度 Gateway 探测子项为**环境阻塞**，缺少 `operator.read`。不能写成“所有健康检查通过”。

10. **实际依赖**
   观察到 **read** 读取 Skill 文件，**exec** 执行 OpenClaw CLI，**process poll** 查询后台审计任务 `crisp-cloud`；依赖 Node.js、Gateway、本地运行状态/日志和模型网络服务。没有执行 Skill 自带脚本，healthcheck 本身也没有附带脚本。详细清单见[问题与实际依赖](问题与实际依赖.md)。

11. **后续问题**
   **甲组**确认探测连接为何未获得 operator.read，检查设备配对/认证路径及授权范围；目前未定位最终根因，不能归因为独立会话。**S1/S3**补充实际工具依赖、后台进程协作和权限阻塞，区分原平台结果与鸿蒙可移植性。模型关于“无读/写权限”的推断超出证据，不采纳。未执行提权或修复。

12. **测试范围**
   **功能子集**：显式读取 Skill → 执行三条只读 CLI → 查询后台任务 → 生成报告。未覆盖自动触发、Linux 系统检查、权限修复、系统加固、独立异常案例和鸿蒙运行。另一次真实复跑见[复跑验证摘要](evidence/reproduction-validation.json)，与本次历史记录分开保存。

13. **skill使用确认**
   **已确认——限显式指定的受测流程。** read 工具实际返回 healthcheck 原文，随后 exec/process 有真实参数、输出与退出状态，证明目标文件被读取并执行了与其说明一致的流程。依据是工具轨迹，不是模型自称或 Ready 状态；本次也不是测试者直接在终端执行命令后的“脚本级成功”。由于输入同时指定了三条命令，未证明模型能够自主选择 Skill，或执行行为完全由 Skill 引起。

## 实际测试输入

以下与提交包中的历史输入一致；`<USER_HOME>`替换了原用户目录，未改变测试要求。

```text
Run a restricted healthcheck baseline in this independent session. I explicitly authorize the following read-only checks now; do not ask for permission again.
First actually read <USER_HOME>/.npm-global/lib/node_modules/openclaw/skills/healthcheck/SKILL.md using the available file-reading tool or bridge. Then use the real execution tool to run each of these exact commands separately, recording stdout, stderr and exit status and continuing after findings:
1. openclaw security audit --deep
2. openclaw gateway status --deep
3. openclaw doctor --lint
The help for these options has been checked. doctor --lint may exit 1 for findings. Do not substitute ordinary doctor or add fix/repair/migration flags. No installs, configuration changes, chmod, service restarts, cron, external messages, or credential-file reads. Do not print tokens/passwords. Limit this run to these three checks; no additional OS checks. Known context: WSL Ubuntu 24.04, personal local workstation; assess provisionally using Balanced posture and mark other context unknown.
If using code-mode tool discovery, discover only the file-read and command-execution tools required here. Never treat shell command text as JavaScript code. Do not retry a failed check repeatedly. Finally report in Chinese the actual checks, findings and gaps, citing tool outputs. A risk finding is not an execution failure. If blocked, identify the exact step. Do not simulate results.
```
