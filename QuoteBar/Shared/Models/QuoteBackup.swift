//
//  QuoteBackup.swift
//  QuoteBar — Value types
//
//  A full, self-describing snapshot of everything QuoteBar stores, for
//  export/import. This is the JSON backup shape — CSV export/import only
//  ever covers the custom quote library subset (see
//  `CustomQuoteImportParsing`), since `CustomQuoteSnapshot` has no tags and
//  CSV has no natural place to carry them.
//

import Foundation

struct QuoteBackup: Equatable, Sendable, Codable {

    /// Bumped whenever a field is added, removed, or reinterpreted. A backup
    /// file can outlive the app version that wrote it — moved to another
    /// Mac, opened months later after several QuoteBar updates — so decoding
    /// rejects a `formatVersion` newer than this build understands rather
    /// than silently mis-reading fields a future format repurposed.
    let formatVersion: Int
    let exportedAt: Date
    let history: [QuoteSnapshot]
    let customQuotes: [CustomQuoteSnapshot]

    static let currentFormatVersion = 2
}
