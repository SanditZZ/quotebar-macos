//
//  PackIdFormatterTests.swift
//  QuoteBarTests
//
//  Pure — no SwiftData.
//

import Testing
@testable import QuoteBar

@Suite("Pack id formatter")
struct PackIdFormatterTests {

    @Test("Hyphenated words become Title Case")
    func hyphenatedWordsBecomeTitleCase() {
        #expect(PackIdFormatter.displayName(for: "stoicism-basics") == "Stoicism Basics")
    }

    @Test("Underscore-separated words become Title Case")
    func underscoreSeparatedWordsBecomeTitleCase() {
        #expect(PackIdFormatter.displayName(for: "film_lines") == "Film Lines")
    }

    @Test("A single word is capitalized")
    func singleWordIsCapitalized() {
        #expect(PackIdFormatter.displayName(for: "poetry") == "Poetry")
    }

    @Test("Mixed casing in the source id is normalized")
    func mixedCasingIsNormalized() {
        #expect(PackIdFormatter.displayName(for: "DEVELOPER-humour") == "Developer Humour")
    }

    @Test("An empty id round-trips to an empty string, not a crash")
    func emptyIdRoundTrips() {
        #expect(PackIdFormatter.displayName(for: "") == "")
    }

    @Test("A run of separators with no letters falls back to the raw id")
    func onlySeparatorsFallsBackToRawId() {
        #expect(PackIdFormatter.displayName(for: "---") == "---")
    }
}
