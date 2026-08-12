//
//  QuoteRecord.swift
//  QuoteBar — SwiftData model
//
//  One row per quote the user has seen. `seenAt` is not unique — the same
//  quote text can legitimately reappear (especially from the bundled set), and
//  each viewing is its own row so history reflects what was actually shown.
//

import Foundation
import SwiftData

@Model
final class QuoteRecord {

    /// Stable identity for this sighting, independent of the quote's content.
    @Attribute(.unique) var id: UUID

    /// The quote text as shown to the user.
    var text: String

    /// The attributed author, or `nil`.
    var author: String?

    /// Raw value of the `QuoteSource` that produced this quote.
    var sourceRaw: String

    /// When this quote was fetched and shown.
    var seenAt: Date

    /// Whether the user marked this sighting as a favorite.
    var isFavorite: Bool

    /// User-assigned tags. `.nullify`: deleting a tag detaches it from here
    /// without deleting this sighting; see `QuoteTag.quotes` for the other
    /// side of this relationship (this app's first `@Relationship` — see
    /// that file's build-verification note).
    @Relationship(deleteRule: .nullify)
    var tags: [QuoteTag] = []

    init(
        id: UUID = UUID(),
        text: String,
        author: String?,
        source: QuoteSource,
        seenAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.text = text
        self.author = author
        self.sourceRaw = source.rawValue
        self.seenAt = seenAt
        self.isFavorite = isFavorite
    }
}

extension QuoteRecord {
    /// Value-type projection used by the calculation layer.
    ///
    /// Calculations never touch `@Model` instances: those are bound to a
    /// `ModelContext` and to the main actor, which would make the pure logic
    /// untestable in isolation.
    var snapshot: QuoteSnapshot {
        QuoteSnapshot(
            id: id,
            text: text,
            author: author,
            source: QuoteSource(rawValue: sourceRaw) ?? .bundled,
            seenAt: seenAt,
            isFavorite: isFavorite,
            tags: tags.map(\.snapshot).sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        )
    }
}
