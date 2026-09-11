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
        themeManager.setMode(.dark)
        XCTAssertEqual(themeManager.currentMode, .dark)
        XCTAssertEqual(themeManager.currentMode.symbol, "●")

        themeManager.cycleTheme()
        XCTAssertEqual(themeManager.currentMode, .light)
        XCTAssertEqual(themeManager.currentMode.symbol, "○")

        themeManager.cycleTheme()
        XCTAssertEqual(themeManager.currentMode, .system)
        XCTAssertEqual(themeManager.currentMode.symbol, "-")

        themeManager.cycleTheme()
        XCTAssertEqual(themeManager.currentMode, .dark)
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

    func testSearchSnippetWithEmptyQuery() {
        let text = "Hello world\nThis is a multiline test"
        let snippet = SearchHighlightEngine.snippet(content: text, query: "")
        XCTAssertEqual(snippet, "Hello world This is a multiline test")
    }

    func testSearchSnippetNearStart() {
        let text = "TokenAuthService: initialize with secret key and database URL"
        let snippet = SearchHighlightEngine.snippet(content: text, query: "token", maxLength: 25)
        XCTAssertTrue(snippet.lowercased().starts(with: "token"))
        XCTAssertTrue(snippet.hasSuffix("…"))
    }

    func testSearchSnippetDeepInContent() {
        let text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec odio. Praesent libero. Sed cursus ante dapibus diam. Sed nisi. Nulla quis sem at nibh elementum imperdiet. Duis sagittis ipsum. Praesent mauris. Fusce nec tellus sed augue semper porta. Mauris massa. Vestibulum lacinia arcu eget nulla. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos."
        let snippet = SearchHighlightEngine.snippet(content: text, query: "elementum", maxLength: 35)

        XCTAssertTrue(snippet.starts(with: "… "))
        XCTAssertTrue(snippet.lowercased().contains("elementum"))
        XCTAssertTrue(snippet.hasSuffix(" …"))
    }

    func testSearchHighlightAttributed() {
        let text = "SwiftUI search highlight test"
        let attributed = SearchHighlightEngine.highlight(text: text, query: "SEARCH")

        let stringForm = String(attributed.characters)
        XCTAssertEqual(stringForm, text)

        // Find the range of "search" in attributed
        if let range = attributed.range(of: "search", options: .caseInsensitive) {
            XCTAssertNotNil(attributed[range].backgroundColor)
        } else {
            XCTFail("Expected 'search' range to be found and styled in AttributedString")
        }
    }

    func testFindAllOccurrencesAcrossClips() {
        let clip1 = ClipItem(content: "line 1: config = true\nline 2: test\nline 3: other config")
        let clip2 = ClipItem(content: "single line with config")

        let occurrences = SearchHighlightEngine.findAllOccurrences(in: [clip1, clip2], query: "config")
        XCTAssertEqual(occurrences.count, 3)

        XCTAssertEqual(occurrences[0].clipId, clip1.id)
        XCTAssertEqual(occurrences[0].lineNumber, 1)

        XCTAssertEqual(occurrences[1].clipId, clip1.id)
        XCTAssertEqual(occurrences[1].lineNumber, 3)

        XCTAssertEqual(occurrences[2].clipId, clip2.id)
        XCTAssertEqual(occurrences[2].lineNumber, 1)
    }

    func testSnippetWithExplicitTargetOffset() {
        let text = "First sentence here. Second sentence with target word here. Third sentence follows."
        // Find offset of "target"
        let range = text.range(of: "target")!
        let offset = text.distance(from: text.startIndex, to: range.lowerBound)

        let snippet = SearchHighlightEngine.snippet(content: text, query: "target", targetOffset: offset, maxLength: 30)
        XCTAssertTrue(snippet.contains("target"))
        XCTAssertTrue(snippet.starts(with: "… "))
    }
}
