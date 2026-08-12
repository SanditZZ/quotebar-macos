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
    ///
    /// - Parameter preference: `nil` tries every tier in the default order.
    ///   A specific source tries only that source, then falls through to
    ///   `bundled` — see `ProviderChainSelector` for why no other tier is
    ///   substituted in between.
    func nextQuote(recentTexts: [String], preference: QuoteSource?) async -> Quote
}

/// `@unchecked Sendable`: every stored property is a `let`-bound `Sendable`
/// value (see `QuoteProvider: Sendable`), assigned once at `init` and never
/// mutated afterward.
final class QuoteProviderService: QuoteProviderServicing, @unchecked Sendable {

    private let defaultOrder: [QuoteSource]
    private let providersBySource: [QuoteSource: any QuoteProvider]
    private let bundled: BundledQuoteProvider

    /// - Parameters:
    ///   - onDeviceAI: Tier 1. Defaults to `FoundationModelsQuoteProvider`.
    ///   - networkProviders: Tiers 2–3, tried in order. Defaults to
    ///     `[ZenQuotesProvider, DummyJSONQuotesProvider]`.
    ///   - pinnedOnlyProviders: Registered so they can be resolved when
    ///     explicitly pinned, but never added to `defaultOrder` — see
    ///     `CustomQuoteProvider` for why. Defaults to `[CustomQuoteProvider]`
    ///     wired to a real repository via `AppEnvironment`; callers that
    ///     don't need it (most tests) can leave this empty.
    ///   - bundled: Tier 4, the guaranteed fallback.
    init(
        onDeviceAI: any QuoteProvider = FoundationModelsQuoteProvider(),
        networkProviders: [any QuoteProvider] = [ZenQuotesProvider(), DummyJSONQuotesProvider()],
        pinnedOnlyProviders: [any QuoteProvider] = [],
        bundled: BundledQuoteProvider = BundledQuoteProvider()
    ) {
        self.defaultOrder = [onDeviceAI.source] + networkProviders.map(\.source)
        var providersBySource: [QuoteSource: any QuoteProvider] = [onDeviceAI.source: onDeviceAI]
        for provider in networkProviders {
            providersBySource[provider.source] = provider
        }
        for provider in pinnedOnlyProviders {
            providersBySource[provider.source] = provider
        }
        self.providersBySource = providersBySource
        self.bundled = bundled
    }

    func nextQuote(recentTexts: [String], preference: QuoteSource?) async -> Quote {
        let order = ProviderChainSelector.resolvedOrder(
            preference: preference,
            defaultOrder: defaultOrder,
            bundled: bundled.source
        )

        for source in order {
            if source == bundled.source {
                if let quote = await bundled.nextQuote(recentTexts: recentTexts) {
                    AppLog.quote.info("[Quote] Served from bundled")
                    return quote
                }
                continue
            }

            guard let provider = providersBySource[source] else { continue }
            if let quote = await tryProvider(provider, recentTexts: recentTexts) {
                return quote
            }
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
