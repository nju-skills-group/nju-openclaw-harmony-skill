# C2 个人独立真机实验

2026 年 11 月 12 日，北京时间。目标是在本人使用的 MateBook 上，用自己的开发者账号发布一项全新应用 Skill 的真机测试，并记录完整调用结果。本记录的结果从本轮重新采集。

| 项目 | 本轮设定 |
| --- | --- |
| 实验工程 | [C2 独立回执](../../code/experiments/harmonyos-c2-independent/README.md) |
| 应用包名 | `com.skilllab.c2pc089e5768` |
| Skill 注册名 | `test-code-receipt-089e5768` |
| 平台显示名 | 测试编号 |
| 运行环境 | HarmonyOS PC/2in1，Stage，目标与兼容 API 26 |
| 业务 | 返回测试码及应用运行时生成的随机 UUID |

## 检查清单

- [x] 新建独立源码、应用包名、Skill 注册名及请求与回包日志。
- [x] 构建并核验 HAP 清单，记录未签名产物哈希。
- [x] 用本人账号给 MateBook 生成调试签名，安装并验证 `app_ready`。
- [x] 在本人小艺开放平台导入同一份签名 HAP，核对导入草稿的 Skill 注册名。
- [x] 在本人账号下登记同包名的 HarmonyOS PC 应用，配置个人真机测试组并发布主对话测试。
- [ ] 连续采集日志，运行三个不同测试码和一个非触发负例。
- [ ] 将小艺匹配、脚本入口、回包和界面结果关联，记录结论及失败节点。

前期使用团队既有发布做过排查。那条发布绑定的包名与为解决签名冲突而另建的 C3 测试包名不同。本轮用一份独立签名 HAP 同时完成安装与平台导入，以 HAP 清单和哈希校验一致性。早期排查不用于本轮成功率或验收判定。

## 本轮构建证据

本机 DevEco Studio `26.0.0.851`、SDK `26.0.0.105`。Hvigor 构建成功。未签名 HAP 为 23001 字节，SHA-256 `CC4B4FFC8CE1FF59E65F387AAFF689D43F71BD511B5D2877BC8018B8D7B19593`。从 HAP 读回包名、`2in1`、API 26 和单项 `skillProfiles`。已核对随包 `SKILL.md` 的注册名、函数名，以及编译产物中的 ArkTS 入口和日志标记。签名 HAP 将另记哈希，作为实际安装和平台导入的共同基线。

## 自动签名排查

用户在独立副本上操作时，DevEco 提示「无法获取用户团队信息」。15:08:02 至 15:08:05 的 IDE 日志多次出现 `401` 和 `getTokenInfo return null`。随后 IDE 已成功读取设备标识，证书与设备查询均有 `OK`，但 15:08:42 创建调试 Profile 时记录 `addProvision responseContent is null`。检查时独立副本仍无可用签名配置。优先刷新 IDE 的华为账号登录会话，再复测 Team 列表和 Profile 创建。[华为 DevEco 自动签名说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing-auto/)

## 11 月 13 日签名与部署

用户重新登录后生成调试签名。`default` 构建产品关联该配置，签名构建成功。签名 HAP 为 58800 字节，SHA-256 `86B340B781318EB4C3957942BB68E3A78DA4F018E373557C7016BEDA845E51E2`。从该 HAP 核对包名 `com.skilllab.c2pc089e5768`、设备类型 `2in1`、API 26，以及 `c2pc089e5768-receipt` 的脚本路径。

HDC 返回安装成功和 `EntryAbility` 启动成功，真机包管理器读回包名一致。14:19:59.412 设备日志 `C2OwnReceipt` 记录 `event=app_ready`。接下来使用上述同一签名 HAP 导入本人小艺开放平台。

