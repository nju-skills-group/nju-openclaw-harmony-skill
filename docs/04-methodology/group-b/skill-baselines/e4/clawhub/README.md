# E4 备选：clawhub

测试两个只读分支：普通 Notion 能力请求默认搜索插件；明确的 weather Skill 请求搜索 Skill。
两案例均实际读取目标原文并选对宿主入口。A 返回两个插件；B 搜索成功，但回答存在排序、数量参数和语言偏差。详情见基线记录。

## 阅读顺序

1. [基线测试记录](baseline-record.md)：13 个字段逐点记录。
2. [问题与实际依赖](issues-and-dependencies.md)：偏差及宿主依赖。
3. [复现说明](reprodeuction.md)：运行器及离线核验。

未安装、卸载、更新、发布或同步任何候选；配置及默认 Skill 目录前后一致。未验证完整生态管理、候选可用性或鸿蒙移植。

## 文件结构

```text
clawhub/
├── README.md  # 阅读入口、文件说明和测试结论。
├── environment.json  # 保存系统版本和 Skill 可见性记录。
├── extract_evidence.py  # 提取脱敏轨迹并核验工具调用。
├── run_baseline.py  # 创建新会话，运行两个只读发现案例。
├── source-manifest.json  # 保存源码哈希及固定版本比对。
├── baseline-record.md  # 按 13 个字段说明输入、输出、证据与限制。
├── reproduction.md  # 说明独立会话复跑及离线核验方法。
├── issues-and-dependencies.md  # 记录工具入口偏差、结果表述和实际依赖。
├── evidence/
│   ├── plugins/
│   │   ├── agent-result.json  # 保存案例 A 的模型回答、实际模型及选取回执。
│   │   ├── events.jsonl  # 保存案例 A 的真实工具调用与返回，保留原事件编号。
│   │   ├── input.txt  # 保存案例 A 的实际测试输入的脱敏副本。
│   │   ├── run-metadata.json  # 保存案例 A 的会话、耗时、配置及 Skill 目录一致性记录。
│   │   ├── tool-output.txt  # 保存案例 A 的从工具结果提取的实际搜索输出。
│   │   └── verification.json  # 保存案例 A 的调用链、工具失败及未观察到变更的核验记录。
│   └── skills/
│       ├── agent-result.json  # 保存案例 B 的模型回答、实际模型及选取回执。
│       ├── events.jsonl  # 保存案例 B 的真实工具调用与返回，保留原事件编号。
│       ├── input.txt  # 保存案例 B 的实际测试输入的脱敏副本。
│       ├── run-metadata.json  # 保存案例 B 的会话、耗时、配置及 Skill 目录一致性记录。
│       ├── tool-output.txt  # 保存案例 B 的从工具结果提取的实际搜索输出。
│       └── verification.json  # 保存案例 B 的调用链、工具失败及未观察到变更的核验记录。
├── prompts/
│   ├── plugins.txt  # 提供默认插件发现的复跑输入模板。
│   └── skills.txt  # 提供明确 Skill 搜索的复跑输入模板。
└── source/
    ├── LICENSE  # 保存 OpenClaw 源码许可。
    └── SKILL.md  # 保存实际被测 clawhub 原文。
```

## 证据与校验

轨迹保留真实原生工具调用及返回，省略系统提示、配置快照、推理和 code-mode 外层包装；选取回执保留模型原始回答。输入中的 <USER_HOME>、<PROJECT_ROOT> 是脱敏路径标记。核验脚本不代表模型全部文字正确。

两个实际运行案例和交付入口准备检查均已完成；保留的脱敏证据也通过离线重提取核验。已删除重复导出、帮助快照、临时整理脚本和缓存，只保留两个复现 Python 脚本。

在 Linux/WSL 中检查文件完整性：

```bash
sha256sum -c SHA256SUMS.txt
```

healthcheck 目录及用户保留的提交包副本未修改。本目录未压缩或提交 Git。
