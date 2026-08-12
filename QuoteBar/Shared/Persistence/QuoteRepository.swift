//
//  QuoteRepository.swift
//  QuoteBar — Persistence boundary
//
//  The rest of the app talks to this protocol and never to SwiftData directly.
//  That keeps views and services free of `ModelContext`, keeps the store
//  swappable, and lets tests run against an in-memory double.
//

import Foundation

/// Errors surfaced by a repository. Callers are expected to degrade gracefully
/// rather than crash.
enum QuoteRepositoryError: LocalizedError {
    case fetchFailed(underlying: any Error)
    case saveFailed(underlying: any Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let underlying):
            return "Could not read quote history: \(underlying.localizedDescription)"
        case .saveFailed(let underlying):
            return "Could not save quote history: \(underlying.localizedDescription)"
        case .notFound:
            return "That quote could not be found in history."
        }
    }
}

/// Reads and writes seen-quote history.
///
/// Main-actor bound because the backing `ModelContext` is the container's main
/// context, and every caller is already UI-driven.
@MainActor
protocol QuoteRepository: AnyObject {

    /// Record a quote as seen and return its persisted snapshot.
    @discardableResult
    func record(_ quote: Quote, seenAt: Date) throws -> QuoteSnapshot

    /// Every recorded sighting, most recent first.
    func allQuotes() throws -> [QuoteSnapshot]

    /// The text of the `limit` most recently seen quotes, most recent first.
    /// Used to avoid immediately repeating a quote — see `RecentQuoteFilter`.
    func recentTexts(limit: Int) throws -> [String]

    /// Flip the favorite flag on a sighting.
    func toggleFavorite(id: UUID) throws

    /// Add `tagID` to a sighting's tags if it isn't already there, otherwise
    /// remove it. Both `quoteID` and `tagID` unknown throw `.notFound` —
    /// unreachable from normal UI, so not worth distinguishing further.
    func toggleTag(_ tagID: UUID, onQuote quoteID: UUID) throws

    /// Delete all history. Irreversible.
    func deleteAll() throws

    /// Write any pending changes to disk immediately.
    func flush() throws
}

extension QuoteRepository {
    /// Convenience: record a quote as seen right now.
    ///
    /// A default argument on the protocol requirement itself would not be
    /// visible through an `any QuoteRepository` existential — Swift resolves
    /// default parameter values statically, not dynamically — so this is a
    /// real overload instead, the same fix idle-tapper-macos's `TapRepository`
    /// uses for `recordTap(at:)`.
    @discardableResult
    func record(_ quote: Quote) throws -> QuoteSnapshot {
        try record(quote, seenAt: Date())
    }
}
