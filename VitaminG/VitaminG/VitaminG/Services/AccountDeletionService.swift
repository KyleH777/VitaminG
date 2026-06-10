import Foundation
import SwiftData
import CloudKit
import UserNotifications
import WidgetKit

// MARK: - AccountDeletionService

/// Permanently deletes the user's account and all associated data (DEL-01).
///
/// Satisfies App Store Guideline 5.1.1(v) (in-app account deletion for apps with
/// account creation) and Terms & Conditions §2 (In-App Account Deletion).
///
/// DELETION ORDER IS DELIBERATE — CloudKit first, local last:
/// If the local store were wiped first and the network call failed, the public
/// CloudKit records (PublicProfile, PublicGoal) would be orphaned forever because
/// vg_appleUserID and the per-goal record names would be gone. By deleting remote
/// records first, any failure leaves local state intact so the user can retry.
///
/// Phases:
///   1. Collect CloudKit record names from local store (read-only)
///   2. Delete PublicGoal records (idempotent — .unknownItem is success)
///   3. Delete PublicProfile record keyed by appleUserID (idempotent)
///   4. Wipe all SwiftData models (SchemaV10.models, batch delete)
///   5. Remove the UserDefaults persistent domain (block list, notification prefs,
///      AI cache, streak freeze, milestone gate, audit log, onboarding flags)
///   6. Cancel all pending + delivered local notifications
///   7. Reload widget timelines so widgets render the signed-out placeholder
///
/// Testing: like PublicGoalService, static override closures let unit tests bypass
/// CKContainer init (which crashes without iCloud entitlements in test runs).
enum AccountDeletionService {

    private static let containerID = "iCloud.com.kyleharrington.VitaminG"

    // MARK: - Test Overrides

    /// Set in test environments to bypass CKContainer init. nil in production.
    static var deletePublicRecordsOverride: ((_ recordNames: [String]) async throws -> Void)?

    // MARK: - Errors

    enum DeletionError: LocalizedError {
        case cloudKitFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .cloudKitFailed:
                return "We couldn't remove your public data from the server. Your local data has NOT been deleted. Please check your connection and try again."
            }
        }
    }

    // MARK: - Public API

    /// Deletes the account. Throws DeletionError.cloudKitFailed if remote deletion
    /// fails — local data is untouched in that case so the user can retry safely.
    /// On success, all local data is gone and the caller must route to onboarding.
    @MainActor
    static func deleteAccount(context: ModelContext) async throws {

        // Phase 1: Collect remote record names BEFORE touching anything.
        let appleUserID = UserDefaults.standard.string(forKey: "vg_appleUserID")
        var recordNames: [String] = []

        let goals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
        for goal in goals {
            if let recordName = goal.cloudKitPublicGoalRecordID, !recordName.isEmpty {
                recordNames.append(recordName)
            }
        }
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        for profile in profiles {
            if let recordName = profile.cloudKitPublicRecordID, !recordName.isEmpty {
                recordNames.append(recordName)
            }
        }
        // PublicProfile record is keyed by the Apple user ID itself
        // (UsernameLookupService.writeUsername uses CKRecord.ID(recordName: appleUserID)).
        if let appleUserID, !appleUserID.isEmpty {
            recordNames.append(appleUserID)
        }

        // Phases 2–3: Delete remote records first. Failure here aborts with local data intact.
        do {
            try await deletePublicRecords(recordNames: recordNames)
        } catch {
            throw DeletionError.cloudKitFailed(underlying: error)
        }

        // Phase 4: Wipe every SwiftData model. Mirrors SchemaV10.models exactly.
        // Explicit enumeration required — ModelContext.delete(model:) is generic
        // and Swift cannot open existential metatypes for it.
        try? context.delete(model: Goal.self)
        try? context.delete(model: SchemaV2.CompletionEvent.self)
        try? context.delete(model: UserProfile.self)
        try? context.delete(model: SchemaV3.DailyWin.self)
        try? context.delete(model: SchemaV4.ChallengeTemplate.self)
        try? context.delete(model: SchemaV4.UserChallenge.self)
        try? context.delete(model: SchemaV4.CheckIn.self)
        try? context.delete(model: SchemaV5.TransformationPhoto.self)
        try? context.delete(model: SchemaV5.SpendingFreezeEntry.self)
        try? context.delete(model: SchemaV5.NutritionEntry.self)
        try? context.delete(model: SchemaV7.GoalIdea.self)
        try? context.delete(model: SchemaV7.MoodEntry.self)
        try? context.save()

        // Phase 5: Remove the entire UserDefaults domain. Covers vg_appleUserID,
        // vg_blockedUserIDs, vg_onboardingName, notification preferences, AI response
        // cache, streak freezes, milestone gates, and the security audit log.
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // Phase 6: Cancel all scheduled and delivered notifications.
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        // Phase 7: Widgets re-render from the now-empty App Group store.
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - CloudKit Deletion

    /// Deletes all public records. Idempotent: .unknownItem means already gone — success.
    /// Mirrors PublicGoalService.deletePublicGoal's error policy (D-10).
    private static func deletePublicRecords(recordNames: [String]) async throws {
        if let override = deletePublicRecordsOverride {
            try await override(recordNames)
            return
        }
        guard !recordNames.isEmpty else { return }

        let db = CKContainer(identifier: containerID).publicCloudDatabase
        for recordName in recordNames {
            do {
                try await db.deleteRecord(withID: CKRecord.ID(recordName: recordName))
            } catch let error as CKError where error.code == .unknownItem {
                // Already deleted — not an error (idempotent delete, same policy as
                // PublicGoalService.deletePublicGoal).
            }
            // Any other CKError propagates and aborts the deletion before local wipe.
        }
    }
}
