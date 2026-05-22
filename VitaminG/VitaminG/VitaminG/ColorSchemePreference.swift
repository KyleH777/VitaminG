import SwiftUI

// MARK: - ColorSchemePreference
// Persisted via @AppStorage("vg_colorScheme"). Raw values are stable lowercase strings
// and must NOT change after shipping — they are stored in UserDefaults (Pitfall 4, D-11).

enum ColorSchemePreference: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    // MARK: - Display

    /// Human-readable label for use in Picker / segmented control.
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    // MARK: - Mapping

    /// Maps to SwiftUI ColorScheme? for use with .preferredColorScheme() on WindowGroup.
    /// `.system` returns nil so the OS decides light/dark based on device setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
