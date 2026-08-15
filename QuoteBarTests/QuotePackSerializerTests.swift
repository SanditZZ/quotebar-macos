//
//  QuotePackSerializerTests.swift
//  QuoteBarTests
//
//  Pure — no SwiftData.
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Quote pack serializer")
struct QuotePackSerializerTests {

    private func makePack(quotes: [QuotePackQuote] = [QuotePackQuote(text: "A", author: "Author A")]) -> QuotePack {
        QuotePack(
            formatVersion: QuotePack.currentFormatVersion,
            packId: "stoicism-basics",
            name: "Stoicism Basics",
            maintainer: "QuoteBar",
            license: "Public Domain",
            attribution: "Compiled from public-domain translations",
            quotes: quotes
        )
    }

    @Test("Encoding then decoding reproduces the original pack exactly")
    func roundTripsExactly() throws {
        let pack = makePack()

        let data = try QuotePackSerializer.encode(pack)
        let decoded = try QuotePackSerializer.decode(data)

        #expect(decoded == pack)
    }

    @Test("A pack with no quotes round-trips to an empty array, not a decode failure")
    func roundTripsEmptyQuotes() throws {
        let pack = makePack(quotes: [])
        #expect(try QuotePackSerializer.decode(QuotePackSerializer.encode(pack)) == pack)
    }

    @Test("nil attribution round-trips as nil")
    func roundTripsNilAttribution() throws {
        let pack = QuotePack(
            formatVersion: QuotePack.currentFormatVersion,
            packId: "no-attribution",
            name: "No Attribution",
            maintainer: "QuoteBar",
            license: "CC0",
            attribution: nil,
            quotes: [QuotePackQuote(text: "A", author: nil)]
        )
        #expect(try QuotePackSerializer.decode(QuotePackSerializer.encode(pack)) == pack)
    }

    @Test("Decoding a pack from a newer, unsupported format version throws")
    func rejectsNewerFormatVersion() throws {
        let pack = QuotePack(
            formatVersion: QuotePack.currentFormatVersion + 1,
            packId: "future-pack",
            name: "Future Pack",
            maintainer: "QuoteBar",
            license: "CC0",
            attribution: nil,
            quotes: []
        )
        let data = try QuotePackSerializer.encode(pack)

        #expect(throws: QuotePackSerializationError.self) {
            try QuotePackSerializer.decode(data)
        }
    }

    @Test("Decoding malformed data throws rather than crashing")
    func rejectsMalformedData() {
        #expect(throws: (any Error).self) {
            try QuotePackSerializer.decode(Data("not json".utf8))
        }
    }

    @Test("The pack format documented in CONTRIBUTING.md and shipped as docs/example-packs/stoicism-basics.json decodes correctly")
    func decodesTheDocumentedExampleFormat() throws {
        let json = """
        {
          "formatVersion": 1,
          "packId": "stoicism-basics",
          "name": "Stoicism Basics",
          "maintainer": "QuoteBar",
          "license": "Public Domain",
          "attribution": "Public-domain English translations of the Stoic philosophers.",
          "quotes": [
            { "text": "You have power over your mind, not outside events.", "author": "Marcus Aurelius" },
            { "text": "No man is free who is not master of himself.", "author": "Epictetus" }
          ]
        }
        """

        let pack = try QuotePackSerializer.decode(Data(json.utf8))

        #expect(pack.packId == "stoicism-basics")
        #expect(pack.license == "Public Domain")
        #expect(pack.quotes.count == 2)
        #expect(pack.quotes.first?.author == "Marcus Aurelius")
    }
}
