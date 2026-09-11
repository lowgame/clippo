import SwiftUI
import AppKit
import Combine

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    private let themeKey = "ClippoThemeMode"

    @Published public var currentMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: themeKey)
            applyAppearance()
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: themeKey) ?? ThemeMode.system.rawValue
        self.currentMode = ThemeMode(rawValue: saved) ?? .system
        applyAppearance()
    }

    public func cycleTheme() {
        currentMode = currentMode.next
    }

    public func setMode(_ mode: ThemeMode) {
        currentMode = mode
    }

    public func applyAppearance(to window: NSWindow? = nil) {
        let appearance = currentMode.nsAppearance
        if let window = window {
            window.appearance = appearance
        } else if NSApp != nil {
            NSApp.appearance = appearance
        }
    }
}
