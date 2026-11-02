# E4 交付：healthcheck

本次要求 OpenClaw 读取 healthcheck，执行安全审计、Gateway 状态和只读诊断，生成报告。
真实轨迹确认了 Skill 读取、命令执行和后台任务查询。三命令流程成功，部分深度探测缺少 operator.read，根因尚未确认。
未验证自动触发、完整健康检查或鸿蒙运行。

## 阅读顺序

1. [基线测试记录](baseline-record.md)：13 个字段逐点说明输入、输出和证据。
2. [问题与实际依赖](issues-and-dependencies.md)：依赖、阻塞和后续问题。
3. [复现说明](reproduction.md)：运行和核验方法。

版本、环境和来源已写入基线记录，机器证据保留在 source-manifest.json 与 evidence/source-environment/。

## 复跑验证

两次仅准备检查、一次真实复跑均通过；会话和输出目录各不相同，原始回执与轨迹未被覆盖，复跑前后配置哈希一致。
[验证摘要](evidence/reproduction-validation.json)中的路径指向本机留档，不要求提交包包含这些运行目录。完整复跑材料保留在本地，包内保留主测证据。

## 文件结构

```text
E4-提交包/
├── README.md  # 阅读入口、文件说明和复跑摘要。
├── extract_evidence.py  # 提取工具输出并核验调用链。
├── prompt-template.txt  # 提供新测试的只读提示词模板。
├── run_baseline.py  # 创建新会话和目录，运行三命令测试。
├── source-manifest.json  # 记录源码哈希及固定版本比对结果。
├── baseline-record.md  # 按 13 个字段记录输入、输出、结论和证据。
├── reproduction.md  # 说明准备、复跑和离线证据核验方法。
├── issues-and-dependencies.md  # 汇总运行依赖、阻塞位置和待确认问题。
├── evidence/
│   ├── agent-result.json  # 保存模型回答、实际模型和选取运行回执。
│   ├── doctor-lint-tool-output.txt  # 保存只读诊断的实际输出。
│   ├── events.jsonl  # 保存真实工具调用及返回，保留原事件编号。
│   ├── gateway-status-tool-output.txt  # 保存 Gateway 状态的实际输出。
│   ├── historical-prompt.txt  # 保存原测试输入的脱敏副本。
│   ├── reproduction-validation.json  # 保存两次准备和一次真实复跑的验证摘要。
│   ├── run-metadata.json  # 记录会话、耗时和配置文件哈希。
│   ├── security-audit-tool-output.txt  # 保存安全审计的实际输出。
│   ├── verified-evidence-index.json  # 索引调用参数、事件编号和退出码。
│   └── source-environment/
│       ├── environment.json  # 记录操作系统和运行时版本。
│       └── skill-info.json  # 记录 Skill 来源、可见性和依赖状态。
└── source/
    ├── LICENSE  # 保存源码许可文本。
    └── SKILL.md  # 保存实际被测的 Skill 原文。
```

## 证据与核验

events.jsonl 是真实 read/exec/process 调用的选取视图，省略系统提示、配置快照、推理和工具发现；agent-result.json 保留模型回答及选取回执。路径标记 <USER_HOME>、<PROJECT_ROOT> 不能直接执行。原始证据及备份副本未修改。

在 Linux/WSL 的提交包目录中校验文件：

```bash
sha256sum -c SHA256SUMS.txt
```

未执行权限修复或系统加固；未提交 Git。
