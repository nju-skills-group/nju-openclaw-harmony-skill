# E2 原平台基线工具

[实验报告与公开证据](../../../docs/04-methodology/group-b/skill-baselines/e2/README.md)。主测 Tavily 0.2.1，备选 weather。第三方源码保持原样；运行器和验证脚本是本次交付新增内容。

## 离线核验（无需账号）

在仓库根目录运行，Python 3.10+，只使用标准库：

```powershell
python tools/skill-baseline/e2/scripts/verify-evidence.py
python tools/skill-baseline/e2/scripts/test-boundaries.py
```

第一条只读检查已归档的源码哈希和证据，不声称重新请求服务。第二条重跑 12 项隔离模拟，不发送 HTTP 请求，也不修改归档结果。

## 本机复跑（Windows PowerShell 7）

先自行安装并配置 OpenClaw。历史实验版本为 OpenClaw 2026.10.3 / Node 24.16.0；导出器依赖该版 SQLite 结构和 Node 24 内置 SQLite/Zstd。Python 3.9+ 运行目标 Skill，离线核验使用 Python 3.10+。其他 OpenClaw 版本可能需要调整 CLI 或数据库适配，未宣称兼容所有版本。

以下值均为示例，替换为你的路径/模型；不依赖提交者的 a1-week1：

```powershell
$env:E2_OPENCLAW = 'C:/your-tools/openclaw.cmd'
$env:E2_BASE_CONFIG = 'C:/your-private-config/openclaw.json'
$env:E2_PYTHON = 'C:/your-python/python.exe'
$env:E2_MODEL = 'your-provider/your-model'
```

BaseConfig 必须包含可用的 `models` 配置。Provider 的凭据若引用环境变量，须由当前进程按你原有方式注入；工具不读取或分发他人的凭据。运行器只继承 models，重新建立实验工作区、工具白名单和独立状态，不继承原工作区或聊天渠道。

先验证配置与源文件复制（不请求模型/Tavily）：

```powershell
./tools/skill-baseline/e2/scripts/run-case.ps1 -Case tavily-normal -PrepareOnly
```

输入 Tavily Key，不把它写进命令或文件：

```powershell
$e2Input = Read-Host 'Tavily API Key' -AsSecureString
$env:TAVILY_API_KEY = [System.Net.NetworkCredential]::new('', $e2Input).Password
Remove-Variable e2Input
./tools/skill-baseline/e2/scripts/run-case.ps1 -Case tavily-normal
Remove-Item Env:TAVILY_API_KEY
```

异常与备选（模型 Provider 仍须可用）：

```powershell
./tools/skill-baseline/e2/scripts/run-case.ps1 -Case tavily-invalid
./tools/skill-baseline/e2/scripts/run-case.ps1 -Case weather-normal
./tools/skill-baseline/e2/scripts/run-case.ps1 -Case weather-fallback
./tools/skill-baseline/e2/scripts/run-case.ps1 -Case weather-error
```

每次使用独立 session/config/state，输出到忽略的 `.local/<case>/<run>/`，结束时还原本进程环境变量。Tavily 正常调用为 basic 搜索，复跑会消耗相应服务/模型额度；invalid 使用合成无效值，不覆盖有效 Key。weather-error 显式注入 1 毫秒超时，不代表服务自然故障。

## 导出与验收

将运行器输出的实际目录传入：

```powershell
node tools/skill-baseline/e2/scripts/export-run.cjs '实际的私有运行目录'
```

导出候选保留在该私有目录的 export/，不会自动发布或覆盖历史证据。它过滤系统提示与推理内容，遮盖运行目录和用户目录，并检查当前环境中密钥类值；发布前仍须核对命令、响应是否含私人信息，重生成公开哈希。`CLI exit=0` 只说明 Agent 正常结束，应另看 `SCRIPT_EXITCODE`/curl 状态与实际响应。

提示词文件是脱敏的历史输入；正常运行会将 `<TAVILY_RUN_ROOT>` 等标记替换为当前运行目录。首次出错的 `tavily-normal-prompt.txt` 仅保留作历史证据，默认 Tavily 正常用例使用路径修正后的模板。

## 来源与许可

- weather：OpenClaw commit d79ab6195d8d0566b285008bcc30c01a6ce368e2，MIT，许可见 source/weather/LICENSE。
- Tavily：jacky1n7/openclaw-tavily-search@0.2.1；发布元数据声明 MIT-0，文件清单/哈希见 source/tavily/release.json。原发布版本没有独立 LICENSE 文件，未伪造作者许可文本。
- 本工具为原平台测试，不是鸿蒙移植工程；原始服务结果的引用不代表团队原创内容。
