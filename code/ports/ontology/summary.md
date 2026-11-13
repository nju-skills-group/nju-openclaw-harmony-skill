# E3 ontology 周4-5 一页汇报摘要

## 案例与目标

- 实现人：张庆涵（E3）。
- 主案例：ClawHub `oswalpalash/ontology` v1.0.4，L2 候选。
- 备选案例：`meme-maker`，本轮未开展移植，按要求不提交准备材料。
- 原功能：用 Python CLI 在 JSONL 图中创建、查询实体和关系，并进行 schema/路径校验。
- 本轮目标：在 HarmonyOS API 26 应用 Skill 中实现可验证的本地实体创建与查询子集。

## 输入输出

- 输入：实体 ID、类型、properties JSON；或查询 ID/类型。
- 输出：统一 `ExecuteResult`，成功返回结构化 entity/entities，失败返回错误码、原因和建议。
- 正例：创建并查询 `note_harmony_e3 / Note / HarmonyOS E3 port`。
- 负例：重复 ID、非法 JSON、Note 缺 content、非法类型。

## 移植改动

1. Python CLI 改为 `createEntity/getEntity/listEntities` 三个 ArkTS 固定函数。
2. JSONL 工作区文件改为应用沙箱 Preferences。
3. `exec` 子进程结果改为 `completeArkTSScriptInApp` 结构化回包。
4. 增加 ID/类型/大小/数量/必填字段校验；无网络、无外部命令、无额外权限。
5. 未实现关系、更新、删除、动态 schema 和 JSONL 导入导出，明确标为功能子集。

## Harness 关键点

OpenClaw 先发现并加载 `SKILL.md`，为 Agent 注册 `skills_search/skills_read`；模型读取 Skill 后再调用 `exec`，脚本 stdout/stderr/退出码作为 tool result 返回模型，最终回复用户。旧模型在工具选择层失败，新工具模型才实际执行成功。鸿蒙侧以 `skillProfiles + SKILL.md Schema + .ets 方法` 替代开放式 `Skill→exec→Python` 链路。

## 实际结果

| 层级 | 结果 |
| --- | --- |
| 原平台 OpenClaw 基线 | 成功；本人 2026-10-30 重跑 |
| HarmonyOS 适配代码 | 已完成本地实现 |
| 静态契约/安全边界 | 已核对 |
| HAP 构建、签名 | 成功；API 26 Hvigor 构建并生成签名 HAP |
| HarmonyOS PC 安装/启动 | 成功；EntryAbility 正常启动 |
| 开放平台导入/安全扫描 | 成功；四阶段 PASS，扫描 BENIGN |
| 系统小艺调用 | 未通过；测试会话未注入 `nju-ontology`，未到达 ArkTS 入口 |

## 未完成项与下一步

平台或甲组需先核查测试版本是否真正下发到当前账号/PC，并确认宿主可用 Skill 列表出现 `nju-ontology`；之后再依次验证三个业务函数的 ArkTS 入口日志和结构化返回。当前结论必须表述为“代码及交付链路通过、宿主下发/注入阻塞”，不能写成端到端成功。

