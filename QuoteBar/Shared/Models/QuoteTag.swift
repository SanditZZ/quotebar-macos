//
//  QuoteTag.swift
//  QuoteBar — SwiftData model
//
//  A user-created label a quote sighting (`QuoteRecord`) can be tagged with.
//  Many-to-many: a tag can apply to many quotes, and a quote can carry many
//  tags — this app's first `@Relationship`, so the shape below mirrors
//  Apple's documented many-to-many pattern (declare `inverse:` on exactly one
//  side; see `QuoteRecord.tags` for the other side).
//
//  IMPORTANT — verify against Xcode 26 before relying on this: written on a
//  Linux machine with no SwiftData headers to compile against, so the
//  relationship/delete-rule syntax below reflects Apple's documented pattern,
//  not a verified build. Confirm the first time this builds on a Mac, via
//  `./scripts/ci-local.sh`.
//

import Foundation
import SwiftData

@Model
final class QuoteTag {

    /// Stable identity for this tag, independent of its name.
    @Attribute(.unique) var id: UUID

    /// The tag's display name. Uniqueness (case-insensitive) is enforced by
    /// `SwiftDataQuoteTagRepository`, not a SwiftData constraint — same
    /// approach `CustomQuoteEntry.text` already uses for its own dedup.
    var name: String

    /// When this tag was created.
    var createdAt: Date

    /// Every quote sighting carrying this tag. `.nullify`: deleting a tag
    /// detaches it from these quotes without deleting them.
    @Relationship(deleteRule: .nullify, inverse: \QuoteRecord.tags)
    var quotes: [QuoteRecord] = []

    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

extension QuoteTag {
    /// Value-type projection used outside the persistence layer.
    var snapshot: TagSnapshot {
        TagSnapshot(id: id, name: name, createdAt: createdAt)
    }
}
