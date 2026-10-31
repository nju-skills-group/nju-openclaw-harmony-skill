#!/usr/bin/env bash
# S08-03 夹具：启动后立即退出的 stdio MCP 服务（预注册 §5）。
#
# 冻结口径：服务进程启动后立即退出。
# 断言口径（由被测客户端承担）：
#     有界超时报错 + 子进程被清理（无孤儿进程）。
#
# 本夹具的行为：向 stdout 写一行 JSON-RPC 错误后以退出码 7 退出，
# 不读 stdin，不等握手。因此被测端若在等 "initialize" 回包，只能靠超时收场——
# 这正是本夹具要触发的路径。
printf '%s\n' '{"jsonrpc":"2.0","id":1,"error":{"code":-32000,"message":"fixture S08-03: server exited at startup"}}'
exit 7
