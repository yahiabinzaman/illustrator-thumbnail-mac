# 🎨 Illustrator Thumbnail Codec & Preview Generator for Mac

> **High-Performance macOS Vector Thumbnail Engine** — Extracts embedded raster artwork previews directly from Adobe Illustrator (`.ai`, `.eps`, `.pdf`) files and injects them into macOS Finder.
> 
> Works seamlessly across **Local Folders**, **External SSDs**, and **NAS / Network Servers (`/Volumes`)** even if **"Create PDF Compatible File" was turned off** in Adobe Illustrator!

---

## 🌟 The Problem & Solution

### ⚠️ The Problem:
When saving `.ai` files in Adobe Illustrator with **"Create PDF Compatible File"** unchecked (to save file size and disk space), macOS Finder fails to show visual thumbnail previews — showing only generic blank white icons. Furthermore, default preview scaling often distorts (squashes/stretches) landscape and portrait designs into square icons.

### 💡 The Solution:
This native Swift engine parses the internal **XMP metadata** and embedded JPEG raster stream of `.ai` files and generates **proportional (Aspect-Fit)** high-resolution Finder thumbnails without distorting your artwork.

---

## 🚀 Key Features

- ⚡ **High-Speed Native Swift Engine:** Processes 100+ files per second with minimal overhead.
- 🎯 **Smart Aspect-Fit Proportional Scaling:** Maintains true aspect ratios (landscape banners, portrait cards, square graphics) without squashing or stretching.
- 👀 **24/7 Real-Time Auto-Watcher:** Uses native Apple `FSEvents` to monitor file saves/modifications in real-time with **0% idle CPU and battery drain**.
- 🌐 **Full NAS & Network Storage Support:** Automatically watches and processes files on network shares (`/Volumes/NAS_Name`), external drives, and local directories.
- 🖱️ **Finder Right-Click Quick Action:** Right-click any file or folder in Finder to instantly generate previews via `Quick Actions > ✨ Generate AI Thumbnails`.
- 📦 **1-Click DMG Installer:** Ready-to-use `.dmg` package with automated system background service setup.

---

## 📥 Installation & Setup

### Method 1: 1-Click Installer (Recommended)
1. Download or open **`Illustrator_Thumbnail_Mac.dmg`** (or open the project folder).
2. Double-click **`1. [CLICK ME] Enable 24-7 Auto Preview.command`** (or `Install_Permanent_Background_Service.command`).
3. Done! The service is now permanently active in the background and will automatically start whenever your Mac boots up.

---

### Method 2: Terminal / Command Line Installation

Open Terminal and run the following commands:

```bash
# 1. Clone the repository
git clone https://github.com/yahiabinzaman/illustrator-thumbnail-mac.git
cd illustrator-thumbnail-mac

# 2. Make scripts executable
chmod +x *.command *.sh bin/ai-codec

# 3. Install 24/7 Background Service & LaunchAgent
./Install_Permanent_Background_Service.command

# 4. Install Finder Right-Click Quick Action
./Install_Finder_Quick_Action.sh
```

---

## 💻 CLI / Terminal Usage

You can also use the standalone `ai-codec` command-line tool directly:

```bash
# 1. Generate thumbnail for a single file
./bin/ai-codec "/path/to/design.ai"

# 2. Process an entire folder (non-recursive)
./bin/ai-codec -f "/path/to/folder"

# 3. Recursively scan a whole folder and all subfolders (Great for entire project directories or NAS drives)
./bin/ai-codec -r "/Volumes/Your_NAS_Server/Designs"

# 4. Start live real-time watcher in Terminal (Watches Home Directory and all /Volumes)
./bin/ai-codec -w

# 5. Start live watcher on specific custom paths
./bin/ai-codec -w "/Volumes/NAS_Share" "/Users/username/Projects"
```

---

## 🖥️ Finder Views & Previews Guide

| Finder View | Shortcut | How it looks |
| :--- | :--- | :--- |
| **Icons View** | `Cmd + 1` | Full visual thumbnail preview on the file icon |
| **List View** | `Cmd + 2` | Small thumbnail preview next to filename |
| **Columns View** | `Cmd + 3` | Visual icon in the file list |
| **Gallery View** | `Cmd + 4` | **Large full-resolution visual preview** of the design artwork |

> [!TIP]
> **About Spacebar (Quick Look):**
> When "Create PDF Compatible File" is disabled in Illustrator, macOS Quick Look reads Adobe's fallback warning text. To view designs at large scale in Finder, simply switch to **Gallery View (`Cmd + 4`)** to see the full embedded artwork preview!

---

## 🛠️ Managing the Background Service

### Check Service Status:
```bash
launchctl list | grep ai-thumbnail
```

### View Live Service Logs:
```bash
tail -f /tmp/ai_thumbnail_watcher.log
```

### Uninstall / Disable Service:
Simply double-click **`Uninstall_Background_Service.command`** or run:
```bash
./Uninstall_Background_Service.command
```

---

## 🔨 Compiling from Source

If you wish to recompile the native Swift binary manually:

```bash
swiftc -O -o bin/ai-codec src/ai_thumbnail_engine.swift
chmod +x bin/ai-codec
```

---

## 📄 License
MIT License. Free for personal and commercial use.