//
//  CustomQuoteCSVFormatter.swift
//  QuoteBar — Calculations
//
//  The mirror image of `CustomQuoteImportParsing`'s CSV parser: turns the
//  custom quote library back into the exact `text,author` shape that parser
//  already reads, so a round-tripped export re-imports identically.
//

import Foundation

enum CustomQuoteCSVFormatter {

    static func format(_ entries: [CustomQuoteSnapshot]) -> Data {
        var lines = ["text,author"]
        for entry in entries {
            lines.append("\(csvField(entry.text)),\(csvField(entry.author ?? ""))")
        }
        return lines.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    /// Wraps a field in `"..."`, doubling any embedded `"`, whenever it
    /// contains a comma, quote, or newline — the same quoting rule
    /// `CustomQuoteImportParsing.parseCSVLine` already un-does on the way in.
    private static func csvField(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
