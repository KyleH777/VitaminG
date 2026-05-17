import SwiftUI

/// Phase 16 placeholder for the Community tab.
///
/// This static view occupies the Community tab slot (TAB-01, success criterion 4 — no crashes
/// on tap) until the real Community tab redesign is built in Phase 21. It renders no user data
/// and has no interactive elements.
struct CommunityPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Coming soon")
                .font(VGTheme.serif(28))
                .foregroundStyle(VGTheme.textMuted)
            Text("Your community is on its way.")
                .font(.system(size: 16))
                .foregroundStyle(VGTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VGTheme.heroBackground.ignoresSafeArea())
    }
}
