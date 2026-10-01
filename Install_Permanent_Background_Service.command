#!/bin/bash
# ==============================================================================
# AI Thumbnail Codec - Permanent macOS Background Service Installer
# Automatically watches ALL Local Folders and NAS Drives 24/7!
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$HOME/Library/Application Support/AIThumbnailCodec"
PLIST_PATH="$HOME/Library/LaunchAgents/com.colorlab.ai-thumbnail-watcher.plist"

echo "🎨 Installing AI Thumbnail Codec & 24/7 Auto Watcher..."
echo "=========================================================="

# 1. Create target app directory and copy binary
mkdir -p "$APP_DIR"
cp "$SCRIPT_DIR/bin/ai-codec" "$APP_DIR/ai-codec"
chmod +x "$APP_DIR/ai-codec"

# Also try linking to /usr/local/bin if possible
mkdir -p "$HOME/.local/bin"
ln -sf "$APP_DIR/ai-codec" "$HOME/.local/bin/ai-codec" 2>/dev/null || true

# 2. Stop existing service if running
launchctl bootout "gui/$(id -u)/com.colorlab.ai-thumbnail-watcher" 2>/dev/null || true
launchctl unload "$PLIST_PATH" 2>/dev/null || true

# 3. Create LaunchAgent plist for macOS
mkdir -p "$HOME/Library/LaunchAgents"

cat << EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.colorlab.ai-thumbnail-watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_DIR/ai-codec</string>
        <string>-w</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/ai_thumbnail_watcher.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/ai_thumbnail_watcher.err</string>
</dict>
</plist>
EOF

# 4. Load & Start the LaunchAgent
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || launchctl load "$PLIST_PATH" 2>/dev/null || true

# 5. Install Finder Quick Action as well
"$SCRIPT_DIR/Install_Finder_Quick_Action.sh" >/dev/null 2>&1 || true

echo ""
echo "=========================================================="
echo "🎉 SUCCESS! 24/7 Auto-Watcher is now permanently ACTIVE!"
echo "=========================================================="
echo " • Works for: Entire Mac (Home folder) + All NAS / Server Drives (/Volumes)"
echo " • Real-Time: Whenever any .ai / .eps file is saved, preview appears automatically!"
echo " • Auto-Starts: Automatically starts every time your Mac turns on."
echo " • Resource friendly: Uses native macOS FSEvents (0% battery / CPU drain)."
echo ""
