//
//  Quote.swift
//  QuoteBar — Data
//
//  The in-flight value a `QuoteProvider` hands back before it is persisted.
//  Plain, `Sendable` value type — never a SwiftData model — so providers,
//  which run off the main actor while fetching, can pass it around freely.
//

import Foundation

struct Quote: Equatable, Hashable, Sendable {
    /// The quote text, trimmed of surrounding whitespace and quotation marks.
    let text: String

    /// The attributed author, or `nil` for an on-device AI quote (which is
    /// never given a fabricated author) or a source that didn't supply one.
    let author: String?

    /// Which provider produced this quote.
    let source: QuoteSource

    init(text: String, author: String?, source: QuoteSource) {
        self.text = text
        self.author = author
        self.source = source
    }
}
