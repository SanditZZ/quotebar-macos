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

    init(id: UUID, text: String, author: String?, addedAt: Date) {
        self.id = id
        self.text = text
        self.author = author
        self.addedAt = addedAt
    }
}
