//
//  VitaminGTests.swift
//  VitaminGTests
//
//  Created by Kyle Harrington on 4/3/26.
//

import Testing
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
