//
//  TagSnapshot.swift
//  QuoteBar — Value types
//
//  Plain, `Sendable` value type that crosses the boundary between persistence
//  and the pure calculation/view layers — the only way tag data is passed
//  around outside `Shared/Persistence/`, mirroring `CustomQuoteSnapshot`.
//

import Foundation

struct TagSnapshot: Equatable, Hashable, Sendable, Codable, Identifiable {
    let id: UUID
    let name: String
    let createdAt: Date

    init(id: UUID, name: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
