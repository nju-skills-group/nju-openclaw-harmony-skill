#!/usr/bin/env python3
"""S05-01 夹具：分页看板服务（预注册 §5）。

冻结口径：L1=Todo / L2=Doing / L3=Done；两页返回，每页 2 条。
断言口径（由被测客户端承担）：
    列表身份正确、无遗漏重复；真实接口若不分页须单列该差异。

路径照抄 Trello REST 的形状，方便被测端只改 base URL：
    GET /1/members/me/boards
    GET /1/boards/<boardId>/lists
    GET /1/boards/<boardId>/cards?page=<n>&limit=2

就绪后向 stdout 打印一行：LISTENING <port>
"""

import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

BOARD = {"id": "b1", "name": "C2 Fixture Board"}
LISTS = [
    {"id": "l1", "name": "Todo", "idBoard": "b1"},
    {"id": "l2", "name": "Doing", "idBoard": "b1"},
    {"id": "l3", "name": "Done", "idBoard": "b1"},
]
# 4 张卡分两页，跨三列：Todo 2 / Doing 1 / Done 1
CARDS = [
    {"id": "c1", "name": "draft outline", "idList": "l1"},
    {"id": "c2", "name": "collect papers", "idList": "l1"},
    {"id": "c3", "name": "write methods", "idList": "l2"},
    {"id": "c4", "name": "submit", "idList": "l3"},
]
PAGE_SIZE = 2


def make_handler():
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def do_GET(self):  # noqa: N802
            u = urlparse(self.path)
            q = parse_qs(u.query)
            path = u.path
            if path == "/1/members/me/boards":
                self._send(200, [BOARD])
                return
            if path.startswith("/1/boards/") and path.endswith("/lists"):
                self._send(200, LISTS)
                return
            if path.startswith("/1/boards/") and path.endswith("/cards"):
                page = int(q.get("page", ["0"])[0])
                limit = int(q.get("limit", [str(PAGE_SIZE)])[0])
                start = page * limit
                chunk = CARDS[start:start + limit]
                self._send(200, chunk, {"X-Total-Count": str(len(CARDS)), "X-Page": str(page)})
                return
            self._send(404, {"error": "not found", "path": path})

        def _send(self, code, payload, extra_headers=None):
            raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(raw)))
            for k, v in (extra_headers or {}).items():
                self.send_header(k, v)
            self.end_headers()
            self.wfile.write(raw)

        def log_message(self, fmt, *args):
            sys.stderr.write("access %s\n" % (fmt % args))

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
