import SwiftUI
import SwiftData

@MainActor
@Observable
final class IdeaBoardViewModel {
    private static let promotionThreshold = 20
    private static let upvotedKey = "vg_upvotedIdeaIDs"

    var showingProposeSheet = false
    var toastMessage: String? = nil

    private var upvotedIDs: Set<String> {
        get {
            let raw = UserDefaults.standard.string(forKey: Self.upvotedKey) ?? ""
            return Set(raw.split(separator: ",").map(String.init))
        }
        set {
            UserDefaults.standard.set(newValue.joined(separator: ","), forKey: Self.upvotedKey)
        }
    }

    func isUpvoted(_ idea: SchemaV7.GoalIdea) -> Bool {
        upvotedIDs.contains(idea.id.uuidString)
    }

    func toggleUpvote(_ idea: SchemaV7.GoalIdea, context: ModelContext) {
        let idStr = idea.id.uuidString
        if upvotedIDs.contains(idStr) {
            var ids = upvotedIDs; ids.remove(idStr); upvotedIDs = ids
            idea.upvoteCount = max(0, idea.upvoteCount - 1)
        } else {
            var ids = upvotedIDs; ids.insert(idStr); upvotedIDs = ids
            idea.upvoteCount += 1
            checkPromotion(idea, context: context)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        try? context.save()
    }

    func addToMyGoals(_ idea: SchemaV7.GoalIdea, goalVM: GoalViewModel, context: ModelContext) {
        let tier = GoalTier.immediate
        let frequency = GoalFrequency.daily
        let category = GoalCategory(rawValue: idea.category) ?? .other
        let input = GoalInput(title: idea.title, tier: tier, category: category,
                              frequency: frequency, reminderTime: nil,
                              isPrivate: false, startDate: nil)
        try? goalVM.addGoal(input: input, context: context)
        idea.copyCount += 1
        try? context.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func submitIdea(title: String, description: String, category: String,
                    authorName: String, context: ModelContext) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let idea = SchemaV7.GoalIdea()
        idea.title = String(title.prefix(80))
        idea.ideaDescription = String(description.prefix(200))
        idea.category = category
        idea.authorName = authorName
        context.insert(idea)
        try? context.save()
        showingProposeSheet = false
    }

    private func checkPromotion(_ idea: SchemaV7.GoalIdea, context: ModelContext) {
        guard idea.upvoteCount >= Self.promotionThreshold, !idea.isPromoted else { return }
        let template = SchemaV4.ChallengeTemplate()
        template.title = idea.title
        template.challengeDescription = idea.ideaDescription
        template.durationDays = 30
        template.isFeatured = false
        context.insert(template)
        idea.isPromoted = true
        idea.promotedChallengeID = template.id
        try? context.save()
        withAnimation {
            toastMessage = "🎉 This idea just became a challenge!"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.toastMessage = nil
        }
    }
}
