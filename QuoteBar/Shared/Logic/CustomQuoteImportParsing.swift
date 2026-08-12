//
//  CustomQuoteImportParsing.swift
//  QuoteBar — Calculations
//
//  Turning an imported file's raw bytes into candidate quotes. Pure: no file
//  I/O here — `CustomQuoteLibrary` reads the file and hands this the bytes.
//  Malformed rows are dropped rather than failing the whole import, since one
//  bad line in a hand-edited CSV shouldn't cost the user every good line in
//  it.
//

import Foundation

/// One row successfully parsed from an import file, not yet checked for
/// duplicates or persisted.
struct ParsedCustomQuote: Equatable, Sendable {
    let text: String
    let author: String?
}

/// The result of parsing an import file.
struct CustomQuoteParseResult: Equatable, Sendable {
    let quotes: [ParsedCustomQuote]

    /// Rows present in the file but dropped — blank text, or (CSV only) a
    /// column count that didn't parse. Surfaced to the user so a bad import
    /// doesn't silently do less than expected.
    let skippedInvalidRows: Int

    static let empty = CustomQuoteParseResult(quotes: [], skippedInvalidRows: 0)
}

enum CustomQuoteImportFormat {
    case json
    case csv

    /// `nil` for an extension this feature doesn't recognize.
    init?(fileExtension: String) {
        switch fileExtension.lowercased() {
        case "json": self = .json
        case "csv": self = .csv
        default: return nil
        }
    }
}

enum CustomQuoteImportParsing {

    static func parse(data: Data, format: CustomQuoteImportFormat) -> CustomQuoteParseResult {
        switch format {
        case .json: return parseJSON(data)
        case .csv: return parseCSV(data)
        }
    }

    // MARK: - JSON

    /// Same shape as `Resources/BackupQuotes.json`: `[{"text": "...", "author": "..."}]`.
    private struct JSONEntry: Decodable {
        let text: String
        let author: String?
    }

    private static func parseJSON(_ data: Data) -> CustomQuoteParseResult {
        guard let entries = try? JSONDecoder().decode([JSONEntry].self, from: data) else {
            return .empty
        }

        var quotes: [ParsedCustomQuote] = []
        var skipped = 0

        for entry in entries {
            if let quote = makeQuote(text: entry.text, author: entry.author) {
                quotes.append(quote)
            } else {
                skipped += 1
            }
        }

        return CustomQuoteParseResult(quotes: quotes, skippedInvalidRows: skipped)
    }

    // MARK: - CSV

    /// Columns are `text,author` with an optional header row (detected by a
    /// first cell of "text", case-insensitive). Quoted fields with embedded
    /// commas or doubled `""` escapes are supported; a field embedding a raw
    /// newline is not — rows are split on newlines first, which keeps the
    /// parser simple for what is expected to be a small, hand-edited or
    /// spreadsheet-exported file.
    private static func parseCSV(_ data: Data) -> CustomQuoteParseResult {
        guard let text = String(data: data, encoding: .utf8) else { return .empty }

        var lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if let first = lines.first, parseCSVLine(first).first?.lowercased() == "text" {
            lines.removeFirst()
        }

        var quotes: [ParsedCustomQuote] = []
        var skipped = 0

        for line in lines {
            let columns = parseCSVLine(line)
            guard let rawText = columns.first else {
                skipped += 1
                continue
            }

            let rawAuthor = columns.count > 1 ? columns[1] : nil
            if let quote = makeQuote(text: rawText, author: rawAuthor) {
                quotes.append(quote)
            } else {
                skipped += 1
            }
        }

        return CustomQuoteParseResult(quotes: quotes, skippedInvalidRows: skipped)
    }

    /// Splits one CSV line into fields, honoring `"..."` quoting and `""` as
    /// an escaped quote inside a quoted field.
    private static func parseCSVLine(_ line: String) -> [String] {
        let characters = Array(line)
        var fields: [String] = []
        var current = ""
        var insideQuotes = false
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character == "\"" {
                let next = index + 1 < characters.count ? characters[index + 1] : nil
                if insideQuotes && next == "\"" {
                    current.append("\"")
                    index += 1
                } else {
                    insideQuotes.toggle()
                }
            } else if character == "," && !insideQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(character)
            }

            index += 1
        }
        fields.append(current)

        return fields.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Shared

    private static func makeQuote(text: String?, author: String?) -> ParsedCustomQuote? {
        let trimmedText = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return nil }

        let trimmedAuthor = author?.trimmingCharacters(in: .whitespacesAndNewlines)
        return ParsedCustomQuote(text: trimmedText, author: (trimmedAuthor?.isEmpty == false) ? trimmedAuthor : nil)
    }
}
