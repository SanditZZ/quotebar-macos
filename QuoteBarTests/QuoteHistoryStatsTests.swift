//
//  QuoteHistoryStatsTests.swift
//  QuoteBarTests
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Quote history stats")
struct QuoteHistoryStatsTests {

    @Test("Empty history returns the empty result")
    func emptyHistory() {
        #expect(QuoteHistoryStats.compute(from: []) == .empty)
    }

    @Test("Counts total, favorites, unique authors and per-source totals")
    func aggregatesCorrectly() {
        let snapshots = [
            TestSupport.snapshot(text: "A", author: "Seneca", source: .bundled, isFavorite: true),
            TestSupport.snapshot(text: "B", author: "Seneca", source: .zenQuotes, isFavorite: false),
            TestSupport.snapshot(text: "C", author: "Marcus Aurelius", source: .onDeviceAI, isFavorite: true),
            TestSupport.snapshot(text: "D", author: nil, source: .dummyJSON, isFavorite: false),
        ]

        let result = QuoteHistoryStats.compute(from: snapshots)

        #expect(result.totalSeen == 4)
        #expect(result.favoriteCount == 2)
        #expect(result.uniqueAuthorCount == 2) // Seneca counted once; nil author excluded.
        #expect(result.countBySource[.bundled] == 1)
        #expect(result.countBySource[.zenQuotes] == 1)
        #expect(result.countBySource[.onDeviceAI] == 1)
        #expect(result.countBySource[.dummyJSON] == 1)
    }

    @Test("Author comparison is case-insensitive")
    func authorComparisonIsCaseInsensitive() {
        let snapshots = [
            TestSupport.snapshot(text: "A", author: "Seneca"),
            TestSupport.snapshot(text: "B", author: "SENECA"),
        ]

        #expect(QuoteHistoryStats.compute(from: snapshots).uniqueAuthorCount == 1)
    }
}
