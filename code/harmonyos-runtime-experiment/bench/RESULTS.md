# D0 / D1 Skill 运行时对比 —— 实测结果（真机）

测量日期 2026-11-04，两轮完整运行。原始日志见 `raw-2026-11-04.txt`（第一轮）与 `raw-2026-11-04b.txt`（第二轮，含内存/异常用例），均为 `hilog -x` 过滤 tag `BenchD`。

## 环境

| 项 | 值 |
| --- | --- |
| 设备 | HarmonyOS PC 真机，hdc target `86E0226903001563`，屏幕 2880x1920 |
| 系统 | HarmonyOS MNT-W72C 7.0.0.111(SP12C00E103R12P2)，机型 MNTXM-24B |
| SDK | OpenHarmony-7.0.0.109，`const.ohos.apiversion` = 26，targetSdkVersion 26.0.0 |
| IDE | DevEco Studio 26.0.0.201（versionCode 2600201），运行在设备本机 |
| 构建 | hvigor modelVersion 26.0.0，由 IDE 调用 |
| Bundle | `com.example.myapplication`，签名配置 `default1` |
| HAP | 第一轮 202474 B（15:39）；第二轮 215841 B（16:04，含内存/异常用例） |
| 业务负载 | `benchWork(50000)`：LCG 填充 int 数组 → 升序 sort → 取模累加，checksum=**33762218** |
| 对照 | PC 上 node 跑同一 JS：15 ms（仅作量级参考，不计入对比） |

## 分组

- **D0**：ArkTS Skill 入口 + ArkTS 业务逻辑（`entry/src/main/ets/bench/BenchWork.ets`）
- **D1**：ArkTS Skill 入口 + 本地 WebView/ArkWeb 页面里的 JS 业务逻辑（`entry/src/main/resources/rawfile/bench.html`，`controller.runJavaScript('benchRun(50000)')`）

两组同一算法、同一规模、同一 checksum 校验、同一设备与签名。

## 结果（热路径，30 有效样本/组，全部 ok，checksum 全一致）

第二轮（16:08）：

| 指标 | D0 ArkTS | D1 WebView JS |
| --- | --- | --- |
| total 中位数 | **79 ms** | **22 ms** |
| total P95 | 94 ms | 23 ms |
| total 区间 | 78–99 ms | 21–24 ms |
| biz 中位数（业务函数内） | 79 ms | 21 ms |
| bridge 中位数 / 最大 | 0（同进程直调） | 1 / 3 ms |
| 成功率 | 30/30 | 30/30 |

第一轮（15:41）：D0 中位数 78 / P95 80 / 区间 78–86；D1 中位数 22 / P95 23 / 区间 21–23。

D1 的离散度始终 ≤3 ms，D0 在两轮之间抖动更大（P95 80 → 94）。3.5–3.6x 的比值在两轮中一致。

## 冷路径

| 指标 | 值 |
| --- | --- |
| WebView **冷加载**（创建 Web 组件 → 本地页 `onPageEnd`） | **362 ms** |
| 页面自身加载（`onPageBegin` → `onPageEnd`） | 9–10 ms |
| 应用启动 → 页面可交互 | 348 ms（第一轮）/ 6491 ms（第二轮，含 MEM5 定时器） |
| 首次调用（coldcall，从点击起算） | 第一轮 total 38 / biz 34 / bridge 4；第二轮 total 37 / biz 33 / bridge 4 |
| 预热样本（第 2–4 次） | 23 / 31 / 23 ms（D1），90–105 ms（D0） |

**更正**：先前报告「WebView 冷加载 9 ms」有误，9–10 ms 只是页面自身的 `onPageBegin→onPageEnd`。把 Web 组件创建时刻（`MEM|stage=create` 时间戳）与 `MEM|stage=loaded` 相减，实际冷加载 **362 ms**，其中约 350 ms 是 ArkWeb 引擎组件初始化。

## 内存（5 时点，PSS）

采样：外部后台循环 `hdc shell "hidumper --mem <pid>"`，每 ~150 ms 取一次 `Total` PSS；时点由应用内 `MEM|stage=` 打点对齐。

| 时点 | 打点 | PSS |
| --- | --- | ---: |
| 应用基线（Web 未创建） | `MEM\|stage=baseline` | **40185 kB ≈ 40.2 MB**（启动瞬间 42928 kB） |
| WebView 创建中 | `MEM\|stage=create` → `created` | 61464 kB ≈ 61.5 MB（过渡态，仅约 0.5 s） |
| 页面加载后空闲 | `MEM\|stage=loaded` | **96727 kB ≈ 96.7 MB** |
| 调用峰值（300 次连续 D1 调用中） | `MEM\|stage=peaked` | **97066 kB ≈ 97.1 MB**（较加载后 +0.34 MB） |
| 空闲 10 s 后 | `MEM\|stage=restore` | **96525 kB ≈ 96.5 MB**（不回落） |

