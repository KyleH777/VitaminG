import SwiftUI

// Watch-specific design tokens — no UIColor (watchOS is UIKit-free)
// Values mirror VGTheme exactly; duplicate to keep the Watch target self-contained.
enum VGWatch {
    static let terra      = Color(red: 0.769, green: 0.404, blue: 0.227)  // #C4673A
    static let terraSoft  = Color(red: 0.910, green: 0.584, blue: 0.427)  // #E8956D
    static let terraGlow  = Color(red: 1.000, green: 0.690, blue: 0.478)  // #FFB07A
    static let sand       = Color(red: 0.949, green: 0.910, blue: 0.851)  // #F2E8D9
    static let clay       = Color(red: 0.239, green: 0.184, blue: 0.118)  // #3D2F1E
    static let sage       = Color(red: 0.478, green: 0.620, blue: 0.494)  // #7A9E7E
    static let sageBright = Color(red: 0.643, green: 0.788, blue: 0.682)  // #A4C9AE
    static let gold       = Color(red: 0.769, green: 0.643, blue: 0.349)  // #C4A459
    static let goldBright = Color(red: 0.910, green: 0.784, blue: 0.439)  // #E8C870
    static let plum       = Color(red: 0.608, green: 0.490, blue: 0.714)  // #9B7DB6
    static let muted      = Color(red: 0.604, green: 0.541, blue: 0.471)  // #9A8A78

    static let trackColor = Color.white.opacity(0.10)

    static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        let name = italic ? "CormorantGaramond-Italic" : "CormorantGaramond-Regular"
        return .custom(name, size: size)
    }
}
