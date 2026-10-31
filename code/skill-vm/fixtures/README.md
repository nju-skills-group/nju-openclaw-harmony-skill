# code/skill-vm/fixtures

C-2B 的故障注入夹具。对应 [C-2B 预注册第 5 节](../../../docs/04-methodology/group-c/evaluation/c-2b-preregistration-v1.md)冻结的口径，执行记录见 [批次 04](../../../docs/04-methodology/group-c/evaluation/c-2b-batch04-static-and-fixtures.md)。

**这里只放我们自己的夹具件**：不含第三方 Skill 内容，不含编译产物，不联网（所有服务只监听 `127.0.0.1`）。

## 文件

| 文件 | 对应用例 | 作用 |
| --- | --- | --- |
| [`s04-timeout-service.py`](s04-timeout-service.py) | S04-03a | 固定延迟 30s 的天气服务；`/health` 立即返回，`/v1/current` 迟到 |
| [`s04-missing-temperature.json`](s04-missing-temperature.json) | S04-03b | HTTP 200 但缺 `temperature` 的响应体 |
| [`s05-trello-paged.py`](s05-trello-paged.py) | S05-01 | 三列 Todo/Doing/Done，卡片分两页各 2 条，路径照 Trello REST 形状 |
| [`s05-unauthorized.py`](s05-unauthorized.py) | S05-02 | 固定 401；访问日志把 `token=`/`key=` 替换为 `***` |
| [`s08-stdio-exit.sh`](s08-stdio-exit.sh) | S08-03 | stdio MCP 服务启动即退出（一行 JSON-RPC 错误 + 退出码 7） |
| [`selfcheck.py`](selfcheck.py) | — | 自检并登记哈希；`--write-manifest` 重写 `manifest.json` |
| [`manifest.json`](manifest.json) | — | **生成物**：逐文件 `sha256` + 自检观测值 + 未覆盖项 |

S06-03 是**参数夹具**（`render __missing_template__ …`），没有本地可执行产物，登记在 `manifest.json` 的 `fixtures[S06-03]`。
S09-02/S09-03 需要鸿蒙测试应用（隐藏按钮、撤销权限），本机无法成型，登记在 `uncovered`。

## 用法

```bash
python3 selfcheck.py                  # 只自检，打印表；约 35s（其中 30s 是 S04-03a 的固定延迟）
python3 selfcheck.py --write-manifest # 自检 + 重写 manifest.json（改了夹具或迁移目录后必须跑）
```

## 纪律

1. **夹具自检通过 ≠ 用例通过。** 自检只证明夹具"如约失败"；被测端是否在 `T_timeout` 内给出正确错误，由用例记录判定，且需预注册 P1 先冻结。
2. **改夹具必须重算哈希**，否则 `manifest.json` 与文件不一致，证据链断裂。不要手改 `manifest.json` 里的 `sha256`。哈希按 LF 计算，`.gitattributes` 已把本目录固定为 `eol=lf`（否则 Windows 上换行转换会让哈希对不上）。
3. **位置是暂定的**：P5（放研究仓库附件还是本仓库）未定；若迁移，整目录搬走并重跑 `--write-manifest`，不要只搬文件。
4. 夹具的冻结参数（延迟、页大小、模板 ID）不得为了让用例"通过"而调整；确需变更时按预注册 §1 追加变更记录。
