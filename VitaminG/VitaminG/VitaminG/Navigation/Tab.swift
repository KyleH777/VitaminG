import Foundation

/// Typed tab selection enum for the v2.0 tab bar.
///
/// Named `AppTab` (not `Tab`) to avoid collision with SwiftUI's generic `Tab<Value, Content, Label>`
/// type introduced in the iOS 18 SDK.
///
/// D-06: String raw values (`"home"`, `"goals"`, `"explore"`, `"community"`, `"profile"`)
/// ensure future deep link and widget intent routing remains stable when tab indices shift
/// (TAB-04). Callers encode the raw value string, never a positional integer.
///
/// D-07: Case order here defines `AppTab.allCases` ordering, which in turn drives the visual
/// order rendered by `VGTabBar` via `ForEach(AppTab.allCases)`. The new v2.0 display order is:
/// Home · Goals · Explore · Community · Profile.
enum AppTab: String, CaseIterable, Hashable {
    case home      = "home"
    case goals     = "goals"
    case explore   = "explore"
    case community = "community"
    case profile   = "profile"
}
