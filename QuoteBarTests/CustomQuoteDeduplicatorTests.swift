//
//  CustomQuoteDeduplicatorTests.swift
//  QuoteBarTests
//

import Testing
@testable import QuoteBar

@Suite("Custom quote deduplicator")
struct CustomQuoteDeduplicatorTests {

    @Test("An exact match is a duplicate")
    func exactMatchIsDuplicate() {
        #expect(CustomQuoteDeduplicator.isDuplicate("Hello world", against: ["Hello world"]))
    }

    @Test("Matching is case-insensitive")
    func caseInsensitiveMatch() {
        #expect(CustomQuoteDeduplicator.isDuplicate("HELLO WORLD", against: ["hello world"]))
    }

    @Test("Matching ignores surrounding whitespace on both sides")
    func whitespaceInsensitiveMatch() {
        #expect(CustomQuoteDeduplicator.isDuplicate("  Hello world  ", against: ["Hello world"]))
        #expect(CustomQuoteDeduplicator.isDuplicate("Hello world", against: ["  Hello world  "]))
    }

    @Test("A genuinely different text is not a duplicate")
    func differentTextIsNotDuplicate() {
        #expect(!CustomQuoteDeduplicator.isDuplicate("Hello world", against: ["Something else"]))
    }

    @Test("An empty candidate is never a duplicate, even against an empty existing entry")
    func emptyCandidateIsNeverDuplicate() {
        #expect(!CustomQuoteDeduplicator.isDuplicate("", against: [""]))
        #expect(!CustomQuoteDeduplicator.isDuplicate("   ", against: ["Hello"]))
    }

    @Test("An empty existing list never matches")
    func emptyExistingListNeverMatches() {
        #expect(!CustomQuoteDeduplicator.isDuplicate("Hello world", against: []))
    }
}
