# 复现

在已配置 OpenClaw、Gateway 和模型认证的 Linux/WSL 中运行。Python 3.10+，无额外 Python 包。先进入本目录。

```bash
# 仅准备文件和查询帮助，不调用模型
python3 run_baseline.py --prepare-only

# 执行一次三命令只读流程；使用现有模型服务
python3 run_baseline.py
```

默认从 PATH 定位 OpenClaw，从安装目录定位 Skill。非标准安装可显式指定：

```bash
python3 run_baseline.py --openclaw /path/to/openclaw \
  --skill-file /path/to/healthcheck/SKILL.md \
  --config /path/to/openclaw.json --output-root /path/to/runs
```

`--config` 只指定哈希检查对象，不切换 OpenClaw 配置。自定义配置应按原有 OPENCLAW_CONFIG_PATH 环境设置。可用 `--model provider/model` 仅覆盖本次模型；默认不覆盖。

## 输出和边界

- 每次生成“UTC 时间+UUID”目录及新会话，不覆盖历史证据。
- 输出含提示词、源码、帮助、Agent 回执、脱敏轨迹、工具输出及核验结果。
- 只隔离会话和证据目录；仍共享现有 Gateway、配置和工作区。命令限制由提示词提出，并非强制工具白名单。
- 运行会调用模型服务，产生会话/日志。不得将 agent exit=0 当作所有健康项通过。
- doctor lint exit=1、Gateway scope 不足应保留原结果；不自动修复。
- 当前脚本面向本次 OpenClaw CLI/轨迹结构；不承诺其他版本兼容。

## 离线核验

```bash
python3 extract_evidence.py --trace /path/to/trajectory/events.jsonl \
  --agent-result /path/to/agent-result.json --output /path/to/new-verification
```

核验要求实际读取 Skill、只执行三条授权命令、取得三项退出结果、Agent 正常结束。输出目录必须不存在；不发送模型请求。结果表示调用证据完整，不表示安全状态无风险。