结论：WebView 的固定成本 ≈ 56 MB（40.2 → 96.7），一次性支付，与调用次数无关；300 次调用的瞬时增量仅 0.3 MB；引擎不随空闲释放。

## B3 异常路径（6 用例，`ERR` 按钮）

| 用例 | 观测 | 说明 |
| --- | --- | --- |
| `no_page` 未加载页面就调用 | Handled（reject） | 未绑定 controller 时 ArkWeb 正确 reject |
| `bridge_error` 调用不存在的 JS 函数 | **Unhandled（resolve）** | `runJavaScript` 不 reject |
| `js_throw` 页面内 `throw new Error` | **Unhandled（resolve）** | `runJavaScript` 不 reject |
| `bad_format` 返回非 `checksum,ms` 字符串 | Handled（返回校验拦截） | 值 `"not-a-valid-pair"` |
| `timeout` 页面忙等 3 s，调用方 1 s 放弃 | Handled（`aborted at 1000ms`） | `Promise.race` 生效 |
| `normal` 正常调用 | Handled（len=13） | 对照组 |

**关键发现：ArkWeb 的 `runJavaScript` 在 JS 抛错、函数不存在时仍会 resolve。** 因此桥接层不能只包 `try/catch`，必须校验返回值格式与内容；超时也必须由调用方自己兜（`Promise.race`）。

## 系统链路总延迟（Agent/用户发起 → 结果返回）

**未测**，且当前环境不具备测量条件：

- 设备无 `ohos-arkTSScript` CLI（桥接 shell 与 `/usr/bin` 均无；`/system/bin` 权限拒绝），无法在本地发起 Skill 调用。
- 从小艺触发：真机小艺已按引导启用并正常应答（`hello` → 有回复），但两次明确询问「调用 echo 技能」「调用 harmonyos-skill-echo 技能」均答复 **「我这边没有名为 … 的技能」**，未产生任何 Skill 侧 hilog。
- 结论：自装应用的 `skillProfiles` 在当前真机上未被小艺索引。这与模拟器上的既往结论一致（可见调用入口缺失），本次在真机上复现。

## 结论

1. 同一业务负载下，**WebView 内 JS 比 ArkTS 快 3.5 倍**（79 ms → 22 ms）。剔除桥接后 biz 比值 3.6x，桥接 1–2 ms 不是瓶颈。
2. 桥接开销稳定在个位数毫秒，冷启动也只有 4 ms，不构成"跨语言调用慢"的证据；真正的墙是返回语义——**JS 侧异常不会以 reject 形式传回**。
3. D1 的固定成本：WebView 冷加载 362 ms、内存 +56 MB；调用期增量可忽略。
4. ArkTS 慢的这一档很可能来自 `number[]` 装箱与 `sort` 比较器开销，不是编译型 vs 解释型的差别。要坐实需换成 TypedArray 变体再测一轮（未做）。

## 复现

```
hdc shell hilog -r
hdc shell aa force-stop com.example.myapplication
hdc shell aa start -a EntryAbility -b com.example.myapplication
hdc shell "uitest uiInput click 1305 460"   # MEM5：内存 5 时点（约 9 s）
hdc shell "uitest uiInput click 1521 375"   # D1 x30（首个 coldcall + 3 预热 + 30 热）
hdc shell "uitest uiInput click 1359 375"   # D0 x30（3 预热 + 30 热）
hdc shell "uitest uiInput click 1589 460"   # ERR：6 个异常用例
hdc shell "uitest uiInput click 1454 460"   # PEAK：300 次调用峰值
hdc shell "hilog -T BenchD -x"              # 缓冲只保留 8–10 s，需在每阶段后立即读取
```

`stats.ps1` 可直接对导出的日志算中位数/P95/成功率；内存时点用 `MEM|stage=` 行的 epoch 时间戳与采样序列对齐。

## 已知限制

- **计时边界**：测得的是「按钮点击 → 结果返回」，不是「Skill 入口 → `completeArkTSScriptInApp`」。后者需要系统调度器真正调用 Skill，本机无法触发（见上）。
- 系统链路总延迟、模拟器对照组未测。
- 单机、单轮协议内每条件 30 样本；D0 在两轮之间 P95 有 80 → 94 的抖动，说明 ArkTS 侧受系统负载影响更明显。
- 计时用 `Date.now()`（ms 精度），业务耗时 21 ms 时量化误差约 5%。
- 内存采样为外部 150 ms 轮询，过渡态（WebView 创建中）只能给出一个近似值。
