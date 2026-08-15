//
//  QuotePack.swift
//  QuoteBar — Value types
//
//  The installable-pack file format (issue #31). Deliberately separate from
//  `QuoteBackup`: a backup is a full snapshot of one user's store for
//  round-tripping, while a pack is redistributed third-party content another
//  user installs. Reuses `QuoteBackup`'s conventions (an integer
//  `formatVersion`, ISO-8601 dates) so the two dialects stay easy to reason
//  about together.
//

import Foundation

struct QuotePack: Equatable, Sendable, Codable {

    /// Bumped whenever a field is added, removed, or reinterpreted. A pack
    /// file can be authored once and installed by an app version released
    /// long afterward, so decoding rejects a `formatVersion` newer than this
    /// build understands rather than silently mis-reading fields a future
    /// format repurposed.
    let formatVersion: Int

    /// Stable identifier for this pack, e.g. `"stoicism-basics"`. Persisted
    /// on every `CustomQuoteEntry` this pack installs, so uninstall can find
    /// exactly the rows it owns. Never reused for a different pack's
    /// content — a maintainer who wants to replace a pack's quotes ships a
    /// new `formatVersion` of the same `packId`, not a new id.
    let packId: String

    let name: String
    let maintainer: String

    /// License the quotes are distributed under, e.g. `"CC0"` or
    /// `"Public Domain"`. Required — see `CONTRIBUTING.md` on why a pack
    /// cannot ship without a stated license.
    let license: String

    /// Free-text attribution shown alongside the pack in Settings, distinct
    /// from any individual quote's author.
    let attribution: String?

    let quotes: [QuotePackQuote]

    static let currentFormatVersion = 1
}

/// One quote inside a `QuotePack`. Deliberately a narrower shape than
/// `CustomQuoteSnapshot` — a pack file carries no `id` or `addedAt`; those
/// are assigned at install time, the same way `ParsedCustomQuote` works for
/// file imports.
struct QuotePackQuote: Equatable, Sendable, Codable {
    let text: String
    let author: String?
}
