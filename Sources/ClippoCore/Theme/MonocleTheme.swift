import SwiftUI
import AppKit

public enum ThemeMode: String, CaseIterable, Codable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    public var title: String {
        switch self {
        case .system: return "Sistem"
        case .light: return "Açık"
        case .dark: return "Koyu"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    public var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    public var next: ThemeMode {
        switch self {
        case .system: return .dark
        case .dark: return .light
        case .light: return .system
        }
    }
}

public enum MonocleTheme {
    // MARK: - Strict 3-Color Discipline (Achromatic: R == G == B)

    // Level 1: Zemin (Negatif Alan)
    public static var background: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(white: 0.05, alpha: 1.0)
                : NSColor(white: 0.99, alpha: 1.0)
        })
    }

    public static var rowHover: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(white: 0.12, alpha: 1.0)
                : NSColor(white: 0.92, alpha: 1.0)
        })
    }

    // Level 2: Ön Plan (Aktif Durum, Odak, Yüksek Kontrast)
    public static var foreground: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(white: 0.98, alpha: 1.0)
                : NSColor(white: 0.05, alpha: 1.0)
        })
    }

    // Level 3: Nötr Ton (Meta, İkincil, Pasif Durum)
    public static var neutral: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(white: 0.55, alpha: 1.0)
                : NSColor(white: 0.46, alpha: 1.0)
        })
    }

    // Nötr Mikro-Kontur (Hafif ayrıştırma çizgisi)
    public static var microBorder: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(white: 0.16, alpha: 1.0)
                : NSColor(white: 0.86, alpha: 1.0)
        })
    }

    // MARK: - Grid Metrics (4pt katsayıları)
    public static let unit: CGFloat = 4
    public static let spacingXS: CGFloat = unit * 1 // 4
    public static let spacingS: CGFloat = unit * 2  // 8
    public static let spacingM: CGFloat = unit * 3  // 12
    public static let spacingL: CGFloat = unit * 4  // 16
    public static let spacingXL: CGFloat = unit * 6 // 24

    // MARK: - Physical Spring Dynamics (150ms - 250ms)
    public static let spring: Animation = .spring(response: 0.20, dampingFraction: 0.85)

    // MARK: - Typography
    public static let fontBody = Font.system(size: 13, weight: .regular, design: .default)
    public static let fontMono = Font.system(size: 12, weight: .regular, design: .monospaced)
    public static let fontNumber = Font.system(size: 12, weight: .semibold, design: .monospaced)
    public static let fontMeta = Font.system(size: 11, weight: .medium, design: .monospaced)
}
