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
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 54, height: 54)
                    .background(VGTheme.accentTerra)
                    .foregroundStyle(VGTheme.background)
                    .clipShape(Circle())
                    .shadow(color: VGTheme.accentTerra.opacity(0.4), radius: 10)
            }
            .padding(.trailing, 20).padding(.bottom, 30)

            // Toast
            if let msg = vm.toastMessage {
                Text(msg)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(VGTheme.accentSage)
                    .clipShape(Capsule())
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
                            .font(.system(size: 9, weight: .semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
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
                            .font(.system(size: 16))
                            .foregroundStyle(vm.isUpvoted(idea) ? VGTheme.accentTerra : VGTheme.textMuted)
                        Text("\(idea.upvoteCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(vm.isUpvoted(idea) ? VGTheme.accentTerra : VGTheme.textMuted)
                    }
                    .frame(width: 40, height: 44)
                    .background(VGTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(vm.isUpvoted(idea) ? VGTheme.accentTerra.opacity(0.4) : VGTheme.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if !idea.ideaDescription.isEmpty {
                Text(idea.ideaDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(VGTheme.textSecondary)
                    .lineLimit(3)
            }

            if idea.isPromoted {
                Label("Now a Challenge — view in Explore", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(VGTheme.accentSage)
            } else if idea.upvoteCount >= 15 {
                Text("🔥 Almost a challenge — \(idea.upvoteCount) votes")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(VGTheme.accentTerra)
            }

            HStack {
                Text("\(idea.copyCount) added this")
                    .font(.system(size: 11)).foregroundStyle(VGTheme.textMuted)
                Spacer()
                Button("Add to my goals →") {
                    vm.addToMyGoals(idea, goalVM: goalVM, context: context)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VGTheme.accentTerra)
            }
        }
        .padding(16)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(VGTheme.separator, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("◈").font(.system(size: 40)).foregroundStyle(VGTheme.textMuted)
            Text("No ideas yet").font(VGTheme.serif(20)).foregroundStyle(VGTheme.textPrimary)
            Text("Be the first to propose a goal the community can work toward together.")
                .font(.system(size: 13)).foregroundStyle(VGTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
