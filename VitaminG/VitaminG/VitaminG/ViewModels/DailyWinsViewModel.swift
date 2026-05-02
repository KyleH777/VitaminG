import SwiftData
import Foundation
import Observation

// MARK: - DailyWinValidationError

enum DailyWinValidationError: LocalizedError, Equatable {
    case textEmpty
    case textTooLong(Int)

    var errorDescription: String? {
        switch self {
        case .textEmpty:
            return "Please enter your win before saving."
        case .textTooLong(let max):
            return "Entry must be \(max) characters or fewer."
        }
    }
}

// MARK: - DailyWinsViewModel

/// MVVM ViewModel for the Daily Wins tab.
/// Follows the @MainActor @Observable pattern established by GoalViewModel and StatsViewModel.
/// ModelContext is injected at call-site — ViewModel holds no SwiftUI or SwiftData dependencies.
/// @Query for the history list lives in DailyWinsView; ViewModel handles mutations only.
@MainActor
@Observable
final class DailyWinsViewModel {

    /// Max allowed characters for a win entry — consistent with goalDescription 500-char limit (D-04).
    static let maxTextLength = 500

    /// Draft text bound to the TextEditor in DailyWinsView.
    var draftText: String = ""

    /// Inline validation error surfaced below the TextEditor.
    var validationError: DailyWinValidationError?

    // MARK: - One-per-day enforcement (D-05, GRAT-04)

    /// Returns today's DailyWin if one exists, otherwise nil.
    /// Uses Calendar.current.startOfDay for DST-safe day boundaries (StreakEngine pattern).
    func todayEntry(context: ModelContext) -> DailyWin? {
        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            return nil
        }
        let descriptor = FetchDescriptor<DailyWin>(
            predicate: #Predicate { win in
                (win.date ?? Date.distantPast) >= today &&
                (win.date ?? Date.distantPast) < tomorrow
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - CRUD

    /// Saves the current draftText as today's win entry.
    /// If today's entry already exists, updates its text (no duplicate insert).
    /// Validates using InputSanitizer before any persistence operation.
    /// Throws DailyWinValidationError on invalid input.
    func saveEntry(context: ModelContext) throws {
        let clean = InputSanitizer.sanitize(draftText)
        guard !clean.isEmpty else {
            validationError = .textEmpty
            throw DailyWinValidationError.textEmpty
        }
        guard clean.count <= Self.maxTextLength else {
            validationError = .textTooLong(Self.maxTextLength)
            throw DailyWinValidationError.textTooLong(Self.maxTextLength)
        }
        validationError = nil

        if let existing = todayEntry(context: context) {
            // Edit existing entry (D-06) — no second insert for today
            existing.text = clean
        } else {
            // Insert new entry (D-05)
            let win = DailyWin(date: Date(), text: clean)
            context.insert(win)
        }
    }

    /// Deletes a win entry from the store (D-07).
    func delete(_ win: DailyWin, context: ModelContext) {
        context.delete(win)
    }
}
