import AppKit
import SwiftUI

@MainActor
public final class ClippoPreviewPanelController: NSObject {
    public static let shared = ClippoPreviewPanelController()

    private var panel: NSPanel?
    private var currentItemId: UUID?
    public var isMouseInsidePreview: Bool = false

    private override init() {
        super.init()
    }

    public func show(
        item: ClipItem,
        searchQuery: String,
        activeLineNumber: Int? = nil,
        relativeTo parentPanel: NSPanel,
        onCopy: @escaping () -> Void
    ) {
        if panel == nil {
            setupPanel()
        }

        guard let panel = panel else { return }

        currentItemId = item.id
        updateContent(item: item, searchQuery: searchQuery, activeLineNumber: activeLineNumber, onCopy: onCopy)
        positionPanel(relativeTo: parentPanel)

        ThemeManager.shared.applyAppearance(to: panel)
        panel.orderFront(nil)
    }

    public func hide() {
        panel?.orderOut(nil)
        currentItemId = nil
        isMouseInsidePreview = false
    }

    public var isVisible: Bool {
        panel?.isVisible ?? false
    }

    public func contains(screenPoint: NSPoint) -> Bool {
        guard let panel = panel, panel.isVisible else { return false }
        return panel.frame.contains(screenPoint)
    }

    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 400),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isMovableByWindowBackground = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        ThemeManager.shared.applyAppearance(to: panel)

        self.panel = panel
    }

    private func updateContent(
        item: ClipItem,
        searchQuery: String,
        activeLineNumber: Int?,
        onCopy: @escaping () -> Void
    ) {
        guard let panel = panel else { return }

        let previewView = ClipPreviewDetailView(
            item: item,
            searchQuery: searchQuery,
            activeLineNumber: activeLineNumber,
            onHoverChanged: { [weak self] isInside in
                self?.isMouseInsidePreview = isInside
            },
            onCopy: { [weak self] in
                self?.hide()
                onCopy()
            }
        )

        let hostingView = NSHostingView(rootView: previewView)
        panel.contentView = hostingView
    }

    private func positionPanel(relativeTo parentPanel: NSPanel) {
        guard let panel = panel else { return }

        let screen = parentPanel.screen ?? NSScreen.main ?? NSScreen.screens.first
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let previewWidth: CGFloat = 340
        let previewHeight: CGFloat = parentPanel.frame.height
        let gap: CGFloat = 6

        // Check if placing to the left of parent fits on screen
        let leftX = parentPanel.frame.minX - previewWidth - gap
        let rightX = parentPanel.frame.maxX + gap

        let finalX: CGFloat
        if leftX >= visibleFrame.minX {
            // Fits to the left (preferred for menu bar on right side of screen)
            finalX = leftX
        } else if rightX + previewWidth <= visibleFrame.maxX {
            // Fits to the right
            finalX = rightX
        } else {
            // Fallback clamped
            finalX = max(visibleFrame.minX, leftX)
        }

        let finalY = parentPanel.frame.minY
        panel.setFrame(NSRect(x: finalX, y: finalY, width: previewWidth, height: previewHeight), display: true)
    }
}
