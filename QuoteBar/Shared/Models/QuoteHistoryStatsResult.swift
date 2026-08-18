//
//  QuoteHistoryStatsResult.swift
//  QuoteBar — Data
//
//  What the history aggregation produces. Plain `Sendable` value types with no
//  logic of their own — see `Shared/Logic/QuoteHistoryStats.swift` for how each
//  field is derived, and `Views/Components/HistoryInsightsView.swift` for how
//  they are shown.
//

import Foundation

/// Aggregate statistics derived from the full history.
struct QuoteHistoryStatsResult: Equatable, Sendable {
    /// Total quotes seen, across all sources.
    let totalSeen: Int

    /// Number of sightings marked as a favorite.
    let favoriteCount: Int

    /// Number of distinct, non-empty authors seen.
    let uniqueAuthorCount: Int

    /// Sightings grouped by source, ordered by `QuoteSource.allCases`. Sources
    /// that never served a quote are left out rather than listed as zero — a
    /// row of zeroes says nothing and costs the same space as a row that does.
    let sourceCounts: [QuoteSourceCount]

    /// The most-seen authors, most first, capped by the limit passed to
    /// `QuoteHistoryStats.compute`.
    let topAuthors: [QuoteAuthorCount]

    /// The most-used tags, most first, capped by the limit passed to
    /// `QuoteHistoryStats.compute`.
    let topTags: [QuoteTagCount]

    /// The zero value, used before any data has loaded.
    static let empty = QuoteHistoryStatsResult(
        totalSeen: 0,
        favoriteCount: 0,
        uniqueAuthorCount: 0,
        sourceCounts: [],
        topAuthors: [],
        topTags: []
    )
}

/// How many sightings one source produced, and what share of the history that
/// is. `share` is meaningful here and nowhere else in this file: every sighting
/// has exactly one source, so these shares partition the history and sum to 1.
/// Authors and tags do not partition it — a sighting can carry several tags, or
/// no author at all — so those tallies carry a count only.
struct QuoteSourceCount: Equatable, Sendable, Identifiable {
    let source: QuoteSource
    let count: Int

    /// `count` over the total seen, in `0...1`.
    let share: Double

    var id: QuoteSource { source }
}

/// How many sightings one author accounts for.
struct QuoteAuthorCount: Equatable, Sendable, Identifiable {
    /// The author as it should be displayed — the spelling that arrived most
    /// recently, since authors are grouped case-insensitively.
    let name: String

    let count: Int

    var id: String { name }
}

/// How many sightings carry one tag.
struct QuoteTagCount: Equatable, Sendable, Identifiable {
    let id: UUID
    let name: String
    let count: Int
}
