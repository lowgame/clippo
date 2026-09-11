import AppKit
import SwiftUI
import ClippoCore

@main
struct ScreenshotGenerator {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let storage = StorageManager()
        let monitor = ClipboardMonitor(storage: storage)

        let sampleClips = [
            ClipItem(content: "const config = {\n  apiKey: 'xyz-987-token',\n  database_url: 'postgres://localhost:5432/main_db',\n  timeout: 30000\n};"),
            ClipItem(content: "brew install lowgame/tap/clippo"),
            ClipItem(content: "curl -X POST https://api.anthropic.com/v1/messages \\\n  -H 'x-api-key: $ANTHROPIC_API_KEY' \\\n  -d '{\"model\": \"claude-3-7-sonnet\"}'"),
            ClipItem(content: "git commit -m \"feat: ultra-minimalist clipboard history\""),
            ClipItem(content: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG... dev@macbook"),
            ClipItem(content: "SELECT id, name, created_at FROM users WHERE active = true ORDER BY id DESC LIMIT 50;")
        ]

        storage.setForPreview(items: sampleClips)

        final class ScreenshotPanel: NSPanel {
            override var canBecomeKey: Bool { true }
            override var canBecomeMain: Bool { true }
        }

        func makePanel(width: CGFloat, height: CGFloat) -> ScreenshotPanel {
            let panel = ScreenshotPanel(
                contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.isMovableByWindowBackground = true
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true

            let screen = NSScreen.screens.first(where: { $0.backingScaleFactor >= 2.0 }) ?? NSScreen.main!
            let screenFrame = screen.frame
            let x = screenFrame.origin.x + (screenFrame.width - width) / 2
            let y = screenFrame.origin.y + (screenFrame.height - height) / 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
            return panel
        }

        func capture(panel: NSPanel, to path: String) {
            let wid = CGWindowID(panel.windowNumber)
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            proc.arguments = ["-l\(wid)", path]
            try? proc.run()
            proc.waitUntilExit()
        }

        let cwd = FileManager.default.currentDirectoryPath
        let assetsDir = "\(cwd)/assets"
        try? FileManager.default.createDirectory(atPath: assetsDir, withIntermediateDirectories: true)

        let themeManager = ThemeManager.shared

        // 1. Capture Dark Mode List
        themeManager.setMode(.dark)
        let darkPanel = makePanel(width: 320, height: 320)
        let darkView = ClippoPopoverView(storage: storage, monitor: monitor, onClose: {})
        darkPanel.contentView = NSHostingView(rootView: darkView)
        darkPanel.orderFrontRegardless()
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        capture(panel: darkPanel, to: "\(assetsDir)/clippo_list_dark.png")
        print("[+] Captured clippo_list_dark.png")
        darkPanel.close()

        // 2. Capture Preview Panel (Sidecar full text inspection)
        let previewPanel = makePanel(width: 340, height: 320)
        let previewView = ClipPreviewDetailView(
            item: sampleClips[0],
            searchQuery: "database_url",
            activeLineNumber: 3,
            onCopy: {}
        )
        previewPanel.contentView = NSHostingView(rootView: previewView)
        previewPanel.orderFrontRegardless()
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        capture(panel: previewPanel, to: "\(assetsDir)/clippo_preview_dark.png")
        print("[+] Captured clippo_preview_dark.png")
        previewPanel.close()

        // 3. Capture Light Mode
        themeManager.setMode(.light)
        let lightPanel = makePanel(width: 320, height: 320)
        let lightView = ClippoPopoverView(storage: storage, monitor: monitor, onClose: {})
        lightPanel.contentView = NSHostingView(rootView: lightView)
        lightPanel.orderFrontRegardless()
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        capture(panel: lightPanel, to: "\(assetsDir)/clippo_light.png")
        print("[+] Captured clippo_light.png")
        lightPanel.close()
    }
}
