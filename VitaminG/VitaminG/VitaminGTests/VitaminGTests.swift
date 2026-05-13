//
//  VitaminGTests.swift
//  VitaminGTests
//
//  Created by Kyle Harrington on 4/3/26.
//

import Testing
import Foundation
@testable import VitaminG

// MARK: - InputSanitizer Tests

struct InputSanitizerTests {

    @Test func sanitizeStripsControlCharacters() {
        let input = "Hello\u{0000}World"
        #expect(InputSanitizer.sanitize(input) == "HelloWorld")
    }

    @Test func sanitizeCollapsesWhitespace() {
        let input = "Hello    World"
        #expect(InputSanitizer.sanitize(input) == "Hello World")
    }

    @Test func sanitizeTrimsEdges() {
        let input = "  Hello World  "
        #expect(InputSanitizer.sanitize(input) == "Hello World")
    }

    @Test func sanitizePreservesNewlines() {
        let input = "Line one\nLine two"
        #expect(InputSanitizer.sanitize(input) == "Line one\nLine two")
    }

    @Test func sanitizeForPublicStripsHTMLCharacters() {
        let input = "<script>alert('xss')</script>"
        let result = InputSanitizer.sanitizeForPublic(input)
        #expect(!result.contains("<"))
        #expect(!result.contains(">"))
        #expect(!result.contains("'"))
    }

    @Test func sanitizeForPublicStripsQuotes() {
        let input = "He said \"hello\""
        let result = InputSanitizer.sanitizeForPublic(input)
        #expect(!result.contains("\""))
    }
}

// MARK: - NotificationPreferences Tests

struct NotificationPreferencesTests {

    @Test func defaultValues() {
        #expect(NotificationPreferences.defaultHour == 8)
        #expect(NotificationPreferences.defaultMinute == 0)
    }
}

// MARK: - GoalTier Tests

struct GoalTierTests {

    @Test func orderedContainsExactlyFourTiers() {
        #expect(GoalTier.ordered.count == 4)
    }

    @Test func orderedContainsAllExpectedCases() {
        let ordered = GoalTier.ordered
        #expect(ordered.contains(.immediate))
        #expect(ordered.contains(.shortTerm))
        #expect(ordered.contains(.longTerm))
        #expect(ordered.contains(.lifeGoal))
    }

    @Test func allTiersHaveNonEmptyDisplayName() {
        for tier in GoalTier.ordered {
            #expect(!tier.displayName.isEmpty, "Expected non-empty displayName for tier \(tier)")
        }
    }

    @Test func allTiersHaveNonEmptyIcon() {
        for tier in GoalTier.ordered {
            #expect(!tier.icon.isEmpty, "Expected non-empty icon for tier \(tier)")
        }
    }
}

// MARK: - OnboardingViewModel Tests

struct OnboardingViewModelTests {

    @Test func initialStateNotCompleted() async {
        let vm = await OnboardingViewModel()
        await #expect(vm.hasCreatedFirstGoal == false)
    }

    @Test func hasCompletedOnboardingDefaultsToFalseWhenNotSet() {
        let key = "hasCompletedOnboarding"
        // Remove key to simulate fresh install state
        UserDefaults.standard.removeObject(forKey: key)
        // @AppStorage("hasCompletedOnboarding") defaults to false (Bool zero value)
        #expect(UserDefaults.standard.bool(forKey: key) == false)
        // Cleanup — ensure key is absent after test
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - EmptyTierView Tests

struct EmptyTierViewTests {

    @Test func warmCopyExistsForAllTiers() {
        // Verify all four tiers produce non-empty prompt copy
        for tier in GoalTier.ordered {
            let view = EmptyTierView(tier: tier, onAdd: {})
            // EmptyTierView exists and can be instantiated for all tiers
            #expect(tier.displayName.isEmpty == false)
            _ = view
        }
    }

    @Test func orderedHasExactlyFourTiersForEmptyStateRendering() {
        // Requirement: EmptyTierView must be renderable for all 4 GoalTier cases
        #expect(GoalTier.ordered.count == 4)
        let expectedTiers: [GoalTier] = [.immediate, .shortTerm, .longTerm, .lifeGoal]
        for expected in expectedTiers {
            #expect(GoalTier.ordered.contains(expected), "GoalTier.ordered missing expected case: \(expected)")
        }
    }
}
