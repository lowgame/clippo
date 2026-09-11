import SwiftUI

public struct SearchInputView: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let onClear: () -> Void

    @Environment(\.colorScheme) var colorScheme

    public init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        onClear: @escaping () -> Void
    ) {
        self._text = text
        self._isFocused = isFocused
        self.onClear = onClear
    }

    public var body: some View {
        HStack(spacing: MonocleTheme.spacingS) {
            // Bauhaus forward slash indicator
            Text("/")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(MonocleTheme.neutral)
                .frame(width: 16)

            // Native TextField
            TextField("type to filter...", text: $text)
                .textFieldStyle(.plain)
                .font(MonocleTheme.fontMono)
                .foregroundColor(MonocleTheme.foreground)
                .focused($isFocused)

            // Inline Clear Button
            if !text.isEmpty {
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
