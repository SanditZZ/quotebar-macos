//
//  CustomQuoteDeduplicator.swift
//  QuoteBar — Calculations
//
//  Deciding whether a candidate quote already exists. Pure: works only on
//  strings, so it can check a candidate against the user's custom library and
//  the bundled set with the same logic, no matter where either list came
//  from.
//

import Foundation

enum CustomQuoteDeduplicator {

    /// Case- and whitespace-insensitive match against `existingTexts`. Blank
    /// text is never considered a duplicate — callers must reject blank text
    /// on its own terms, not by relying on this.
    static func isDuplicate(_ text: String, against existingTexts: [String]) -> Bool {
        let needle = normalized(text)
        guard !needle.isEmpty else { return false }
        return existingTexts.contains { normalized($0) == needle }
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
