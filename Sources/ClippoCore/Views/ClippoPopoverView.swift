import SwiftUI

public struct ClippoPopoverView: View {
    @ObservedObject var storage: StorageManager
    @ObservedObject var themeManager: ThemeManager = .shared
    let monitor: ClipboardMonitor
    let onClose: () -> Void

    @State private var searchQuery: String = ""
    @State private var currentMatchIndex: Int = 0
    @State private var hoveredItemId: UUID? = nil
    @State private var isCopiedOverlayVisible: Bool = false
    @State private var isCopying: Bool = false
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

    /// True general multi-word search across all clipboard items
    private var filteredItems: [ClipItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return storage.items
        }
        let words = query.lowercased().split(separator: " ").map(String.init)
        return storage.items.filter { item in
            let contentLower = item.content.lowercased()
            return words.allSatisfy { word in contentLower.contains(word) }
        }
    }

    /// All exact match occurrences across filtered items
    private var allSearchOccurrences: [SearchMatchOccurrence] {
        SearchHighlightEngine.findAllOccurrences(in: filteredItems, query: searchQuery)
    }

    /// Currently focused occurrence (navigated via Enter or Arrow keys)
    private var activeOccurrence: SearchMatchOccurrence? {
        guard !allSearchOccurrences.isEmpty else { return nil }
        let safeIndex = min(max(0, currentMatchIndex), allSearchOccurrences.count - 1)
        return allSearchOccurrences[safeIndex]
    }

    private func nextMatch() {
        let count = allSearchOccurrences.count
        guard count > 0 else { return }
        currentMatchIndex = (currentMatchIndex + 1) % count
        updatePreviewForActiveOccurrence()
    }

    private func previousMatch() {
        let count = allSearchOccurrences.count
        guard count > 0 else { return }
        currentMatchIndex = (currentMatchIndex - 1 + count) % count
        updatePreviewForActiveOccurrence()
    }

    private func updatePreviewForActiveOccurrence() {
        guard let active = activeOccurrence else { return }
        if let item = filteredItems.first(where: { $0.id == active.clipId }) {
            showPreview(for: item, activeLine: active.lineNumber)
        }
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header: Direct Search Input (No leading slash, supports Enter to cycle matches)
                VStack(spacing: MonocleTheme.spacingS) {
                    SearchInputView(
                        text: $searchQuery,
                        isFocused: $isSearchFocused,
                        matchCount: allSearchOccurrences.count,
                        currentMatchIndex: currentMatchIndex,
                        onNext: {
                            nextMatch()
                        },
                        onClear: {
                            searchQuery = ""
                            currentMatchIndex = 0
                        }
                    )
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
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 2) {
                                ForEach(Array(filteredItems.prefix(50).enumerated()), id: \.element.id) { index, item in
                                    let isRowActiveInSearch = (!searchQuery.isEmpty && activeOccurrence?.clipId == item.id)
                                    let activeOffsetForThisRow = isRowActiveInSearch ? activeOccurrence?.charOffset : nil

                                    ClipRowView(
                                        item: item,
                                        index: searchQuery.isEmpty && index < 9 ? index + 1 : nil,
                                        isSelected: isRowActiveInSearch,
                                        isNearBottom: index >= max(0, filteredItems.count - 4),
                                        searchQuery: searchQuery,
                                        activeOffset: activeOffsetForThisRow,
                                        onSelect: {
                                            select(item: item)
                                        },
                                        onDelete: {
                                            storage.remove(id: item.id)
                                            if hoveredItemId == item.id {
                                                hidePreview()
                                            }
                                        },
                                        onHoverChanged: { isHovered in
                                            if isHovered {
                                                hoveredItemId = item.id
                                                showPreview(for: item)
                                            } else if hoveredItemId == item.id {
                                                Task {
                                                    try? await Task.sleep(nanoseconds: 200_000_000)
                                                    await MainActor.run {
                                                        if !ClippoPreviewPanelController.shared.isMouseInsidePreview && hoveredItemId == item.id && searchQuery.isEmpty {
                                                            hoveredItemId = nil
                                                            hidePreview()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    )
                                    .id(item.id)
                                }
                            }
                            .padding(.horizontal, MonocleTheme.spacingS)
                            .padding(.vertical, 2)
                        }
                        .frame(maxHeight: 340)
                        .onChange(of: currentMatchIndex) { _, _ in
                            if let active = activeOccurrence {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    proxy.scrollTo(active.clipId, anchor: .center)
                                }
                                if let item = filteredItems.first(where: { $0.id == active.clipId }) {
                                    showPreview(for: item, activeLine: active.lineNumber)
                                }
                            }
                        }
                        .onChange(of: searchQuery) { _, newQuery in
                            currentMatchIndex = 0
                            let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                if let firstOccur = allSearchOccurrences.first,
                                   let firstItem = filteredItems.first(where: { $0.id == firstOccur.clipId }) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        proxy.scrollTo(firstItem.id, anchor: .top)
                                    }
                                    showPreview(for: firstItem, activeLine: firstOccur.lineNumber)
                                } else if let first = filteredItems.first {
                                    showPreview(for: first, activeLine: nil)
                                } else {
                                    hidePreview()
                                }
                            } else {
                                hidePreview()
                            }
                        }
                    }
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
                    .onHover { isInside in
                        if isInside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .help(themeManager.currentMode.title)
                }
                .padding(.horizontal, MonocleTheme.spacingM)
                .padding(.vertical, 4)
                .background(MonocleTheme.background.opacity(0.8))
            }

            // Full-Window "copied" Feedback Overlay ("copied, bütün pencerede yazsın")
            if isCopiedOverlayVisible {
                ZStack {
                    MonocleTheme.background.opacity(0.88)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 8) {
                        Text("✓")
                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                            .foregroundColor(MonocleTheme.foreground)

                        Text("copied")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(MonocleTheme.foreground)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(MonocleTheme.background)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.6 : 0.2), radius: 20, x: 0, y: 6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(MonocleTheme.microBorder, lineWidth: 1)
                    )
                }
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .frame(width: 320)
        .background(MonocleTheme.background)
        .preferredColorScheme(themeManager.currentMode.colorScheme)
        .onAppear {
            monitor.checkForChanges()
        }
        .onDisappear {
            hidePreview()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clippoSelectSlot)) { notification in
            if let idx = notification.object as? Int {
                selectIndex(idx)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .clippoCopyCurrentMatch)) { _ in
            if !searchQuery.isEmpty, let active = activeOccurrence,
               let item = filteredItems.first(where: { $0.id == active.clipId }) {
                select(item: item)
            } else if let first = filteredItems.first {
                select(item: first)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .clippoNextMatch)) { _ in
            nextMatch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clippoPrevMatch)) { _ in
            previousMatch()
        }
    }

    private func showPreview(for item: ClipItem, activeLine: Int? = nil) {
        guard let panel = ClippoPanelController.shared.currentPanel else { return }
        ClippoPreviewPanelController.shared.show(
            item: item,
            searchQuery: searchQuery,
            activeLineNumber: activeLine,
            relativeTo: panel,
            onCopy: {
                select(item: item)
            }
        )
    }

    private func hidePreview() {
        ClippoPreviewPanelController.shared.hide()
    }

    public func select(item: ClipItem) {
        guard !isCopying else { return }
        isCopying = true
        hidePreview()
        monitor.copyToPasteboard(item: item)

        withAnimation(.easeOut(duration: 0.12)) {
            isCopiedOverlayVisible = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.1)) {
                    isCopiedOverlayVisible = false
                }
                onClose()
                isCopying = false
            }
        }
    }

    public func selectIndex(_ index: Int) {
        let items = filteredItems
        if index >= 0 && index < items.count {
            select(item: items[index])
        }
    }
}
