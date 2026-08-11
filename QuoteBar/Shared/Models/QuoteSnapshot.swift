//
//  QuoteSnapshot.swift
//  QuoteBar — Value types
//
//  Plain, `Sendable` value types that cross the boundary between persistence
//  and the pure calculation layer.
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

    init(
        id: UUID,
        text: String,
        author: String?,
        source: QuoteSource,
        seenAt: Date,
        isFavorite: Bool
    ) {
        self.id = id
        self.text = text
        self.author = author
        self.source = source
        self.seenAt = seenAt
        self.isFavorite = isFavorite
    }
}

/// Aggregate statistics derived from the full history. See
/// `Shared/Logic/QuoteHistoryStats.swift` for how this is computed.
struct QuoteHistoryStatsResult: Equatable, Sendable {
    /// Total quotes seen, across all sources.
    let totalSeen: Int

    /// Number of sightings marked as a favorite.
    let favoriteCount: Int

    /// Number of distinct, non-empty authors seen.
    let uniqueAuthorCount: Int

    /// Sightings grouped by source, in `QuoteSource.allCases` order.
    let countBySource: [QuoteSource: Int]

    /// The zero value, used before any data has loaded.
    static let empty = QuoteHistoryStatsResult(
        totalSeen: 0,
        favoriteCount: 0,
        uniqueAuthorCount: 0,
        countBySource: [:]
    )
}
