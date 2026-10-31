# 第二阶段 · 丙组 SkillVM 评估与开源成果入口

> **状态：工作基线 / 待认领。** 这是丙组研究与交付的持续导航，不是已经完成的研究报告。当前的成果文件为待填写框架，乙组静态样本不等于已成功移植的 Skill。

## 从这里开始

1. **[协作与使用指南](GUIDE.md)**：必须先读，了解如何参与同一最终成果、认领工作包、提 PR 及共同验收。
2. **[计划、参考工作包与认领表](plan.md)**：正式交付范围、6 个可调整工作包、成果协调人/包负责人空栏、里程碑、完整验收要求。
3. [全仓库 Git 工作流](../../05-protocols/git-workflow.md) · [乙组普查 PR #13](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/pull/13) · [【Skill 发布仓库】openclaw-skills-for-harmony](https://github.com/nju-skills-group/openclaw-skills-for-harmony)

## 四项正式成果（完成状态以完整交付为准）

| 最终成果 | 唯一成果入口 | 当前状态 | 已合并内容 / 验收证据 | 下一步/依赖 |
| --- | --- | --- | --- | --- |
| **C-1** 技术机制对比表 | [SkVM / SkCC / SkillSmith 机制比较](research/mechanism-comparison.md) | 未完成；框架待认领 | 待 PR/证据 | 共同完成对比表并经审查；向乙组反馈结论 |
| **C-2** 《SkillVM 覆盖率评估报告 v1.0》 | [统一评估报告](evaluation/coverage-evaluation-v1.md) | **v1.0 已定稿（2026-10-31），待 C-2A 共同签署**；四类证据中静态 9/9、工具链 5/9 有据，原平台基线（缺模型凭证）与目标运行（缺入口/设备/E7）记未测/阻断，27 个用例 0 执行 | [C-2A 方法协议](evaluation/c-2a-method-v1.md) 及三份附件、[C-2B 预注册](evaluation/c-2b-preregistration-v1.md)、[C-2B 批次 01](evaluation/c-2b-toolchain-batch01.md)、[C-2B 批次 02](evaluation/c-2b-batch02-baseline-and-provenance.md)、[C-2B 批次 03](evaluation/c-2b-toolchain-batch03.md)、[C-2B 批次 04](evaluation/c-2b-batch04-static-and-fixtures.md)、[未完成项台账](evaluation/c-2b-open-items-v1.md)、[`code/skill-vm/`](../../../code/skill-vm/README.md) | 待 C-2A 签 P1、裁 P7、冻 P8；待组内定 provider；待甲组入口与 E7；待乙组轨迹。逐项见台账 |
| **C-3** SkillIR 规范草案 | [统一 SkillIR 草案](ir/skill-ir-v0.md) | 未完成；框架待认领 | 待 PR/证据 | 核定语义、目标绑定及代表示例 |
| **C-4** 开源仓库与首批 5 个 Skill | [【发布仓库】openclaw-skills-for-harmony](https://github.com/nju-skills-group/openclaw-skills-for-harmony) | **尚未验收**；创建基线时仓库空白 | 待发布仓库 PR/调用证据 | C-4A 骨架/导入工具可先做；C-4B 等乙组 Skill 与甲组目标环境 |


## 进度与使用方式

- 认领前先和**同一最终成果**的其他组员确定范围、协作方式和成果协调人，并填写 [`plan.md`](plan.md) 中的两层认领表。
- 成员可以在工作包 PR 中合并阶段性结果，但更新本页时应注明“阶段性已合并 / 未完成最终验收”，附 PR 或实验记录。
- 所有参与者共同确认最终文档或发布结果满足 [`plan.md`](plan.md) 的完整验收标准后，成果协调人再将本表改为“已验收”，并附能核实的 PR、版本与证据。
- 如果因甲乙组依赖而未达标，准确写“未测/阻断”和需要的输入，不采用猜测性的通过状态。

## 可以直接利用的第一阶段成果

- [OpenClaw Skill 生命周期源码地图](../../02-research/openclaw-skill-lifecycle-source-map.md)；[鸿蒙 Skill 接入契约 v1.0](../Group_C2/harmony-skill-contract.md)（目标调用细节仍需甲组实测确认）。
- [Skill VM 论文笔记](../../02-research/papers/2026-chen-skillvm.md)、[SkillOpt](../../02-research/papers/2026-yang-skillopt.md)、[SkillAdaptor](../../02-research/papers/2026-yu-skilladaptor.md)、[SkillGuard](../../02-research/papers/2026-pan-skillguard-permission.md)、[Harnessing Agent Skills](../../02-research/papers/2026-xia-skill-harnessing.md)、[Gorilla](../../02-research/papers/2024-patil-gorilla-api-calling.md)。SkCC / SkillSmith 参考原论文或官方实现并固定所用版本。
- [乙组普查 PR #13](https://github.com/nju-skills-group/nju-openclaw-harmony-skill/pull/13)：引用固定提交 `126d80d5507293af800e7fafe538a772b16e4f21`，包含源码静态分类候选和 L3 卡点，不是已完成移植样例。

## 双仓库界限

**研究仓库（本仓库）** 保存 C-1/C-2/C-3 正式成果及实验依据；仅在实际需要复现脚本时使用 `code/skill-vm/`，不要求单独自研 VM。**【发布仓库】** 仅提供经审核的 Skill、必要导入工具和面向用户的指南。C-4 验收目标是外部开发者依照 README 三步以内完成导入与实际调用；乙组真实样例和甲组运行证据不到位时，不得把占位 Skill 宣布为通过。
