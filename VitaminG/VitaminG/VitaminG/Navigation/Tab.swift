import Foundation

/// Typed tab selection enum for the v2.0 tab bar.
///
/// D-06: String raw values (`"home"`, `"goals"`, `"explore"`, `"community"`, `"profile"`)
/// ensure future deep link and widget intent routing remains stable when tab indices shift
/// (TAB-04). Callers encode the raw value string, never a positional integer.
///
/// D-07: Case order here defines `Tab.allCases` ordering, which in turn drives the visual
/// order rendered by `VGTabBar` via `ForEach(Tab.allCases)`. The new v2.0 display order is:
/// Home · Goals · Explore · Community · Profile.
enum Tab: String, CaseIterable, Hashable {
    case home      = "home"
    case goals     = "goals"
    case explore   = "explore"
    case community = "community"
    case profile   = "profile"
}
