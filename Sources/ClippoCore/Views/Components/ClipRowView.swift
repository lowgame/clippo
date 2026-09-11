import SwiftUI

public struct ClipRowView: View {
    let item: ClipItem
    let index: Int? // 1..9 or nil if beyond 9
    let onSelect: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered: Bool = false
    @State private var isPrimedForPurge: Bool = false
    @State private var purgeResetTask: Task<Void, Never>? = nil

    public init(
        item: ClipItem,
        index: Int?,
        onSelect: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = item
        self.index = index
        self.onSelect = onSelect
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: MonocleTheme.spacingS) {
            // Index number badge (1..9 or dot)
            Group {
                if let idx = index {
                    Text("\(idx)")
                        .font(MonocleTheme.fontNumber)
                        .foregroundColor(MonocleTheme.neutral)
                } else {
                    Text("·")
                        .font(MonocleTheme.fontNumber)
                        .foregroundColor(MonocleTheme.neutral.opacity(0.5))
                }
            }
            .frame(width: 14, alignment: .trailing)

            // Text Preview (Single Line, Truncated)
            Text(item.cleanPreview)
                .font(MonocleTheme.fontMono)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(MonocleTheme.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Micro-Meta and Purge Button (Reserved width to prevent layout shift)
            HStack(spacing: MonocleTheme.spacingXS) {
                // Character Count
                Text(item.charCountLabel)
                    .font(MonocleTheme.fontMeta)
                    .foregroundColor(MonocleTheme.neutral)
                    .opacity(isHovered ? 0.8 : 0.0)

                // Armored Two-Click Purge Button (× -> ◎)
                Button(action: handlePurgeClick) {
                    Text(isPrimedForPurge ? "◎" : "×")
                        .font(.system(size: isPrimedForPurge ? 12 : 13, weight: isPrimedForPurge ? .bold : .light))
                        .foregroundColor(isPrimedForPurge ? MonocleTheme.foreground : MonocleTheme.neutral)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isHovered || isPrimedForPurge ? 1.0 : 0.0)
                .allowsHitTesting(isHovered || isPrimedForPurge)
            }
        }
        .padding(.horizontal, MonocleTheme.spacingS)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isHovered ? MonocleTheme.rowHover : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
                if !hovering && !isPrimedForPurge {
                    // reset hover
                }
            }
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
            // First click: prime for purge (inline armed state)
            isPrimedForPurge = true
            purgeResetTask?.cancel()
            purgeResetTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if !Task.isCancelled {
                    await MainActor.run {
                        withAnimation {
                            isPrimedForPurge = false
                        }
                    }
                }
            }
        }
    }
}
