import SwiftUI
import AppKit

public struct ClipRowView: View {
    let item: ClipItem
    let index: Int? // 1..9 or nil if beyond 9
    let isSelected: Bool
    let isNearBottom: Bool
    let searchQuery: String
    let activeOffset: Int?
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onHoverChanged: ((Bool) -> Void)?

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered: Bool = false
    @State private var hasPushedCursor: Bool = false
    @State private var isPrimedForPurge: Bool = false
    @State private var purgeResetTask: Task<Void, Never>? = nil

    public init(
        item: ClipItem,
        index: Int?,
        isSelected: Bool = false,
        isNearBottom: Bool = false,
        searchQuery: String = "",
        activeOffset: Int? = nil,
        onSelect: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onHoverChanged: ((Bool) -> Void)? = nil
    ) {
        self.item = item
        self.index = index
        self.isSelected = isSelected
        self.isNearBottom = isNearBottom
        self.searchQuery = searchQuery
        self.activeOffset = activeOffset
        self.onSelect = onSelect
        self.onDelete = onDelete
        self.onHoverChanged = onHoverChanged
    }

    public var body: some View {
        HStack(spacing: MonocleTheme.spacingS) {
            // Text Content (With search match context snippet & high-contrast in-text highlighting)
            let snippet = SearchHighlightEngine.snippet(content: item.content, query: searchQuery, targetOffset: activeOffset)
            let highlighted = SearchHighlightEngine.highlight(text: snippet, query: searchQuery, isMono: true)

            Text(highlighted)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Pixel-Perfect Armored Two-Click Purge Button (Fixed metrics, zero layout shift)
            Button(action: handlePurgeClick) {
                ZStack {
                    Circle()
                        .fill(isPrimedForPurge ? MonocleTheme.foreground : Color.clear)
                        .frame(width: 18, height: 18)

                    Text("×")
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(isPrimedForPurge ? MonocleTheme.background : MonocleTheme.neutral)
                }
                .frame(width: 20, height: 20, alignment: .center)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isHovered || isPrimedForPurge ? 1.0 : 0.0)
            .allowsHitTesting(isHovered || isPrimedForPurge)
        }
        .padding(.horizontal, MonocleTheme.spacingS)
        .padding(.vertical, 4)
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? MonocleTheme.neutral.opacity(0.25) : (isHovered ? MonocleTheme.rowHover : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? MonocleTheme.neutral.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
            setPointingCursor(hovering)
            onHoverChanged?(hovering)
        }
        .onDisappear {
            setPointingCursor(false)
            purgeResetTask?.cancel()
            purgeResetTask = nil
        }
    }

    private func setPointingCursor(_ active: Bool) {
        if active && !hasPushedCursor {
            NSCursor.pointingHand.push()
            hasPushedCursor = true
        } else if !active && hasPushedCursor {
            NSCursor.pop()
            hasPushedCursor = false
        }
    }

    private func handlePurgeClick() {
        if isPrimedForPurge {
            // Second click: permanent delete
            purgeResetTask?.cancel()
            purgeResetTask = nil
            isPrimedForPurge = false
            onDelete()
        } else {
            // First click: prime for purge (make x bold)
            withAnimation(.easeInOut(duration: 0.12)) {
                isPrimedForPurge = true
            }
            purgeResetTask?.cancel()
            purgeResetTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if !Task.isCancelled {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            isPrimedForPurge = false
                        }
                    }
                }
            }
        }
    }
}
