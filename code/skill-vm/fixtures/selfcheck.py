#!/usr/bin/env python3
"""C-2B 夹具自检（batch 04）：验证夹具本身"如约失败"，并登记路径与哈希。

预注册第 5 节要求："以上夹具的脚本、响应文件与测试应用工程须在首次执行前
保存路径与哈希；本文件只冻结参数口径，不替代夹具本身的哈希登记。"
本脚本补的就是这一步：跑一遍夹具，把**观测到的行为**与冻结口径对照，
然后把 `sha256` 与观测值写进 `manifest.json`。

判读边界（重要）：
    夹具自检通过 ≠ 用例通过。它只证明"夹具按冻结口径失败/响应"，
    被测客户端在正确时间内报错才由用例记录（P1 冻结后）判定。

用法：
    python3 selfcheck.py                 # 只自检，打印表
    python3 selfcheck.py --write-manifest  # 自检 + 重写 manifest.json
不需要联网：所有服务只监听 127.0.0.1。Python 3.8+ 标准库即可。
"""

import argparse
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
PY = sys.executable
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))

# 与预注册第 5 节一一对应；顺序即打印顺序。
FIXTURES = [
    {"id": "S04-03a", "kind": "service", "file": "s04-timeout-service.py",
     "frozen": "固定延迟 30s；T_timeout=10s；容差 +5s"},
    {"id": "S04-03b", "kind": "data", "file": "s04-missing-temperature.json",
     "frozen": "固定 JSON，缺 temperature 字段；HTTP 200"},
    {"id": "S05-01", "kind": "service", "file": "s05-trello-paged.py",
     "frozen": "L1=Todo/L2=Doing/L3=Done；两页返回，每页 2 条"},
    {"id": "S05-02", "kind": "service", "file": "s05-unauthorized.py",
     "frozen": "固定 401；日志中不含 token"},
    {"id": "S06-03", "kind": "argv", "file": None,
     "frozen": "模板 ID __missing_template__"},
    {"id": "S08-03", "kind": "process", "file": "s08-stdio-exit.sh",
     "frozen": "服务进程启动后立即退出"},
]

# 预注册第 5 节有、但本地建不出来的：
UNCOVERED = [
    {"id": "S09-02", "why": "需鸿蒙测试应用（隐藏“保存”按钮）与设备，无法在本机成型"},
    {"id": "S09-03", "why": "需鸿蒙测试应用与运行时权限撤销，无法在本机成型"},
]

S06_ARGV = ["render", "__missing_template__", "--text", "before", "--text", "after",
            "--out", "<tmp>/c2b-s06-03.svg"]

results = []


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def record(fid, status, detail, measured=None):
    results.append({"id": fid, "status": status, "detail": detail, "measured": measured or {}})


def http_get(url, timeout):
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        return resp.read()


