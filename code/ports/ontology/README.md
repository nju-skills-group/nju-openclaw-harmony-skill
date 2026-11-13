# E3 Ontology HarmonyOS 移植

负责人：张庆涵（E3）  
原样本：ClawHub `oswalpalash/ontology` v1.0.4  
目标：HarmonyOS API 26+、Stage 模型、应用侧 ArkTS Skill

许可记录：团队普查元数据登记为 `MIT-0`，但 v1.0.4 安装包内没有 LICENSE 文件，`declared_license_text` 为“未声明”。该信息仅作来源登记，不构成法律审查；公开复用前应向上游确认许可文本。

## 移植范围

本轮实现 ontology 的本地实体存储子集：

- `createEntity`：创建带固定 ID、类型和 JSON 属性的实体；
- `getEntity`：按 ID 获取实体；
- `listEntities`：按类型列出实体；
- 重复 ID、空参数、非法 JSON 和缺少必填字段的错误分支。

未实现：关系、更新、删除、schema 合并、图约束、JSONL 导入导出。原 Python CLI 改为 HarmonyOS 函数契约；持久化从工作区 JSONL 改为应用沙箱 Preferences，不申请文件或网络权限。

## 目录

```text
entry/
├── skills/nju-ontology/
│   ├── SKILL.md
│   └── scripts/
│       ├── OntologySkill.ets
│       └── OntologyStore.ets
└── src/main/module.skill-profile.json5
```

`module.skill-profile.json5` 是应合并到目标工程 `entry/src/main/module.json5` 的片段，不是可单独构建的完整 module 文件。

配套材料：

- [移植对照记录](port-record.md)
- [一页汇报摘要](summary.md)
- [静态验证日志](evidence/static-validation.md)
- [运行结果](evidence/runtime-results.md)
- [HarmonyOS PC 移植与真机链路验证报告](evidence/harmonyos-pc-real-device-report-2026-11-13.md)
- [固定来源清单](evidence/source-inventory.md)
- [原平台 E3 基线](../../../docs/04-methodology/group-b/skill-baselines/e3/baseline-record.md)
- [Harness 调用链说明](../../../docs/04-methodology/group-b/harness/ontology-e3-call-chain.md)

## 接入甲组工程

1. 将 `entry/skills/nju-ontology` 复制到目标 Stage 工程的 `entry/skills/`。
2. 将 `module.skill-profile.json5` 中的对象加入目标工程 `module.skillProfiles` 数组；保留工程原有 Ability、权限和其它配置。
3. 确认目标工程存在名为 `EntryAbility` 的 Ability；否则同步修改 `abilityName`。
4. 使用 API 26+ SDK 构建 HAP。
5. 分别记录构建、安装/启动、系统智能体调用和真机验证结果；构建成功不等于 Skill 调用成功。

## 预期调用示例

```text
创建：createEntity("note_harmony_e3", "Note", "{\"content\":\"HarmonyOS E3 port\",\"tags\":[\"e3\",\"harmonyos\"]}")
查询：getEntity("note_harmony_e3")
列表：listEntities("Note")
```

## 当前验证状态

| 层级 | 状态 | 说明 |
| --- | --- | --- |
| 原平台基线 | 已通过 | 见 E3 ontology 基线记录；本人于 2026-10-30 重跑 |
| 代码/契约静态检查 | 已通过 | 名称、入口、函数名、参数顺序和返回分支已核对 |
| HAP 构建与签名 | 已通过 | API 26 Hvigor 构建成功，生成签名 HAP |
| HarmonyOS PC 安装/启动 | 已通过 | HDC 安装成功，`EntryAbility` 成功启动 |
| 开放平台导入/扫描 | 已通过 | validate/package/upload/safety_scan 全部 PASS，风险 BENIGN |
| 系统智能体调用 | 未通过/阻塞 | 测试会话未注入 `nju-ontology`，未到达 ArkTS 入口 |
| 真机业务回包 | 未到达 | 设备和应用可运行，但三个业务函数未被系统宿主调度 |

## 安全与数据边界

- 不使用网络、外部命令、明文密钥或公共存储。
- 数据保存于目标应用沙箱的 Preferences `e3_ontology_store`。
- 属性 JSON 最大 16 KiB；实体最多 500 条；ID、类型和必填字段均在入口后再次校验。
- 此原型不得用于存储密码、令牌等秘密数据。

