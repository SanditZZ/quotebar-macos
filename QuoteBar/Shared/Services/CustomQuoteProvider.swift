//
//  CustomQuoteProvider.swift
//  QuoteBar — Actions
//
//  A pin-only tier: registered with `QuoteProviderService` but never part of
//  its automatic fallback order (see `QuoteSource.custom`), so it only runs
//  when `AppSettings.preferredSource` is pinned to it.
//
//  `@unchecked Sendable`: `repository` and `randomIndex` are both `let`-bound
//  and assigned once at `init`. `repository` is `@MainActor`-isolated, so
//  every call into it already hops onto the main actor and is serialized
//  there — the same trust boundary `QuoteTracker` and `SwiftDataQuoteRepository`
//  already rely on.
//

import Foundation

final class CustomQuoteProvider: QuoteProvider, @unchecked Sendable {
    let source = QuoteSource.custom

    private let repository: any CustomQuoteRepository

    /// Injectable random-index function, same pattern as `BundledQuoteProvider`.
    private let randomIndex: @Sendable (Range<Int>) -> Int

    init(
        repository: any CustomQuoteRepository,
        randomIndex: @escaping @Sendable (Range<Int>) -> Int = { $0.randomElement() ?? $0.lowerBound }
    ) {
        self.repository = repository
        self.randomIndex = randomIndex
    }

    func nextQuote() async -> Quote? {
        guard let entries = try? await repository.allEntries(), !entries.isEmpty else { return nil }

        let index = randomIndex(0..<entries.count)
        let entry = entries[index]
        return Quote(text: entry.text, author: entry.author, source: .custom)
    }
}
