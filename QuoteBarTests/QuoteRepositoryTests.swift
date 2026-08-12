//
//  QuoteRepositoryTests.swift
//  QuoteBarTests
//
//  Runs against a real SwiftData stack backed by an in-memory store.
//

import Testing
import Foundation
import SwiftData
@testable import QuoteBar

@Suite("Quote repository")
@MainActor
struct QuoteRepositoryTests {

    private func makeRepository() throws -> SwiftDataQuoteRepository {
        let container = try ModelContainerFactory.makeInMemory()
        return SwiftDataQuoteRepository(container: container)
    }

    /// A quote repository and a tag repository sharing the same store, for
    /// tests that exercise the `QuoteRecord` ↔ `QuoteTag` relationship.
    private func makeRepositoryPair() throws -> (SwiftDataQuoteRepository, SwiftDataQuoteTagRepository) {
        let container = try ModelContainerFactory.makeInMemory()
        return (SwiftDataQuoteRepository(container: container), SwiftDataQuoteTagRepository(container: container))
    }

    @Test("A fresh repository has no history")
    func freshRepositoryIsEmpty() throws {
        let repository = try makeRepository()
        #expect(try repository.allQuotes().isEmpty)
    }

    @Test("Recording a quote persists it and returns a matching snapshot")
    func recordPersists() throws {
        let repository = try makeRepository()
        let quote = TestSupport.quote(text: "Hello", author: "Someone", source: .zenQuotes)

        let snapshot = try repository.record(quote, seenAt: TestSupport.referenceDate)

        #expect(snapshot.text == "Hello")
        #expect(snapshot.author == "Someone")
        #expect(snapshot.source == .zenQuotes)
        #expect(try repository.allQuotes().count == 1)
    }

    @Test("The same text can be recorded more than once, as separate sightings")
    func sameTextCanRepeat() throws {
        let repository = try makeRepository()
        let quote = TestSupport.quote(text: "Repeat me")

        try repository.record(quote)
        try repository.record(quote)

        #expect(try repository.allQuotes().count == 2)
    }

    @Test("allQuotes() returns most recent first")
    func allQuotesOrdersByMostRecent() throws {
        let repository = try makeRepository()
        let earlier = TestSupport.referenceDate
        let later = earlier.addingTimeInterval(60)

        try repository.record(TestSupport.quote(text: "Older"), seenAt: earlier)
        try repository.record(TestSupport.quote(text: "Newer"), seenAt: later)

        #expect(try repository.allQuotes().map(\.text) == ["Newer", "Older"])
    }

    @Test("recentTexts(limit:) respects the limit and ordering")
    func recentTextsRespectsLimit() throws {
        let repository = try makeRepository()
        for (index, text) in ["A", "B", "C"].enumerated() {
            try repository.record(
                TestSupport.quote(text: text),
                seenAt: TestSupport.referenceDate.addingTimeInterval(Double(index))
            )
        }

        #expect(try repository.recentTexts(limit: 2) == ["C", "B"])
    }

    @Test("recentTexts(limit: 0) returns an empty array")
    func recentTextsZeroLimit() throws {
        let repository = try makeRepository()
        try repository.record(TestSupport.quote(text: "A"))
        #expect(try repository.recentTexts(limit: 0).isEmpty)
    }

    @Test("toggleFavorite flips the flag")
    func toggleFavoriteFlipsFlag() throws {
        let repository = try makeRepository()
        let snapshot = try repository.record(TestSupport.quote(text: "Fav me"))

        #expect(snapshot.isFavorite == false)

        try repository.toggleFavorite(id: snapshot.id)
        #expect(try repository.allQuotes().first?.isFavorite == true)

        try repository.toggleFavorite(id: snapshot.id)
        #expect(try repository.allQuotes().first?.isFavorite == false)
    }

