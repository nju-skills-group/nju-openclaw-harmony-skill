# E3 ontology 移植对照记录

## 1. 身份与代码版本

| 字段 | 内容 |
| --- | --- |
| 实现人 | 张庆涵（E3） |
| 原样本 | ClawHub `oswalpalash/ontology` v1.0.4 |
| 来源许可 | 普查元数据为 `MIT-0`；v1.0.4 包内无 LICENSE，声明文本未提供，待上游确认 |
| 原脚本 SHA-256 | `25e10809ab4f809f2fd3b475989a882e6fcdd9127655ec40fccf44d10f0c0491` |
| 原平台基线 | 2026-10-30 由本人重跑；OpenClaw 2026.10.4 完整调用链复测通过 |
| 本地适配分支 | `feature/A/e3-ontology-harmony-port` |
| 目标实现 | `code/ports/ontology` |
| 目标版本 | `nju-ontology` 0.1.0 |

## 2. 分类与功能范围

ontology 属于 L2 候选：它不依赖网络或外部服务，但包含脚本执行、结构化数据校验和持久化状态，不是纯提示类 Skill。

本轮只移植实体 CRUD 中的创建和读取子集：

| 原能力 | 目标能力 | 状态 |
| --- | --- | --- |
| `create --type --props --id` | `createEntity(id, type, propertiesJson)` | 已实现代码 |
| `get --id` | `getEntity(id)` | 已实现代码 |
| `list --type` | `listEntities(type)` | 已实现代码 |
| `query --where` | 无 | 未实现 |
| `relate` / `related` | 无 | 未实现 |
| `update` / `delete` | 无 | 未实现 |
| `validate` / `schema-append` | 固定白名单与部分必填字段校验 | 功能删减 |
| JSONL 历史记录 | Preferences 当前状态 | 语义替代 |

## 3. 执行位置

| 部分 | 位置 |
| --- | --- |
| 原 OpenClaw Agent、Python 脚本、Ollama | Windows 本机，`D:\OpenClaw` |
| HarmonyOS 适配代码 | 本地 Git 工作区 |
| 静态检查 | Windows 本机 |
| HAP 构建 | 已执行：API 26 Hvigor 构建、打包和签名通过 |
| HarmonyOS PC | 已安装并成功启动 EntryAbility；系统小艺调用未到达目标入口 |

## 4. 能力映射

| 原工具/运行时/权限 | HarmonyOS 目标接口 | 验证状态 |
| --- | --- | --- |
| `SKILL.md` 指令 | API 26 应用 Skill `SKILL.md` 场景与 JSON Schema | 平台导入与规范校验通过 |
| Python CLI 子命令 | `OntologySkill.ets` 的 3 个 `public async` 方法 | 编译通过，宿主调用未到达 |
| OpenClaw `exec` | `ohos-arkTSScript` / `scriptManager` 回调 | 编译通过，系统调用未到达 |
| 工作区 JSONL | 应用沙箱 Preferences `e3_ontology_store` | 编译通过，业务入口未执行 |
| stdout JSON | `scriptManager.ExecuteResult.result` | 编译通过，业务入口未执行 |
| 工作区路径保护 | 不暴露路径，只使用应用沙箱存储 | 设计替代 |
| Python/PyYAML | ArkTS + `@kit.ArkData` | 已消除 Python/PyYAML 依赖 |
| 文件读写权限 | Preferences 应用沙箱 | 不需要额外权限 |

## 5. 具体修改

1. 把“模型读说明后自行拼 CLI”改成 3 个固定函数契约，参数位置与 Schema 明确对应。
2. 将 properties 作为 JSON 字符串传入，在业务层再次解析和校验，不依赖模型完全遵守 Schema。
3. 将 JSONL 追加日志改为 Preferences 中的实体数组；因此不保留操作历史，也不支持外部文件互操作。
4. 增加 ID 正则、类型白名单、16 KiB 属性上限、500 实体上限、重复 ID、必填字段和敏感字段拒绝分支。
5. 统一通过 `completeArkTSScriptInApp` 返回 `success/failed` 结构；回调异常写入系统日志。
6. 明确禁止秘密数据、网络访问和跨应用文件路径。

