//
//  QuoteTagFilterTests.swift
//  QuoteBarTests
//

import Testing
@testable import QuoteBar

@Suite("Quote tag filter")
struct QuoteTagFilterTests {

    @Test("Empty quotes returns empty, regardless of selection")
    func emptyQuotesReturnsEmpty() {
        let tag = TestSupport.tag(name: "stoic")
        let result = QuoteTagFilter.matching([], selectedTagIDs: [tag.id])
        #expect(result.isEmpty)
    }

    @Test("Empty selection returns every quote unchanged, including untagged ones")
    func emptySelectionReturnsAll() {
        let tagged = TestSupport.snapshot(text: "Tagged", tags: [TestSupport.tag(name: "stoic")])
        let untagged = TestSupport.snapshot(text: "Untagged")

        let result = QuoteTagFilter.matching([tagged, untagged], selectedTagIDs: [])

        #expect(result.map(\.text) == ["Tagged", "Untagged"])
    }

    @Test("A quote with no tags never matches a non-empty selection")
    func untaggedQuoteNeverMatches() {
        let untagged = TestSupport.snapshot(text: "Untagged")
        let someTagID = TestSupport.tag(name: "stoic").id

        let result = QuoteTagFilter.matching([untagged], selectedTagIDs: [someTagID])

        #expect(result.isEmpty)
    }

    @Test("A selected tag ID that no quote carries returns an empty result, not an error")
    func unusedTagIDReturnsEmpty() {
        let stoic = TestSupport.tag(name: "stoic")
        let quote = TestSupport.snapshot(text: "Funny one", tags: [TestSupport.tag(name: "funny")])

        let result = QuoteTagFilter.matching([quote], selectedTagIDs: [stoic.id])

        #expect(result.isEmpty)
    }

    @Test("OR semantics: a quote with only one of the selected tags is included")
    func matchesAnySelectedTag() {
        let stoic = TestSupport.tag(name: "stoic")
        let funny = TestSupport.tag(name: "funny")
        let stoicOnly = TestSupport.snapshot(text: "Stoic only", tags: [stoic])

        let result = QuoteTagFilter.matching([stoicOnly], selectedTagIDs: [stoic.id, funny.id])

        #expect(result.map(\.text) == ["Stoic only"])
    }

    @Test("A quote matching more than one selected tag is included exactly once")
    func matchingQuoteNotDuplicated() {
        let stoic = TestSupport.tag(name: "stoic")
        let funny = TestSupport.tag(name: "funny")
        let both = TestSupport.snapshot(text: "Both tags", tags: [stoic, funny])

        let result = QuoteTagFilter.matching([both], selectedTagIDs: [stoic.id, funny.id])

        #expect(result.count == 1)
    }
}
