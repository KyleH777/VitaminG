import SwiftUI
import SwiftData

struct IdeaBoardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SchemaV7.GoalIdea.upvoteCount, order: .reverse)
    private var ideas: [SchemaV7.GoalIdea]

    @State private var vm = IdeaBoardViewModel()
    @State private var goalVM = GoalViewModel()
    @AppStorage("vg_onboardingName") private var userName: String = ""

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(ideas) { idea in
                        ideaCard(idea)
                    }
                    if ideas.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }

            // FAB
            Button { vm.showingProposeSheet = true } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .frame(width: 54, height: 54)
                    .background(VGTheme.accentTerra)
                    .foregroundStyle(VGTheme.background)
                    .clipShape(Circle())
                    .shadow(color: VGTheme.accentTerra.opacity(0.4), radius: 10)
            }
            .padding(.trailing, 20).padding(.bottom, 30)
            .accessibilityLabel("Propose a new goal idea")

            // Toast
            if let msg = vm.toastMessage {
                Text(msg)
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(VGTheme.accentSage)
                    .clipShape(Capsule())
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityLiveRegion(.polite)
            }
        }
        .sheet(isPresented: $vm.showingProposeSheet) {
            ProposeIdeaSheet(vm: vm, authorName: userName)
        }
        .animation(.easeInOut, value: vm.toastMessage)
    }

    private func ideaCard(_ idea: SchemaV7.GoalIdea) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if !idea.category.isEmpty {
                        Text(idea.category.uppercased())
                            .font(.caption2.weight(.semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
                            .accessibilityHidden(true)
                    }
                    Text(idea.title)
                        .font(VGTheme.serif(17))
                        .foregroundStyle(VGTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button { vm.toggleUpvote(idea, context: context) } label: {
                    VStack(spacing: 2) {
                        Text("△")
                            .font(.callout)
                            .foregroundStyle(vm.isUpvoted(idea) ? VGTheme.accentTerra : VGTheme.textMuted)
                            .accessibilityHidden(true)
                        Text("\(idea.upvoteCount)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(vm.isUpvoted(idea) ? VGTheme.accentTerra : VGTheme.textMuted)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .background(VGTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(vm.isUpvoted(idea) ? VGTheme.accentTerra.opacity(0.4) : VGTheme.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(vm.isUpvoted(idea) ? "Remove upvote. \(idea.upvoteCount) votes" : "Upvote. \(idea.upvoteCount) votes")
                .accessibilityAddTraits(vm.isUpvoted(idea) ? [.isSelected] : [])
            }

            if !idea.ideaDescription.isEmpty {
                Text(idea.ideaDescription)
                    .font(.callout)
                    .foregroundStyle(VGTheme.textSecondary)
                    .lineLimit(3)
            }

            if idea.isPromoted {
                Label("Now a Challenge — view in Explore", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(VGTheme.accentSage)
            } else if idea.upvoteCount >= 15 {
                Text("Almost a challenge — \(idea.upvoteCount) votes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(VGTheme.accentTerra)
            }

            HStack {
                Text("\(idea.copyCount) added this")
                    .font(.caption).foregroundStyle(VGTheme.textMuted)
                Spacer()
                Button("Add to my goals") {
                    vm.addToMyGoals(idea, goalVM: goalVM, context: context)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(VGTheme.accentTerra)
                .frame(minHeight: 44)
                .accessibilityLabel("Add \(idea.title) to my goals")
            }
        }
        .padding(16)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(VGTheme.separator, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("◈").font(.largeTitle).foregroundStyle(VGTheme.textMuted).accessibilityHidden(true)
            Text("No ideas yet").font(VGTheme.serif(20)).foregroundStyle(VGTheme.textPrimary)
            Text("Be the first to propose a goal the community can work toward together.")
                .font(.callout).foregroundStyle(VGTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
