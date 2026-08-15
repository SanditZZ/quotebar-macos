//
//  QuotePackSerializer.swift
//  QuoteBar — Calculations
//
//  Encoding/decoding a `QuotePack` to/from JSON. Pure: no file I/O here —
//  a future `QuotePackService` reads/writes the bytes and hands this the
//  `Data`, mirroring `QuoteBackupSerializer`.
//

import Foundation

enum QuotePackSerializationError: Error, Equatable {
    case unsupportedFormatVersion(Int)
}

enum QuotePackSerializer {

    static func encode(_ pack: QuotePack) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(pack)
    }

    static func decode(_ data: Data) throws -> QuotePack {
        let decoder = JSONDecoder()
        let pack = try decoder.decode(QuotePack.self, from: data)

        guard pack.formatVersion <= QuotePack.currentFormatVersion else {
            throw QuotePackSerializationError.unsupportedFormatVersion(pack.formatVersion)
        }

        return pack
    }
}