    @Test("toggleFavorite on an unknown id throws")
    func toggleFavoriteUnknownIdThrows() throws {
        let repository = try makeRepository()
        #expect(throws: QuoteRepositoryError.self) {
            try repository.toggleFavorite(id: UUID())
        }
    }

    @Test("toggleTag adds the tag, and toggling again removes it")
    func toggleTagAddsThenRemoves() throws {
        let (quoteRepository, tagRepository) = try makeRepositoryPair()
        let quote = try quoteRepository.record(TestSupport.quote(text: "Tag me"))
        let tag = try tagRepository.add(name: "Stoic")

        try quoteRepository.toggleTag(tag.id, onQuote: quote.id)
        #expect(try quoteRepository.allQuotes().first?.tags.map(\.name) == ["Stoic"])

        try quoteRepository.toggleTag(tag.id, onQuote: quote.id)
        #expect(try quoteRepository.allQuotes().first?.tags.isEmpty == true)
    }

    @Test("toggleTag with an unknown quote id throws")
    func toggleTagUnknownQuoteThrows() throws {
        let (quoteRepository, tagRepository) = try makeRepositoryPair()
        let tag = try tagRepository.add(name: "Stoic")

        #expect(throws: QuoteRepositoryError.self) {
            try quoteRepository.toggleTag(tag.id, onQuote: UUID())
        }
    }

    @Test("toggleTag with an unknown tag id throws")
    func toggleTagUnknownTagThrows() throws {
        let (quoteRepository, _) = try makeRepositoryPair()
        let quote = try quoteRepository.record(TestSupport.quote(text: "Tag me"))

        #expect(throws: QuoteRepositoryError.self) {
            try quoteRepository.toggleTag(UUID(), onQuote: quote.id)
        }
    }

    @Test("A tag applied to two different quotes shows up on both")
    func tagAppliesToMultipleQuotes() throws {
        let (quoteRepository, tagRepository) = try makeRepositoryPair()
        let first = try quoteRepository.record(TestSupport.quote(text: "First"))
        let second = try quoteRepository.record(TestSupport.quote(text: "Second"))
        let tag = try tagRepository.add(name: "Stoic")

        try quoteRepository.toggleTag(tag.id, onQuote: first.id)
        try quoteRepository.toggleTag(tag.id, onQuote: second.id)

        let all = try quoteRepository.allQuotes()
        #expect(all.allSatisfy { $0.tags.map(\.name) == ["Stoic"] })
    }

    @Test("Deleting a tag removes it from a quote without deleting the quote")
    func deletingTagDetachesWithoutDeletingQuote() throws {
        let (quoteRepository, tagRepository) = try makeRepositoryPair()
        let quote = try quoteRepository.record(TestSupport.quote(text: "Tag me"))
        let tag = try tagRepository.add(name: "Stoic")
        try quoteRepository.toggleTag(tag.id, onQuote: quote.id)

        try tagRepository.remove(id: tag.id)

        let all = try quoteRepository.allQuotes()
        #expect(all.count == 1)
        #expect(all.first?.tags.isEmpty == true)
    }

    @Test("Renaming a tag is reflected on an already-tagged quote")
    func renamingTagReflectsOnTaggedQuote() throws {
        let (quoteRepository, tagRepository) = try makeRepositoryPair()
        let quote = try quoteRepository.record(TestSupport.quote(text: "Tag me"))
        let tag = try tagRepository.add(name: "Stoic")
        try quoteRepository.toggleTag(tag.id, onQuote: quote.id)

        try tagRepository.rename(id: tag.id, to: "Stoicism")

        #expect(try quoteRepository.allQuotes().first?.tags.map(\.name) == ["Stoicism"])
    }

    @Test("deleteAll removes every sighting")
    func deleteAllRemovesEverything() throws {
        let repository = try makeRepository()
        try repository.record(TestSupport.quote(text: "A"))
        try repository.record(TestSupport.quote(text: "B"))

        try repository.deleteAll()

        #expect(try repository.allQuotes().isEmpty)
    }
}
