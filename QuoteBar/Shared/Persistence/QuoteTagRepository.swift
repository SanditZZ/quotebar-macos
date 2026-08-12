//
//  QuoteTagRepository.swift
//  QuoteBar — Persistence boundary
//
//  Owns the user's tag vocabulary — a separate concern from `QuoteRepository`,
//  same rationale as `CustomQuoteRepository`: curating a library of
//  user-defined things is different from acting on a specific `QuoteRecord`
//  sighting. Assigning/unassigning a tag to a quote is a `QuoteRecord`
//  mutation instead, so it lives on `QuoteRepository.toggleTag(_:onQuote:)`.
//

import Foundation

enum QuoteTagRepositoryError: LocalizedError {
    case emptyName
    case duplicate
    case notFound
    case saveFailed(underlying: any Error)
    case fetchFailed(underlying: any Error)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "A tag needs a name."
        case .duplicate:
            return "You already have a tag with that name."
        case .notFound:
            return "That tag could not be found."
        case .saveFailed(let underlying):
            return "Could not save your tags: \(underlying.localizedDescription)"
        case .fetchFailed(let underlying):
            return "Could not read your tags: \(underlying.localizedDescription)"
        }
    }
}

@MainActor
protocol QuoteTagRepository: AnyObject {

    /// Add one tag, rejecting a blank or already-existing (case-insensitive)
    /// name.
    @discardableResult
    func add(name: String) throws -> TagSnapshot

    /// Every tag, alphabetical by name.
    func allTags() throws -> [TagSnapshot]

    /// Rejects a blank name or a name colliding (case-insensitively) with a
    /// different existing tag. Already-tagged quotes see the new name on
    /// their next read, since the relationship stores the tag itself, not a
    /// copy of its name.
    func rename(id: UUID, to newName: String) throws

    /// Deletes the tag. Quotes tagged with it keep their other tags — see
    /// `QuoteTag`'s `.nullify` delete rule.
    func remove(id: UUID) throws
}
