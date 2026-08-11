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
        let candidates = [TestSupport.quote(text: "Hello World")]

        let filtered = RecentQuoteFilter.excludingRecent(candidates, recentTexts: ["hello world"])

        #expect(filtered.isEmpty)
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
