//
//  QuoteTrackerStatsTests.swift
//  QuoteBarTests
//
//  `QuoteTracker.stats` is cached rather than recomputed on read, so the thing
//  worth testing is not the arithmetic (that is covered in
//  QuoteHistoryStatsTests) but the invariant that makes caching safe: every
//  path that changes history also refreshes the cache. A stale stats block is
//  a silent bug — the numbers stay plausible, they are just the previous
//  ones — so each mutating path gets a check here.
//

import Testing
import Foundation
import SwiftData
@testable import QuoteBar

private struct StubProviderService: QuoteProviderServicing {
    let quote: Quote
    func nextQuote(recentTexts: [String], preference: QuoteSource?) async -> Quote { quote }
}

@Suite("Quote tracker stats cache")
@MainActor
struct QuoteTrackerStatsTests {

    private func makeTracker(serving text: String = "Fetched") throws -> (QuoteTracker, SwiftDataQuoteRepository) {
        let container = try ModelContainerFactory.makeInMemory()
        let repository = SwiftDataQuoteRepository(container: container)
        let defaults = UserDefaults(suiteName: "QuoteTrackerStatsTests-\(UUID().uuidString)")!
        let tracker = QuoteTracker(
            repository: repository,
            provider: StubProviderService(quote: TestSupport.quote(text: text, author: "Seneca", source: .zenQuotes)),
            settings: AppSettings(defaults: defaults),
            isEphemeral: false
        )
        return (tracker, repository)
    }

    @Test("A fresh tracker reports the empty stats")
    func freshTrackerIsEmpty() throws {
        let (tracker, _) = try makeTracker()
        #expect(tracker.stats == .empty)
    }

    @Test("Fetching a quote updates the stats, not just the history")
    func fetchUpdatesStats() async throws {
        let (tracker, _) = try makeTracker()

        await tracker.requestNewQuote()

        #expect(tracker.history.count == 1)
        #expect(tracker.stats.totalSeen == 1)
        #expect(tracker.stats.sourceCounts.map(\.source) == [.zenQuotes])
        #expect(tracker.stats.topAuthors.map(\.name) == ["Seneca"])
    }

    @Test("Reloading from disk updates the stats")
    func refreshUpdatesStats() throws {
        let (tracker, repository) = try makeTracker()
        _ = try repository.record(TestSupport.quote(text: "Written behind the tracker's back", author: "Zeno"))

        tracker.refresh()

        #expect(tracker.stats.totalSeen == 1)
        #expect(tracker.stats.topAuthors.map(\.name) == ["Zeno"])
    }

    @Test("Favoriting a quote updates the stats")
    func favoriteUpdatesStats() async throws {
        let (tracker, _) = try makeTracker()
        await tracker.requestNewQuote()
        let id = try #require(tracker.history.first?.id)

        tracker.toggleFavorite(id: id)

        #expect(tracker.stats.favoriteCount == 1)
    }

    @Test("Clearing history clears the stats with it")
    func clearHistoryClearsStats() async throws {
        let (tracker, _) = try makeTracker()
        await tracker.requestNewQuote()

        tracker.clearHistory()

        #expect(tracker.history.isEmpty)
        #expect(tracker.stats == .empty)
    }
}
