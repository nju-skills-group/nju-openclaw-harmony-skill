---
name: example-org-music-assistant
description: 提供本地示例曲库的歌曲查询、播放状态模拟与播放控制；不连接真实音乐服务。
---

## 触发场景

当用户明确要求从示例曲库按歌名或歌手查找歌曲，或控制当前模拟播放状态时调用。

典型话术：
- “播放 SongA”
- “播放 SingerA 的歌”
- “暂停播放”
- “继续播放”
- “下一首”
- “上一首”

不调用的情况：
- 用户要求搜索在线音乐、登录音乐服务、购买歌曲或访问真实播放列表。
- 用户要求收藏、下载、分享歌曲；本示例没有实现这些能力。
- 用户只在讨论歌曲，不要求播放或控制。

### 场景 1：按名称播放（playMusicByName）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'example-org-music-assistant' --scriptPath 'scripts/MusicSkill.ets' --functionName 'playMusicByName' --args '{
  "arg1": "SongA",
  "arg2": "SingerA"
}')
```

参数 Schema：

```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": { "type": "string", "description": "歌曲名" },
      "arg2": { "type": "string", "description": "歌手名" }
    },
    "anyOf": [
      { "required": ["arg1"] },
      { "required": ["arg2"] }
    ]
  }
}
```

执行返回值成功示例：

```json
{
  "type": "result",
  "status": "success",
  "data": {
    "playingTrack": { "name": "SongA", "singer": "SingerA", "duration": 269 },
    "matchedCount": 1,
    "playback": "playing"
  }
}
```

执行返回值失败示例：

```json
{
  "type": "result",
  "status": "failed",
  "errCode": "ERR_NOT_FOUND",
  "data": { "searchedKeywords": ["MissingSong", "UnknownSinger"] },
  "suggestion": "没有找到相关歌曲"
}
```

### 场景 2：播放控制（controlPlayback）

#### 执行参数

```text
exec-cli(command: ohos-arkTSScript --skillName 'example-org-music-assistant' --scriptPath 'scripts/MusicSkill.ets' --functionName 'controlPlayback' --args '{
  "arg1": "pause"
}')
```

参数 Schema：

```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": {
        "type": "string",
        "enum": ["pause", "resume", "next", "previous"],
        "description": "暂停、继续、下一首或上一首"
      }
    },
    "required": ["arg1"]
  }
}
```

执行返回值成功示例：

```json
{
  "type": "result",
  "status": "success",
  "data": {
    "action": "pause",
    "status": "paused",
    "playingTrack": { "name": "SongA", "singer": "SingerA", "duration": 269 }
  }
}
```

执行返回值失败示例：

```json
{
  "type": "result",
  "status": "failed",
  "errCode": "ERR_NOT_FOUND",
  "errMsg": "There is no active track",
  "suggestion": "请先选择一首歌曲再控制播放。"
}
```
