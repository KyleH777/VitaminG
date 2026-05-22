import SwiftUI

// MARK: - AboutView
// MON-01: About page with app name, version, verbatim founder bio, and floating tip footer.
// D-02: floating tip button only — no inline tip affordance in the scroll content.
// D-03: founderBio displayed verbatim from AboutContent.founderBio — no edits, no lineLimit.

struct AboutView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(AboutContent.appName)
                    .font(VGTheme.serif(34))
                    .foregroundStyle(VGTheme.textPrimary)

                Text(AboutContent.appVersionString)
                    .font(.system(size: 15))
                    .foregroundStyle(VGTheme.muted)
                    .accessibilityLabel("App version \(AboutContent.appVersionString)")

                VGTheme.separator
                    .frame(height: 1)

                // D-03: founderBio displayed verbatim — no edits, no lineLimit.
                Text(AboutContent.founderBio)
                    .font(.system(size: 17))
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineSpacing(5)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 100)  // prevent floating footer from occluding last bio line
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .navigationTitle("About Vitamin G")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                NavigationLink(destination: TipJarView()) {
                    Text("Tip the Developer ☕")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(VGTheme.warmWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(VGTheme.accentTerra)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
            }
            .background(VGTheme.sandLight)
        }
    }
}
