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

        // Cmd+Return copies the active search match immediately
        if event.keyCode == 36 && event.modifierFlags.contains(.command) {
            NotificationCenter.default.post(name: .clippoCopyCurrentMatch, object: nil)
            return
        }

        // Down Arrow (125) / Up Arrow (126) navigates search matches
        if event.keyCode == 125 {
            NotificationCenter.default.post(name: .clippoNextMatch, object: nil)
            return
        }
        if event.keyCode == 126 {
            NotificationCenter.default.post(name: .clippoPrevMatch, object: nil)
            return
        }

        // Cmd+S: Save to iCloud with HUD feedback
        if (event.charactersIgnoringModifiers?.lowercased() == "s" || event.keyCode == 1) && event.modifierFlags.contains(.command) {
            NotificationCenter.default.post(name: .clippoTriggerSave, object: nil)
            return
        }

        // Check if text input is active
        let isTextInputActive = (firstResponder is NSTextView)

        if !isTextInputActive {
            // Return key copies current match when not typing
            if event.keyCode == 36 {
                NotificationCenter.default.post(name: .clippoCopyCurrentMatch, object: nil)
                return
            }

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

    public var currentPanel: NSPanel? { panel }

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
        setupFamilyOObservers()
    }

    // MARK: - Main Menu (Ensures Edit shortcuts Cmd+C, Cmd+V, Cmd+A, Cmd+Z work)

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Clippo")

        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLoginAction), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        appMenu.addItem(launchAtLoginItem)

        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Clippo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        let saveItem = NSMenuItem(title: "Save to iCloud", action: #selector(saveToiCloudAction), keyEquivalent: "s")
        saveItem.target = self
        fileMenu.addItem(saveItem)
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

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

    @objc private func toggleLaunchAtLoginAction() {
        LaunchAtLoginManager.shared.toggle()
        setupMainMenu()
    }

    @objc private func saveToiCloudAction() {
        NotificationCenter.default.post(name: .clippoTriggerSave, object: nil)
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
            let r: CGFloat = 5.8
            let strokeWidth: CGFloat = 1.3

            let pTop = CGPoint(x: center.x, y: center.y + r)
            let pRight = CGPoint(x: center.x + r, y: center.y)
            let cornerTip = CGPoint(x: center.x + r * 0.30, y: center.y + r * 0.30)

            let path = NSBezierPath()
            path.lineWidth = strokeWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            // Sweep from 90° counter-clockwise around the bottom to 0°
            path.appendArc(withCenter: center, radius: r, startAngle: 90, endAngle: 0, clockwise: false)

            // Crease line across to top
            path.line(to: pTop)

            // Folded corner flap
            path.line(to: cornerTip)
            path.line(to: pRight)

            path.stroke()
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

        // Monitor clicks outside the panel (and preview panel) to auto-dismiss
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, let p = self.panel, p.isVisible else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !p.frame.contains(mouseLocation) && !ClippoPreviewPanelController.shared.contains(screenPoint: mouseLocation) {
                self.closePanel()
            }
        }
    }

    public func closePanel() {
        ClippoPreviewPanelController.shared.hide()
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
        NotificationCenter.default.post(name: .clippoSelectSlot, object: index)
    }

    // MARK: - Family O Integration

    private func setupFamilyOObservers() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleFamilyOToggle),
            name: Notification.Name("family.o.clippo.toggle"),
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleFamilyOSaveAll),
            name: Notification.Name("family.o.saveAll"),
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleFamilyOHubState),
            name: Notification.Name("family.o.hubState"),
            object: nil
        )
        checkFamilyOHubRunning()
    }

    private func checkFamilyOHubRunning() {
        let isHubRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.family-o.hub" || $0.localizedName?.lowercased() == "o"
        }
        statusItem?.isVisible = !isHubRunning
    }

    @objc private func handleFamilyOHubState(_ notification: Notification) {
        if let isRunning = notification.userInfo?["isRunning"] as? Bool {
            statusItem?.isVisible = !isRunning
        } else {
            checkFamilyOHubRunning()
        }
    }

    @objc private func handleFamilyOToggle() {
        guard let panel = panel else { return }
        if panel.isVisible {
            closePanel()
        } else {
            if let button = statusItem?.button, statusItem?.isVisible == true {
                showPanel(relativeTo: button)
            } else {
                if let screen = NSScreen.main {
                    let frame = screen.visibleFrame
                    let x = frame.maxX - panel.frame.width - 24
                    let y = frame.maxY - panel.frame.height - 8
                    panel.setFrameOrigin(NSPoint(x: max(10, x), y: y))
                }
                ThemeManager.shared.applyAppearance(to: panel)
                panel.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                panel.makeFirstResponder(panel.contentView)
            }
        }
    }

    @objc private func handleFamilyOSaveAll() {
        NotificationCenter.default.post(name: .clippoTriggerSave, object: nil)
    }
}

extension Notification.Name {
    public static let clippoSelectSlot = Notification.Name("clippoSelectSlot")
    public static let clippoCopyCurrentMatch = Notification.Name("clippoCopyCurrentMatch")
    public static let clippoNextMatch = Notification.Name("clippoNextMatch")
    public static let clippoPrevMatch = Notification.Name("clippoPrevMatch")
    public static let clippoTriggerSave = Notification.Name("clippoTriggerSave")
}

