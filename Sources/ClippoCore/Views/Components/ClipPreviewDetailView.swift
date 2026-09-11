import SwiftUI
import AppKit

public struct ClipPreviewDetailView: View {
    let item: ClipItem
    let searchQuery: String
    let activeLineNumber: Int?
    let onHoverChanged: ((Bool) -> Void)?
    let onCopy: () -> Void

    @ObservedObject var themeManager: ThemeManager = .shared
    @Environment(\.colorScheme) var colorScheme

    public init(
        item: ClipItem,
        searchQuery: String = "",
        activeLineNumber: Int? = nil,
        onHoverChanged: ((Bool) -> Void)? = nil,
        onCopy: @escaping () -> Void
    ) {
        self.item = item
        self.searchQuery = searchQuery
        self.activeLineNumber = activeLineNumber
        self.onHoverChanged = onHoverChanged
        self.onCopy = onCopy
    }

    private var lines: [String] {
        item.content.components(separatedBy: "\n")
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Body: Pure text scrollable inspector with exact match auto-scrolling
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, lineText in
                            let lineNum = index + 1
                            let isActive = (activeLineNumber == lineNum)

                            Text(SearchHighlightEngine.highlightLine(
                                text: lineText.isEmpty ? " " : lineText,
                                query: searchQuery,
                                isActiveLine: isActive,
                                isMono: true
                            ))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(lineNum)
                            .padding(.horizontal, MonocleTheme.spacingM)
                            .padding(.vertical, 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isActive ? MonocleTheme.neutral.opacity(0.25) : Color.clear)
                            )
                        }
                    }
                    .padding(.vertical, MonocleTheme.spacingS)
                }
                .onChange(of: activeLineNumber) { _, targetLine in
                    if let line = targetLine {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            proxy.scrollTo(line, anchor: .center)
                        }
                    }
                }
                .onAppear {
                    if let line = activeLineNumber {
                        proxy.scrollTo(line, anchor: .center)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Removed footer bar completely ("copy yazısını falan kaldır kullanıcı intuitive olarak keşfetsin")
        }
        .frame(width: 340, height: 400)
        .background(MonocleTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(MonocleTheme.microBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
        .onHover { isInside in
            onHoverChanged?(isInside)
            if isInside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .preferredColorScheme(themeManager.currentMode.colorScheme)
    }
}
