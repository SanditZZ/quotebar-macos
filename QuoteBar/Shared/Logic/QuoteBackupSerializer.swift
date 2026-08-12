//
//  QuoteBackupSerializer.swift
//  QuoteBar — Calculations
//
//  Encoding/decoding a `QuoteBackup` to/from JSON. Pure: no file I/O here —
//  `QuoteBackupService` reads/writes the bytes and hands this the `Data`.
//

import Foundation

enum QuoteBackupSerializationError: Error, Equatable {
    case unsupportedFormatVersion(Int)
}

enum QuoteBackupSerializer {

    static func encode(_ backup: QuoteBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> QuoteBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(QuoteBackup.self, from: data)

        guard backup.formatVersion <= QuoteBackup.currentFormatVersion else {
            throw QuoteBackupSerializationError.unsupportedFormatVersion(backup.formatVersion)
        }

        return backup
    }
}
