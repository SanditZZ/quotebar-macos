//
//  CustomQuoteProviderTests.swift
//  QuoteBarTests
//

import Testing
import Foundation
@testable import QuoteBar

@MainActor
private final class FakeCustomQuoteRepository: CustomQuoteRepository {
    var entries: [CustomQuoteSnapshot] = []

    func add(text: String, author: String?) throws -> CustomQuoteSnapshot {
        let snapshot = CustomQuoteSnapshot(id: UUID(), text: text, author: author, addedAt: Date())
        entries.append(snapshot)
        return snapshot
    }

    func importMany(_ parsed: [ParsedCustomQuote]) throws -> CustomQuoteImportResult {
        CustomQuoteImportResult(added: 0, skippedDuplicates: 0)
    }

    func allEntries() throws -> [CustomQuoteSnapshot] { entries }

    func remove(id: UUID) throws {
        entries.removeAll { $0.id == id }
    }
}

@Suite("Custom quote provider")
@MainActor
struct CustomQuoteProviderTests {

    @Test("Returns nil when the library is empty")
    func returnsNilWhenEmpty() async {
        let provider = CustomQuoteProvider(repository: FakeCustomQuoteRepository())
        let quote = await provider.nextQuote()
        #expect(quote == nil)
    }

    @Test("Returns a quote tagged .custom when the library has entries")
    func returnsCustomQuote() async {
        let repository = FakeCustomQuoteRepository()
        repository.entries = [TestSupport.customQuoteSnapshot(text: "My quote", author: "Me")]

        let provider = CustomQuoteProvider(repository: repository, randomIndex: { $0.lowerBound })
        let quote = await provider.nextQuote()

        #expect(quote?.text == "My quote")
        #expect(quote?.author == "Me")
        #expect(quote?.source == .custom)
    }

    @Test("randomIndex selects among all entries")
    func randomIndexSelectsAmongEntries() async {
        let repository = FakeCustomQuoteRepository()
        repository.entries = [
            TestSupport.customQuoteSnapshot(text: "First"),
            TestSupport.customQuoteSnapshot(text: "Second"),
        ]

        let provider = CustomQuoteProvider(repository: repository, randomIndex: { $0.upperBound - 1 })
        let quote = await provider.nextQuote()

        #expect(quote?.text == "Second")
    }
}
