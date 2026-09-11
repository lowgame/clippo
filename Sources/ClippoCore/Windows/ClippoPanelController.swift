import AppKit
import SwiftUI

final class ClippoPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        // Esc key closes panel or unfocuses search
        if event.keyCode == 53 {
            ClippoPanelController.shared.handleEscape()
            return
        }

        // Check if text input is active
        let isTextInputActive = (firstResponder is NSTextView)

        if !isTextInputActive {
            if let chars = event.charactersIgnoringModifiers,
               let num = Int(chars), num >= 1 && num <= 9,
               !event.modifierFlags.contains(.command),
               !event.modifierFlags.contains(.control) {
                ClippoPanelController.shared.selectSlot(num - 1)
                return
            }
        }

        super.keyDown(with: event)
    }
}

@MainActor
public final class ClippoPanelController: NSObject, NSWindowDelegate {
    public static let shared = ClippoPanelController()

    private var statusItem: NSStatusItem?
    private var panel: ClippoPanel?
    private var eventMonitor: Any?

    private let storage = StorageManager.shared
    private let monitor = ClipboardMonitor.shared

    private override init() {
        super.init()
    }

    public func setup() {
        setupMainMenu()
        setupStatusItem()
        setupPanel()
        monitor.startMonitoring()
    }

    // MARK: - Main Menu (Ensures Edit shortcuts Cmd+C, Cmd+V, Cmd+A, Cmd+Z work)

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Clippo")
        appMenu.addItem(withTitle: "Quit Clippo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit Menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redoItem = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(redoItem)
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Status Item Setup (Template Overlapping Pills Icon)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        updateStatusItemIcon()

        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    public func updateStatusItemIcon() {
        guard let button = statusItem?.button else { return }

        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let strokeColor = NSColor.labelColor
            strokeColor.setStroke()

            let center = CGPoint(x: 9.0, y: 9.0)
            let r: CGFloat = 5.4

            // Main circular arc sweeping around the bottom (from 130° clockwise to 50°)
            let path = NSBezierPath()
            path.appendArc(withCenter: center, radius: r, startAngle: 130, endAngle: 50, clockwise: true)
            path.lineWidth = 1.2
            path.stroke()

            // Inward folded top arc dipping down
            let leftPt = CGPoint(x: center.x - r * cos(50 * .pi / 180), y: center.y + r * sin(50 * .pi / 180))
            let rightPt = CGPoint(x: center.x + r * cos(50 * .pi / 180), y: center.y + r * sin(50 * .pi / 180))
            let foldApex = CGPoint(x: center.x, y: center.y + r * 0.15)

            let foldPath = NSBezierPath()
            foldPath.move(to: leftPt)
            foldPath.curve(
                to: rightPt,
                controlPoint1: CGPoint(x: center.x - 1.5, y: foldApex.y),
                controlPoint2: CGPoint(x: center.x + 1.5, y: foldApex.y)
            )
            foldPath.lineWidth = 1.2
            foldPath.stroke()

            return true
        }
        image.isTemplate = true
        button.image = image
    }

    // MARK: - Panel Setup

    private func setupPanel() {
        let popoverContent = ClippoPopoverView(
            storage: storage,
            monitor: monitor,
            onClose: { [weak self] in
                self?.closePanel()
            }
        )

        let hostingView = NSHostingView(rootView: popoverContent)

        let panel = ClippoPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isMovableByWindowBackground = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.delegate = self

        self.panel = panel
    }

    // MARK: - Actions

    @objc private func statusItemClicked() {
        guard let panel = panel, let button = statusItem?.button else { return }

        if panel.isVisible {
            closePanel()
        } else {
            showPanel(relativeTo: button)
        }
    }

    private func showPanel(relativeTo button: NSStatusBarButton) {
        guard let panel = panel else { return }

        // Position panel directly beneath status item icon
        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
        let panelWidth = panel.frame.width
        let x = buttonFrame.midX - (panelWidth / 2)
        let y = buttonFrame.minY - panel.frame.height - 4

        panel.setFrameOrigin(NSPoint(x: max(10, x), y: y))
        ThemeManager.shared.applyAppearance(to: panel)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Make sure focus is clean so 1..9 immediately work
        panel.makeFirstResponder(panel.contentView)

        // Monitor clicks outside the panel to auto-dismiss
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, let p = self.panel, p.isVisible else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !p.frame.contains(mouseLocation) {
                self.closePanel()
            }
        }
    }

    public func closePanel() {
        panel?.orderOut(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    public func handleEscape() {
        closePanel()
    }

    public func selectSlot(_ index: Int) {
        if index >= 0 && index < storage.items.count {
            let item = storage.items[index]
            monitor.copyToPasteboard(item: item)
            closePanel()
        }
    }
}