## 6. 目标环境

- HarmonyOS API 26+，Stage 模型；
- 目标模块存在 `EntryAbility`；
- `skillProfiles` 注册 `nju-ontology`，入口为 `.ets`；
- 运行时使用 `@kit.AbilityKit` 与 `@kit.ArkData`；
- 系统智能体调用和真机条件沿用团队现有实验边界：构建通过、应用启动、Skill 匹配、入口执行和结果返回必须分别记录。

## 7. 对照用例

### 正常用例

业务输入：创建 Note `note_harmony_e3`，内容 `HarmonyOS E3 port`，标签 `e3/harmonyos`，随后按 ID 查询。

| 项目 | OpenClaw 源端 | HarmonyOS 目标端 |
| --- | --- | --- |
| 调用 | Python `ontology.py create/get` | `createEntity/getEntity` |
| 预期 | 固定 ID 实体可查询 | 固定 ID 实体可查询 |
| 实际 | 已生成 JSONL，`get` 退出码 0 | 编译、安装和应用启动通过；系统宿主未调度目标入口 |

### 异常用例

| 输入 | 源端 | 目标端预期 | 目标端实际 |
| --- | --- | --- | --- |
| 工作区外路径 | `Invalid graph path`，退出码 1 | 不接受路径参数，数据固定在应用沙箱 | 设计已消除该攻击面，运行未测 |
| 重复 ID | 原脚本按既有逻辑处理 | `ERR_CONFLICT` | 代码分支已实现，运行未测 |
| Note 缺少 content | schema 约束路径 | `ERR_REQUIRED_PROPERTY` | 代码分支已实现，运行未测 |
| 非法 properties JSON | CLI 解析失败 | `ERR_INVALID_JSON` | 代码分支已实现，运行未测 |

## 8. 判定与差异

- **已通过**：原平台基线、目标目录/注册/函数名一致性、代码静态审查、权限最小化设计。
- **已通过**：API 26 构建、签名 HAP、HarmonyOS PC 安装启动、开放平台导入与安全扫描。
- **未通过/未到达**：系统智能体未注入目标 Skill，业务函数没有真实入口回包。
- **主要差异**：目标端仅实现实体创建与查询；存储语义从追加历史变为当前状态；关系和动态 schema 被删减。
- **额外副作用**：实体写入应用 Preferences，会随应用数据清除而丢失；容量限制为原型人为设置。
- **当前状态**：代码与交付链路已完成；宿主匹配/下发链路阻塞，不能写为端到端成功。

## 9. 验证层级

| 层级 | 状态 | 证据/缺口 |
| --- | --- | --- |
| 原平台 | 成功 | `docs/04-methodology/group-b/skill-baselines/e3` |
| 适配代码 | 已完成 | `code/ports/ontology` |
| 静态契约 | 通过 | `evidence/static-validation.md` |
| 构建 | 成功 | Hvigor 构建日志与签名 HAP |
| 应用安装/启动 | 成功 | HarmonyOS PC HDC 部署与启动日志 |
| 平台导入/扫描 | 成功 | validate/package/upload/safety_scan PASS |
| 目标调用 | 未通过 | 测试会话可用 Skill 中无 `nju-ontology` |
| 真机业务入口 | 未到达 | 设备可运行应用，但没有 ArkTS 入口日志与回包 |

## 10. 复现步骤

1. 在 API 26 Stage 工程中复制 `entry/skills/nju-ontology`。
2. 将注册片段合并到 `module.skillProfiles`。
3. 构建 HAP，保存完整日志和产物标识。
4. 安装并启动应用；该结果单独登记。
5. 依次调用创建、查询、列表、重复 ID、非法 JSON 和缺字段用例。
6. 对每步记录实际返回；系统未调度到入口时，记录匹配、下发、端侧日志分别停在哪层。

