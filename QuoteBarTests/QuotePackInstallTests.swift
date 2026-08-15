//
//  QuotePackInstallTests.swift
//  QuoteBarTests
//
//  Runs against a real SwiftData stack backed by an in-memory store, same
//  pattern as `CustomQuoteRepositoryTests`.
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Quote pack install/uninstall")
@MainActor
struct QuotePackInstallTests {

    private func makeRepository() throws -> SwiftDataCustomQuoteRepository {
        let container = try ModelContainerFactory.makeInMemory()
        return SwiftDataCustomQuoteRepository(container: container)
    }

    private func makePack(
        packId: String = "stoicism-basics",
        quotes: [QuotePackQuote] = [
            QuotePackQuote(text: "You have power over your mind", author: "Marcus Aurelius"),
            QuotePackQuote(text: "It is not what happens to you", author: "Epictetus"),
        ]
    ) -> QuotePack {
        QuotePack(
            formatVersion: QuotePack.currentFormatVersion,
            packId: packId,
            name: "Stoicism Basics",
            maintainer: "QuoteBar",
            license: "Public Domain",
            attribution: nil,
            quotes: quotes
        )
    }

    @Test("Installing a pack adds every quote, tagged with the pack's id")
    func installAddsAllQuotesTagged() throws {
        let repository = try makeRepository()
        let result = try repository.installPack(makePack())

        #expect(result.added == 2)
        #expect(result.skippedDuplicates == 0)

        let entries = try repository.allEntries()
        #expect(entries.count == 2)
        #expect(entries.allSatisfy { $0.packId == "stoicism-basics" })
    }

    @Test("Installing the same pack twice skips every quote the second time, without duplicating rows")
    func installingTwiceIsIdempotent() throws {
        let repository = try makeRepository()
        try repository.installPack(makePack())
        let second = try repository.installPack(makePack())

        #expect(second.added == 0)
        #expect(second.skippedDuplicates == 2)
        #expect(try repository.allEntries().count == 2)
    }

    @Test("A pack quote that duplicates something the user already typed is skipped, and the existing row stays user-owned")
    func packQuoteDuplicatingUserEntryStaysUserOwned() throws {
        let repository = try makeRepository()
        try repository.add(text: "You have power over your mind", author: "Marcus Aurelius")

        let result = try repository.installPack(makePack())

        #expect(result.added == 1)
        #expect(result.skippedDuplicates == 1)

        let entries = try repository.allEntries()
        let existing = entries.first { $0.text == "You have power over your mind" }
        #expect(existing?.packId == nil)
    }

    @Test("Uninstalling a pack removes exactly its own rows, leaving user-typed and other packs' quotes untouched")
    func uninstallRemovesOnlyItsOwnRows() throws {
        let repository = try makeRepository()
        try repository.add(text: "My own quote", author: nil)
        try repository.installPack(makePack())
        try repository.installPack(makePack(
            packId: "poetry-favorites",
            quotes: [QuotePackQuote(text: "Two roads diverged", author: "Robert Frost")]
        ))

        let removed = try repository.uninstallPack(packId: "stoicism-basics")

        #expect(removed == 2)
        let remainingTexts = Set(try repository.allEntries().map(\.text))
        #expect(remainingTexts == ["My own quote", "Two roads diverged"])
    }

    @Test("Uninstalling an unknown packId removes nothing and doesn't throw")
    func uninstallingUnknownPackIdRemovesNothing() throws {
        let repository = try makeRepository()
        try repository.add(text: "My own quote", author: nil)

        let removed = try repository.uninstallPack(packId: "nonexistent")

        #expect(removed == 0)
        #expect(try repository.allEntries().count == 1)
    }

    @Test("installedPackSummaries groups by packId with an accurate count, excluding user-owned entries")
    func installedPackSummariesGroupsCorrectly() throws {
        let repository = try makeRepository()
        try repository.add(text: "My own quote", author: nil)
        try repository.installPack(makePack())
        try repository.installPack(makePack(
            packId: "poetry-favorites",
            quotes: [QuotePackQuote(text: "Two roads diverged", author: "Robert Frost")]
        ))

        let summaries = try repository.installedPackSummaries()

        #expect(summaries.count == 2)
        #expect(summaries.first { $0.packId == "stoicism-basics" }?.quoteCount == 2)
        #expect(summaries.first { $0.packId == "poetry-favorites" }?.quoteCount == 1)
    }

    @Test("A fresh repository has no installed packs")
    func freshRepositoryHasNoInstalledPacks() throws {
        let repository = try makeRepository()
        #expect(try repository.installedPackSummaries().isEmpty)
    }
}
