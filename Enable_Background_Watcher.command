#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "👀 Starting AI Thumbnail Auto-Watcher..."
python3 "$DIR/src/ai_watcher.py"
