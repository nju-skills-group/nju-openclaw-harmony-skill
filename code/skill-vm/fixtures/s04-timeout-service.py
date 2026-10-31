#!/usr/bin/env python3
"""S04-03a 夹具：固定延迟 30s 的天气服务（预注册 §5）。

冻结口径：固定延迟 30s；T_timeout=10s；容差 +5s。
断言口径（由**被测客户端**承担，不由本夹具承担）：
    客户端须在 <=15s 内返回超时类错误，不得挂起至服务端返回。

本夹具只负责"如约迟到"：/v1/current 在 delay 秒后才写出响应体，
/health 立即返回，方便自检确认进程已就绪而不是卡死。

用法：
    python3 s04-timeout-service.py [--delay 30] [--port 0]
    就绪后向 stdout 打印一行：LISTENING <port>
"""

import argparse
import json
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

BODY = {
    "city": "Shanghai",
    "observed_at": "2026-10-31T14:00:00+08:00",
    "temperature": 19,
    "description": "light rain",
    "humidity": 78,
    "wind_kph": 12,
}


def make_handler(delay):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def do_GET(self):  # noqa: N802 (http.server API)
            path = self.path.split("?", 1)[0]
            if path == "/health":
                self._send(200, {"ok": True, "fixture": "S04-03a", "delay_s": delay})
                return
            if path in ("/v1/current", "/weather"):
                time.sleep(delay)
                self._send(200, BODY)
                return
            self._send(404, {"error": "not found", "path": path})

        def _send(self, code, payload):
            raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def log_message(self, fmt, *args):  # 只记到 stderr，避免污染 LISTENING 行
            sys.stderr.write("access %s\n" % (fmt % args))

    return Handler


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--delay", type=float, default=30.0)
    ap.add_argument("--port", type=int, default=0)
    args = ap.parse_args()

    httpd = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(args.delay))
    httpd.daemon_threads = True
    sys.stdout.write("LISTENING %d\n" % httpd.server_address[1])
    sys.stdout.flush()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()


if __name__ == "__main__":
    main()
