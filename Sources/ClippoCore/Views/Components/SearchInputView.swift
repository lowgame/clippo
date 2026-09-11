import SwiftUI

public struct SearchInputView: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let matchCount: Int
    let currentMatchIndex: Int
    let onNext: () -> Void
    let onClear: () -> Void

    @Environment(\.colorScheme) var colorScheme

    public init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        matchCount: Int = 0,
        currentMatchIndex: Int = 0,
        onNext: @escaping () -> Void = {},
        onClear: @escaping () -> Void
    ) {
        self._text = text
        self._isFocused = isFocused
        self.matchCount = matchCount
        self.currentMatchIndex = currentMatchIndex
        self.onNext = onNext
        self.onClear = onClear
    }

    public var body: some View {
        HStack(spacing: MonocleTheme.spacingS) {
            // Direct native TextField without leading slash
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(MonocleTheme.fontMono)
                .foregroundColor(MonocleTheme.foreground)
                .focused($isFocused)
                .onSubmit {
                    onNext()
                }

            // Search Match Counter & Clear Button
            if !text.isEmpty {
                if matchCount > 0 {
                    Text("\(currentMatchIndex + 1)/\(matchCount)")
                        .font(MonocleTheme.fontMeta)
                        .foregroundColor(MonocleTheme.neutral)
                } else {
                    Text("0")
                        .font(MonocleTheme.fontMeta)
                        .foregroundColor(MonocleTheme.neutral.opacity(0.6))
                }

                Button(action: {
                    text = ""
                    onClear()
                }) {
                    Text("×")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MonocleTheme.neutral)
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { isInside in
                    if isInside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
        .padding(.horizontal, MonocleTheme.spacingM)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(MonocleTheme.microBorder, lineWidth: 1)
        )
    }
}
