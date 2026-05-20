// Phase 18 Wave 0 — RED tests. Will go GREEN as Plans 02 & 05 land implementations.
// Tests GOAL2-02: GoalCategory.suggestions covers 33 goals across all categories except .other.
// NOTE: GoalCategory.suggestions already exists in the codebase — these tests may go GREEN early.

import XCTest
@testable import VitaminG

final class Phase18PremadeGoalsTests: XCTestCase {

    // MARK: - GOAL2-02: Total premade goal count

    /// GOAL2-02: Flattening all GoalCategory suggestions must yield at least 33 goals.
    /// Expected distribution per RESEARCH.md: body(5) + mind(5) + wellness(5) + money(5) +
    /// connection(4) + creative(4) + habit(5) = 33. .other has 0 suggestions.
    func test_premadeGoals_totalCountIs33OrGreater() {
        let allSuggestions = GoalCategory.allCases
            .filter { !$0.suggestions.isEmpty }
            .flatMap { $0.suggestions }

        XCTAssertGreaterThanOrEqual(
            allSuggestions.count,
            33,
            "GOAL2-02: Total premade goal count must be >= 33 (got \(allSuggestions.count))"
        )
    }

    // MARK: - GOAL2-02: .other category excluded from premade goals

    /// GOAL2-02: The .other category should have no suggestions — it's for custom goals only.
    func test_premadeGoals_excludesOtherCategory() {
        let otherSuggestions = GoalCategory.other.suggestions

        XCTAssertTrue(
            otherSuggestions.isEmpty,
            "GOAL2-02: GoalCategory.other must have no premade suggestions (got \(otherSuggestions.count))"
        )
    }

    // MARK: - GOAL2-02: No empty suggestion titles

    /// GOAL2-02: Every suggestion string must be non-empty when trimmed.
    /// Guards against accidentally adding blank entries to any category.
    func test_premadeGoals_noEmptyTitles() {
        let allSuggestions = GoalCategory.allCases.flatMap { $0.suggestions }

        let emptyOrBlank = allSuggestions.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        XCTAssertTrue(
            emptyOrBlank.isEmpty,
            "GOAL2-02: Found \(emptyOrBlank.count) empty/blank suggestion titles — all suggestions must have non-empty text"
        )
    }

    // MARK: - GOAL2-02: All expected categories have suggestions

    /// GOAL2-02: The distinct set of categories with non-empty suggestions must include
    /// the 7 active categories: .body, .mind, .wellness, .money, .connection, .creative, .habit.
    func test_premadeGoals_categoriesCoverAllExpected() {
        let expectedCategories: Set<GoalCategory> = [
            .body, .mind, .wellness, .money, .connection, .creative, .habit
        ]

        let categoriesWithSuggestions = Set(
            GoalCategory.allCases.filter { !$0.suggestions.isEmpty }
        )

        let missing = expectedCategories.subtracting(categoriesWithSuggestions)

        XCTAssertTrue(
            missing.isEmpty,
            "GOAL2-02: Missing premade goals for categories: \(missing.map { $0.rawValue }.sorted().joined(separator: ", "))"
        )

        XCTAssertTrue(
            expectedCategories.isSubset(of: categoriesWithSuggestions),
            "GOAL2-02: All 7 expected categories (.body, .mind, .wellness, .money, .connection, .creative, .habit) must have suggestions"
        )
    }
}
