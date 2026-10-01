#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Starting AI Thumbnail Codec Dashboard..."
open "http://127.0.0.1:7890"
python3 "$DIR/app/server.py"
