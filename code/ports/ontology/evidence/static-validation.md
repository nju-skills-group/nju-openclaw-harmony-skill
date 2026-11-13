# E3 ontology HarmonyOS 静态验证日志

验证日期：2026-11-06  
执行者：张庆涵（E3）

## 1. 文件来源

- 原始 Skill：`D:\OpenClaw\workspace\skills\ontology`，ClawHub v1.0.4。
- 原始脚本：`scripts/ontology.py`。
- 目标模板：仓库 `docs/05-protocols/harmonyos-app-skill-template.md`。
- 目标接口说明：仓库 `docs/05-protocols/harmonyos-app-skill-format-and-api.md`。
- 目标实现：`code/ports/ontology`。

## 2. 环境检查

```text
node.exe = C:\nvm4w\nodejs\node.exe
java.exe = C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot\bin\java.exe
DevEcoStudio = not found
hvigor/hvigorw = not found
HarmonyOS API 26 SDK = not found
```

结论：可做源文件和契约静态检查；不能执行 HAP 构建、模拟器或真机验证。

## 3. 静态验收项

第一次检查器只识别半角括号，未识别场景标题中的全角括号，导致 `docFunctions` 为空并报错。修正检查器为同时接受 `()` 与 `（）` 后重跑；该问题属于检查脚本，不是 Skill 代码错误。

重跑原始结果：

```text
NameMatch=True
EntryIsEts=True
EntryExists=True
FunctionsMatch=True
UsesArkTSScriptInfo=True
UsesCompleteCallback=True
UsesPreferences=True
HasNoNetwork=True
HasCreateValidation=True
DocFunctions=createEntity,getEntity,listEntities
CodeFunctions=createEntity,getEntity,listEntities
```

加入敏感字段拒绝后最终回归：

```text
NameMatch=True
EntryExists=True
FunctionsMatch=True
UsesCallback=True
UsesPreferences=True
HasForbiddenGuard=True
HasNoNetwork=True
JsonBlocksValid=4
```

| 检查项 | 结果 |
| --- | --- |
| 目录名 / frontmatter name / profile name 均为 `nju-ontology` | 通过 |
| `srcEntries` 指向 `.ets` | 通过 |
| `abilityName=EntryAbility`，接入时须对照目标工程 | 通过（条件项） |
| `functionName` 与入口公开方法一致 | 通过 |
| Schema arg 顺序与 argv 读取一致 | 通过 |
| 成功、参数错误、JSON 错误、冲突、未找到、内部错误分支 | 通过 |
| 每条业务路径最终调用一次统一 report | 通过 |
| `completeArkTSScriptInApp` 有异常捕获 | 通过 |
| 网络/外部命令/明文密钥 | 未使用 |
| 任意文件路径输入 | 已消除，使用应用沙箱 Preferences |

## 4. 当前判定

```text
原平台基线：成功
目标代码适配：已完成
静态契约检查：通过
HAP 构建：环境阻塞/未执行
业务运行：未执行
系统智能体调用：未执行
真机：未执行
综合状态：已完成本地代码适配，尚不能认定移植运行成功
```

## 5. 官方 API 复核

- 华为 Preferences API 文档确认 `import { preferences } from '@kit.ArkData'`、`getPreferences(context, options)`、`get/put/flush` Promise 接口，以及数据存放在应用沙箱：<https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-data-preferences>
- 华为应用 Skill 指南确认仅支持 Stage 模型，入口第一个参数为 `ArkTSScriptInfo`，并通过 `completeArkTSScriptInApp(context, requestCode, result)` 上报结果：<https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-skill-development-guide/>

API 形态与本实现一致；由于本机没有 API 26 SDK，类型检查和编译结果仍须在目标工具链中验证。

## 6. 按维护目录归位后的复检

```text
TargetPath=code/ports/ontology
NameMatch=True
EntryExists=True
FunctionsMatch=True
HasForbiddenGuard=True
JsonBlocksValid=4
SecretEmailUserPathHits=0
NonEnglishFilenames=0
```

原平台材料不再复制到 `baseline-tests/`，统一引用 `docs/04-methodology/group-b/skill-baselines/e3/`；Harness 已移动到 `docs/04-methodology/group-b/harness/ontology-e3-call-chain.md`。

