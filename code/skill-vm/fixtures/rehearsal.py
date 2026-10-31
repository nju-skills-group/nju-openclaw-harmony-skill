#!/usr/bin/env python3
"""C-2B 故障分支演练（batch 05）：只用夹具 + 参考客户端，不产生用例判定。

为什么要做：预注册 P1 的预算（T_timeout、重试上限）在没有真实被测端时无法验证
"这个预算够不够"。演练用**源 SKILL.md 里写的那条命令形状**做参考客户端
（weather 的 curl 回退、trello 的 curl+jq、MCP 的 stdio 握手），证明：

    夹具能起跑 + 参考客户端能在预算内得到"有界失败" + 耗时可以被测出来

它**不能**证明：OpenClaw 的 Skill 调用、鸿蒙侧的任何行为、27 个用例的通过。
参考客户端不等于被测端；本脚本的任何输出都不得写进用例记录。

用法：
    python3 rehearsal.py                 # 跑三条分支，打印表
    python3 rehearsal.py --write-report  # 同时写 rehearsal-report.json
需要 curl；jq 可缺（缺了就记录为环境缺口，与本机 OpenClaw 的 missing 一致）。
"""

import argparse
import datetime
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
PY = sys.executable

# 预注册 §4 的预算（口头签署后按此值演练；P1 书面记录待补）
T_TIMEOUT = {"S04-03a": 10.0, "S05-02": 30.0, "S08-03": 20.0}
S05_TOKEN = "tok_rehearsal_sentinel_7c1d"
S05_KEY = "key_rehearsal_sentinel_7c1d"

