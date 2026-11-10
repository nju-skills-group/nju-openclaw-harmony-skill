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

## 4. 结果

| 项目 | 实测结果 |
|---|---|
| 构建 | `BUILD SUCCESSFUL in 3 s 836 ms`（增量构建） |
| 应用启动 | 成功，2 s 160 ms |
| 页面加载 | 显示 `ArkWeb JavaScript runtime ready` |
| 功能测试 | `6/6 tests passed` |
| 结论 | 本地 ArkWeb 页面 JavaScript 可通过 ETS 桥接完成同等业务功能 |

## 5. 关键限制

B3 依赖 Web 组件和页面生命周期：控制器必须已经绑定且页面加载完成。若系统在应用页面尚未创建时直接调度 Skill，当前桥接会返回 `ERR_WEB_NOT_READY`。因此本实验只能证明应用内 ArkWeb 形态可运行，不能证明它适合无界面的后台 Skill，也不能证明系统小艺/Agent 冷启动调用成功。

此外，本次只做正确性验证，没有执行 30 次延迟采样、冷/热调用分离或内存测量。
