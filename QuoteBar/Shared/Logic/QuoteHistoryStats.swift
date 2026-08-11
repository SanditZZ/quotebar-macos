//
//  QuoteHistoryStats.swift
//  QuoteBar — Calculations
//
//  Aggregate statistics over quote history. Pure function over value types —
//  no SwiftData, no I/O.
//

import Foundation

enum QuoteHistoryStats {

    static func compute(from snapshots: [QuoteSnapshot]) -> QuoteHistoryStatsResult {
        guard !snapshots.isEmpty else { return .empty }

        let favoriteCount = snapshots.filter(\.isFavorite).count

        let uniqueAuthors = Set(
            snapshots.compactMap { snapshot -> String? in
                let display = QuoteTextFormatter.authorDisplay(snapshot.author)
                return display == "Unknown" ? nil : display.lowercased()
            }
        )

        var countBySource: [QuoteSource: Int] = [:]
        for snapshot in snapshots {
            countBySource[snapshot.source, default: 0] += 1
        }

        return QuoteHistoryStatsResult(
            totalSeen: snapshots.count,
            favoriteCount: favoriteCount,
            uniqueAuthorCount: uniqueAuthors.count,
            countBySource: countBySource
        )
    }
}
