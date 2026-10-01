import Foundation
import AppKit
import PDFKit
import CoreGraphics

// ==============================================================================
// AI Thumbnail Codec & Preview Generator for macOS
// Extracts embedded raster previews from Adobe Illustrator (.ai) files
// even if "Create PDF Compatible File" was turned off!
// ==============================================================================

class AIThumbnailExtractor {
    
    /// Try extracting thumbnail from XMP metadata (<xmpGImg:image>)
    static func extractXMPThumbnail(from fileURL: URL) -> NSImage? {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return nil }
        defer { try? fileHandle.close() }
        
        // Read the first 2MB (XMP metadata is always near the beginning)
        let headerData = fileHandle.readData(ofLength: 2 * 1024 * 1024)
        guard !headerData.isEmpty else { return nil }
        
        let startTag = "xmpGImg:image>".data(using: .utf8)!
        let endTag = "<".data(using: .utf8)!
        
        guard let startRange = headerData.range(of: startTag) else { return nil }
        let searchStartIndex = startRange.upperBound
        
        let remainingData = headerData.subdata(in: searchStartIndex..<headerData.count)
        guard let endRange = remainingData.range(of: endTag) else { return nil }
        
        let rawBase64Data = remainingData.subdata(in: 0..<endRange.lowerBound)
        guard var base64Str = String(data: rawBase64Data, encoding: .utf8) else { return nil }
        
        // Clean XML entities and whitespace
        base64Str = base64Str.replacingOccurrences(of: "&#xA;", with: "")
        base64Str = base64Str.replacingOccurrences(of: "\n", with: "")
        base64Str = base64Str.replacingOccurrences(of: "\r", with: "")
        base64Str = base64Str.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let imageData = Data(base64Encoded: base64Str, options: .ignoreUnknownCharacters) else { return nil }
        return NSImage(data: imageData)
    }
    
    /// Try extracting older PostScript ASCII-Hex thumbnail (%AI7_Thumbnail:)
    static func extractAI7Thumbnail(from fileURL: URL) -> NSImage? {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return nil }
        defer { try? fileHandle.close() }
        
        let headerData = fileHandle.readData(ofLength: 1024 * 1024)
        guard let text = String(data: headerData, encoding: .ascii) else { return nil }
        
        guard let startRange = text.range(of: "%AI7_Thumbnail:") else { return nil }
        let sub = text[startRange.upperBound...]
        guard let endRange = sub.range(of: "%%EndData") else { return nil }
        
        let hexBlock = sub[..<endRange.lowerBound]
        let lines = hexBlock.components(separatedBy: .newlines)
        var hexDataString = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.starts(with: "%") {
                let stripped = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                hexDataString.append(stripped)
            }
        }
        
        var data = Data()
        var hexIndex = hexDataString.startIndex
        while hexIndex < hexDataString.endIndex {
            let nextIndex = hexDataString.index(hexIndex, offsetBy: 2, limitedBy: hexDataString.endIndex) ?? hexDataString.endIndex
            let byteString = String(hexDataString[hexIndex..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            }
            hexIndex = nextIndex
        }
        
        guard !data.isEmpty else { return nil }
        return NSImage(data: data)
    }
    
    /// Try extracting PDF first page render if PDF stream exists
    static func extractPDFPage(from fileURL: URL) -> NSImage? {
        guard let pdfDoc = PDFDocument(url: fileURL),
              let page = pdfDoc.page(at: 0) else { return nil }
        
        let pageRect = page.bounds(for: .mediaBox)
        let targetSize = NSSize(width: max(pageRect.width, 256), height: max(pageRect.height, 256))
        return page.thumbnail(of: targetSize, for: .mediaBox)
    }
    
    /// Master extractor: Tries XMP -> PDF -> AI7
    static func getThumbnail(for fileURL: URL) -> NSImage? {
        if let img = extractXMPThumbnail(from: fileURL) {
            return img
        }
        if let img = extractPDFPage(from: fileURL) {
            return img
        }
        if let img = extractAI7Thumbnail(from: fileURL) {
            return img
        }
        return nil
    }
    
    /// Creates an aspect-fit square icon so Finder does not stretch/distort non-square designs
    static func createAspectFitSquareIcon(from sourceImage: NSImage, targetDimension: CGFloat = 512) -> NSImage {
        var srcWidth = sourceImage.size.width
        var srcHeight = sourceImage.size.height
        
        if let rep = sourceImage.representations.first {
            if rep.pixelsWide > 0 && rep.pixelsHigh > 0 {
                srcWidth = CGFloat(rep.pixelsWide)
                srcHeight = CGFloat(rep.pixelsHigh)
            }
        }
        
        guard srcWidth > 0 && srcHeight > 0 else { return sourceImage }
        
        let scale = min(targetDimension / srcWidth, targetDimension / srcHeight)
        let drawWidth = round(srcWidth * scale)
        let drawHeight = round(srcHeight * scale)
        let drawX = round((targetDimension - drawWidth) / 2.0)
        let drawY = round((targetDimension - drawHeight) / 2.0)
        
        let squareImage = NSImage(size: NSSize(width: targetDimension, height: targetDimension))
        squareImage.lockFocus()
        
        if let ctx = NSGraphicsContext.current {
            ctx.imageInterpolation = .high
            ctx.shouldAntialias = true
        }
        
        let destRect = NSRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
        sourceImage.draw(in: destRect, from: NSRect(x: 0, y: 0, width: sourceImage.size.width, height: sourceImage.size.height), operation: .sourceOver, fraction: 1.0)
        
        squareImage.unlockFocus()
        return squareImage
    }

    /// Sets Finder Custom Icon for file
    static func applyIcon(image: NSImage, to fileURL: URL) -> Bool {
        let squareIcon = createAspectFitSquareIcon(from: image)
        return NSWorkspace.shared.setIcon(squareIcon, forFile: fileURL.path, options: [])
    }
}

