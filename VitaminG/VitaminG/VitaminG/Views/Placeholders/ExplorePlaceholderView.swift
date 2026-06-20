import SwiftUI

/// Phase 16 placeholder for the Explore tab.
///
/// This static view occupies the Explore tab slot (TAB-01, success criterion 4 — no crashes
/// on tap) until the real Explore tab content is built in Phase 20. It renders no user data
/// and has no interactive elements.
struct ExplorePlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Coming soon")
                .font(VGTheme.serif(28))
                .foregroundStyle(VGTheme.textMuted)
            Text("Something exciting is brewing.")
                .font(.body)
                .foregroundStyle(VGTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VGTheme.heroBackground.ignoresSafeArea())
    }
}
