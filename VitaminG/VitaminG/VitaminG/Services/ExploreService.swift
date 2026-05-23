import Foundation
import CloudKit

/// Fetches TrendingGoal records from the CloudKit public database.
/// Mirrors CommunityService.fetchPosts pattern exactly.
/// Falls back to an empty array on any error — callers use ExploreContent.staticTrendingGoals
/// as fallback when the returned array is empty.
enum ExploreService {

    static func fetchTrendingGoals(limit: Int = 5) async -> [TrendingGoalItem] {
        do {
            let db = CKContainer.default().publicCloudDatabase
            let query = CKQuery(
                recordType: "TrendingGoal",
                predicate: NSPredicate(value: true)
            )
            query.sortDescriptors = [NSSortDescriptor(key: "participantCount", ascending: false)]
            let (results, _) = try await db.records(matching: query, resultsLimit: limit)
            let records = results.compactMap { try? $0.1.get() }
            return records.compactMap { record -> TrendingGoalItem? in
                guard
                    let rawTitle = record["title"] as? String,
                    let categoryStr = record["category"] as? String,
                    let participantCount = record["participantCount"] as? Int,
                    let completedCount = record["completedCount"] as? Int,
                    let category = GoalCategory(rawValue: categoryStr)
                else { return nil }
                // ASVS V5 — sanitize CloudKit string before display
                let title = InputSanitizer.sanitize(rawTitle)
                return TrendingGoalItem(
                    id: record.recordID.recordName,
                    title: title,
                    category: category,
                    participantCount: participantCount,
                    completedCount: completedCount
                )
            }
        } catch {
            // Silent fallback — TrendingGoal schema may not yet be deployed to production
            return []
        }
    }
}
