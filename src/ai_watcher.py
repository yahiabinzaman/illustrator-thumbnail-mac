#!/usr/bin/env python3
"""
AI Thumbnail Auto-Watcher for macOS
Continuously monitors selected directories and automatically applies
embedded visual thumbnails to all newly saved or modified .ai/.eps files.
"""

import os
import sys
import time
import subprocess
from pathlib import Path

CODEC_BIN = Path(__file__).resolve().parent.parent / "bin" / "ai-codec"

DEFAULT_WATCH_DIRS = [
    Path.home() / "Downloads",
    Path.home() / "Desktop",
    Path.home() / "Documents"
]

def process_file(file_path: Path):
    if file_path.suffix.lower() in [".ai", ".eps"] and file_path.exists():
        try:
            # Give a brief moment for Illustrator to finish writing the file
            time.sleep(0.3)
            res = subprocess.run([str(CODEC_BIN), str(file_path)], capture_output=True, text=True)
            if "✅" in res.stdout:
                print(f"🎨 [AUTO-THUMBNAIL] Generated for: {file_path.name}")
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

def watch_directories(dirs):
    print("👀 AI Thumbnail Auto-Watcher is active!")
    print("--------------------------------------------------")
    print("Watching directories:")
    for d in dirs:
        print(f" • {d}")
    print("--------------------------------------------------")
    print("Whenever you save an .ai file in Illustrator, its thumbnail will appear automatically in Finder!")
    print("Press Ctrl+C to stop.\n")

    seen_mtimes = {}

    # Initialize initial state
    for d in dirs:
        if d.exists():
            for p in d.rglob("*.ai"):
                try:
                    seen_mtimes[str(p)] = p.stat().st_mtime
                except Exception:
                    pass

    try:
        while True:
            for d in dirs:
                if not d.exists():
                    continue
                for p in d.rglob("*.ai"):
                    try:
                        mtime = p.stat().st_mtime
                        p_str = str(p)
                        if p_str not in seen_mtimes or seen_mtimes[p_str] < mtime:
                            seen_mtimes[p_str] = mtime
                            process_file(p)
                    except Exception:
                        pass
            time.sleep(2)
    except KeyboardInterrupt:
        print("\n👋 Auto-Watcher stopped.")

if __name__ == "__main__":
    target_dirs = DEFAULT_WATCH_DIRS
    if len(sys.argv) > 1:
        target_dirs = [Path(p).resolve() for p in sys.argv[1:]]
    watch_directories(target_dirs)
