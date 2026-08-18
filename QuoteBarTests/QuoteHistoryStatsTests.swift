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
        #expect(count(of: .bundled, in: result) == 1)
        #expect(count(of: .zenQuotes, in: result) == 1)
        #expect(count(of: .onDeviceAI, in: result) == 1)
        #expect(count(of: .dummyJSON, in: result) == 1)
    }

    @Test("Author comparison is case-insensitive")
    func authorComparisonIsCaseInsensitive() {
        let snapshots = [
            TestSupport.snapshot(text: "A", author: "Seneca"),
            TestSupport.snapshot(text: "B", author: "SENECA"),
        ]

        #expect(QuoteHistoryStats.compute(from: snapshots).uniqueAuthorCount == 1)
    }

    // MARK: - Sources

    @Test("Source counts skip sources that never served a quote, and keep chain order")
    func sourceCountsAreOrderedAndSparse() {
        let snapshots = [
            TestSupport.snapshot(text: "A", source: .bundled),
            TestSupport.snapshot(text: "B", source: .onDeviceAI),
            TestSupport.snapshot(text: "C", source: .onDeviceAI),
        ]

        let result = QuoteHistoryStats.compute(from: snapshots)

        #expect(result.sourceCounts.map(\.source) == [.onDeviceAI, .bundled])
        #expect(result.sourceCounts.map(\.count) == [2, 1])
    }

    @Test("Source shares are of the whole history and add up to it")
    func sourceSharesPartitionHistory() {
        let snapshots = [
            TestSupport.snapshot(text: "A", source: .bundled),
            TestSupport.snapshot(text: "B", source: .zenQuotes),
            TestSupport.snapshot(text: "C", source: .zenQuotes),
            TestSupport.snapshot(text: "D", source: .zenQuotes),
        ]

        let result = QuoteHistoryStats.compute(from: snapshots)

        #expect(result.sourceCounts.first { $0.source == .zenQuotes }?.share == 0.75)
        #expect(result.sourceCounts.first { $0.source == .bundled }?.share == 0.25)
        #expect(abs(result.sourceCounts.reduce(0) { $0 + $1.share } - 1) < 0.000_001)
    }

    // MARK: - Top authors

    @Test("Authors rank by sightings, then alphabetically so ties are stable")
    func authorsRankByCountThenName() {
        let snapshots =
            Array(repeating: TestSupport.snapshot(text: "A", author: "Seneca"), count: 3)
            + [
                TestSupport.snapshot(text: "B", author: "Zeno"),
                TestSupport.snapshot(text: "C", author: "Epictetus"),
            ]

        let result = QuoteHistoryStats.compute(from: snapshots)

        // Zeno and Epictetus are tied at one; the name breaks it, so the order
        // is the same on every run over the same input.
        #expect(result.topAuthors.map(\.name) == ["Seneca", "Epictetus", "Zeno"])
        #expect(result.topAuthors.map(\.count) == [3, 1, 1])
    }

    @Test("Unattributed quotes are not ranked as an author")
    func unknownAuthorIsNotRanked() {
        let snapshots = [
            TestSupport.snapshot(text: "A", author: nil),
            TestSupport.snapshot(text: "B", author: "   "),
            TestSupport.snapshot(text: "C", author: "Anonymous"),
            TestSupport.snapshot(text: "D", author: "Seneca"),
        ]

        let result = QuoteHistoryStats.compute(from: snapshots)

        #expect(result.topAuthors.map(\.name) == ["Seneca"])
    }

    @Test("A case-variant author is tallied once, under its most recent spelling")
    func authorTallyUsesMostRecentSpelling() {
        // History arrives most recent first.
        let snapshots = [
            TestSupport.snapshot(text: "A", author: "Seneca"),
            TestSupport.snapshot(text: "B", author: "SENECA"),
        ]

        let result = QuoteHistoryStats.compute(from: snapshots)

        #expect(result.topAuthors == [QuoteAuthorCount(name: "Seneca", count: 2)])
    }

    @Test("The ranked lists are capped by the limits passed in")
    func rankedListsRespectTheirLimits() {
        let tag = TestSupport.tag(name: "stoic")
        let snapshots = [
            TestSupport.snapshot(text: "A", author: "One", tags: [tag]),
            TestSupport.snapshot(text: "B", author: "Two", tags: [TestSupport.tag(name: "calm")]),
            TestSupport.snapshot(text: "C", author: "Three", tags: [TestSupport.tag(name: "focus")]),
        ]

        let result = QuoteHistoryStats.compute(from: snapshots, topAuthorLimit: 2, topTagLimit: 1)

        #expect(result.topAuthors.count == 2)
        #expect(result.topTags.count == 1)
        // Capping the list must not cap the count above it.
        #expect(result.uniqueAuthorCount == 3)
    }

    @Test("A limit of zero or less returns no rows rather than trapping")
    func nonPositiveLimitsAreEmpty() {
        let snapshots = [TestSupport.snapshot(text: "A", author: "Seneca", tags: [TestSupport.tag(name: "stoic")])]

        let result = QuoteHistoryStats.compute(from: snapshots, topAuthorLimit: 0, topTagLimit: -1)

        #expect(result.topAuthors.isEmpty)
        #expect(result.topTags.isEmpty)
    }

    // MARK: - Top tags

    @Test("Tags tally across quotes, and a quote's several tags each count")
    func tagsTallyAcrossQuotes() {
        let stoic = TestSupport.tag(name: "stoic")
        let morning = TestSupport.tag(name: "morning")
        let snapshots = [
            TestSupport.snapshot(text: "A", tags: [stoic, morning]),
            TestSupport.snapshot(text: "B", tags: [stoic]),
            TestSupport.snapshot(text: "C", tags: []),
        ]

        let result = QuoteHistoryStats.compute(from: snapshots)

        #expect(result.topTags.map(\.name) == ["stoic", "morning"])
        #expect(result.topTags.map(\.count) == [2, 1])
    }

    @Test("Two tags sharing a name stay two tags")
    func sameNamedTagsAreNotMerged() {
        let first = TestSupport.tag(name: "stoic")
        let second = TestSupport.tag(name: "stoic")
        let snapshots = [
            TestSupport.snapshot(text: "A", tags: [first]),
            TestSupport.snapshot(text: "B", tags: [second]),
        ]

        let result = QuoteHistoryStats.compute(from: snapshots)

        #expect(result.topTags.count == 2)
        #expect(Set(result.topTags.map(\.id)) == [first.id, second.id])
    }

    // MARK: - Helpers

    private func count(of source: QuoteSource, in result: QuoteHistoryStatsResult) -> Int? {
        result.sourceCounts.first { $0.source == source }?.count
    }
}
