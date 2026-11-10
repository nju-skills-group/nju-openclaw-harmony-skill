# B3 实验报告：ETS 入口调用 ArkWeb 页面 JavaScript

## 1. 实验信息

`.ets` Skill 入口保持不变。JSON Toolkit 业务逻辑放入本地 `rawfile/json_toolkit_web.html`，ETS 侧通过 `WebviewController.runJavaScript()` 调用页面函数。

## 2. 架构

```text
JsonToolkitSkill.ets / Index.ets
            |
            v
JsonToolkitWebRuntime.ets
            |
            v
WebviewController.runJavaScript()
            |
            v
json_toolkit_web.html -> window.JsonToolkit.execute()
```

桥接请求和返回值均序列化为 JSON。页面返回失败信封时，ETS 桥接层转换为统一的 `JsonToolkitError`。

## 3. 步骤

1. 创建本地 ArkWeb HTML 和等价 JavaScript 业务逻辑。
2. 创建 `JsonToolkitWebRuntime.ets`，保存控制器、页面就绪状态并负责调用和结果校验。
3. Skill 入口改为异步调用该桥接对象。
4. 应用页面加载本地 HTML；`onPageEnd` 后启用测试按钮。
5. 执行与 B0-B2 相同的六项测试。
6. 记录页面加载时间、桥接调用次数及单次桥接耗时。
7. 分别验证页面未加载、控制器未绑定、页面 JavaScript 抛错、返回值损坏和执行超时五条异常路径。

## 4. 结果

| 项目 | 实测结果 |
|---|---|
| 构建 | 增量构建 `3 s 836 ms`；最终全量重编译 `18 s 581 ms` |
| 应用启动 | 成功，2 s 160 ms |
| 页面加载 | 显示 `ArkWeb runtime ready`，实测 2051 ms |
| 功能测试 | `6/6 tests passed` |
| 桥接统计 | 6 次调用，平均 3.17 ms，最后一次 3 ms |
| 异常路径 | `5/5 failure paths handled` |
| 结论 | 本地 ArkWeb 页面 JavaScript 可通过 ETS 桥接完成同等业务功能 |

异常路径的标准化结果如下：

| 场景 | 结果 |
|---|---|
| 页面尚未加载 | `ERR_WEB_NOT_READY` |
| WebviewController 未绑定 | `ERR_WEB_BRIDGE` |
| 页面 JavaScript 抛错 | `ERR_WEB_BRIDGE` |
| 页面返回值格式损坏 | `ERR_WEB_RESPONSE` |
| 页面执行超过 1000 ms | `ERR_WEB_TIMEOUT`，实测约 1005 ms |

页面 JavaScript 抛错时，ArkWeb 曾以 `undefined` 作为拒绝值传播，无法直接读取错误对象。最终在 `runProbe()` 最外层建立异常契约边界，将所有非 `JsonToolkitError` 统一转换为 `ERR_WEB_BRIDGE`，从而避免平台异常形态泄漏给调用方。

## 5. 关键限制

B3 依赖 Web 组件和页面生命周期：控制器必须已经绑定且页面加载完成。若系统在应用页面尚未创建时直接调度 Skill，当前桥接会返回 `ERR_WEB_NOT_READY`。因此本实验只能证明应用内 ArkWeb 形态可运行，不能证明它适合无界面的后台 Skill，也不能证明系统小艺/Agent 冷启动调用成功。

本次性能数据仅为一次页面加载和六次桥接调用的观测值，没有执行 30 次重复采样、冷/热调用分离或内存测量，不能作为不同运行形态的性能排名依据。
