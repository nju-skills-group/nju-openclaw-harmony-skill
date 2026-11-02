# 问题与实际依赖

## 实际依赖

| 依赖 | 作用与证据 |
|---|---|
| OpenClaw CLI、Gateway | 三项检查及原平台 Agent；版本均 2026.10.2 |
| 模型服务 | deepseek-v4-pro |
| read | 读取安装目录的 healthcheck/SKILL.md，轨迹 seq 12–13 |
| exec | 启动三个授权命令，seq 50、89、98 |
| process | 查询后台审计任务 crisp-cloud，seq 65、80 |
| Node、工作区/运行日志 | OpenClaw 运行及证据保存；Node v24.21.0 |
| Gateway operator scope | 深度探测需要；本次报缺少 operator.read |

seq 对应历史最终轨迹。Skill 无自带脚本，无额外编码代理依赖。

## 问题

| 问题 | 定位与影响 | 状态 |
|---|---|---|
| 深度探测缺少 operator.read | audit 返回 gateway.probe_failed；status 显示 connected-no-operator-scope；部分深度项未完成 | 未改权限；根因未继续调查 |
| doctor --lint 返回 1 | 36 项执行、30 项跳过，2 个 warning；不是命令启动失败 | 已正确识别 |
| 反代信任、插件版本、明文敏感字段等警告 | 原始输出保留；当前 loopback-only，不据此认定公网暴露 | 未修复，超出测试范围 |
| 模型扩大权限结论 | “无读/写权限”超出证据；仅确认本次探测缺少 operator scope | 报告已收窄 |
| 原运行器会话/输出写死 | 可能续用旧会话或覆盖证据 | 已改唯一会话、独立目录和显式参数 |

未覆盖：Linux 系统检查、Windows 主机安全状态、加固、独立异常案例和鸿蒙执行。
