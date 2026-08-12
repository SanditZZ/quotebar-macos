//
//  CustomQuoteImportParsingTests.swift
//  QuoteBarTests
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Custom quote import parsing")
struct CustomQuoteImportParsingTests {

    // MARK: - Format detection

    @Test("Recognizes json and csv extensions, case-insensitively")
    func recognizesExtensions() {
        #expect(CustomQuoteImportFormat(fileExtension: "json") == .json)
        #expect(CustomQuoteImportFormat(fileExtension: "JSON") == .json)
        #expect(CustomQuoteImportFormat(fileExtension: "csv") == .csv)
        #expect(CustomQuoteImportFormat(fileExtension: "txt") == nil)
    }

    // MARK: - JSON

    @Test("Parses a well-formed JSON array")
    func parsesJSON() {
        let json = """
        [
            {"text": "First quote", "author": "Author A"},
            {"text": "Second quote", "author": null}
        ]
        """
        let result = CustomQuoteImportParsing.parse(data: Data(json.utf8), format: .json)

        #expect(result.quotes == [
            ParsedCustomQuote(text: "First quote", author: "Author A"),
            ParsedCustomQuote(text: "Second quote", author: nil),
        ])
        #expect(result.skippedInvalidRows == 0)
    }

    @Test("Skips JSON entries with blank text")
    func skipsBlankJSONText() {
        let json = """
        [
            {"text": "Good", "author": "A"},
            {"text": "   ", "author": "B"}
        ]
        """
        let result = CustomQuoteImportParsing.parse(data: Data(json.utf8), format: .json)

        #expect(result.quotes == [ParsedCustomQuote(text: "Good", author: "A")])
        #expect(result.skippedInvalidRows == 1)
    }

    @Test("Malformed JSON produces an empty result rather than crashing")
    func malformedJSONIsEmpty() {
        let result = CustomQuoteImportParsing.parse(data: Data("not json".utf8), format: .json)
        #expect(result == .empty)
    }

    // MARK: - CSV

    @Test("Parses plain CSV rows")
    func parsesPlainCSV() {
        let csv = "First quote,Author A\nSecond quote,Author B"
        let result = CustomQuoteImportParsing.parse(data: Data(csv.utf8), format: .csv)

        #expect(result.quotes == [
            ParsedCustomQuote(text: "First quote", author: "Author A"),
            ParsedCustomQuote(text: "Second quote", author: "Author B"),
        ])
        #expect(result.skippedInvalidRows == 0)
    }

    @Test("A text-only column is accepted with no author")
    func parsesTextOnlyCSV() {
        let csv = "Just text"
        let result = CustomQuoteImportParsing.parse(data: Data(csv.utf8), format: .csv)

        #expect(result.quotes == [ParsedCustomQuote(text: "Just text", author: nil)])
    }

    @Test("A header row whose first column is exactly 'text' is dropped")
    func dropsHeaderRow() {
        let csv = "text,author\nHello,World"
        let result = CustomQuoteImportParsing.parse(data: Data(csv.utf8), format: .csv)

        #expect(result.quotes == [ParsedCustomQuote(text: "Hello", author: "World")])
    }

    @Test("A real quote that happens to start with the word 'Text' is not mistaken for a header")
    func doesNotMistakeQuoteStartingWithTextForHeader() {
        let csv = "Text is powerful,Some Author"
        let result = CustomQuoteImportParsing.parse(data: Data(csv.utf8), format: .csv)

        #expect(result.quotes == [ParsedCustomQuote(text: "Text is powerful", author: "Some Author")])
    }

    @Test("Quoted fields with embedded commas are kept as one field")
    func handlesQuotedCommas() {
        let csv = "\"Quote, with a comma\",Author A"
        let result = CustomQuoteImportParsing.parse(data: Data(csv.utf8), format: .csv)

        #expect(result.quotes == [ParsedCustomQuote(text: "Quote, with a comma", author: "Author A")])
    }

    @Test("Doubled quotes inside a quoted field become one literal quote")
    func handlesEscapedQuotes() {
        let csv = "\"She said \"\"hi\"\"\",Author A"
        let result = CustomQuoteImportParsing.parse(data: Data(csv.utf8), format: .csv)

        #expect(result.quotes == [ParsedCustomQuote(text: "She said \"hi\"", author: "Author A")])
    }

    @Test("Blank lines are skipped rather than producing an empty-text row")
    func skipsBlankLines() {
        let csv = "First,A\n\n\nSecond,B"
        let result = CustomQuoteImportParsing.parse(data: Data(csv.utf8), format: .csv)

        #expect(result.quotes.map(\.text) == ["First", "Second"])
        #expect(result.skippedInvalidRows == 0)
    }

    @Test("A row with only an empty text column is skipped and counted")
    func skipsEmptyTextColumn() {
        let csv = ",Author A\nSecond,Author B"
        let result = CustomQuoteImportParsing.parse(data: Data(csv.utf8), format: .csv)

        #expect(result.quotes == [ParsedCustomQuote(text: "Second", author: "Author B")])
        #expect(result.skippedInvalidRows == 1)
    }
}
