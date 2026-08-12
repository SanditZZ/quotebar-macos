//
//  CustomQuoteCSVFormatterTests.swift
//  QuoteBarTests
//
//  Pure — exercises the round-trip against the existing CSV import parser to
//  prove `CustomQuoteCSVFormatter` really is its mirror image.
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Custom quote CSV formatter")
struct CustomQuoteCSVFormatterTests {

    @Test("Formatting then parsing reproduces the same text/author pairs")
    func roundTripsThroughExistingParser() {
        let entries = [
            TestSupport.customQuoteSnapshot(text: "Simple, with a comma", author: "A. Author"),
            TestSupport.customQuoteSnapshot(text: "Has \"quotes\" inside", author: nil),
        ]

        let data = CustomQuoteCSVFormatter.format(entries)
        let parsed = CustomQuoteImportParsing.parse(data: data, format: .csv)

        #expect(parsed.quotes.map(\.text) == entries.map(\.text))
        #expect(parsed.quotes.map(\.author) == entries.map(\.author))
        #expect(parsed.skippedInvalidRows == 0)
    }

    @Test("An empty library formats to just the header row")
    func emptyLibraryFormatsToHeaderOnly() {
        let data = CustomQuoteCSVFormatter.format([])
        #expect(String(data: data, encoding: .utf8) == "text,author")
    }
}
