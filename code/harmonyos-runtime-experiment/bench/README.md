# 性能对比实验（任务 D）

对应 `docs/experiment/harmony-skill-experiment-record.md` 的 D 节与
`docs/harmonyos-skill-runtime-comparison-plan.md` 第 7 节。

## 两组

| 组 | 形态 |
|---|---|
| D0 | ArkTS Skill 入口 + ArkTS 业务逻辑 |
| D1 | ArkTS Skill 入口 + WebView 页面内 JS 业务逻辑 |

同一个业务：`benchWork(n)`，n = 50000，伪随机填充 + 排序 + 校验和。
两份实现逐行一致：

- ArkTS：`entry/src/main/ets/bench/BenchWork.ets`
- JS：`entry/src/main/resources/rawfile/bench.html`

基准校验和（Node 运行同一算法）：**33762218**。
两组都必须得到该值，否则说明实现不一致，数据不可用。

## 计时边界

| 指标 | 起点 → 终点 |
|---|---|
| total | D0：业务函数调用前后；D1：`runJavaScript` 调用前后（含桥接）；冷调用样本从 `aboutToAppear` 起算 |
| biz | 业务函数内部，业务函数前后的 `Date.now()`（D1 由页面内测量后随返回值带回） |
| bridge | D1 的 total − biz |
| load | `onPageBegin` → `onPageEnd`，仅冷加载样本有效 |

`total` 是"Skill 执行耗时"的代理量，**不是**系统链路总延迟。
小艺当前匹配不到该 Skill，系统链路总延迟记"未测"。

## 运行

1. 构建并安装：`hvigorw assembleHap`，`hdc install -r entry/build/default/outputs/default/entry-default-signed.hap`
2. 打开应用，等页面出现 `page loaded`。
3. 冷调用：先杀进程（`hdc shell aa force-stop com.example.myapplication`），重开应用，点 `D1 x30`。
   第一条 `coldcall` 样本即冷样本；随后 3 条 `warmup` 丢弃，剩 30 条 `hot` 有效样本。
4. 热调用：同一进程内再点 `D0 x30`、`D1 x30`，各得 30 条 `hot`。
5. 拉日志与统计：

```powershell
powershell -ExecutionPolicy Bypass -File bench\collect.ps1 -Hdc "C:\Users\21297\OneDrive\Desktop\工作环境\tool\hdc.exe" -Out bench\d0d1-log.txt
powershell -ExecutionPolicy Bypass -File bench\stats.ps1
```

## 日志格式

```
SAMPLE|D0|hot|seq=1|total=42|biz=42|bridge=0|load=0|checksum=33762218|ok=1
SAMPLE|D1|coldcall|seq=0|total=1180|biz=31|bridge=14|load=612|checksum=33762218|ok=1
LOAD|D1|load=612|fromStart=980
ERR|D1|<json>
```

`stats.ps1` 输出每组的中位数、P95、成功率与校验和一致性。

## 采样要求

- 真机与模拟器分开统计，不混合。
- 冷样本与热样本分开报告，预热样本（`warmup`）不计入。
- 每组 ≥ 30 条有效样本；失败/超时单独记录，不丢弃。
- 结论须注明设备型号、HarmonyOS 版本、SDK/API、DevEco 版本、Hvigor 版本、工程 commit。
