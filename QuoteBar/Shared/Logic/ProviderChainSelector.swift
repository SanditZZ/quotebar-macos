//
//  ProviderChainSelector.swift
//  QuoteBar — Calculations
//
//  Decides which order of QuoteSource tiers to try for a given request. Pure:
//  works only on QuoteSource identity, never touches an actual QuoteProvider,
//  so it is testable without fakes or async.
//

import Foundation

enum ProviderChainSelector {

    /// `nil` preference (automatic) returns `defaultOrder` unchanged.
    ///
    /// A non-nil preference means the user pinned one source and does not
    /// want another network/AI tier silently substituted — so only the
    /// pinned source is tried, then `bundled` as the guaranteed last resort
    /// (never skipped, since the chain must always produce something).
    /// Pinning `bundled` itself needs no separate fallback.
    static func resolvedOrder(
        preference: QuoteSource?,
        defaultOrder: [QuoteSource],
        bundled: QuoteSource
    ) -> [QuoteSource] {
        guard let preference else { return defaultOrder }
        return preference == bundled ? [bundled] : [preference, bundled]
    }
}
