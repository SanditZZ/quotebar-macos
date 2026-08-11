//
//  QuoteProviderService.swift
//  QuoteBar — Actions
//
//  Orchestrates the four-tier provider chain. Tries each provider in order
//  and returns the first success; never throws, because `BundledQuoteProvider`
//  is always able to produce something. See CONTRIBUTING.md §"The provider
//  chain is additive, not branching" before adding a new tier.
//

import Foundation

protocol QuoteProviderServicing: Sendable {
    /// Fetch the next quote, avoiding (where possible) anything whose text
    /// appears in `recentTexts`. Always returns a quote — the bundled tier is
    /// the guaranteed last resort.
    func nextQuote(recentTexts: [String]) async -> Quote
}

/// `@unchecked Sendable`: every stored property is a `let`-bound `Sendable`
/// value (see `QuoteProvider: Sendable`), assigned once at `init` and never
/// mutated afterward.
final class QuoteProviderService: QuoteProviderServicing, @unchecked Sendable {

    private let onDeviceAI: any QuoteProvider
    private let networkProviders: [any QuoteProvider]
    private let bundled: BundledQuoteProvider

    /// - Parameters:
    ///   - onDeviceAI: Tier 1. Defaults to `FoundationModelsQuoteProvider`.
    ///   - networkProviders: Tiers 2–3, tried in order. Defaults to
    ///     `[ZenQuotesProvider, DummyJSONQuotesProvider]`.
    ///   - bundled: Tier 4, the guaranteed fallback.
    init(
        onDeviceAI: any QuoteProvider = FoundationModelsQuoteProvider(),
        networkProviders: [any QuoteProvider] = [ZenQuotesProvider(), DummyJSONQuotesProvider()],
        bundled: BundledQuoteProvider = BundledQuoteProvider()
    ) {
        self.onDeviceAI = onDeviceAI
        self.networkProviders = networkProviders
        self.bundled = bundled
    }

    func nextQuote(recentTexts: [String]) async -> Quote {
        if let quote = await tryProvider(onDeviceAI, recentTexts: recentTexts) {
            return quote
        }

        for provider in networkProviders {
            if let quote = await tryProvider(provider, recentTexts: recentTexts) {
                return quote
            }
        }

        if let quote = await bundled.nextQuote(recentTexts: recentTexts) {
            AppLog.quote.info("[Quote] Served from bundled")
            return quote
        }

        // BundledQuoteProvider only returns nil if BackupQuotes.json itself is
        // missing or empty — a packaging bug, not a runtime condition callers
        // should have to handle. Fail loudly rather than returning a fake quote.
        AppLog.quote.fault("[Quote] Every tier failed, including bundled — is BackupQuotes.json present?")
        return Quote(
            text: "No quote could be loaded. Please reinstall QuoteBar.",
            author: nil,
            source: .bundled
        )
    }

    /// Try one provider, filtering its result against recent texts (network
    /// and AI providers don't know about history themselves, unlike
    /// `BundledQuoteProvider` which filters internally against its full set).
    private func tryProvider(_ provider: any QuoteProvider, recentTexts: [String]) async -> Quote? {
        guard let quote = await provider.nextQuote() else { return nil }

        if recentTexts.contains(where: { $0.caseInsensitiveCompare(quote.text) == .orderedSame }) {
            AppLog.quote.debug("[Quote] \(provider.source.rawValue, privacy: .public) repeated a recent quote — skipping")
            return nil
        }

        AppLog.quote.info("[Quote] Served from \(provider.source.rawValue, privacy: .public)")
        return quote
    }
}
