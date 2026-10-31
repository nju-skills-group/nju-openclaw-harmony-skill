# C-2B 批次 05：三条故障分支的演练

> 类型：**演练（fixture dry-run）**，不是用例执行。日期 2026-10-31（UTC 07:08），位置 WSL2 Ubuntu 20.04。
> 起因：P1 预算经 C-2A 口头确认后，先验证"夹具 + 参考客户端"能否在预算内得到**有界失败**，避免等到有凭证/设备时才发现夹具或预算不成立。
> 结论：三条分支全部可起跑并有界失败（10.03s / 0.01s / 0.011s）；同时独立复现了原平台判定的 `jq` 缺失。**本次不产生任何用例判定。**

## 1. 这次演练是什么、不是什么

| | |
| --- | --- |
| 是 | 夹具能起跑；预算（T_timeout）可观察；失败是**有界**的（不会挂到天荒地老）；参考客户端能拿到可判读的错误 |
| 不是 | OpenClaw 的 Skill 调用行为；鸿蒙侧任何行为；27 个用例的通过/失败；"原平台基线"或"目标运行"证据 |

参考客户端取的是**源 `SKILL.md` 里写的命令形状**（weather 的 curl 回退、trello 的 `curl`+`jq`、MCP 的 stdio 握手），用它替身"被测端"，因为本机既无模型凭证也无鸿蒙入口。**参考客户端 ≠ OpenClaw ≠ ArkTS**，因此本文件的任何数字都不得抄进用例记录。

## 2. 结果

| 分支 | 参考客户端 | T_timeout | 观测 | 演练判定 |
| --- | --- | --- | --- | --- |
| S04-03a 超时服务 | `curl --fail --silent --show-error --max-time 10 <夹具>/v1/current` | 10s（容差 +5s） | 退出码 **28**（`CURLE_OPERATION_TIMEDOUT`），耗时 **10.03s**，stderr：`Operation timed out after 10019 milliseconds with 0 bytes received` | 有界失败成立 |
| S05-02 无效凭据 | `curl -s -o body -w '%{http_code}' '…?key=***&token=***'` | 30s | HTTP **401**，耗时 **0.01s**；响应体不含哨兵令牌（`leaked=False`）；与"空看板"可区分 | 有界失败成立 |
| S08-03 stdio 秒退 | 向 stdio 夹具写入 `initialize`，等待 EOF | 20s | 退出码 **7**，耗时 **0.011s**，无超时；首行 JSON-RPC 错误 `fixture S08-03: server exited at startup`；**无孤儿进程** | 有界失败成立 |

机读记录：[`fixtures/rehearsal-report.json`](../../../../code/skill-vm/fixtures/rehearsal-report.json)；脚本：[`fixtures/rehearsal.py`](../../../../code/skill-vm/fixtures/rehearsal.py)。

## 3. 三条附带发现

1. **`jq` 缺失被独立复现。** 本机无 `jq`（`bash: jq: command not found`），与 OpenClaw `skills check` 对 trello 的判定 `missing requirements: jq` 一致。演练因此把解析器换成 `python -m json` 并记录该偏离——这不是"适配"，是环境缺口，S05 用例在补齐 `jq` 之前不可能通过。
2. **超时判定应看客户端退出码，不看服务端时刻。** `--max-time 10` 实际在 **10019ms** 返回：curl 自报的计时包含握手，比"服务端 30s 延迟"晚/早都不重要——重要的是"客户端在自己的预算内主动放弃"。这一条要在用例记录里写成断言形式（退出码 28 + 耗时 ≤ T_timeout+容差），而不是"服务端多久返回"。
3. **S08-03 的"无孤儿"是可以机检的。** 夹具天然退出，`pgrep -af s08-stdio-exit` 为空。真正需要测孤儿的是"握手成功但调用中途崩溃"那种夹具（本批未做，见 [批次 04 §6](c-2b-batch04-static-and-fixtures.md)）。

## 4. 对 P1 的意义与仍不成立的部分

- **成立**：预算的**量级**是对的。三条路径的失败都在预算内可观察，不需要临时放宽；容差 `+5s` 对 S04-03a 足够（超时提前 19ms 触发）。
- **不成立**：本演练不能证明"真实被测端也会这样失败"。OpenClaw 的 Skill 调用要经过模型选择工具、参数拼装、shell 执行，耗时可能是 curl 的数倍；鸿蒙侧更是另一套。因此 `T_timeout` 的**数值仍需真实两端各一条记录来校准**，P1 的口头签署只解除"无判定效力"，不等于"数值已被实验验证"。
- **待补**：P1 的书面记录（口头确认日期、确认范围、是否含容差与重试上限）尚未归档；本批只在预注册 §7 追加了变更记录。

## 5. 复现

```bash
python3 code/skill-vm/fixtures/rehearsal.py --write-report
```

原始日志（未入库，哈希可核对）：

| 日志 | 大小 | SHA-256 |
| --- | --- | --- |
| `batch05-rehearsal-20261031T150854.log` | 1085 B | `538fba6c6406a735937d44f3d2709e796f6561caa3dddb7bba6d33deaa735a74` |

需要 `curl`（本机 7.68.0）；`jq` 可缺，缺了会被记录而不是被绕过。
