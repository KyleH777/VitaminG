import XCTest
@testable import VitaminG

// Wave 0 RED test stubs for AIViewModel.
//
// These tests REFERENCE types that Plan 02 (Wave 1) will introduce:
//   AIViewModel, MotivationResult, AIProxyService.staticSuggestions
//
// The VitaminGTests target build WILL FAIL until Plan 02 adds AIViewModel.swift —
// this is the expected Wave 0 RED state. Plan 02 turns these GREEN.
//
// Analog: WatchSessionManagerTests.swift (singleton stub injection, @MainActor, setUp/tearDown)
// Ref: 28-VALIDATION.md Wave 0 Requirements, 28-RESEARCH.md Validation Architecture (lines 902–964)

@MainActor
final class AIViewModelTests: XCTestCase {

    // MARK: - Subject under test

    private var viewModel: AIViewModel!

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        viewModel = AIViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - motivationLabel tests (AI-02)

    /// Validates motivationLabel returns "YOUR DOSE" when motivationResult is .claude (D-01).
    /// The label changes to indicate live Claude copy is displayed, not VGQuoteBank fallback.
    func test_motivationLabel_claudeResult_returnsYourDose() {
        viewModel.motivationResult = .claude("hi")

        XCTAssertEqual(viewModel.motivationLabel, "YOUR DOSE",
                       "motivationLabel must be 'YOUR DOSE' when result is .claude per D-01")
    }

    /// Validates motivationLabel returns "TODAY'S DOSE" when motivationResult is .fallback (D-01).
    /// The fallback label matches the existing quoteSection header text.
    func test_motivationLabel_fallbackResult_returnsTodaysDose() {
        viewModel.motivationResult = .fallback("hi")

        XCTAssertEqual(viewModel.motivationLabel, "TODAY'S DOSE",
                       "motivationLabel must be 'TODAY'S DOSE' when result is .fallback per D-01")
    }

    // MARK: - addedSuggestionIndices tests (AI-01)

    /// Validates addedSuggestionIndices starts empty — no suggestions are pre-added on init.
    func test_addedSuggestionIndices_initiallyEmpty() {
        XCTAssertTrue(viewModel.addedSuggestionIndices.isEmpty,
                      "addedSuggestionIndices must be empty on initialization (no pre-added suggestions)")
    }

    /// Validates addedSuggestionIndices correctly tracks inserted indices.
    /// Inserting index 0 must reflect in contains(0) but not contains(1).
    func test_addedSuggestionIndices_insertReflected() {
        viewModel.addedSuggestionIndices.insert(0)

        XCTAssertTrue(viewModel.addedSuggestionIndices.contains(0),
                      "addedSuggestionIndices must contain 0 after insert")
        XCTAssertFalse(viewModel.addedSuggestionIndices.contains(1),
                       "addedSuggestionIndices must not contain 1 when only 0 was inserted")
    }

    // MARK: - Initial state tests

    /// Validates initial suggestions are the static fallback list (D-07).
    /// Before any network fetch, the card shows generic suggestions, not an empty state.
    func test_initialSuggestions_areStaticFallback() {
        XCTAssertEqual(viewModel.suggestions, AIProxyService.staticSuggestions,
                       "Initial suggestions must equal AIProxyService.staticSuggestions (D-07 — card always present)")
    }

    /// Validates initial motivationResult is .fallback (not .claude).
    /// Before any Claude response is received, the card shows VGQuoteBank copy (D-03).
    func test_initialMotivation_isFallback() {
        XCTAssertFalse(viewModel.motivationResult.isClaude,
                       "Initial motivationResult must be .fallback — Claude copy is not available before first fetch")
    }
}
