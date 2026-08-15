//
//  CustomQuoteSnapshot.swift
//  QuoteBar — Value types
//
//  Plain, `Sendable` value type crossing the boundary between persistence and
//  everything else — same role as `QuoteSnapshot` plays for `QuoteRecord`.
//

import Foundation

/// One entry in the user's custom/imported quote library.
struct CustomQuoteSnapshot: Equatable, Hashable, Sendable, Codable, Identifiable {
    let id: UUID
    let text: String
    let author: String?
    let addedAt: Date

    /// The installed pack this entry came from, or `nil` for a user-added
    /// entry. Optional so a backup written before packs existed still
    /// decodes — a missing key becomes `nil` — and so an older app version
    /// still decodes a backup written by a newer one, ignoring the extra
    /// key. See `CustomQuoteEntry.packId`.
    let packId: String?

    init(id: UUID, text: String, author: String?, addedAt: Date, packId: String? = nil) {
        self.id = id
        self.text = text
        self.author = author
        self.addedAt = addedAt
        self.packId = packId
    }
}
