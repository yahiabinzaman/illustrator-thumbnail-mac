#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Scanning and Generating Thumbnails for all .ai files in ~/Downloads..."
echo "--------------------------------------------------"
"$DIR/bin/ai-codec" -r "$HOME/Downloads"
echo "--------------------------------------------------"
echo "🎉 Done! Open Finder to see all previews!"
read -p "Press Enter to exit..."
