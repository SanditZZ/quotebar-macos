//
//  BundledQuoteProvider.swift
//  QuoteBar — Actions
//
//  Tier 4, the last resort: `Resources/BackupQuotes.json`, shipped inside the
//  app bundle. Always available — no network, no on-device model — so this is
//  the only provider `QuoteProviderService` is allowed to assume never
//  returns `nil` in practice.
//

import Foundation

/// `@unchecked Sendable`: every stored property is either an immutable,
/// lazily-computed-once `static let` (`allQuotes`) or a `let`-bound
/// `@Sendable` closure assigned once at `init` and never mutated afterward —
/// genuinely safe to share across concurrency domains, just not something the
/// compiler can verify automatically for a class.
final class BundledQuoteProvider: QuoteProvider, @unchecked Sendable {
    let source = QuoteSource.bundled

    /// Every bundled quote's text, for checking a custom/imported quote
    /// against the offline set before it's added — see `CustomQuoteDeduplicator`.
    static var allTexts: [String] { allQuotes.map(\.text) }

    private struct Entry: Decodable {
        let text: String
        let author: String?
    }

    /// Loaded once and cached; the bundled file never changes at runtime.
    private static let allQuotes: [Quote] = {
        guard
            let url = Bundle.main.url(forResource: "BackupQuotes", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([Entry].self, from: data)
        else {
            AppLog.quote.fault("[Quote] BackupQuotes.json is missing or malformed — bundled fallback has nothing to serve")
            return []
        }

        return entries.map { Quote(text: $0.text, author: $0.author, source: .bundled) }
    }()

    /// Injectable random-index function so `nextQuote(recentTexts:)` is
    /// testable without depending on `Int.random(in:)`.
    private let randomIndex: @Sendable (Range<Int>) -> Int

    init(randomIndex: @escaping @Sendable (Range<Int>) -> Int = { $0.randomElement() ?? $0.lowerBound }) {
        self.randomIndex = randomIndex
    }

    func nextQuote() async -> Quote? {
        await nextQuote(recentTexts: [])
    }

    /// Preferred entry point: avoids repeating what the user just saw. The
    /// no-argument `nextQuote()` above satisfies `QuoteProvider` for the
    /// generic chain; `QuoteProviderService` calls this overload directly.
    func nextQuote(recentTexts: [String]) async -> Quote? {
        RecentQuoteFilter.pick(
            from: Self.allQuotes,
            recentTexts: recentTexts,
            randomIndex: randomIndex
        )
    }
}