同一 HAP 已导入个人工作台，分类选「实用工具 / 其他工具」，平台创建草稿 `c2pc089e5768-receipt`。平台编辑器的安全扫描报告将名称中的 `C2` 解读为 Command and Control，给出 `MALICIOUS` 判定。报告中的指令及脚本维度均未发现恶意行为。按报告建议澄清技能名称与描述，明确脚本只处理用户输入的测试码，并重新运行平台扫描。

修订版使用 `test-code-receipt-089e5768`，应用包名和签名保持一致，业务继续返回原测试码及应用内生成的 UUID。新签名 HAP 的 SHA-256 为 `8D46032E87D6F4CF4C04BADCA3711BC2F196FC0C4E2FD272A7162D0B3BDF1A37`。安装更新成功，14:27:16.956 记录 `app_ready`。个人工作台 14:30:58 出现同名修订版草稿，规范校验、打包、上传和远程安全扫描均通过，扫描结果为 `BENIGN`。

## 11 月 13 日小艺 Work 安装失败

在 MateBook 的小艺办公入口发送平台生成的安装提示词。设备日志 14:37:10.773 记录复制到默认 Skill 目录时返回 `Read-only file system`，14:37:27.779 记录后续本地技能搜索。该时段未观察到 `C2OwnReceipt` 的业务调用记录。

Work 回复称下载和解压成功，1342 字节的 ZIP 仅包含 `test-code-receipt-089e5768/SKILL.md`，目录写入另触发 `path_denied`，且 `install_skill` 在云端技能库中查不到该注册名。ZIP 内容和云端检索结果来自用户转述的客户端回复。Work 下载包中缺少 `SKILL.md` 所声明的 `.ets` 源文件，独立复核签名 HAP 则确认其 `ets/modules.abc` 含 `ReceiptSkill`、`issueReceipt` 和 `C2OwnReceipt`，HAP 哈希与签名部署记录一致。补充 ZIP 文件仍需可用的 Work 安装通道。带签名的下载链接保留在平台页面。

用户随后在小艺办公发送测试码 `PC7-RCPT-1113-B8N3` 的业务请求。办公回复称按「测试编号生成」搜索远程技能库未找到匹配，本地技能中也无该项，并给出通用编号示例 `TEST-PC7-RCPT-1113-B8N3-20261113`。这是客户端报告的检索与回退结果。请求没有返回应用 Skill 定义的 `nonce` 和随机 UUID `receiptId`，该样本记为 Work 未调用。它与主对话使用同一测试码，但来自另一入口，分别记录。

## 11 月 13 日小艺主对话发布与设备复测

