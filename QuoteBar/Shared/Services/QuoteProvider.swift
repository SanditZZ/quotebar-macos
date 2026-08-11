//
//  QuoteProvider.swift
//  QuoteBar — Actions
//
//  Common interface for every tier in the provider chain. A provider never
//  throws to its caller — it returns `nil` on any failure (unavailable model,
//  network error, malformed response) so `QuoteProviderService` can fall
//  through to the next tier unconditionally. See CONTRIBUTING.md §"The
//  provider chain is additive, not branching" before adding a new one.
//

import Foundation

protocol QuoteProvider: Sendable {
    /// Which source this provider represents, for tagging the returned quote
    /// and for logging.
    var source: QuoteSource { get }

    /// Fetch one quote, or `nil` if this tier could not produce one right now.
    func nextQuote() async -> Quote?
}
