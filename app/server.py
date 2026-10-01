#!/usr/bin/env python3
"""
AI Thumbnail Codec Dashboard Server for macOS
Provides a sleek local web interface for scanning, batch generating,
previewing, and monitoring AI file thumbnails in Finder.
"""

import os
import sys
import json
import base64
import subprocess
import threading
from pathlib import Path
from http.server import HTTPServer, SimpleHTTPRequestHandler
import urllib.parse

PORT = 7890
ROOT_DIR = Path(__file__).resolve().parent.parent
CODEC_BIN = ROOT_DIR / "bin" / "ai-codec"
STATIC_DIR = ROOT_DIR / "app"

watcher_process = None
watcher_active = False

def extract_thumbnail_base64(file_path: Path):
    try:
        with open(file_path, "rb") as f:
            header = f.read(2 * 1024 * 1024)
        
        start_tag = b"xmpGImg:image>"
        start = header.find(start_tag)
        if start != -1:
            end = header.find(b"<", start)
            raw = header[start + len(start_tag):end]
            clean_b64 = raw.replace(b"&#xA;", b"").replace(b"\n", b"").replace(b"\r", b"").strip()
            return clean_b64.decode("ascii")
    except Exception:
        pass
    return None

class RequestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        url = urllib.parse.urlparse(self.path)
        if url.path == "/api/status":
            self.send_json({
                "watcher_active": watcher_active,
                "codec_installed": CODEC_BIN.exists()
            })
        elif url.path == "/api/list_files":
            qs = urllib.parse.parse_qs(url.query)
            folder_str = qs.get("folder", [str(Path.home() / "Downloads")])[0]
            folder = Path(folder_str).expanduser()
            items = []
            if folder.exists() and folder.is_dir():
                for p in folder.glob("*.ai"):
                    thumb_b64 = extract_thumbnail_base64(p)
                    items.append({
                        "name": p.name,
                        "path": str(p),
                        "size": p.stat().st_size,
                        "mtime": p.stat().st_mtime,
                        "has_thumbnail": thumb_b64 is not None,
                        "thumbnail_data": f"data:image/jpeg;base64,{thumb_b64}" if thumb_b64 else None
                    })
            self.send_json({"folder": str(folder), "files": items})
        elif url.path == "/" or url.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            with open(STATIC_DIR / "index.html", "rb") as f:
                self.wfile.write(f.read())
        else:
            super().do_GET()

    def do_POST(self):
        global watcher_process, watcher_active
        url = urllib.parse.urlparse(self.path)
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length > 0 else b"{}"
        data = json.loads(body.decode("utf-8")) if body else {}

        if url.path == "/api/process_folder":
            folder = data.get("folder", str(Path.home() / "Downloads"))
            recursive = data.get("recursive", True)
            flag = "-r" if recursive else "-f"
            res = subprocess.run([str(CODEC_BIN), flag, folder], capture_output=True, text=True)
            self.send_json({"success": True, "output": res.stdout})
        
        elif url.path == "/api/process_file":
            file_path = data.get("path")
            if file_path and os.path.exists(file_path):
                res = subprocess.run([str(CODEC_BIN), file_path], capture_output=True, text=True)
                self.send_json({"success": True, "output": res.stdout})
            else:
                self.send_json({"success": False, "error": "File not found"})

        elif url.path == "/api/toggle_watcher":
            if watcher_active:
                if watcher_process:
                    watcher_process.terminate()
                    watcher_process = None
                watcher_active = False
            else:
                watcher_script = ROOT_DIR / "src" / "ai_watcher.py"
                watcher_process = subprocess.Popen([sys.executable, str(watcher_script)])
                watcher_active = True
            self.send_json({"watcher_active": watcher_active})
        else:
            self.send_error(404, "Endpoint Not Found")

    def send_json(self, obj):
        data = json.dumps(obj).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

def run_server():
    server = HTTPServer(("127.0.0.1", PORT), RequestHandler)
    print(f"🚀 AI Thumbnail Codec Dashboard running on: http://127.0.0.1:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    run_server()
