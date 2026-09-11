import AppKit
import ClippoCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run strictly as menu bar accessory agent (no Dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Initialize status bar item, panel, and clipboard monitor
        ClippoPanelController.shared.setup()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
