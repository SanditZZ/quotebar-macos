//
//  QuoteTextFormatterTests.swift
//  QuoteBarTests
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Quote text formatter")
struct QuoteTextFormatterTests {

    @Test("Trims whitespace")
    func trimsWhitespace() {
        #expect(QuoteTextFormatter.normalize("  Hello  \n") == "Hello")
    }

    @Test("Strips wrapping curly quotes")
    func stripsCurlyQuotes() {
        #expect(QuoteTextFormatter.normalize("\u{201C}Hello\u{201D}") == "Hello")
    }

    @Test("Strips wrapping straight quotes")
    func stripsStraightQuotes() {
        #expect(QuoteTextFormatter.normalize("\"Hello\"") == "Hello")
    }

    @Test("Leaves an internal quotation mark alone")
    func leavesInternalQuoteAlone() {
        #expect(QuoteTextFormatter.normalize("She said \"hi\" to me") == "She said \"hi\" to me")
    }

    @Test("nil author displays as Unknown")
    func nilAuthorIsUnknown() {
        #expect(QuoteTextFormatter.authorDisplay(nil) == "Unknown")
    }

    @Test("Empty or placeholder author displays as Unknown", arguments: ["", "   ", "unknown", "Anonymous"])
    func placeholderAuthorIsUnknown(input: String) {
        #expect(QuoteTextFormatter.authorDisplay(input) == "Unknown")
    }

    @Test("A real author passes through, trimmed")
    func realAuthorPassesThrough() {
        #expect(QuoteTextFormatter.authorDisplay("  Marcus Aurelius  ") == "Marcus Aurelius")
    }

    @Test("Attribution is prefixed with an em dash")
    func attributionIsPrefixed() {
        #expect(QuoteTextFormatter.attribution(author: "Seneca") == "— Seneca")
        #expect(QuoteTextFormatter.attribution(author: nil) == "— Unknown")
    }
}
