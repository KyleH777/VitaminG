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
    static let muted      = Color(red: 0.447, green: 0.384, blue: 0.310)  // #72624F — 4.9:1 on sandLight, passes WCAG AA
    static let warmWhite  = Color(red: 0.992, green: 0.980, blue: 0.965)  // #FDFAF6

    // MARK: - Dark mode raw values (luminous accent variants)
    // Used where a glow/pop is needed on dark backgrounds.
    static let terraGlow  = Color(red: 1.000, green: 0.541, blue: 0.361)  // #FF8A5C
    static let sageGlow   = Color(red: 0.584, green: 0.839, blue: 0.612)  // #95D69C
    static let goldGlow   = Color(red: 0.910, green: 0.816, blue: 0.439)  // #E8D070
    static let irisGlow   = Color(red: 0.761, green: 0.643, blue: 0.867)  // #C2A4DD
    // Deep dark backgrounds (darker than clay — #16110C, #1F1812)
    static let inkDeep    = Color(red: 0.086, green: 0.067, blue: 0.047)  // #16110C
    static let inkMid     = Color(red: 0.122, green: 0.094, blue: 0.071)  // #1F1812

    // MARK: - Adaptive semantic tokens (light / dark)
    // Hero / always-dark background (intentionally dark in both modes — used by HomeView)
    static let heroBackground = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.086, green: 0.067, blue: 0.047, alpha: 1)   // inkDeep #16110C
            : UIColor(red: 0.239, green: 0.184, blue: 0.118, alpha: 1)   // clay #3D2F1E
    })
    static let heroBackgroundSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.122, green: 0.094, blue: 0.071, alpha: 1)   // inkMid #1F1812
            : UIColor(red: 0.353, green: 0.259, blue: 0.196, alpha: 1)   // clayMid #5A4232
    })

    // Backgrounds
    static let background = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.086, green: 0.067, blue: 0.047, alpha: 1)   // inkDeep #16110C
            : UIColor(red: 0.980, green: 0.961, blue: 0.933, alpha: 1)   // sandLight #FAF5EE
    })
    static let backgroundSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.122, green: 0.094, blue: 0.071, alpha: 1)   // inkMid #1F1812
            : UIColor(red: 0.992, green: 0.980, blue: 0.965, alpha: 1)   // warmWhite #FDFAF6
    })

    // Surfaces (cards, sheets)
    static let surface = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.992, green: 0.980, blue: 0.965, alpha: 0.045)  // frosted warm tint
            : UIColor(red: 0.992, green: 0.980, blue: 0.965, alpha: 1)      // warmWhite
    })
    static let surface2 = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.992, green: 0.980, blue: 0.965, alpha: 0.07)
            : UIColor(red: 0.910, green: 0.851, blue: 0.769, alpha: 0.4)    // sandMid light tint
    })

    // Borders / separators
    static let separator = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.992, green: 0.980, blue: 0.965, alpha: 0.07)   // hair
            : UIColor(red: 0.910, green: 0.851, blue: 0.769, alpha: 1)      // sandMid #E8D9C4
    })
    static let separator2 = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.992, green: 0.980, blue: 0.965, alpha: 0.12)   // hair2
            : UIColor(red: 0.831, green: 0.769, blue: 0.659, alpha: 1)      // sandDeep #D4C4A8
    })

    // Text
    static let textPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.949, green: 0.910, blue: 0.851, alpha: 1)      // sand #F2E8D9
            : UIColor(red: 0.239, green: 0.184, blue: 0.118, alpha: 1)      // clay #3D2F1E
    })
    static let textSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.949, green: 0.910, blue: 0.851, alpha: 0.62)   // sandSoft
            : UIColor(red: 0.239, green: 0.184, blue: 0.118, alpha: 0.75)   // clay soft
    })
    static let textMuted = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.949, green: 0.910, blue: 0.851, alpha: 0.42)   // muted sand
            : UIColor(red: 0.447, green: 0.384, blue: 0.310, alpha: 1)      // #72624F — 4.9:1 on sandLight
    })
    static let textFaint = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.949, green: 0.910, blue: 0.851, alpha: 0.26)
            : UIColor(red: 0.447, green: 0.384, blue: 0.310, alpha: 0.55)
    })

    // Accents — full luminosity in dark, standard in light
    static let accentTerra = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.000, green: 0.541, blue: 0.361, alpha: 1)      // terraGlow #FF8A5C
            : UIColor(red: 0.769, green: 0.404, blue: 0.227, alpha: 1)      // terra #C4673A
    })
    static let accentSage = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.584, green: 0.839, blue: 0.612, alpha: 1)      // sageGlow #95D69C
            : UIColor(red: 0.478, green: 0.620, blue: 0.494, alpha: 1)      // sage #7A9E7E
    })
    static let accentGold = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.910, green: 0.816, blue: 0.439, alpha: 1)      // goldGlow #E8D070
            : UIColor(red: 0.769, green: 0.643, blue: 0.349, alpha: 1)      // gold #C4A459
    })
    static let accentPurple = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.761, green: 0.643, blue: 0.867, alpha: 1)      // irisGlow #C2A4DD
            : UIColor(red: 0.608, green: 0.490, blue: 0.714, alpha: 1)      // purple #9B7DB6
    })

    // MARK: - Typography helpers
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .semibold, .bold, .heavy, .black:
            return Font.custom("CormorantGaramond-SemiBold", size: size)
        case .medium:
            return Font.custom("CormorantGaramond-Medium", size: size)
        default:
            return Font.custom("CormorantGaramond-Regular", size: size)
        }
    }

    static func serifItalic(_ size: CGFloat) -> Font {
        Font.custom("CormorantGaramond-Italic", size: size)
    }
}
