//
//  RecentQuoteFilterTests.swift
//  QuoteBarTests
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Recent quote filter")
struct RecentQuoteFilterTests {

    @Test("Excludes candidates whose text was recently seen")
    func excludesRecent() {
        let candidates = [
            TestSupport.quote(text: "A"),
            TestSupport.quote(text: "B"),
            TestSupport.quote(text: "C"),
        ]

        let filtered = RecentQuoteFilter.excludingRecent(candidates, recentTexts: ["A", "C"])

        #expect(filtered.map(\.text) == ["B"])
    }

    @Test("Exclusion is case-insensitive")
    func exclusionIsCaseInsensitive() {
        // A second, non-matching candidate keeps this test clear of the
        // all-excluded fallback exercised separately below — this test is
        // specifically about case-insensitive matching, not the fallback.
        let candidates = [TestSupport.quote(text: "Hello World"), TestSupport.quote(text: "Something else")]

        let filtered = RecentQuoteFilter.excludingRecent(candidates, recentTexts: ["hello world"])

        #expect(filtered.map(\.text) == ["Something else"])
    }

    @Test("Falls back to the full pool when every candidate was recently seen")
    func fallsBackWhenAllExcluded() {
        let candidates = [TestSupport.quote(text: "A"), TestSupport.quote(text: "B")]

        let filtered = RecentQuoteFilter.excludingRecent(candidates, recentTexts: ["A", "B"])

        #expect(Set(filtered.map(\.text)) == ["A", "B"])
    }

    @Test("Empty candidate list stays empty regardless of recent texts")
    func emptyCandidatesStayEmpty() {
        #expect(RecentQuoteFilter.excludingRecent([], recentTexts: ["A"]).isEmpty)
    }

    @Test("pick(from:) returns nil for an empty pool")
    func pickReturnsNilForEmptyPool() {
        let result = RecentQuoteFilter.pick(from: [], recentTexts: []) { $0.lowerBound }
        #expect(result == nil)
    }

    @Test("pick(from:) uses the injected random index")
    func pickUsesInjectedIndex() {
        let candidates = [
            TestSupport.quote(text: "A"),
            TestSupport.quote(text: "B"),
            TestSupport.quote(text: "C"),
        ]

        let result = RecentQuoteFilter.pick(from: candidates, recentTexts: []) { range in
            range.upperBound - 1
        }

        #expect(result?.text == "C")
    }
}
