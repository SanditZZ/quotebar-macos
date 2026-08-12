//
//  QuoteTagRepositoryTests.swift
//  QuoteBarTests
//
//  Runs against a real SwiftData stack backed by an in-memory store, same
//  pattern as `QuoteRepositoryTests`.
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Quote tag repository")
@MainActor
struct QuoteTagRepositoryTests {

    private func makeRepository() throws -> SwiftDataQuoteTagRepository {
        let container = try ModelContainerFactory.makeInMemory()
        return SwiftDataQuoteTagRepository(container: container)
    }

    @Test("A fresh repository has no tags")
    func freshRepositoryIsEmpty() throws {
        let repository = try makeRepository()
        #expect(try repository.allTags().isEmpty)
    }

    @Test("Adding a tag persists it and returns a matching snapshot")
    func addPersists() throws {
        let repository = try makeRepository()
        let snapshot = try repository.add(name: "Stoic")

        #expect(snapshot.name == "Stoic")
        #expect(try repository.allTags().count == 1)
    }

    @Test("Name is trimmed")
    func trimsName() throws {
        let repository = try makeRepository()
        let snapshot = try repository.add(name: "  Stoic  ")
        #expect(snapshot.name == "Stoic")
    }

    @Test("Adding a blank name throws")
    func addingBlankNameThrows() throws {
        let repository = try makeRepository()
        #expect(throws: QuoteTagRepositoryError.self) {
            try repository.add(name: "   ")
        }
    }

    @Test("Adding a duplicate name throws, case-insensitively")
    func addingDuplicateThrows() throws {
        let repository = try makeRepository()
        try repository.add(name: "Stoic")

        #expect(throws: QuoteTagRepositoryError.self) {
            try repository.add(name: "stoic")
        }
        #expect(try repository.allTags().count == 1)
    }

    @Test("allTags() returns alphabetical order")
    func allTagsOrdersAlphabetically() throws {
        let repository = try makeRepository()
        try repository.add(name: "Stoic")
        try repository.add(name: "Funny")

        #expect(try repository.allTags().map(\.name) == ["Funny", "Stoic"])
    }

    @Test("Renaming updates the name")
    func renameUpdatesName() throws {
        let repository = try makeRepository()
        let snapshot = try repository.add(name: "Stoic")

        try repository.rename(id: snapshot.id, to: "Stoicism")

        #expect(try repository.allTags().map(\.name) == ["Stoicism"])
    }

    @Test("Renaming to its own current name does not throw")
    func renameToSameNameDoesNotThrow() throws {
        let repository = try makeRepository()
        let snapshot = try repository.add(name: "Stoic")

        try repository.rename(id: snapshot.id, to: "Stoic")

        #expect(try repository.allTags().map(\.name) == ["Stoic"])
    }

    @Test("Renaming to a name colliding with a different tag throws")
    func renameToCollidingNameThrows() throws {
        let repository = try makeRepository()
        try repository.add(name: "Stoic")
        let funny = try repository.add(name: "Funny")

        #expect(throws: QuoteTagRepositoryError.self) {
            try repository.rename(id: funny.id, to: "stoic")
        }
    }

    @Test("Renaming an unknown id throws")
    func renameUnknownIdThrows() throws {
        let repository = try makeRepository()
        #expect(throws: QuoteTagRepositoryError.self) {
            try repository.rename(id: UUID(), to: "Anything")
        }
    }

    @Test("Removing a tag deletes it")
    func removeDeletes() throws {
        let repository = try makeRepository()
        let snapshot = try repository.add(name: "Stoic")

        try repository.remove(id: snapshot.id)

        #expect(try repository.allTags().isEmpty)
    }

    @Test("Removing an unknown id throws")
    func removeUnknownIdThrows() throws {
        let repository = try makeRepository()
        #expect(throws: QuoteTagRepositoryError.self) {
            try repository.remove(id: UUID())
        }
    }
}
