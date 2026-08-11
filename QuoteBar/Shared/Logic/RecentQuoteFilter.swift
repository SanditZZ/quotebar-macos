//
//  RecentQuoteFilter.swift
//  QuoteBar — Calculations
//
//  Picking a quote that avoids repeating what the user just saw. Pure: no
//  randomness source is baked in — callers supply one — so results are
//  reproducible in tests.
//

import Foundation

enum RecentQuoteFilter {

    /// Candidates with text matching (case-insensitively) anything in
    /// `recentTexts` removed. If that would remove everything, the original
    /// list is returned unfiltered — a repeat is better than nothing.
    static func excludingRecent(_ candidates: [Quote], recentTexts: [String]) -> [Quote] {
        guard !recentTexts.isEmpty, !candidates.isEmpty else { return candidates }

        let recent = Set(recentTexts.map { $0.lowercased() })
        let filtered = candidates.filter { !recent.contains($0.text.lowercased()) }

        return filtered.isEmpty ? candidates : filtered
    }

    /// Pick one candidate, avoiding recent repeats, using `randomIndex` to
    /// choose among what remains.
    ///
    /// - Parameter randomIndex: Given a range, returns an index inside it.
    ///   Injected so tests can supply a deterministic choice instead of
    ///   `Int.random(in:)`.
    static func pick(
        from candidates: [Quote],
        recentTexts: [String],
        randomIndex: (Range<Int>) -> Int
    ) -> Quote? {
        let pool = excludingRecent(candidates, recentTexts: recentTexts)
        guard !pool.isEmpty else { return nil }
        let index = randomIndex(0..<pool.count)
        return pool[index]
    }
}
