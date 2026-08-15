//
//  CustomQuoteEntryProvenanceTests.swift
//  QuoteBarTests
//
//  `packId` (issue #31) is a new optional property on an already-shipped
//  model. Runs against a real SwiftData stack, same pattern as
//  `CustomQuoteRepositoryTests`, to prove the two things that make it safe:
//  every entry written before packs existed is indistinguishable from a
//  user-owned entry, and a pack-owned entry's provenance survives a real
//  save/fetch round trip.
//

import Testing
import Foundation
import SwiftData
@testable import QuoteBar

@Suite("Custom quote entry provenance")
@MainActor
struct CustomQuoteEntryProvenanceTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemory()
    }

    @Test("An entry added the ordinary way — the shape of every pre-existing row — has no packId")
    func repositoryAddedEntryHasNoPackId() throws {
        let repository = SwiftDataCustomQuoteRepository(container: try makeContainer())

        let snapshot = try repository.add(text: "Hello world", author: nil)

        #expect(snapshot.packId == nil)
    }

    @Test("A pack-owned entry's packId survives a save and fetch round trip")
    func packOwnedEntrySurvivesRoundTrip() throws {
        let context = ModelContext(try makeContainer())
        let entry = CustomQuoteEntry(text: "As it is with a play", author: "Epictetus", packId: "stoicism-basics")
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CustomQuoteEntry>())

        #expect(fetched.count == 1)
        #expect(fetched.first?.packId == "stoicism-basics")
        #expect(fetched.first?.snapshot.packId == "stoicism-basics")
    }

    @Test("A mix of user-owned and pack-owned entries keeps each row's own packId distinct")
    func mixedProvenanceStaysDistinct() throws {
        let context = ModelContext(try makeContainer())
        context.insert(CustomQuoteEntry(text: "User's own quote", author: nil, packId: nil))
        context.insert(CustomQuoteEntry(text: "Pack quote", author: nil, packId: "stoicism-basics"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CustomQuoteEntry>())

        #expect(fetched.first { $0.text == "User's own quote" }?.packId == nil)
        #expect(fetched.first { $0.text == "Pack quote" }?.packId == "stoicism-basics")
    }
}
