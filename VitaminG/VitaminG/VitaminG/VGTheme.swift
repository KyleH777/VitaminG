import SwiftUI

// MARK: - VGTheme
// Brand color system for the Vitamin G design spec.

enum VGTheme {
    // MARK: - Warm neutrals
    static let sand       = Color(red: 0.949, green: 0.910, blue: 0.851)  // #F2E8D9
    static let sandLight  = Color(red: 0.980, green: 0.961, blue: 0.933)  // #FAF5EE
    static let sandMid    = Color(red: 0.910, green: 0.851, blue: 0.769)  // #E8D9C4
    static let sandDeep   = Color(red: 0.831, green: 0.769, blue: 0.659)  // #D4C4A8

    // MARK: - Clay (dark backgrounds)
    static let clay       = Color(red: 0.239, green: 0.184, blue: 0.118)  // #3D2F1E
    static let clayMid    = Color(red: 0.353, green: 0.259, blue: 0.196)  // #5A4232

    // MARK: - Terra (primary accent)
    static let terra      = Color(red: 0.769, green: 0.404, blue: 0.227)  // #C4673A
    static let terraSoft  = Color(red: 0.910, green: 0.584, blue: 0.427)  // #E8956D
    static let terraLight = Color(red: 0.961, green: 0.867, blue: 0.816)  // #F5DDD0

    // MARK: - Sage (secondary accent)
    static let sage       = Color(red: 0.478, green: 0.620, blue: 0.494)  // #7A9E7E
    static let sageMid    = Color(red: 0.361, green: 0.541, blue: 0.380)  // #5C8A61
    static let sageLight  = Color(red: 0.918, green: 0.949, blue: 0.922)  // #EAF2EB

    // MARK: - Gold
    static let gold       = Color(red: 0.769, green: 0.643, blue: 0.349)  // #C4A459
    static let goldLight  = Color(red: 0.961, green: 0.929, blue: 0.816)  // #F5EDD0

    // MARK: - Purple
    static let purple     = Color(red: 0.608, green: 0.490, blue: 0.714)  // #9B7DB6

    // MARK: - Utility
    static let muted      = Color(red: 0.604, green: 0.541, blue: 0.471)  // #9A8A78
    static let warmWhite  = Color(red: 0.992, green: 0.980, blue: 0.965)  // #FDFAF6

    // MARK: - Typography helpers
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Georgia", size: size).weight(weight)
    }

    static func serifItalic(_ size: CGFloat) -> Font {
        Font.custom("Georgia-Italic", size: size)
    }
}
