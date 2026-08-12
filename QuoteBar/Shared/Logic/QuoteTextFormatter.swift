//
//  QuoteTextFormatter.swift
//  QuoteBar — Calculations
//
//  Pure text formatting for quote display. No I/O, no SwiftData, no network.
//

import Foundation

enum QuoteTextFormatter {

    /// Trims whitespace and stray surrounding quotation marks a provider's raw
    /// text sometimes carries (several public quote APIs wrap the text in
    /// curly quotes).
    static func normalize(_ rawText: String) -> String {
        var text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        let wrappers: [(Character, Character)] = [("\u{201C}", "\u{201D}"), ("\"", "\"")]
        for (open, close) in wrappers {
            if text.first == open, text.last == close, text.count >= 2 {
                text = String(text.dropFirst().dropLast())
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return text
    }

    /// The author line shown under a quote. `nil`/empty/whitespace-only authors
    /// (and the literal placeholders some APIs use) all collapse to "Unknown".
    static func authorDisplay(_ author: String?) -> String {
        guard let author else { return "Unknown" }
        let trimmed = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let placeholders: Set<String> = ["", "unknown", "unknown author", "anonymous"]
        return placeholders.contains(trimmed.lowercased()) ? "Unknown" : trimmed
    }

    /// The full "— Author" attribution string.
    static func attribution(author: String?) -> String {
        "— \(authorDisplay(author))"
    }

    /// Text for AVSpeechSynthesizer to read aloud. Spells out "By <author>"
    /// rather than reusing `attribution`'s em dash, since some voices read
    /// "—" literally as "dash."
    static func spokenText(text: String, author: String?) -> String {
        "\(text). By \(authorDisplay(author))."
    }
}
