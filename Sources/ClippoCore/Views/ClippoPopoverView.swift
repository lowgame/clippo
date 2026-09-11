import SwiftUI

public struct ClippoPopoverView: View {
    @ObservedObject var storage: StorageManager
    @ObservedObject var themeManager: ThemeManager = .shared
    let monitor: ClipboardMonitor
    let onClose: () -> Void

    @State private var searchQuery: String = ""
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    @MainActor
    public init(
        storage: StorageManager? = nil,
        monitor: ClipboardMonitor? = nil,
        onClose: @escaping () -> Void
    ) {
        self.storage = storage ?? .shared
        self.monitor = monitor ?? .shared
        self.onClose = onClose
    }

    private var filteredItems: [ClipItem] {
        if searchQuery.isEmpty {
            return storage.items
        }
        return storage.items.filter {
            $0.content.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header: Minimal Search Input
            VStack(spacing: MonocleTheme.spacingS) {
                SearchInputView(
                    text: $searchQuery,
                    isFocused: $isSearchFocused,
                    onClear: {
                        searchQuery = ""
                    }
                )
                .onSubmit {
                    if let first = filteredItems.first {
                        select(item: first)
                    }
                }
            }
            .padding(.horizontal, MonocleTheme.spacingM)
            .padding(.top, MonocleTheme.spacingM)
            .padding(.bottom, MonocleTheme.spacingS)

            // Content List
            if filteredItems.isEmpty {
                VStack(spacing: MonocleTheme.spacingS) {
                    Spacer()
                    Text(storage.items.isEmpty ? "no clips yet" : "no matching clips")
                        .font(MonocleTheme.fontMono)
                        .foregroundColor(MonocleTheme.neutral)
                    Text(storage.items.isEmpty ? "copied text appears here automatically" : "press esc to clear filter")
                        .font(MonocleTheme.fontMeta)
                        .foregroundColor(MonocleTheme.neutral.opacity(0.7))
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredItems.prefix(50).enumerated()), id: \.element.id) { index, item in
                            ClipRowView(
                                item: item,
                                index: index < 9 ? index + 1 : nil,
                                onSelect: {
                                    select(item: item)
                                },
                                onDelete: {
                                    storage.remove(id: item.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, MonocleTheme.spacingS)
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 340)
            }

            // Divider
            Rectangle()
                .fill(MonocleTheme.microBorder)
                .frame(height: 1)

            // Footer: Minimal Theme Mode Glyph
            HStack {
                Spacer()

                Button(action: {
                    themeManager.cycleTheme()
                }) {
                    Text(themeManager.currentMode.symbol)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(MonocleTheme.neutral)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(themeManager.currentMode.title)
            }
            .padding(.horizontal, MonocleTheme.spacingM)
            .padding(.vertical, 4)
            .background(MonocleTheme.background.opacity(0.8))
        }
        .frame(width: 320)
        .background(MonocleTheme.background)
        .preferredColorScheme(themeManager.currentMode.colorScheme)
        .onAppear {
            // Check if clipboard changed right as panel opened
            monitor.checkForChanges()
        }
    }

    public func select(item: ClipItem) {
        monitor.copyToPasteboard(item: item)
        onClose()
    }

    public func selectIndex(_ index: Int) {
        let items = filteredItems
        if index >= 0 && index < items.count {
            select(item: items[index])
        }
    }
}
