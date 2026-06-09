import SwiftUI

/// Motivation card component for the Home tab.
/// Replaces the legacy `quoteSection` in HomeView.swift.
///
/// Shows the YOUR DOSE label when Claude copy is live; the TODAY'S DOSE label when VGQuoteBank
/// fallback is active (D-01). Displays a redacted placeholder while the async fetch is in
/// flight (D-03). Never shows an empty card or error state — fallback always fills the slot.
struct AIMotivationSection: View {

    @Bindable var aiViewModel: AIViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(aiViewModel.motivationLabel)
                .font(.system(size: 9, weight: .semibold))
                .kerning(1.4)
                .textCase(.uppercase)
                .foregroundStyle(VGTheme.textMuted)

            if aiViewModel.isLoadingMotivation {
                Text("                                ")
                    .redacted(reason: .placeholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(aiViewModel.motivationResult.text)
                    .font(VGTheme.serifItalic(16))
                    .foregroundStyle(VGTheme.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Daily motivation: \(aiViewModel.motivationResult.text)")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's dose section")
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VGTheme.surface)
        .overlay(alignment: .leading) {
            Rectangle().frame(width: 2).foregroundStyle(VGTheme.accentTerra)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}
