//
//  CustomQuoteRepository.swift
//  QuoteBar — Persistence boundary
//
//  Owns the user's custom/imported quote library — a separate concern from
//  `QuoteRepository`, which logs sightings rather than curating a source
//  library. Same rationale as `QuoteRepository`: the rest of the app talks to
//  this protocol, never to SwiftData directly.
//

import Foundation

enum CustomQuoteRepositoryError: LocalizedError {
    case emptyText
    case duplicate
    case notFound
    case saveFailed(underlying: any Error)
    case fetchFailed(underlying: any Error)

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "A quote needs some text."
        case .duplicate:
            return "That quote is already in your library."
        case .notFound:
            return "That quote could not be found."
        case .saveFailed(let underlying):
            return "Could not save your quote library: \(underlying.localizedDescription)"
        case .fetchFailed(let underlying):
            return "Could not read your quote library: \(underlying.localizedDescription)"
        }
    }
}

/// The outcome of importing a batch of parsed quotes.
struct CustomQuoteImportResult: Equatable, Sendable {
    let added: Int
    let skippedDuplicates: Int
}

@MainActor
protocol CustomQuoteRepository: AnyObject {

    /// Add one quote, rejecting blank text and anything already present in
    /// the library or the bundled set.
    @discardableResult
    func add(text: String, author: String?) throws -> CustomQuoteSnapshot

    /// Add every parsed quote that isn't a duplicate, skipping (not
    /// throwing on) the rest.
    func importMany(_ parsed: [ParsedCustomQuote]) throws -> CustomQuoteImportResult

    /// Every library entry, most recently added first.
    func allEntries() throws -> [CustomQuoteSnapshot]

    /// Remove one entry. Does not touch past `QuoteRecord` sightings that
    /// came from it — history is a log of what was shown, not a live view
    /// of the library.
    func remove(id: UUID) throws

    /// Remove every entry whose id is in `ids`, in one save. Unknown ids are
    /// silently ignored, mirroring `QuoteRepository.deleteAll()`'s "don't
    /// fail the whole batch" stance — the UI only ever passes ids it just
    /// read from `allEntries()`.
    @discardableResult
    func removeMany(ids: Set<UUID>) throws -> Int
}
