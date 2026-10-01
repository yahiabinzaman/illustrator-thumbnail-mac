#!/bin/bash
# ==============================================================================
# AI Thumbnail Codec - Uninstaller
# ==============================================================================

PLIST_PATH="$HOME/Library/LaunchAgents/com.colorlab.ai-thumbnail-watcher.plist"
APP_DIR="$HOME/Library/Application Support/AIThumbnailCodec"
SERVICE_NAME="✨ Generate AI Thumbnails.workflow"
TARGET_PATH="$HOME/Library/Services/$SERVICE_NAME"

echo "🗑️ Removing AI Thumbnail Background Service..."

launchctl bootout "gui/$(id -u)/com.colorlab.ai-thumbnail-watcher" 2>/dev/null || true
launchctl unload "$PLIST_PATH" 2>/dev/null || true
rm -f "$PLIST_PATH"
rm -rf "$APP_DIR"
rm -rf "$TARGET_PATH"

echo "✅ Background service and Quick Action uninstalled successfully."
