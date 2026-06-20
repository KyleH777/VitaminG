import SwiftUI

struct FAQView: View {
    private let faqs: [(question: String, answer: String)] = [
        ("What is Vitamin G?", "Vitamin G is your daily dose of intentionality. It helps you set goals across four tiers — from quick wins to life goals — and keeps them in front of you every morning."),
        ("Is Vitamin G free?", "Yes, Vitamin G is free to download and use. We may introduce optional premium features in the future."),
        ("How do I add my first goal?", "Tap the Goals tab and hit the + button. You can set a title, tier, and optional inspiration quote."),
        ("What are the four tiers?", "Immediate Wins are today's tasks. Short-Term are this week or month. Long-Term are 3–12 months. Life Goals are your north star."),
        ("Does my data sync across devices?", "Yes — your goals sync automatically via iCloud when you're signed in on multiple devices."),
        ("How do notifications work?", "Vitamin G sends you a daily morning notification with your active goal titles. You can change the time in Settings."),
        ("How do challenges work?", "Browse challenges in the Explore tab, join one, and check in daily. Your streak and progress are tracked automatically."),
        ("Is my data private?", "Your personal goals are stored privately in iCloud. Community posts are public within a challenge category."),
        ("How do I contact support?", "Email us at hello@vitamingapp.com — we read every message and usually reply within 24 hours.")
    ]

    @State private var expanded: Set<Int> = []

    var body: some View {
        List {
            ForEach(faqs.indices, id: \.self) { index in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expanded.contains(index) },
                        set: { isExpanded in
                            if isExpanded { expanded.insert(index) } else { expanded.remove(index) }
                        }
                    ),
                    content: {
                        Text(faqs[index].answer)
                            .font(.body)
                            .fontDesign(.rounded)
                            .foregroundStyle(VGTheme.textMuted)
                            .lineSpacing(4)
                            .padding(.top, 4)
                    },
                    label: {
                        Text(faqs[index].question)
                            .font(.callout.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundStyle(VGTheme.textPrimary)
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
        .tint(VGTheme.terra)
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityLabel("Frequently Asked Questions")
    }
}
