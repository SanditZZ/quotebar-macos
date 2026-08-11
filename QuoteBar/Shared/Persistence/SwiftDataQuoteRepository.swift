//
//  SwiftDataQuoteRepository.swift
//  QuoteBar — Persistence implementation
//
//  SwiftData-backed `QuoteRepository`. Unlike a tap counter, quotes are
//  written once per fetch rather than on every interaction, so there is no
//  need for the debounced-save/cached-record machinery idle-tapper-macos uses
//  for its much hotter write path — every mutation here saves immediately.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataQuoteRepository: QuoteRepository {

    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
        AppLog.persistence.debug("[Persistence] Repository ready")
    }

    // MARK: - Writes

    @discardableResult
    func record(_ quote: Quote, seenAt: Date = Date()) throws -> QuoteSnapshot {
        let record = QuoteRecord(
            text: quote.text,
            author: quote.author,
            source: quote.source,
            seenAt: seenAt
        )
        context.insert(record)

        do {
            try context.save()
            AppLog.persistence.debug("[Persistence] Recorded a quote from \(quote.source.rawValue, privacy: .public)")
            return record.snapshot
        } catch {
            AppLog.persistence.error(
                "[Persistence] Save failed: \(error.localizedDescription, privacy: .public)"
            )
            throw QuoteRepositoryError.saveFailed(underlying: error)
        }
    }

    func toggleFavorite(id: UUID) throws {
        guard let record = try fetchAllRecords().first(where: { $0.id == id }) else {
            throw QuoteRepositoryError.notFound
        }

        record.isFavorite.toggle()

        do {
            try context.save()
        } catch {
            AppLog.persistence.error(
                "[Persistence] Favorite toggle failed: \(error.localizedDescription, privacy: .public)"
            )
            throw QuoteRepositoryError.saveFailed(underlying: error)
        }
    }

    func deleteAll() throws {
        let records = try fetchAllRecords()

        do {
            for record in records {
                context.delete(record)
            }
            try context.save()
            AppLog.persistence.info("[Persistence] Deleted all quote history (\(records.count) sightings)")
        } catch {
            AppLog.persistence.error(
                "[Persistence] Delete-all failed: \(error.localizedDescription, privacy: .public)"
            )
            throw QuoteRepositoryError.saveFailed(underlying: error)
        }
    }

    func flush() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            AppLog.persistence.error(
                "[Persistence] Flush failed: \(error.localizedDescription, privacy: .public)"
            )
            throw QuoteRepositoryError.saveFailed(underlying: error)
        }
    }

    // MARK: - Reads

    func allQuotes() throws -> [QuoteSnapshot] {
        try fetchAllRecords()
            .map(\.snapshot)
            .sorted { $0.seenAt > $1.seenAt }
    }

    func recentTexts(limit: Int) throws -> [String] {
        guard limit > 0 else { return [] }
        return try allQuotes().prefix(limit).map(\.text)
    }

    // MARK: - Helpers

    /// Fetch every record, unsorted.
    ///
    /// Sorting happens in Swift rather than through `SortDescriptor`, matching
    /// idle-tapper-macos's `SwiftDataTapRepository`: `#Predicate` and
    /// `SortDescriptor` key paths are not yet `Sendable`, which trips strict
    /// concurrency checking, and at this app's scale (a few quotes fetched per
    /// session) pushing the work into SQLite buys nothing measurable.
    private func fetchAllRecords() throws -> [QuoteRecord] {
        do {
            return try context.fetch(FetchDescriptor<QuoteRecord>())
        } catch {
            AppLog.persistence.error(
                "[Persistence] Fetch failed: \(error.localizedDescription, privacy: .public)"
            )
            throw QuoteRepositoryError.fetchFailed(underlying: error)
        }
    }
}