// ==============================================================================
// CLI Processor
// ==============================================================================

func processFile(path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    let ext = url.pathExtension.lowercased()
    guard ext == "ai" || ext == "eps" || ext == "pdf" else { return false }
    
    if let image = AIThumbnailExtractor.getThumbnail(for: url) {
        let success = AIThumbnailExtractor.applyIcon(image: image, to: url)
        if success {
            print("✅ [PREVIEW SET] \(url.lastPathComponent)")
            return true
        } else {
            print("⚠️ [ICON FAILED] \(url.lastPathComponent)")
            return false
        }
    } else {
        print("❌ [NO PREVIEW FOUND] \(url.lastPathComponent)")
        return false
    }
}

func scanFolder(dirPath: String, recursive: Bool) -> (total: Int, success: Int) {
    let url = URL(fileURLWithPath: dirPath)
    guard let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: recursive ? [] : [.skipsSubdirectoryDescendants]
    ) else {
        print("❌ Cannot read folder: \(dirPath)")
        return (0, 0)
    }
    
    var total = 0
    var successCount = 0
    
    for case let fileURL as URL in enumerator {
        let ext = fileURL.pathExtension.lowercased()
        if ext == "ai" || ext == "eps" {
            total += 1
            if processFile(path: fileURL.path) {
                successCount += 1
            }
        }
    }
    
    return (total, successCount)
}

// ==============================================================================
// Native FSEvents Background Watcher
// ==============================================================================

import CoreServices

func startWatcher(watchPaths: [String]) {
    print("👀 AI Thumbnail Background Watcher Active!")
    print("======================================================================")
    for p in watchPaths {
        print(" 📂 Watching: \(p)")
    }
    print("======================================================================")
    print("🚀 Active! Whenever an .ai / .eps file is saved or opened anywhere,")
    print("   macOS Finder will automatically show the full thumbnail preview.")
    print("   (Press Ctrl+C to stop, or run as background LaunchAgent)\n")
    
    let callback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
        guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }
        for path in paths {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
                if isDir.boolValue {
                    // Automatically process any folders that were copied/unzipped/moved
                    _ = scanFolder(dirPath: path, recursive: true)
                } else {
                    let ext = (path as NSString).pathExtension.lowercased()
                    if ext == "ai" || ext == "eps" {
                        usleep(300_000)
                        _ = processFile(path: path)
                    }
                }
            }
        }
    }
    
    var context = FSEventStreamContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
    guard let stream = FSEventStreamCreate(
        kCFAllocatorDefault,
        callback,
        &context,
        watchPaths as CFArray,
        FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
        0.5,
        FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer)
    ) else {
        print("❌ Failed to create FSEventStream")
        return
    }
    
    FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
    FSEventStreamStart(stream)
    dispatchMain()
}

// ==============================================================================
// Main Entry Point
// ==============================================================================

let args = CommandLine.arguments

if args.count < 2 {
    print("""
    🎨 AI Thumbnail Codec for Mac
    ======================================================================
    Usage:
      ai-codec <file.ai>                      # Generate preview for single file
      ai-codec -f /path/to/folder             # Scan folder (non-recursive)
      ai-codec -r /path/to/folder             # Scan folder and subfolders (recursive)
      ai-codec -w [/path/to/watch ...]        # Real-time background watcher (Local + NAS)
    ======================================================================
    """)
    exit(0)
}

let mode = args[1]

if mode == "-w" || mode == "--watch" {
    var targets: [String] = []
    if args.count > 2 {
        for i in 2..<args.count {
            targets.append(args[i])
        }
    } else {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        targets = [home, "/Volumes"]
    }
    startWatcher(watchPaths: targets)
} else if mode == "-r" || mode == "--recursive" {
    let targetDir = args.count > 2 ? args[2] : FileManager.default.currentDirectoryPath
    print("🚀 Recursively generating thumbnails in: \(targetDir)")
    let res = scanFolder(dirPath: targetDir, recursive: true)
    print("\n🎉 Completed! Updated \(res.success) / \(res.total) files.")
} else if mode == "-f" || mode == "--folder" {
    let targetDir = args.count > 2 ? args[2] : FileManager.default.currentDirectoryPath
    print("🚀 Generating thumbnails in: \(targetDir)")
    let res = scanFolder(dirPath: targetDir, recursive: false)
    print("\n🎉 Completed! Updated \(res.success) / \(res.total) files.")
} else {
    var successCount = 0
    for i in 1..<args.count {
        let filePath = args[i]
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir) {
            if isDir.boolValue {
                let res = scanFolder(dirPath: filePath, recursive: true)
                successCount += res.success
            } else {
                if processFile(path: filePath) {
                    successCount += 1
                }
            }
        }
    }
    print("\n🎉 Done! Processed \(successCount) file(s).")
}
