# C2 独立回执 Skill

面向 HarmonyOS PC/2in1 和平板的 Stage 工程，使用 HarmonyOS SDK API 26。应用包名为 `com.skilllab.c2pc089e5768`，仓库中的 Skill 注册名为 `test-code-receipt-089e5768`。`ReceiptSkill.issueReceipt` 原样返回测试码，并在设备上为每次调用生成随机 UUID。

## 构建与真机测试

1. 在 DevEco Studio 打开工程根目录，选择 API 26 和 `default` 产品。连接目标 MateBook 后，在工程副本中用自己的华为开发者账号配置调试签名，确认 `default` 产品已关联签名配置。
2. 构建 `entry-default-signed.hap`。核对 HAP 的包名、`2in1`、Skill 注册名和 SHA-256。安装并打开应用，确认设备日志出现 `C2OwnReceipt` 的 `event=app_ready`。
3. 登录自己的小艺开放平台。通过「Skill → 新建 Skill → 导入 Skill」上传第 2 步的同一份签名 HAP。核对解析出的应用包名、注册名和 API 26，将显示名设为「测试编号」。[华为应用 Skill 开发指导](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-skill-development-guide/)、[导入 Skill](https://developer.huawei.com/consumer/cn/doc/service/import-skill-0000002592931542/)
4. 在真机测试面板选择通道。小艺 Work 使用平台生成的安装提示词，在 MateBook 确认 Skill 安装结果。小艺主对话需要将设备登录账号加入真机测试组、发布测试，并确认出现「Skill真机测试中」。记录测试通道与时间。[华为 Skill 真机测试](https://developer.huawei.com/consumer/cn/doc/service/skill-real-machine-testing-0000002592771628/)
5. 用不同测试码分别发送三次「请调用测试编号技能，为测试码 `DEMO-PC-A71E` 生成编号，并原样返回完整编号」。另发「什么是测试回执」作为负例。每轮记录输入、界面回复和筛选后的同轮 HiLog。每个正例应返回原测试码和不同的 UUID。

### 复现平板版本

在独立工程副本中，将 `entry/skills/test-code-receipt-089e5768` 重命名为 `tablet-test-receipt-089e5768`。同时替换该目录中 `SKILL.md` 的 `name` 和命令示例，以及 `entry/src/main/module.json5` 中的 `skillProfiles.name` 和 `srcEntries` 对应目录。保持包名与脚本实现一致。工程的 `deviceTypes` 已包含 `tablet`。用覆盖目标平板的个人调试签名重新构建，并将该份 HAP 安装到平板、导入开放平台和发布真机测试。[平板复测记录](../../../docs/experiment/c2-independent-2026-11-12.md#matepad-交叉验证准备)

## 证据判定

安装、启动、Skill 匹配、ArkTS 入口和回包分别记录。端到端通过要求同一次请求有目标 Skill 的调度证据，以及带同一个 UUID 的 `skill_entered`、`result_ready`、`result_reported` 日志，且小艺回复展示匹配的测试码和 UUID。`report_failed` 表示脚本进入后上报失败。负例预期没有目标脚本入口事件。

签名配置、私钥、证书、用户组账号和设备标识保留在本机或对应平台。可提交工程源文件和筛选后的实验日志。
