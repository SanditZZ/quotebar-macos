//
//  QuoteTagFilter.swift
//  QuoteBar — Calculations
//
//  Filters seen history by user-assigned tags for `HistoryView`'s tag filter.
//  Pure: OR semantics — a quote matches if it carries any of the selected
//  tags, not all of them.
//

import Foundation

enum QuoteTagFilter {

    /// An empty `selectedTagIDs` means "no filter": every quote passes
    /// through unchanged, including quotes with no tags at all.
    static func matching(_ quotes: [QuoteSnapshot], selectedTagIDs: Set<UUID>) -> [QuoteSnapshot] {
        guard !selectedTagIDs.isEmpty else { return quotes }

        return quotes.filter { quote in
            quote.tags.contains { selectedTagIDs.contains($0.id) }
        }
    }
}