results = []


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def start_server(script):
    path = os.path.join(HERE, script)
    proc = subprocess.Popen([PY, "-u", path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    line = proc.stdout.readline().strip()
    if not line.startswith("LISTENING "):
        proc.kill()
        raise RuntimeError("%s 未就绪：%r" % (script, line))
    return proc, int(line.split()[1])


def stop_server(proc):
    proc.terminate()
    try:
        proc.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.communicate()


def record(fid, status, detail, **extra):
    row = {"id": fid, "status": status, "detail": detail, "t_timeout_s": T_TIMEOUT[fid]}
    row.update(extra)
    results.append(row)


def rehearsal_s04_03a():
    if not shutil.which("curl"):
        record("S04-03a", "BLOCKED", "本机无 curl，无法按源文的回退命令演练")
        return
    proc, port = start_server("s04-timeout-service.py")
    try:
        url = "http://127.0.0.1:%d/v1/current" % port
        cmd = ["curl", "--fail", "--silent", "--show-error", "--max-time",
               str(int(T_TIMEOUT["S04-03a"])), url]
        t0 = time.time()
        done = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        elapsed = time.time() - t0
    finally:
        stop_server(proc)
    bounded = done.returncode == 28 and elapsed <= T_TIMEOUT["S04-03a"] + 5.0
    record("S04-03a", "PASS(演练)" if bounded else "CHECK",
           "curl 退出码 %d（28=CURLE_OPERATION_TIMEDOUT），耗时 %.2fs（T_timeout=10s，容差 +5s）；"
           "stderr=%r" % (done.returncode, elapsed, done.stderr.strip()[:80]),
           cmd="curl --fail --silent --show-error --max-time 10 http://127.0.0.1:<port>/v1/current",
           exit_code=done.returncode, elapsed_s=round(elapsed, 2),
           bounded_failure=bounded, fixture_sha256=sha256(os.path.join(HERE, "s04-timeout-service.py")))


def rehearsal_s05_02():
    if not shutil.which("curl"):
        record("S05-02", "BLOCKED", "本机无 curl，无法演练")
        return
    proc, port = start_server("s05-unauthorized.py")
    tmpd = tempfile.mkdtemp(prefix="c2b-s0502-")
    body = os.path.join(tmpd, "body.json")
    try:
        url = "http://127.0.0.1:%d/1/members/me/boards?key=%s&token=%s" % (port, S05_KEY, S05_TOKEN)
        cmd = ["curl", "-s", "-o", body, "-w", "%{http_code}", "--max-time",
               str(int(T_TIMEOUT["S05-02"])), url]
        t0 = time.time()
        done = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        elapsed = time.time() - t0
        code = done.stdout.strip()
        raw = open(body, "r", encoding="utf-8").read() if os.path.exists(body) else ""
        jq = shutil.which("jq")
        if jq:
            parsed = subprocess.run([jq, "."], input=raw, capture_output=True, text=True)
            parser = "jq %s（源文写法）" % subprocess.run([jq, "--version"], capture_output=True, text=True).stdout.strip()
            parse_ok = parsed.returncode == 0
            parse_err = parsed.stderr.strip()[:80]
        else:
            try:
                json.loads(raw)
                parse_ok, parse_err = True, ""
                parser = "python json（本机无 jq，见备注）"
            except ValueError as exc:
                parse_ok, parse_err = False, str(exc)[:80]
                parser = "python json"
    finally:
        stop_server(proc)
    leaked = (S05_TOKEN in raw) or (S05_KEY in raw)
    failed_cleanly = code == "401" and not leaked
    record("S05-02", "PASS(演练)" if failed_cleanly else "CHECK",
           "HTTP %s、耗时 %.2fs；401 与“空看板”可区分；响应体不含哨兵令牌（leaked=%s）；"
           "解析器=%s；本机 jq=%s" % (code, elapsed, leaked, parser, "有" if jq else "无（与 OpenClaw missing 一致）"),
           cmd="curl -s -o body -w '%{http_code}' 'http://127.0.0.1:<port>/1/members/me/boards?key=***&token=***'",
           http_status=code, elapsed_s=round(elapsed, 2), token_leaked=leaked,
           parse_ok=parse_ok, parse_err=parse_err, jq_present=bool(jq),
           fixture_sha256=sha256(os.path.join(HERE, "s05-unauthorized.py")))


def rehearsal_s08_03():
    path = os.path.join(HERE, "s08-stdio-exit.sh")
    init = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "initialize",
                       "params": {"protocolVersion": "2025-06-18", "capabilities": {}}}) + "\n"
    t0 = time.time()
    try:
        done = subprocess.run(["bash", path], input=init, capture_output=True, text=True,
                              timeout=T_TIMEOUT["S08-03"])
        elapsed = time.time() - t0
        rc, out, err = done.returncode, done.stdout, done.stderr
        timed_out = False
    except subprocess.TimeoutExpired as exc:
        elapsed = time.time() - t0
        rc, out, err, timed_out = None, (exc.stdout or ""), (exc.stderr or ""), True
    first = (out or "").splitlines()[0] if out else ""
    try:
        msg = json.loads(first).get("error", {}).get("message", "")
    except ValueError:
        msg = ""
    # 孤儿进程检查：夹具应当已经退出，不应留下同名的 bash 进程
    try:
        orphans = subprocess.run(["pgrep", "-af", "s08-stdio-exit"], capture_output=True, text=True).stdout.strip()
    except FileNotFoundError:
        orphans = "(pgrep 不可用)"
    ok = (rc == 7 and not timed_out and elapsed < 2.0 and "S08-03" in msg and not orphans)
    record("S08-03", "PASS(演练)" if ok else "CHECK",
           "stdin 写入 initialize 后进程退出码 %s、耗时 %.3fs、无超时；EOF 早于预算（T_timeout=20s）；"
           "孤儿进程=%r；首行=%r" % (rc, elapsed, orphans or "无", msg),
           exit_code=rc, elapsed_s=round(elapsed, 3), timed_out=timed_out,
           orphan_procs=orphans, fixture_sha256=sha256(path))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write-report", action="store_true")
    args = ap.parse_args()

    print("# C-2B 故障分支演练（不判定用例）")
    print("时间(UTC) %s" % datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"))
    print("python   %s" % sys.version.split()[0])
    print("curl     %s" % (shutil.which("curl") or "缺失"))
    print("jq       %s" % (shutil.which("jq") or "缺失"))
    print()

    for fn in (rehearsal_s04_03a, rehearsal_s05_02, rehearsal_s08_03):
        try:
            fn()
        except Exception as exc:
            fid = {"rehearsal_s04_03a": "S04-03a", "rehearsal_s05_02": "S05-02",
                   "rehearsal_s08_03": "S08-03"}[fn.__name__]
            record(fid, "FAIL", "%s: %s" % (type(exc).__name__, exc))

    width = max(len(r["id"]) for r in results) + 2
    for r in results:
        print("%-*s %-10s T_timeout=%-4s %s" % (width, r["id"], r["status"], r["t_timeout_s"], r["detail"]))
    print()
    print("口径：以上均为“夹具 + 参考客户端”的演练结果，不构成用例判定，也不构成原平台或目标运行证据。")

    if args.write_report:
        out = {
            "batch": "c-2b-batch05",
            "purpose": "验证三条故障分支可起跑、预算可观察；不判定用例",
            "generated_utc": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
            "python": sys.version.split()[0],
            "curl": shutil.which("curl"),
            "jq": shutil.which("jq"),
            "t_timeout_frozen": T_TIMEOUT,
            "rows": results,
            "not_evidence_of": [
                "OpenClaw 的 Skill 调用行为",
                "鸿蒙侧任何行为",
                "27 个用例的通过/失败",
            ],
        }
        path = os.path.join(HERE, "rehearsal-report.json")
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(out, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        print("写入 %s" % path)

    return 0


if __name__ == "__main__":
    sys.exit(main())
