#!/usr/bin/env python3
"""
Minimal SPA static server for the Flutter web build.
Serves files from the build/web directory (or a custom dir) and falls back
to index.html for client-side routing (single-page app behavior).

Usage:
  python3 spa_server.py --dir build/web --port 8000

This is intentionally simple and has no production hardening.
"""

import argparse
import http.server
import socketserver
import os
from pathlib import Path


class SPARequestHandler(http.server.SimpleHTTPRequestHandler):
    """Serve static files and fall back to index.html for missing paths."""

    def __init__(self, *args, directory=None, index_file="index.html", **kwargs):
        self._spa_index = index_file
        super().__init__(*args, directory=directory, **kwargs)

    def send_head(self):
        # Try to serve the requested path normally
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            for index in ("index.html", "index.htm"):
                index_path = os.path.join(path, index)
                if os.path.exists(index_path):
                    return super().send_head()
            return self.list_directory(path)

        if os.path.exists(path):
            return super().send_head()

        # Not found on disk: fall back to SPA index
        index_path = os.path.join(self.directory, self._spa_index)
        if os.path.exists(index_path):
            try:
                f = open(index_path, 'rb')
            except OSError:
                self.send_error(404, "File not found")
                return None
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            fs = os.fstat(f.fileno())
            self.send_header("Content-Length", str(fs[6]))
            self.end_headers()
            return f

        return super().send_head()


def run_server(directory: str, port: int):
    directory = os.path.abspath(directory)
    if not os.path.isdir(directory):
        print(f"Error: directory does not exist: {directory}")
        return 2

    handler = lambda *args, **kwargs: SPARequestHandler(*args, directory=directory, **kwargs)
    with socketserver.TCPServer(("", port), handler) as httpd:
        sa = httpd.socket.getsockname()
        print(f"Serving {directory} at http://{sa[0] or 'localhost'}:{sa[1]}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("Shutting down...")
            httpd.shutdown()
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Serve a Flutter web build directory with SPA fallback")
    parser.add_argument("--dir", default="build/web", help="Directory to serve (default: build/web)")
    parser.add_argument("--port", type=int, default=8000, help="Port to listen on (default: 8000)")
    args = parser.parse_args()
    exit(run_server(args.dir, args.port))
