import Foundation

public struct ClipItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let content: String
    public let timestamp: Date
    public let sourceAppBundle: String?

    public init(
        id: UUID = UUID(),
        content: String,
        timestamp: Date = Date(),
        sourceAppBundle: String? = nil
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.sourceAppBundle = sourceAppBundle
    }

    /// Single line clean preview with whitespace collapsed for compact row scanning
    public var cleanPreview: String {
        let singleLine = content
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        return singleLine.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isMultiLineOrLong: Bool {
        content.contains("\n") || content.count > 34
    }

    public var charCount: Int {
        content.count
    }

    public var charCountLabel: String {
        if charCount > 9999 {
            return String(format: "%.1fk c", Double(charCount) / 1000.0)
        }
        return "\(charCount)c"
    }

    public var timeAgo: String {
        let elapsed = -timestamp.timeIntervalSinceNow
        if elapsed < 60 {
            return "now"
        } else if elapsed < 3600 {
            return "\(Int(elapsed / 60))m"
        } else if elapsed < 86400 {
            return "\(Int(elapsed / 3600))h"
        } else {
            return "\(Int(elapsed / 86400))d"
        }
    }
}
