//
//  CustomQuoteRepositoryTests.swift
//  QuoteBarTests
//
//  Runs against a real SwiftData stack backed by an in-memory store, same
//  pattern as `QuoteRepositoryTests`.
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Custom quote repository")
@MainActor
struct CustomQuoteRepositoryTests {

    private func makeRepository() throws -> SwiftDataCustomQuoteRepository {
        let container = try ModelContainerFactory.makeInMemory()
        return SwiftDataCustomQuoteRepository(container: container)
    }

    @Test("A fresh repository has no entries")
    func freshRepositoryIsEmpty() throws {
        let repository = try makeRepository()
        #expect(try repository.allEntries().isEmpty)
    }

    @Test("Adding a quote persists it")
    func addPersists() throws {
        let repository = try makeRepository()
        let snapshot = try repository.add(text: "Hello world", author: "Someone")

        #expect(snapshot.text == "Hello world")
        #expect(snapshot.author == "Someone")
        #expect(try repository.allEntries().count == 1)
    }

    @Test("Text is trimmed, and an all-whitespace author becomes nil")
    func trimsTextAndBlankAuthor() throws {
        let repository = try makeRepository()
        let snapshot = try repository.add(text: "  Hello  ", author: "   ")

        #expect(snapshot.text == "Hello")
        #expect(snapshot.author == nil)
    }

    @Test("Adding blank text throws")
    func addingBlankTextThrows() throws {
        let repository = try makeRepository()
        #expect(throws: CustomQuoteRepositoryError.self) {
            try repository.add(text: "   ", author: nil)
        }
    }

    @Test("Adding the same text twice throws duplicate on the second add")
    func addingDuplicateThrows() throws {
        let repository = try makeRepository()
        try repository.add(text: "Hello world", author: nil)

        #expect(throws: CustomQuoteRepositoryError.self) {
            try repository.add(text: "hello world", author: "Different author") // case-insensitive match
        }
        #expect(try repository.allEntries().count == 1)
    }

    @Test("Removing an entry deletes it")
    func removeDeletes() throws {
        let repository = try makeRepository()
        let snapshot = try repository.add(text: "Hello world", author: nil)

        try repository.remove(id: snapshot.id)

        #expect(try repository.allEntries().isEmpty)
    }

    @Test("Removing an unknown id throws")
    func removeUnknownIdThrows() throws {
        let repository = try makeRepository()
        #expect(throws: CustomQuoteRepositoryError.self) {
            try repository.remove(id: UUID())
        }
    }

    @Test("importMany adds every non-duplicate row and counts duplicates skipped")
    func importManyAddsNonDuplicates() throws {
        let repository = try makeRepository()
        try repository.add(text: "Already here", author: nil)

        let parsed = [
            ParsedCustomQuote(text: "Already here", author: nil), // duplicate of existing
            ParsedCustomQuote(text: "New one", author: "Author A"),
            ParsedCustomQuote(text: "New one", author: "Author A"), // duplicate within the batch itself
        ]

        let result = try repository.importMany(parsed)

        #expect(result.added == 1)
        #expect(result.skippedDuplicates == 2)
        #expect(try repository.allEntries().count == 2)
    }

    @Test("allEntries() returns most recently added first")
    func allEntriesOrdersByMostRecentlyAdded() throws {
        let repository = try makeRepository()
        try repository.add(text: "Older", author: nil)
        try repository.add(text: "Newer", author: nil)

        #expect(try repository.allEntries().map(\.text) == ["Newer", "Older"])
    }
}
