//
//  CustomQuoteEntry.swift
//  QuoteBar — SwiftData model
//
//  One row per quote the user has added or imported. Distinct from
//  `QuoteRecord`: this is the library of quotes that *can* be served, not a
//  log of sightings — a single entry here can be picked and recorded as a
//  `QuoteRecord` many times over.
//

import Foundation
import SwiftData

@Model
final class CustomQuoteEntry {

    /// Stable identity for this library entry.
    @Attribute(.unique) var id: UUID

    /// The quote text, trimmed of surrounding whitespace.
    var text: String

    /// The attributed author, or `nil`.
    var author: String?

    /// When this entry was added or imported.
    var addedAt: Date

    /// The installed pack this entry came from, or `nil` for anything the
    /// user typed or imported themselves. Existing rows decode this as `nil`
    /// under SwiftData's automatic lightweight migration, since it's a new
    /// optional property — every entry that predates packs is correctly
    /// user-owned. Uninstalling a pack removes exactly the rows whose
    /// `packId` matches; a row a user typed by hand, or a pack quote that
    /// was skipped as a duplicate against something already in the library,
    /// is never touched (see `CustomQuoteDeduplicator`).
    var packId: String?

    init(
        id: UUID = UUID(),
        text: String,
        author: String?,
        addedAt: Date = Date(),
        packId: String? = nil
    ) {
        self.id = id
        self.text = text
        self.author = author
        self.addedAt = addedAt
        self.packId = packId
    }
}

extension CustomQuoteEntry {
    /// Value-type projection used outside the persistence layer.
    var snapshot: CustomQuoteSnapshot {
        CustomQuoteSnapshot(id: id, text: text, author: author, addedAt: addedAt, packId: packId)
    }
}
