# D0 / D1 Skill 运行时对比 —— 实测结果（真机）

测量日期 2026-11-04。数据为单次完整协议运行的原始样本，日志见 `raw-2026-11-04.txt`（`hilog -x` 过滤 tag `BenchD`）。

## 环境

| 项 | 值 |
| --- | --- |
| 设备 | HarmonyOS PC 真机，hdc target `86E0226903001563`，屏幕 2880x1920 |
| 系统 | HarmonyOS MNT-W72C 7.0.0.111(SP12C00E103R12P2)，机型 MNTXM-24B |
| SDK / API | targetSdkVersion 26.0.0，compatibleSdkVersion 26.0.0；运行时 `const.ohos.apiversion`=26，`const.ohos.fullname`=OpenHarmony-7.0.0.109 |
| DevEco Studio | 26.0.0.201（装在设备本机，非 Windows），`bm dump` versionCode 2600201 |
| Hvigor | 随 IDE 打包，`hvigor-config.json5` modelVersion 26.0.0 |
| 构建 | hvigor 由 IDE 调用，`/data/service/hnp/hmos-clt.org/.../hvigorw.js` |
| Bundle | `com.example.myapplication`，签名配置 `default1` |
| HAP | `entry-default-signed.hap` 202474 B，2026-11-04 15:39 构建 |
| 业务负载 | `benchWork(50000)`：LCG 填充 int 数组 → 升序 sort → 取模累加，checksum=**33762218** |
| 对照 | PC 上 node 跑同一 JS：15 ms（仅作量级参考，不计入对比） |

## 分组

- **D0**：ArkTS Skill 入口 + ArkTS 业务逻辑（`entry/src/main/ets/bench/BenchWork.ets`）
- **D1**：ArkTS Skill 入口 + 本地 WebView/ArkWeb 页面里的 JS 业务逻辑（`entry/src/main/resources/rawfile/bench.html`，`controller.runJavaScript('benchRun(50000)')`）

两组同一算法、同一规模、同一 checksum 校验、同一设备与签名。

## 结果（热路径，30 有效样本/组，全部 ok，checksum 全一致）

| 指标 | D0 ArkTS | D1 WebView JS | 比值 |
| --- | --- | --- | --- |
| total 中位数 | **78 ms** | **22 ms** | 3.5x |
| total P95 | 80 ms | 23 ms | — |
| total 区间 | 78–86 ms | 21–23 ms | — |
| biz 中位数（业务函数内） | 78 ms | 21 ms | 3.7x |
| bridge 中位数 / 最大 | 0（同进程直调） | 1 / 2 ms | — |
| 成功率 | 30/30 | 30/30 | — |

D1 拆解：total 22 ms ≈ biz 21 ms + bridge 1 ms，桥接开销约占 5%。

## 冷路径

| 指标 | 值 |
| --- | --- |
| WebView 页面加载（`onPageBegin`→`onPageEnd`，本地 rawfile） | **9 ms** |
| 从 aboutToAppear 到页面可交互 | 348 ms |
| 首次调用（coldcall，从点击起算） | total 38 ms / biz 34 ms / bridge 4 ms |
| 预热样本（第 2–4 次） | 24 / 31 / 23 ms |

首次调用比稳态慢约 16 ms（biz 34 vs 21），为 JS 引擎 JIT 预热成本；3 条预热后进入稳态。

## 内存

`hidumper --mem` 采到的应用 PSS：页面加载并空闲后 **92021 kB（≈90 MB）**。

未采到的点：应用基线（WebView 创建前）、调用峰值。原因是本工程在 `build()` 里直接创建 Web 组件，页面在 348 ms 内就加载完，外部采样抓不到 WebView 创建前的窗口，峰值窗口仅约 0.7 s。补齐需要应用内埋点（`process.getMemoryInfo`）。

## 结论

1. 同一业务负载下，**WebView 内 JS 比 ArkTS 快 3.5 倍**（78 ms → 22 ms）。剔除桥接后 biz 比值 3.7x，桥接 1–2 ms 不是瓶颈。
2. 桥接开销稳定在个位数毫秒，冷启动也只有 4 ms，不构成"跨语言调用慢"的证据。
3. 代价在冷启动：页面加载 9 ms 可接受，但首次调用多 16 ms；且 D1 额外需要一个 Web 组件与页面资源。
4. ArkTS 慢的这一档很可能来自 `number[]` 装箱与 `sort` 比较器开销，不是编译型 vs 解释型的差别。要坐实需换成 TypedArray 变体再测一轮（未做）。

## 复现

```
hdc shell hilog -r
hdc shell aa force-stop com.example.myapplication
hdc shell aa start -a EntryAbility -b com.example.myapplication
# 等页面 ready（约 0.4 s 后 LOAD 行出现）
hdc shell "uitest uiInput click 1521 375"   # D1 x30（首个样本 coldcall + 3 预热 + 30 热）
hdc shell "uitest uiInput click 1359 375"   # D0 x30（3 预热 + 30 热）
hdc shell "hilog -x" | grep BenchD
```

`stats.ps1` 可直接对导出的日志算中位数/P95/成功率。

## 已知限制

- 单次运行、单台真机；未做多轮重复（每组 30 样本内变异很小：D0 ±1 ms，D1 ±1 ms）。
- 计时用 `Date.now()`（ms 精度），业务耗时 21 ms 时量化误差约 5%。
- **计时边界偏差**：本次两组都是“页面按钮点击 → 结果打印”，未从小艺触发 Skill，因此不含“Skill 入口开始 → `completeArkTSScriptInApp` 上报”这一段的系统调用开销。两组偏差同向，比值仍可比，但绝对值不等于 Skill 执行耗时。
- 系统链路总延迟（Agent 发起→结果返回）**未测**：Skill 需要从小艺触发。按实验方案，该项只在实际测到系统链路时才填写。
- 内存 5 点只拿到 1 点（应用基线、WebView 创建后、调用峰值、空闲恢复后未采）。
