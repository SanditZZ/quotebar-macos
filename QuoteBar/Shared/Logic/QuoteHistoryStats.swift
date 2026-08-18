//
//  QuoteHistoryStats.swift
//  QuoteBar — Calculations
//
//  Aggregate statistics over quote history. Pure function over value types —
//  no SwiftData, no I/O.
//

import Foundation

enum QuoteHistoryStats {

    /// Default number of rows a ranked breakdown keeps. Five fits the History
    /// window without pushing the quote list off the bottom, and a "top" list
    /// longer than that stops being a summary.
    static let defaultRankedLimit = 5

    /// - Parameters:
    ///   - snapshots: the full history, most recent first.
    ///   - topAuthorLimit: how many ranked authors to keep.
    ///   - topTagLimit: how many ranked tags to keep.
    static func compute(
        from snapshots: [QuoteSnapshot],
        topAuthorLimit: Int = QuoteHistoryStats.defaultRankedLimit,
        topTagLimit: Int = QuoteHistoryStats.defaultRankedLimit
    ) -> QuoteHistoryStatsResult {
        guard !snapshots.isEmpty else { return .empty }

        var favoriteCount = 0
        var countBySource: [QuoteSource: Int] = [:]
        // Authors are grouped case-insensitively, so the key is lowercased and
        // the value carries the spelling to display alongside the tally.
        var authorTallies: [String: (name: String, count: Int)] = [:]
        // Tags are grouped by identity rather than by name: two tags can be
        // named the same and still be two tags, and renaming one must not
        // silently merge its history into another's.
        var tagTallies: [UUID: (name: String, count: Int)] = [:]

        for snapshot in snapshots {
            if snapshot.isFavorite { favoriteCount += 1 }

            countBySource[snapshot.source, default: 0] += 1

            let author = QuoteTextFormatter.authorDisplay(snapshot.author)
            if author != QuoteTextFormatter.unknownAuthorDisplay {
                let key = author.lowercased()
                // `snapshots` is most recent first, so the first spelling seen
                // for a key is the most recent one, which is the one to show.
                let existing = authorTallies[key]
                authorTallies[key] = (existing?.name ?? author, (existing?.count ?? 0) + 1)
            }

            for tag in snapshot.tags {
                let existing = tagTallies[tag.id]
                tagTallies[tag.id] = (existing?.name ?? tag.name, (existing?.count ?? 0) + 1)
            }
        }

        let total = Double(snapshots.count)
        let sourceCounts = QuoteSource.allCases.compactMap { source -> QuoteSourceCount? in
            guard let count = countBySource[source], count > 0 else { return nil }
            return QuoteSourceCount(source: source, count: count, share: Double(count) / total)
        }

        // Dictionary iteration order is not guaranteed, so the sort has to be a
        // total order rather than "by count" alone — otherwise two authors with
        // the same tally could swap places between two runs over identical
        // input, and the list would appear to reshuffle itself for no reason.
        let topAuthors = authorTallies.values
            .map { QuoteAuthorCount(name: $0.name, count: $0.count) }
            .sorted { ranks($0.count, $0.name.lowercased(), before: $1.count, $1.name.lowercased()) }
            .prefix(max(0, topAuthorLimit))

        let topTags = tagTallies
            .map { QuoteTagCount(id: $0.key, name: $0.value.name, count: $0.value.count) }
            .sorted {
                // Two distinct tags really can share a name, so the id breaks
                // the last tie.
                if $0.count != $1.count || $0.name.lowercased() != $1.name.lowercased() {
                    return ranks($0.count, $0.name.lowercased(), before: $1.count, $1.name.lowercased())
                }
                return $0.id.uuidString < $1.id.uuidString
            }
            .prefix(max(0, topTagLimit))

        return QuoteHistoryStatsResult(
            totalSeen: snapshots.count,
            favoriteCount: favoriteCount,
            uniqueAuthorCount: authorTallies.count,
            sourceCounts: sourceCounts,
            topAuthors: Array(topAuthors),
            topTags: Array(topTags)
        )
    }

    /// Ranking shared by every "top" list: most sightings first, then by label
    /// so equal tallies land in a stable, repeatable order.
    private static func ranks(
        _ lhsCount: Int,
        _ lhsLabel: String,
        before rhsCount: Int,
        _ rhsLabel: String
    ) -> Bool {
        lhsCount == rhsCount ? lhsLabel < rhsLabel : lhsCount > rhsCount
    }
}
