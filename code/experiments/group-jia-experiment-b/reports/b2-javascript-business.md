# B2 实验报告：ETS 入口调用 JavaScript 业务层

## 1. 实验信息

入口保持 `JsonToolkitSkill.ets`，业务实现切换为 `JsonToolkitServiceJs.js`。输入、预期输出、模拟器和 Skill 注册均与 B0 相同。

## 2. 实施过程

1. 新增普通 JavaScript 业务模块，实现相同的五类 JSON 操作。
2. ETS 入口和自测页面导入该 JS 模块。
3. 为 ArkTSCheck 增加 `JsonToolkitServiceJs.d.ts`，只描述类型，不承载业务逻辑。
4. 清理构建后在模拟器执行六项测试。

## 3. 兼容性问题

### 3.1 JS 动态字段缺少 ArkTS 静态类型

直接导入时，ArkTSCheck 报告 `result`、`valid`、`jsonType`、`itemCount`、`size` 和 `errorCode` 等属性不存在。原因是 ArkTS 无法从普通 JS 动态对象完整推断类型。增加同名 `.d.ts` 类型契约后红色错误消失。

### 3.2 ArkTS Kit 导入不能直接照搬到普通 JS

JS 初版使用 `import { util } from '@kit.ArkTS'`。应用能够启动，format 和 minify 通过，但执行 validate 时出现模块导出错误，结果为 `2/6 tests passed`。尝试旧式 `@ohos.util` 后仍观察到相同运行时模块错误。最终删除平台 util 依赖，用纯 JavaScript 实现 UTF-8 字节数计算，完整清理构建后通过。

## 4. 最终结果

| 项目 | 实测结果 |
|---|---|
| 最终构建 | `BUILD SUCCESSFUL in 11 s 142 ms` |
| 最终应用启动 | 成功，2 s 400 ms |
| 最终功能测试 | `6/6 tests passed` |
| 结论 | ETS 入口可调用普通 JS 业务层，但需要显式类型契约并避开不兼容的 ArkTS 专用导入形式 |

## 5. 限制

本结果证明普通 JS helper 的应用内运行，不代表 `.js` 可直接注册为 `skillProfiles.srcEntries`。系统 Skill 调度仍未验证。
