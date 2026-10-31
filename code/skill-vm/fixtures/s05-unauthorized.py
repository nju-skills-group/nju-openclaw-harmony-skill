#!/usr/bin/env python3
"""S05-02 夹具：固定 401 的鉴权失败服务（预注册 §5）。

冻结口径：固定 401 响应，日志中不含 token。
断言口径（由被测客户端承担）：
    与“空看板”可区分；无成功数据伪装。

本夹具附带一条可自检的性质：访问日志把 `token=`/`key=` 的值一律替换为 ***，
因此夹具自身的日志不含令牌；被测端是否泄漏令牌由自检用它发的哨兵值反查。

就绪后向 stdout 打印一行：LISTENING <port>
"""

import argparse
import re
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REDACT = re.compile(r"((?:token|key)=)[^&\s]+", re.IGNORECASE)
BODY = {"error": "unauthorized", "message": "invalid token"}


def make_handler():
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def do_GET(self):  # noqa: N802
            self._send(401, BODY)

        def do_POST(self):  # noqa: N802
            self._send(401, BODY)

        def _send(self, code, payload):
            import json
            raw = json.dumps(payload).encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def log_message(self, fmt, *args):
            sys.stderr.write("access %s\n" % REDACT.sub(r"\1***", fmt % args))

    return Handler


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=0)
    args = ap.parse_args()
    httpd = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler())
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
