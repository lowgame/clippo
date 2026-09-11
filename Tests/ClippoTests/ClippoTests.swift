import XCTest
@testable import ClippoCore

final class ClippoTests: XCTestCase {

    func testClipItemPreviewSanitization() {
        let raw = "First line\nSecond line\r\n\tTabbed text   "
        let item = ClipItem(content: raw)

        XCTAssertEqual(item.cleanPreview, "First line Second line  Tabbed text")
        XCTAssertEqual(item.charCount, raw.count)
        XCTAssertEqual(item.charCountLabel, "\(raw.count)c")
    }

    func testClipItemTimeAgo() {
        let item = ClipItem(content: "test", timestamp: Date())
        XCTAssertEqual(item.timeAgo, "now")

        let tenMinutesAgo = Date().addingTimeInterval(-600)
        let itemOld = ClipItem(content: "old", timestamp: tenMinutesAgo)
        XCTAssertEqual(itemOld.timeAgo, "10m")
    }

    @MainActor
    func testStorageManagerEnforces50Limit() {
        let storage = StorageManager()
        storage.clearAll()

        for i in 1...60 {
            storage.add(content: "Item \(i)")
        }

        XCTAssertEqual(storage.items.count, 50)
        XCTAssertEqual(storage.items.first?.content, "Item 60")

        // Cleanup
        storage.clearAll()
    }

    @MainActor
    func testStorageManagerDeduplicationAndBubbling() {
        let storage = StorageManager()
        storage.clearAll()

        storage.add(content: "Alpha")
        storage.add(content: "Beta")
        storage.add(content: "Gamma")

        XCTAssertEqual(storage.items.count, 3)
        XCTAssertEqual(storage.items.map { $0.content }, ["Gamma", "Beta", "Alpha"])

        // Re-adding "Alpha" should bubble it to the top without increasing count
        storage.add(content: "Alpha")
        XCTAssertEqual(storage.items.count, 3)
        XCTAssertEqual(storage.items.map { $0.content }, ["Alpha", "Gamma", "Beta"])

        // Adding identical to top should be a no-op
        storage.add(content: "Alpha")
        XCTAssertEqual(storage.items.count, 3)

        // Cleanup
        storage.clearAll()
    }

    @MainActor
    func testThemeCycle() {
        let themeManager = ThemeManager.shared
        themeManager.setMode(.system)
        XCTAssertEqual(themeManager.currentMode, .system)

        themeManager.cycleTheme()
        XCTAssertEqual(themeManager.currentMode, .dark)

        themeManager.cycleTheme()
        XCTAssertEqual(themeManager.currentMode, .light)

        themeManager.cycleTheme()
        XCTAssertEqual(themeManager.currentMode, .system)
    }

    @MainActor
    func testSensitivePasteboardTypes() {
        let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        let transient = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        let standard = NSPasteboard.PasteboardType.string

        let customPasteboard = NSPasteboard.withUniqueName()
        customPasteboard.declareTypes([concealed, transient, standard], owner: nil)

        let monitor = ClipboardMonitor(pasteboard: customPasteboard)
        XCTAssertTrue(monitor.isSensitivePasteboard())

        let regularPasteboard = NSPasteboard.withUniqueName()
        regularPasteboard.declareTypes([standard], owner: nil)
        let safeMonitor = ClipboardMonitor(pasteboard: regularPasteboard)
        XCTAssertFalse(safeMonitor.isSensitivePasteboard())
    }
}
