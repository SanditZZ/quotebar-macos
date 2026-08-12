//
//  QuoteBackupSerializerTests.swift
//  QuoteBarTests
//
//  Pure — no SwiftData.
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Quote backup serializer")
struct QuoteBackupSerializerTests {

    @Test("Encoding then decoding reproduces the original backup exactly")
    func roundTripsExactly() throws {
        let backup = QuoteBackup(
            formatVersion: QuoteBackup.currentFormatVersion,
            exportedAt: TestSupport.referenceDate,
            history: [TestSupport.snapshot(text: "A", tags: [TestSupport.tag(name: "Wisdom")])],
            customQuotes: [TestSupport.customQuoteSnapshot(text: "B")]
        )

        let data = try QuoteBackupSerializer.encode(backup)
        let decoded = try QuoteBackupSerializer.decode(data)

        #expect(decoded == backup)
    }

    @Test("Decoding an empty backup round-trips to empty arrays, not a decode failure")
    func roundTripsEmptyBackup() throws {
        let backup = QuoteBackup(
            formatVersion: 1,
            exportedAt: TestSupport.referenceDate,
            history: [],
            customQuotes: []
        )

        #expect(try QuoteBackupSerializer.decode(QuoteBackupSerializer.encode(backup)) == backup)
    }

    @Test("Decoding a backup from a newer, unsupported format version throws")
    func rejectsNewerFormatVersion() throws {
        let backup = QuoteBackup(
            formatVersion: QuoteBackup.currentFormatVersion + 1,
            exportedAt: TestSupport.referenceDate,
            history: [],
            customQuotes: []
        )
        let data = try QuoteBackupSerializer.encode(backup)

        #expect(throws: QuoteBackupSerializationError.self) {
            try QuoteBackupSerializer.decode(data)
        }
    }

    @Test("Decoding malformed data throws rather than crashing")
    func rejectsMalformedData() {
        #expect(throws: (any Error).self) {
            try QuoteBackupSerializer.decode(Data("not json".utf8))
        }
    }
}
