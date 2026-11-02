# HarmonyOS 应用 Skill：音乐助手示例

本目录将华为官方《基于 ArkTS 脚本的应用 Skill 开发指导》中的音乐助手模式整理为可拷入项目的示例文件。目录及接口命名沿用官方示例；`MusicPlayer.ets` 是本仓库补充的内存曲库演示服务，**不播放真实音频**。

## 文件

```text
entry/
├── skills/example-org-music-assistant/
│   ├── SKILL.md
│   └── scripts/MusicSkill.ets
└── src/main/ets/service/MusicPlayer.ets
```

在目标 HarmonyOS 工程中复制以上文件到对应位置，然后把下面的 Skill 配置合并到 `entry/src/main/module.json5` 的 `module.skillProfiles` 数组：

```json5
{
  "name": "example-org-music-assistant",
  "abilityName": "EntryAbility",
  "srcEntries": [
    "../../skills/example-org-music-assistant/scripts/MusicSkill.ets"
  ],
  "version": "1.0.0"
}
```

不要用此片段覆盖现有模块配置。名称须与目录名、`SKILL.md` frontmatter 一致；`abilityName` 改成工程内真实 Ability 名称。

## 本示例覆盖的接口

- `playMusicByName(info, ...argv)`：`arg1` 为歌名，`arg2` 为歌手；至少提供一个。
- `controlPlayback(info, ...argv)`：`arg1` 为 `pause`、`resume`、`next` 或 `previous`。
- 返回统一通过 `scriptManager.completeArkTSScriptInApp` 上报。

## 限制

- 它是 API 26+、Stage 模型的应用 Skill 示例，不是小艺开放平台的 Vibe Skill 包。
- 当前 `MusicPlayer.ets` 只模拟曲库匹配与播放状态，不接入媒体服务、网络或真实音频。
- 构建 HAP 不等于系统智能体已发现/调用 Skill；运行时调用仍需目标环境验证。

## 官方来源

- [基于 ArkTS 脚本的应用 Skill 开发指导](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-skill-development-guide)
- [HarmonyOS Skill 格式与接口说明](../../../docs/03-environment/Group_A/harmonyos-app-skill-format-and-api.md)
