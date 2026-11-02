# 复现

在已配置模型及 Gateway 的 Linux/WSL 中，进入 clawhub 目录。需要 Python 3.10+ 和可用的 OpenClaw；无额外 Python 包。

```bash
# 只核对帮助并准备输入，不调用模型
python3 run_baseline.py --prepare-only

# 依次运行两个案例
python3 run_baseline.py

# 只运行一个分支
python3 run_baseline.py --case plugins
python3 run_baseline.py --case skills
```

默认从 PATH 查找 OpenClaw，从安装目录定位 clawhub/SKILL.md。非标准安装可用 `--openclaw /path/to/openclaw --skill-file /path/to/clawhub/SKILL.md`；`--output-root` 指定新结果目录。

每次创建独立会话及“时间+UUID”目录，不覆盖已交证据；仍共享既有 Gateway、配置和工作区。提示词只读约束并非强制工具白名单。实际运行会请求模型及公开目录；不安装、发布或自动修复。

输出在 `runs/<编号>/`，含输入、回执、原始导出和 selected/ 中的脱敏证据。复跑结果可能随模型、目录内容及网络变化，不保证候选列表相同。

离线重新提取已有脱敏轨迹，不请求模型：

```bash
python3 extract_evidence.py --case plugins \
  --trace evidence/plugins/events.jsonl \
  --agent-result evidence/plugins/agent-result.json \
  --input evidence/plugins/input.txt --output runs/offline-new
```

`--output` 必须是不存在的新目录。核验确认目标原文读取、对应发现入口及无观察到的变更调用；不评价候选是否安全、可安装或可运行，也不自动背书模型的全部文字结论。
