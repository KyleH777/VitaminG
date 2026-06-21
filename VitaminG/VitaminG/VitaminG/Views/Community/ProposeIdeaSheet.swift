import SwiftUI
import SwiftData

struct ProposeIdeaSheet: View {
    let vm: IdeaBoardViewModel
    let authorName: String

    @Environment(\.modelContext) private var context
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = ""

    private let categories = ChallengeLibrary.categories.map(\.name)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Propose a challenge")
                        .font(VGTheme.serif(28))
                        .foregroundStyle(VGTheme.textPrimary)
                        .padding(.top, 8)
                        .accessibilityAddTraits(.isHeader)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("GOAL IDEA").font(.caption2.weight(.semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
                            .accessibilityHidden(true)
                        TextField("e.g. Walk 10,000 steps every day", text: $title, axis: .vertical)
                            .font(VGTheme.serif(20))
                            .foregroundStyle(VGTheme.textPrimary)
                            .onChange(of: title) { _, new in
                                if new.count > 80 { title = String(new.prefix(80)) }
                            }
                            .accessibilityLabel("Goal idea")
                        Divider().background(VGTheme.accentTerra)
                        Text("\(title.count)/80").font(.caption)
                            .foregroundStyle(VGTheme.textMuted).frame(maxWidth: .infinity, alignment: .trailing)
                            .accessibilityLabel("\(title.count) of 80 characters used")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("DESCRIPTION (OPTIONAL)").font(.caption2.weight(.semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
                            .accessibilityHidden(true)
                        TextField("Why is this a great goal?", text: $description, axis: .vertical)
                            .font(.body)
                            .foregroundStyle(VGTheme.textSecondary)
                            .lineLimit(3...6)
                            .onChange(of: description) { _, new in
                                if new.count > 200 { description = String(new.prefix(200)) }
                            }
                            .accessibilityLabel("Description (optional)")
                        Divider()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY").font(.caption2.weight(.semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
                            .accessibilityAddTraits(.isHeader)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                let isOn = selectedCategory == cat
                                Button { selectedCategory = isOn ? "" : cat } label: {
                                    Text(cat).font(.caption.weight(isOn ? .semibold : .regular))
                                        .foregroundStyle(isOn ? VGTheme.accentTerra : VGTheme.textMuted)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(isOn ? VGTheme.accentTerra.opacity(0.1) : VGTheme.surface)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().strokeBorder(
                                            isOn ? VGTheme.accentTerra : VGTheme.separator, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .frame(minHeight: 44)
                                .accessibilityAddTraits(isOn ? [.isSelected] : [])
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
            .background(VGTheme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.showingProposeSheet = false }.foregroundStyle(VGTheme.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share idea") {
                        vm.submitIdea(title: title, description: description,
                                      category: selectedCategory, authorName: authorName, context: context)
                    }
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(title.trimmingCharacters(in: .whitespaces).isEmpty ? VGTheme.textMuted : VGTheme.accentTerra)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
