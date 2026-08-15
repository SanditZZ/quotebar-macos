//
//  PackIdFormatter.swift
//  QuoteBar — Calculations
//
//  Once installed, only a pack's stable `packId` slug persists (see
//  `InstalledPackSummary`) — its human-readable `QuotePack.name` is never
//  stored. This turns a slug like "stoicism-basics" back into something
//  presentable ("Stoicism Basics") for the installed-packs list, without
//  needing a separate metadata store.
//

import Foundation

enum PackIdFormatter {

    static func displayName(for packId: String) -> String {
        let words = packId
            .split(whereSeparator: { $0 == "-" || $0 == "_" })
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return packId }

        return words
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
