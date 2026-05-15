import SwiftUI

struct Step2NameScreen: View {
    @Bindable var wizardVM: GoalCreationWizardViewModel
    @FocusState private var isFocused: Bool
    @State private var suggestionIndex: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerText
                goalInputCard
                suggestionsSection
                smartTip
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { nextButton }
        .onAppear { isFocused = true }
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 6) {
            stepDots
            Text("Say it\nout loud.")
                .font(.custom("CormorantGaramond-Regular", size: 34))
                .foregroundStyle(VGTheme.clay)
            Text("Name your goal. The clearer, the more it sticks.")
                .font(.subheadline)
                .foregroundStyle(VGTheme.muted)
        }
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i <= 1 ? VGTheme.terra : VGTheme.sandMid)
                    .frame(width: i == 1 ? 22 : 8, height: 8)
            }
        }
    }

    private var goalInputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Walk 10,000 steps", text: $wizardVM.draftTitle, axis: .vertical)
                .font(.custom("CormorantGaramond-Regular", size: 22))
                .foregroundStyle(VGTheme.clay)
                .lineLimit(1...4)
                .focused($isFocused)
                .onChange(of: wizardVM.draftTitle) { _, new in
                    if new.count > 100 { wizardVM.draftTitle = String(new.prefix(100)) }
                }
                .padding(.bottom, 10)
            Divider()
            HStack {
                Text("\(wizardVM.draftTitle.count)/100")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(
                        wizardVM.draftTitle.count >= 100 ? .red :
                        wizardVM.draftTitle.count >= 85 ? .orange :
                        Color.secondary.opacity(0.5)
                    )
                Spacer()
                Text("✨ Make it personal").font(.caption2).foregroundStyle(VGTheme.terra)
            }
            .padding(.top, 8)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Need ideas?")
                    .font(.caption).fontWeight(.bold).textCase(.uppercase)
                    .foregroundStyle(VGTheme.muted).tracking(1)
                Spacer()
                let pool = wizardVM.selectedCategory.suggestions
                if !pool.isEmpty {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            wizardVM.draftTitle = pool[suggestionIndex % pool.count]
                            suggestionIndex += 1
                        }
                    } label: {
                        Text("Pick one for me ✦")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(VGTheme.accentTerra)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(VGTheme.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(VGTheme.separator, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            FlowLayout(spacing: 6) {
                ForEach(wizardVM.selectedCategory.suggestions, id: \.self) { suggestion in
                    Button { wizardVM.draftTitle = suggestion } label: {
                        Text(suggestion)
                            .font(.subheadline)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(wizardVM.draftTitle == suggestion ? VGTheme.terraLight : Color.white)
                            .foregroundStyle(wizardVM.draftTitle == suggestion ? VGTheme.terra : VGTheme.clay)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(
                                wizardVM.draftTitle == suggestion ? VGTheme.terra : VGTheme.sandMid,
                                lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var smartTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("💡")
            Text("**Pro tip:** Specific goals win. \"Walk 10k steps\" beats \"exercise more.\"")
                .font(.footnote).foregroundStyle(VGTheme.clay)
        }
        .padding(12)
        .background(VGTheme.terraLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(VGTheme.terraSoft, lineWidth: 1))
    }

    private var nextButton: some View {
        Button { wizardVM.currentStep = 2 } label: {
            Text("Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(wizardVM.canAdvanceStep2 ? VGTheme.terra : VGTheme.sandMid)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!wizardVM.canAdvanceStep2)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 { y += rowHeight + spacing; x = 0; rowHeight = 0 }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing; x = bounds.minX; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height); x += size.width + spacing
        }
    }
}
