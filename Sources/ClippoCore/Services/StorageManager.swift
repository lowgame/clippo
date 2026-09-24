import Foundation
import Combine

@MainActor
public final class StorageManager: ObservableObject {
    public static let shared = StorageManager()

    public static let maxCapacity: Int = 50

    @Published public private(set) var items: [ClipItem] = []

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.items = loadHistory()
    }

    // MARK: - File Paths

    private var localDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let dir = appSupport.appendingPathComponent("clippo", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var localDataURL: URL {
        localDirectory.appendingPathComponent("history.json")
    }

    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private var iCloudDocsURL: URL? {
        guard !isRunningTests else { return nil }
        let home = fileManager.homeDirectoryForCurrentUser
        let cloudDocs = home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/clippo", isDirectory: true)
        if fileManager.fileExists(atPath: home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs").path) {
            if !fileManager.fileExists(atPath: cloudDocs.path) {
                try? fileManager.createDirectory(at: cloudDocs, withIntermediateDirectories: true)
            }
            return cloudDocs.appendingPathComponent("history.json")
        }
        return nil
    }

    // MARK: - Persistence

    public func loadHistory() -> [ClipItem] {
        var localItems: [ClipItem]?
        var localModDate: Date = .distantPast
        if fileManager.fileExists(atPath: localDataURL.path),
           let data = try? Data(contentsOf: localDataURL),
           let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) {
            localItems = Array(decoded.prefix(Self.maxCapacity))
            localModDate = (try? fileManager.attributesOfItem(atPath: localDataURL.path)[.modificationDate] as? Date) ?? .distantPast
        }

        var cloudItems: [ClipItem]?
        var cloudModDate: Date = .distantPast
        if let cloudURL = iCloudDocsURL,
           fileManager.fileExists(atPath: cloudURL.path),
           let data = try? Data(contentsOf: cloudURL),
           let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) {
            cloudItems = Array(decoded.prefix(Self.maxCapacity))
            cloudModDate = (try? fileManager.attributesOfItem(atPath: cloudURL.path)[.modificationDate] as? Date) ?? .distantPast
        }

        if let cloud = cloudItems, cloudModDate > localModDate {
            return cloud
        }
        return localItems ?? cloudItems ?? []
    }

    public func saveHistory() {
        let trimmed = Array(items.prefix(Self.maxCapacity))
        guard let data = try? JSONEncoder().encode(trimmed) else { return }

        // Atomic write to local
        try? data.write(to: localDataURL, options: .atomic)

        // Asynchronous mirror to iCloud Drive
        if let cloudURL = iCloudDocsURL {
            DispatchQueue.global(qos: .utility).async {
                try? data.write(to: cloudURL)
            }
        }
    }

    public func forceSaveToiCloud() {
        let trimmed = Array(items.prefix(Self.maxCapacity))
        guard let data = try? JSONEncoder().encode(trimmed) else { return }

        try? data.write(to: localDataURL, options: .atomic)

        if let cloudURL = iCloudDocsURL {
            try? data.write(to: cloudURL)
        }
    }

    // MARK: - Mutations

    @discardableResult
    public func add(content: String, sourceAppBundle: String? = nil) -> ClipItem? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // If top item is identical in content, do not add duplicate
        if let first = items.first, first.content == content {
            return nil
        }

        // If already exists deeper in history, remove the older occurrence (bubble to top)
        items.removeAll { $0.content == content }

        let newItem = ClipItem(content: content, timestamp: Date(), sourceAppBundle: sourceAppBundle)
        items.insert(newItem, at: 0)

        // Keep strictly within max capacity
        if items.count > Self.maxCapacity {
            items = Array(items.prefix(Self.maxCapacity))
        }

        saveHistory()
        return newItem
    }

    public func remove(id: UUID) {
        items.removeAll { $0.id == id }
        saveHistory()
    }

    public func clearAll() {
        items.removeAll()
        saveHistory()
    }

    public func setForPreview(items: [ClipItem]) {
        self.items = items
    }
}
