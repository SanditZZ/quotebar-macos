//
//  QuoteSnapshot.swift
//  QuoteBar — Value types
//
//  The plain, `Sendable` value type that crosses the boundary between
//  persistence and the pure calculation layer. What the calculation layer
//  produces from it lives in `QuoteHistoryStatsResult.swift`.
//

import Foundation

/// An immutable reading of one seen quote.
struct QuoteSnapshot: Equatable, Hashable, Sendable, Codable, Identifiable {
    let id: UUID
    let text: String
    let author: String?
    let source: QuoteSource
    let seenAt: Date
    let isFavorite: Bool
    let tags: [TagSnapshot]

    init(
        id: UUID,
        text: String,
        author: String?,
        source: QuoteSource,
        seenAt: Date,
        isFavorite: Bool,
        tags: [TagSnapshot]
    ) {
        self.id = id
        self.text = text
        self.author = author
        self.source = source
        self.seenAt = seenAt
        self.isFavorite = isFavorite
        self.tags = tags
    }
}