平台从 HAP 读到 `com.skilllab.c2pc089e5768`。最初保存时平台提示「关联的应用不存在」。在本人 HarmonyOS 开发者中心新建项目并登记同包名的 PC/2in1 应用「测试编号回执」，重新选择包名，设定最低和目标 API 26 及中文映射名「测试编号」，平台返回「保存成功」。[华为 HarmonyOS 应用登记示例](https://developer.huawei.com/consumer/cn/codelab/AGCPreparation-HarmonyOS/)

新建并启用「C2 MateBook 个人真机」测试组，用户数为 1，平台确认当前账号已加入。随后小艺主对话测试返回「发布成功」，界面显示「取消发布」与「重新发布」，平台标注测试有效期 15 天。MateBook 仍需核对小艺 11.7.x 或更高版本与「Skill真机测试中」快捷方式，再执行正例和负例并核对 `C2OwnReceipt` 日志。[华为 Skill 真机测试](https://developer.huawei.com/consumer/cn/doc/service/skill-real-machine-testing-0000002592771628/)

用户读回小艺版本 `11.7.9.301`。USB 读回 MateBook 系统版本 `7.0.0.111(SP12C00E103R12P2)`、API 26，确认独立包 `com.skilllab.c2pc089e5768` 仍在设备上。发布后检查小艺主对话快捷区，未出现「Skill真机测试中」。约 15:06，通过 USB 在普通主对话发送 `PC7-RCPT-1113-B8N3` 的测试编号请求，随后在会话列表观察到「测试请求被拒」标题，未读到完整回复。同期日志未检出该测试码、Skill 注册名或 `C2OwnReceipt`，没有可归因于脚本的回执。

本轮定位到主对话的设备端测试入口未就绪。用户确认 MateBook 小艺当前登录的华为账号与开放平台测试白名单账号相同。再次检查开放平台，小艺主对话仍显示「取消发布」「重新发布」，选中的组为「C2 MateBook 个人真机」。USB 包管理器读回小艺版本 `11.7.9.301`，独立应用为 `debug` 签名包。重新读取可见设备日志，未检出该 Skill 的配置同步、测试组匹配、入口启用或脚本调度记录。设备端日志可见性有限，无法据此判断服务端是否已下发配置。

发布页还要求完成 HarmonyOS 7 升级报名，并以「Skill真机测试中」快捷方式验证能力已启用。页面示例列出若干手机和平板系列，并将完整支持机型指向活动详情。这台 MateBook 14 `MNT-W72C` 的具体系统构建是否具备小艺主对话应用 Skill 真机测试资格，以及该发布的配置是否已下发，需要华为平台侧确认。该普通对话尝试只记录为入口不可用时的观察，正式正例及负例待入口就绪后执行。

## MatePad 交叉验证准备

用户的 MatePad 11.5″S `TGR-W00` 已升级到 `7.0.0.111 (SP18C00E111R2P2)`，小艺版本 `11.7.8.339`。HDC 已识别到 `TGR-W00`，读回 API 26。沿用本人独立工程和 Skill，在 `deviceTypes` 中加入 `tablet`。未签名构建成功，从 HAP 的 `module.json` 核对 `2in1`、`tablet`、API 26、包名 `com.skilllab.c2pc089e5768` 和 `issueReceipt` 所在脚本路径。未签名 HAP 的 SHA-256 为 `022A59C6E7335A0B7BFD3096E325FBAF1255DC72D5C4EE795B3BE7F503F75C94`。签名副本位于 `tmp/c2-tablet-signing`，等待为平板生成个人调试签名。

用户生成个人调试签名后，将签名配置绑定到 `default` 构建产品。签名 HAP 构建成功，SHA-256 为 `123AD34F70331A2FD75257A9B04EA65ED13D71DD650B88AB04F722A6BD890BB5`。核对签名 HAP 包名、平板设备类型及 Skill 注册名后，指定 `TGR-W00` 安装并启动 `EntryAbility`。11 月 13 日 17:35:04.673，平板日志 `C2OwnReceipt` 记录 `event=app_ready`。待将同一份签名 HAP 用于小艺开放平台的平板真机测试，再核对测试入口与 `issueReceipt` 调用。

在 HarmonyOS 开发者中心打开同包名应用「测试编号回执」的「应用上架 → 应用信息」，勾选支持设备「平板」，页面返回「保存成功」。之后该页面曾出现请求未知错误，尚未独立复核重新加载后的设备设置。小艺现有 Skill 编辑页仍显示主对话测试的「重新发布」入口，平板 HAP 的平台更新与本轮重新发布仍待完成。

平台导入平板 HAP 时提示原 Skill 注册名已被使用。平板测试副本改用 `tablet-test-receipt-089e5768`，同步更新 `SKILL.md`、调用示例、目录和模块配置。新签名 HAP 的 SHA-256 为 `AC11F38EF1950F162426B7BADBFB71631886A6E72D99DB81735477C171A2F1C5`。已从包中核对新注册名及脚本路径，并在 `TGR-W00` 上更新安装。11 月 13 日 20:35:44.952，设备日志记录 `C2OwnReceipt event=app_ready`。下一步导入该签名 HAP，向本人测试组发布小艺主对话真机测试。

用户确认平板版小艺主对话真机测试发布成功。重启平板小艺后，检查主对话首屏与横向快捷方式列表，未看到「Skill真机测试中」。通过 USB 在平板小艺主对话进行了两次探测。

| 测试码 | 提示词指定的名称 | 小艺界面 | 脚本证据 |
| --- | --- | --- | --- |
| `PAD7-RCPT-1113-N5Q8` | 测试编号 | 显示「调用执行测试编号」，随后报告无法调用 | 可见日志无 `skill_entered`，无 UUID 回执 |
| `PAD7-RCPT-1113-T2M6` | `tablet-test-receipt-089e5768` | 显示「调用执行tablet-test-receipt-089e5768」，随后报告无法正常加载和执行 | 可见日志无 `skill_entered`，无 UUID 回执 |

第二次请求后，11 月 13 日 20:57:46.589，小艺日志 `HwVA_SkillListenerStub` 连续记录 `onFinish` 与 `remote is null`。这一日志未带 Skill 名称，也未暴露加载失败的具体错误码。平台侧可按设备构建、Skill 注册名与时间窗口排查测试入口下发、关联应用解析和端侧调度。C2 平板端到端验收待完成。

## 小艺 Work 安装复测

用户提供的小艺 Work 回复称，`tablet-test-receipt-089e5768.zip` 下载解压成功，安全扫描为 Benign，退出码 0，随后安装到 `~/.openclaw/workspace/skills/tablet-test-receipt-089e5768/`。Work 报告 ZIP 仅含 `SKILL.md`，未包含其声明的 `scripts/ReceiptSkill.ets`，所以本轮仅记录 Work 报告安装成功，尚无调用回执。该回复也未说明执行环境是否能通过 `ohos-arkTSScript` 调度关联的鸿蒙应用。

复核同一签名 HAP，SHA-256 与平板部署记录一致。归档内有 `skills/tablet-test-receipt-089e5768/SKILL.md` 和 `ets/modules.abc`，字节码内可检出该注册名、`ReceiptSkill`、`issueReceipt` 与 `C2OwnReceipt`。Work ZIP 内容来自用户提供的客户端报告。待平台确认 HAP 导入后生成仅含说明的 Work ZIP 是否符合预期，以及 Work 是否支持调度这类应用 Skill。[华为 ArkTS 应用 Skill 开发指导](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-skill-development-guide/)

## 工单回复后的配置复核

工单回复指出，Work 的 ZIP 安装路径无法验证已安装的 ArkTS 应用 Skill，建议回到 MatePad 主对话排查设备配置和应用侧调度。复核当前签名 HAP 的 `module.json`，模块为 `entry`，`deviceTypes` 包含 `tablet`，主组件和 `skillProfiles.abilityName` 均为 `EntryAbility`，脚本路径与 `SKILL.md` 一致，`visibility` 省略并使用文档规定的默认 `system`。[华为模块配置文档](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/module-configuration-file/)

MatePad 上 `bm dump -n` 确认包名、`EntryAbility`、`tablet`、API 26 及调试签名类型。该输出未列出 `skillProfiles`，因此没有取得系统技能注册表中的解析结果。通过普通调试 shell 也未取得安装包哈希。平台实际下发的 `availableOn` 尚未核验，HAP 的 `deviceTypes` 只确认应用模块支持设备。`remote is null` 未带 Skill 注册名或具体调度错误码，故组件连接失败仍为待验证的排查方向。[华为 Skill 开发规范](https://developer.huawei.com/consumer/cn/doc/service/skill-development-standards-0000002592931546/)

2026 年 11 月 13 日 22:14:49.114，使用同包名、同签名和同 Skill 声明的临时诊断 HAP，在 MatePad 上调用 `skillManager.getSkillInfoForSelf('entry', 'tablet-test-receipt-089e5768', GET_SKILL_INFO_WITH_SRC_ENTRIES)` 成功。系统返回 `abilityName=EntryAbility`、`visibility=system`、`srcEntries=["skills/tablet-test-receipt-089e5768/scripts/ReceiptSkill.ets"]`。查询后恢复并启动了已发布的原签名 HAP，移除了临时诊断代码。自查 API 返回的是设备包管理侧的注册信息，`SkillInfo` 没有平台侧 `availableOn` 字段。本次查询没有调用 `issueReceipt`，端到端验收待平台核对下发和调度记录。[华为 skillManager 文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-skillmanager/)

## 22:27 小艺主对话复现

截图的两条 `PAD7-RCPT-1113-A7Q2` 请求均收到加载失败回复。读取 HiLog 时未按测试码找到可关联的原始事件，随后在同一小艺主对话使用唯一注册名发送 `PAD7-RCPT-TRACE-K8V4`。发送时间为北京时间 2026 年 11 月 13 日 22:27:01，界面显示「调用执行tablet-test-receipt-089e5768」，回复称技能仍无法成功加载，未返回 UUID。复现窗口内未发现 `C2OwnReceipt event=skill_entered` 或系统 Skill 调度错误码。

设备日志摘录：

```text
11-13 22:27:18.234 MK_IntentionExecutor: processDialogFinish
11-13 22:27:18.237 HwVA_SkillListenerStub: onFinish
11-13 22:27:18.237 HwVA_SkillListenerStub: remote is null
```

`remote is null` 记录在对话结束回调，未附请求 ID、Skill 注册名或底层错误码。同期也出现小艺内部 JSON 解析失败和 `GET_TTS_IS_COMPLETE` 超时，日志未将这些事件关联到 Skill 调度。可复现的故障表现为小艺报告加载失败，应用入口无执行证据。平台需按该测试码和 22:27:01–22:27:18 的时间窗口核对实际 Skill 加载或 ArkTS 调度事件及第一个失败步骤。

后续工单回复将 AgentRuntime 连接应用组件列为排查方向，并提出 `16000050` 作为候选错误码。华为文档将该码定义为通用内部错误，公开的 `completeArkTSScriptInApp` 接口也列有该码。此前复现未捕获对应错误码或请求级关联信息。22:34 再查时，HiLog 可见缓冲区已无 22:27 复现窗口，也未发现 `16000050`、`17700093`、`17700101` 或 `skill_entered`。因此保留 22:27 的已记录摘录，AgentRuntime 组件连接、平台 `availableOn` 和实际错误码仍待请求级日志确认。[华为元能力子系统错误码](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/errorcode-ability/)

## MatePad 重启后复测

平板重启后，于北京时间 2026 年 11 月 13 日 22:41:58 开始实时采集过滤后的 HiLog，保留历史日志。22:44:16 在小艺主对话按注册名 `tablet-test-receipt-089e5768` 发送 `PAD7-RCPT-REBOOT-K6R9`。界面显示「调用执行」，随后回复技能仍然加载失败。未观察到应用的 `C2OwnReceipt event=skill_entered` 或 UUID 回执。

- 22:44:33.840，小艺 `ensureToolleryManuals` 加载 `toollery/manuals/tools/SkillLoad.json` 时报告 `Invalid relative path`。同一时段其他工具说明资源也报了相同警告。
- 22:44:35.617，小艺 `HwVA_SkillListenerStub` 再次记录 `remote is null`。本轮未捕获属于该请求的 `16000050` 或其他底层错误码。启动阶段同码日志来自桌面与定位服务。

`SkillLoad.json` 是小艺日志中的工具说明资源路径。该警告未带 C2 请求 ID，尚无法确认它直接导致本次加载失败。平台排查可优先按该测试码核对 22:44:16–22:44:36 的 SkillLoad 工具加载与后续 ArkTS 调度，并检查资源相对路径或加载上下文。过滤后的实时日志保存于 `logs/c2-independent-2026-11-12/matepad-post-reboot-K6R9.log`。
