# E3 ontology HarmonyOS 运行结果与证据

日期：2026-11-13  
执行者：张庆涵（E3）

完整过程见 [HarmonyOS PC 移植与真机链路验证报告](harmonyos-pc-real-device-report-2026-11-13.md)。

## 实际结果

| 验证层 | 状态 | 结果 |
| --- | --- | --- |
| API 26 ArkTS 编译 | PASS | Hvigor `BUILD SUCCESSFUL` |
| HAP 打包与签名 | PASS | 生成签名 HAP |
| HarmonyOS PC 安装/启动 | PASS | HDC 安装成功，EntryAbility 成功启动 |
| 开放平台导入/安全扫描 | PASS | validate/package/upload/safety_scan 全部通过，BENIGN |
| 测试组与版本发布 | PASS | 测试账号已加入并启用，完成发布配置 |
| 系统小艺业务调用 | FAIL/BLOCKED | 会话未注入 `nju-ontology`，未到达 ArkTS 入口 |

## 业务用例

| 编号 | 实际输入 | 预期输出 | 当前实际输出 | 状态 |
| --- | --- | --- | --- | --- |
| H1 | `createEntity("note_harmony_e3", "Note", "{\"content\":\"HarmonyOS E3 port\"}")` | 创建成功 | 宿主未调度目标入口 | NOT REACHED |
| H2 | `getEntity("note_harmony_e3")` | 返回 H1 实体 | 宿主未调度目标入口 | NOT REACHED |
| H3 | `listEntities("Note")` | 数组包含 H1 | 宿主未调度目标入口 | NOT REACHED |
| H4 | 重复执行 H1 | `ERR_CONFLICT` | 仅完成代码与静态检查 | NOT REACHED |
| H5 | 非法 properties JSON | `ERR_INVALID_JSON` | 仅完成代码与静态检查 | NOT REACHED |
| H6 | Note 缺少 `content` | `ERR_REQUIRED_PROPERTY` | 仅完成代码与静态检查 | NOT REACHED |
| H7 | 查询未知 ID | `ERR_NOT_FOUND` | 仅完成代码与静态检查 | NOT REACHED |
| H8 | properties 含顶层敏感字段 | `ERR_FORBIDDEN_PROPERTY` | 仅完成代码与静态检查 | NOT REACHED |

应用安装启动、开放平台导入以及内置备忘录成功均不等价于目标入口执行。最终判定以 `OntologySkill.ets` 入口日志及结构化回包为准。
