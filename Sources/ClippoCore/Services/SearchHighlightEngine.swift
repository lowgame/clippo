import Foundation
import SwiftUI

public struct SearchMatchOccurrence: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let clipId: UUID
    public let clipIndex: Int
    public let occurrenceInClip: Int
    public let charOffset: Int
    public let lineNumber: Int

    public init(
        id: UUID = UUID(),
        clipId: UUID,
        clipIndex: Int,
        occurrenceInClip: Int,
        charOffset: Int,
        lineNumber: Int
    ) {
        self.id = id
        self.clipId = clipId
        self.clipIndex = clipIndex
        self.occurrenceInClip = occurrenceInClip
        self.charOffset = charOffset
        self.lineNumber = lineNumber
    }
}

public enum SearchHighlightEngine {

    /// Finds all match occurrences across a list of items, mapping exact line and character positions.
    public static func findAllOccurrences(in items: [ClipItem], query: String) -> [SearchMatchOccurrence] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let words = trimmedQuery.lowercased().split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else { return [] }

        var results: [SearchMatchOccurrence] = []

        for (clipIndex, item) in items.enumerated() {
            let lines = item.content.components(separatedBy: "\n")
            var runningOffset = 0
            var occurrenceCounter = 0

            for (lineIndex, lineText) in lines.enumerated() {
                let lineNumber = lineIndex + 1
                let lowerLine = lineText.lowercased()

                for word in words {
                    var searchStart = lowerLine.startIndex
                    while searchStart < lowerLine.endIndex,
                          let matchRange = lowerLine[searchStart...].range(of: word) {
                        let offsetInLine = lowerLine.distance(from: lowerLine.startIndex, to: matchRange.lowerBound)
                        let totalOffset = runningOffset + offsetInLine

                        results.append(
                            SearchMatchOccurrence(
                                clipId: item.id,
                                clipIndex: clipIndex,
                                occurrenceInClip: occurrenceCounter,
                                charOffset: totalOffset,
                                lineNumber: lineNumber
                            )
                        )
                        occurrenceCounter += 1

                        if matchRange.upperBound < lowerLine.endIndex {
                            searchStart = matchRange.upperBound
                        } else {
                            break
                        }
                    }
                }

                // Account for newline character
                runningOffset += lineText.count + 1
            }
        }

        return results
    }

    /// Generates a single-line snippet centered around a specific character offset or the first match.
    public static func snippet(
        content: String,
        query: String,
        targetOffset: Int? = nil,
        maxLength: Int = 45
    ) -> String {
        // Sanitize multi-line and whitespace to single line
        let singleLine = content
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return singleLine
        }

        let words = trimmedQuery.lowercased().split(separator: " ").map(String.init)
        guard !words.isEmpty else {
            return singleLine
        }

        let lowerContent = singleLine.lowercased()

        var matchOffset = targetOffset ?? 0
        if targetOffset == nil {
            // Find the earliest match of any query token
            var earliestMatchRange: Range<String.Index>? = nil
            for word in words {
                if let range = lowerContent.range(of: word) {
                    if let currentEarliest = earliestMatchRange {
                        if range.lowerBound < currentEarliest.lowerBound {
                            earliestMatchRange = range
                        }
                    } else {
                        earliestMatchRange = range
                    }
                }
            }
            if let range = earliestMatchRange {
                matchOffset = singleLine.distance(from: singleLine.startIndex, to: range.lowerBound)
            } else {
                return singleLine
            }
        }

        matchOffset = min(max(0, matchOffset), singleLine.count)

        // If the match is already near the start, just return prefix
        if matchOffset <= 15 {
            if singleLine.count <= maxLength {
                return singleLine
            } else {
                let endIdx = singleLine.index(singleLine.startIndex, offsetBy: min(singleLine.count, maxLength))
                return String(singleLine[..<endIdx]) + " …"
            }
        }

        // Match is deeper in the string: center snippet around the match
        let leadingContext = 12
        let startOffset = max(0, matchOffset - leadingContext)
        let startIdx = singleLine.index(singleLine.startIndex, offsetBy: min(startOffset, singleLine.count))

        let remainingLength = singleLine.count - startOffset
        let snippetLength = min(remainingLength, maxLength)
        let endIdx = singleLine.index(startIdx, offsetBy: max(0, min(snippetLength, singleLine.distance(from: startIdx, to: singleLine.endIndex))))

        let prefix = startOffset > 0 ? "… " : ""
        let suffix = endIdx < singleLine.endIndex ? " …" : ""

        return prefix + String(singleLine[startIdx..<endIdx]) + suffix
    }

    /// Highlights all occurrences of query tokens with high-contrast text and background badge
    public static func highlight(
        text: String,
        query: String,
        isMono: Bool = true,
        baseColor: Color = MonocleTheme.foreground
    ) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.font = isMono ? MonocleTheme.fontMono : MonocleTheme.fontBody
        attributed.foregroundColor = baseColor

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return attributed
        }

        let words = trimmedQuery.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else {
            return attributed
        }

        for word in words {
            var searchRange = attributed.startIndex..<attributed.endIndex
            while searchRange.lowerBound < searchRange.upperBound,
                  let range = attributed[searchRange].range(of: word, options: .caseInsensitive) {
                attributed[range].foregroundColor = MonocleTheme.foreground
                attributed[range].font = Font.system(
                    size: isMono ? 12 : 13,
                    weight: .heavy,
                    design: isMono ? .monospaced : .default
                )
                attributed[range].backgroundColor = MonocleTheme.neutral.opacity(0.38)

                if range.upperBound < attributed.endIndex {
                    searchRange = range.upperBound..<attributed.endIndex
                } else {
                    break
                }
            }
        }

        return attributed
    }

    /// Highlights a specific line in the preview, applying distinct active styling if this line is currently focused
    public static func highlightLine(
        text: String,
        query: String,
        isActiveLine: Bool,
        isMono: Bool = true
    ) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.font = isMono ? MonocleTheme.fontMono : MonocleTheme.fontBody
        attributed.foregroundColor = isActiveLine ? MonocleTheme.foreground : MonocleTheme.foreground.opacity(0.85)

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return attributed
        }

        let words = trimmedQuery.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else {
            return attributed
        }

        for word in words {
            var searchRange = attributed.startIndex..<attributed.endIndex
            while searchRange.lowerBound < searchRange.upperBound,
                  let range = attributed[searchRange].range(of: word, options: .caseInsensitive) {
                attributed[range].foregroundColor = MonocleTheme.foreground
                attributed[range].font = Font.system(
                    size: isMono ? 12 : 13,
                    weight: .black,
                    design: isMono ? .monospaced : .default
                )

                if isActiveLine {
                    attributed[range].backgroundColor = MonocleTheme.neutral.opacity(0.7)
                } else {
                    attributed[range].backgroundColor = MonocleTheme.neutral.opacity(0.35)
                }

                if range.upperBound < attributed.endIndex {
                    searchRange = range.upperBound..<attributed.endIndex
                } else {
                    break
                }
            }
        }

        return attributed
    }
}