def start_server(script, *args):
    path = os.path.join(HERE, script)
    proc = subprocess.Popen([PY, "-u", path] + list(args),
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    line = proc.stdout.readline().strip()
    m = re.match(r"LISTENING (\d+)$", line)
    if not m:
        proc.kill()
        raise RuntimeError("%s 未就绪：%r" % (script, line))
    return proc, int(m.group(1))


def stop_server(proc):
    proc.terminate()
    try:
        _, err = proc.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()
        _, err = proc.communicate()
    return err or ""


def check_s04_timeout():
    proc, port = start_server("s04-timeout-service.py")
    try:
        t0 = time.time()
        http_get("http://127.0.0.1:%d/health" % port, 5)
        health = time.time() - t0
        t0 = time.time()
        body = json.loads(http_get("http://127.0.0.1:%d/v1/current" % port, 90).decode("utf-8"))
        delay = time.time() - t0
    finally:
        stop_server(proc)
    ok = 29.0 <= delay <= 45.0 and health < 1.0 and body.get("temperature") == 19
    record("S04-03a", "PASS" if ok else "FAIL",
           "响应在 %.2fs 后到达（冻结 30s），/health %.3fs；因此 T_timeout=10s 的客户端必然先超时"
           % (delay, health),
           {"first_byte_delay_s": round(delay, 2), "health_latency_s": round(health, 3),
            "payload_has_temperature": body.get("temperature") == 19})


def check_s04_missing_field():
    path = os.path.join(HERE, "s04-missing-temperature.json")
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    absent = "temperature" not in data
    others = all(k in data for k in ("city", "description", "humidity", "wind_kph"))
    trap = data.get("temperature", 0) == 0
    ok = absent and others and trap
    record("S04-03b", "PASS" if ok else "FAIL",
           "temperature 缺失=%s，其余字段齐备=%s；data.get('temperature', 0) 会静默得到 0（正是断言要禁止的填充）"
           % (absent, others),
           {"temperature_absent": absent, "silent_default_to_zero": trap})


def check_s05_paged():
    proc, port = start_server("s05-trello-paged.py")
    base = "http://127.0.0.1:%d" % port
    try:
        boards = json.loads(http_get(base + "/1/members/me/boards", 5).decode("utf-8"))
        lists = json.loads(http_get(base + "/1/boards/%s/lists" % boards[0]["id"], 5).decode("utf-8"))
        p0 = json.loads(http_get(base + "/1/boards/%s/cards?page=0&limit=2" % boards[0]["id"], 5).decode("utf-8"))
        p1 = json.loads(http_get(base + "/1/boards/%s/cards?page=1&limit=2" % boards[0]["id"], 5).decode("utf-8"))
        p2 = json.loads(http_get(base + "/1/boards/%s/cards?page=2&limit=2" % boards[0]["id"], 5).decode("utf-8"))
    finally:
        stop_server(proc)
    names = [x["name"] for x in lists]
    ids = [c["id"] for c in p0 + p1]
    ok = (names == ["Todo", "Doing", "Done"] and len(p0) == 2 and len(p1) == 2
          and p2 == [] and len(set(ids)) == 4
          and all(c["idList"] in {x["id"] for x in lists} for c in p0 + p1))
    record("S05-01", "PASS" if ok else "FAIL",
           "三列 %s；page0=%d、page1=%d、page2=%d，去重后共 %d 张卡；故“无遗漏重复”可判定"
           % ("/".join(names), len(p0), len(p1), len(p2), len(set(ids))),
           {"lists": names, "page_sizes": [len(p0), len(p1), len(p2)], "unique_cards": len(set(ids))})


def check_s05_401():
    sentinel_key = "key_sentinel_9f3ac1"
    sentinel_tok = "tok_sentinel_9f3ac1"
    proc, port = start_server("s05-unauthorized.py")
    url = "http://127.0.0.1:%d/1/members/me/boards?key=%s&token=%s" % (port, sentinel_key, sentinel_tok)
    status = None
    try:
        http_get(url, 5)
    except urllib.error.HTTPError as exc:
        status = exc.code
    finally:
        err = stop_server(proc)
    leaked = (sentinel_key in err) or (sentinel_tok in err)
    redacted = "***" in err
    ok = status == 401 and not leaked and redacted
    record("S05-02", "PASS" if ok else "FAIL",
           "HTTP %s；夹具访问日志含 *** 且不含哨兵令牌（leaked=%s），故“日志不含 token”可机检"
           % (status, leaked),
           {"status": status, "token_leaked_in_fixture_log": leaked, "redacted": redacted})


def check_s06_argv():
    record("S06-03", "REGISTERED",
           "参数夹具（无本地可执行产物）：%s；执行时须留 stdout/stderr 与退出码，判“是否留下误导性产物”"
           % " ".join(S06_ARGV),
           {"argv": S06_ARGV})


def check_s08_stdio():
    path = os.path.join(HERE, "s08-stdio-exit.sh")
    t0 = time.time()
    proc = subprocess.run(["bash", path], capture_output=True, text=True, timeout=15)
    elapsed = time.time() - t0
    first = (proc.stdout.splitlines() or [""])[0]
    parsed = {}
    try:
        parsed = json.loads(first)
    except ValueError:
        pass
    msg = (parsed.get("error") or {}).get("message", "")
    ok = (proc.returncode == 7 and elapsed < 2.0 and "S08-03" in msg and proc.stderr.strip() == "")
    record("S08-03", "PASS" if ok else "FAIL",
           "退出码 %d、用时 %.2fs、首行 JSON-RPC 错误=%r；不会与客户端握手，故必走有界超时路径"
           % (proc.returncode, elapsed, msg),
           {"exit_code": proc.returncode, "elapsed_s": round(elapsed, 3),
            "stderr_empty": proc.stderr.strip() == ""})


def git_head():
    try:
        out = subprocess.run(["git", "-C", REPO, "rev-parse", "HEAD"],
                             capture_output=True, text=True, timeout=10)
        return out.stdout.strip() if out.returncode == 0 else None
    except Exception:
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write-manifest", action="store_true")
    args = ap.parse_args()

    print("# C-2B 夹具自检")
    print("时间(UTC) %s" % datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"))
    print("python   %s" % sys.version.split()[0])
    print("目录     %s" % HERE)
    print()

    checks = [check_s04_timeout, check_s04_missing_field, check_s05_paged,
              check_s05_401, check_s06_argv, check_s08_stdio]
    for fn in checks:
        try:
            fn()
        except Exception as exc:  # 夹具崩了也要留痕，不吞异常
            record("?", "FAIL", "%s: %s" % (type(exc).__name__, exc))

    width = max(len(r["id"]) for r in results) + 2
    for r in results:
        print("%-*s %-11s %s" % (width, r["id"], r["status"], r["detail"]))
    for u in UNCOVERED:
        print("%-*s %-11s %s" % (width, u["id"], "BLOCKED", u["why"]))
    print()

    bad = [r for r in results if r["status"] == "FAIL"]
    print("小计：PASS %d / REGISTERED %d / FAIL %d / BLOCKED %d"
          % (sum(1 for r in results if r["status"] == "PASS"),
             sum(1 for r in results if r["status"] == "REGISTERED"),
             len(bad), len(UNCOVERED)))

    if args.write_manifest:
        entries = []
        for f in FIXTURES:
            row = dict(f)
            row["path"] = ("code/skill-vm/fixtures/" + f["file"]) if f["file"] else None
            row["sha256"] = sha256(os.path.join(HERE, f["file"])) if f["file"] else None
            row["selfcheck"] = next((r["measured"] for r in results if r["id"] == f["id"]), {})
            entries.append(row)
        manifest = {
            "batch": "c-2b-batch04",
            "generated_utc": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
            "python": sys.version.split()[0],
            "git_head": git_head(),
            "purpose": "预注册 §5 的夹具哈希登记；只证明夹具行为，不构成任何用例判定",
            "selfcheck_sha256": sha256(os.path.join(HERE, "selfcheck.py")),
            "fixtures": entries,
            "status": {r["id"]: r["status"] for r in results},
            "uncovered": UNCOVERED,
            "location_is_provisional": "P5 未定：若改放研究仓库附件，整目录迁移并更新本文件哈希",
        }
        out = os.path.join(HERE, "manifest.json")
        with open(out, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(manifest, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        print("写入 %s" % out)

    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
