//
//  SwiftDataCustomQuoteRepository.swift
//  QuoteBar — Persistence implementation
//
//  SwiftData-backed `CustomQuoteRepository`. At the scale of a personal quote
//  library (tens to low hundreds of entries), re-fetching everything to check
//  for a duplicate on each add is not worth trading away for `#Predicate`,
//  same reasoning `SwiftDataQuoteRepository` already applies.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataCustomQuoteRepository: CustomQuoteRepository {

    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    // MARK: - Writes

    @discardableResult
    func add(text: String, author: String?) throws -> CustomQuoteSnapshot {
        try insertEntry(text: text, author: author, packId: nil)
    }

    func importMany(_ parsed: [ParsedCustomQuote]) throws -> CustomQuoteImportResult {
        var added = 0
        var skipped = 0

        for candidate in parsed {
            do {
                try insertEntry(text: candidate.text, author: candidate.author, packId: candidate.packId)
                added += 1
            } catch CustomQuoteRepositoryError.duplicate {
                skipped += 1
            } catch CustomQuoteRepositoryError.emptyText {
                skipped += 1
            }
        }

        AppLog.persistence.info(
            "[Persistence] Imported custom quotes: \(added, privacy: .public) added, \(skipped, privacy: .public) skipped"
        )
        return CustomQuoteImportResult(added: added, skippedDuplicates: skipped)
    }

    @discardableResult
    func installPack(_ pack: QuotePack) throws -> QuotePackInstallResult {
        var added = 0
        var skipped = 0

        for quote in pack.quotes {
            do {
                try insertEntry(text: quote.text, author: quote.author, packId: pack.packId)
                added += 1
            } catch CustomQuoteRepositoryError.duplicate {
                skipped += 1
            } catch CustomQuoteRepositoryError.emptyText {
                skipped += 1
            }
        }

        AppLog.persistence.info(
            "[Persistence] Installed pack \(pack.packId, privacy: .public): \(added, privacy: .public) added, \(skipped, privacy: .public) skipped"
        )
        return QuotePackInstallResult(added: added, skippedDuplicates: skipped)
    }

    @discardableResult
    func uninstallPack(packId: String) throws -> Int {
        let matches = try fetchAllEntries().filter { $0.packId == packId }
        guard !matches.isEmpty else { return 0 }

        do {
            for entry in matches {
                context.delete(entry)
            }
            try context.save()
            AppLog.persistence.info(
                "[Persistence] Uninstalled pack \(packId, privacy: .public): removed \(matches.count, privacy: .public) quotes"
            )
            return matches.count
        } catch {
            AppLog.persistence.error(
                "[Persistence] Pack uninstall failed: \(error.localizedDescription, privacy: .public)"
            )
            throw CustomQuoteRepositoryError.saveFailed(underlying: error)
        }
    }

    func installedPackSummaries() throws -> [InstalledPackSummary] {
        let packIds = try fetchAllEntries().compactMap(\.packId)
        let counts = Dictionary(packIds.map { ($0, 1) }, uniquingKeysWith: +)
        return counts
            .map { InstalledPackSummary(packId: $0.key, quoteCount: $0.value) }
            .sorted { $0.packId < $1.packId }
    }

    func remove(id: UUID) throws {
        guard let entry = try fetchAllEntries().first(where: { $0.id == id }) else {
            throw CustomQuoteRepositoryError.notFound
        }

        context.delete(entry)

        do {
            try context.save()
        } catch {
            AppLog.persistence.error(
                "[Persistence] Custom quote delete failed: \(error.localizedDescription, privacy: .public)"
            )
            throw CustomQuoteRepositoryError.saveFailed(underlying: error)
        }
    }

    @discardableResult
    func removeMany(ids: Set<UUID>) throws -> Int {
        guard !ids.isEmpty else { return 0 }
        let matches = try fetchAllEntries().filter { ids.contains($0.id) }

        do {
            for entry in matches {
                context.delete(entry)
            }
            try context.save()
            AppLog.persistence.info("[Persistence] Removed \(matches.count, privacy: .public) custom quotes")
            return matches.count
        } catch {
            AppLog.persistence.error(
                "[Persistence] Bulk custom quote delete failed: \(error.localizedDescription, privacy: .public)"
            )
            throw CustomQuoteRepositoryError.saveFailed(underlying: error)
        }
    }

    // MARK: - Reads

    func allEntries() throws -> [CustomQuoteSnapshot] {
        try fetchAllEntries()
            .map(\.snapshot)
            .sorted { $0.addedAt > $1.addedAt }
    }

    // MARK: - Helpers

    /// Shared by `add`, `importMany` and `installPack` — the only difference
    /// between "the user typed one quote," "a file import added many," and
    /// "a pack installed many" is which `packId` (if any) the new rows carry.
    private func insertEntry(text: String, author: String?, packId: String?) throws -> CustomQuoteSnapshot {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { throw CustomQuoteRepositoryError.emptyText }

        let existingTexts = try allEntries().map(\.text) + BundledQuoteProvider.allTexts
        guard !CustomQuoteDeduplicator.isDuplicate(trimmedText, against: existingTexts) else {
            throw CustomQuoteRepositoryError.duplicate
        }

        let trimmedAuthor = author?.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = CustomQuoteEntry(
            text: trimmedText,
            author: (trimmedAuthor?.isEmpty == false) ? trimmedAuthor : nil,
            packId: packId
        )
        context.insert(entry)

        do {
            try context.save()
            AppLog.persistence.debug("[Persistence] Added a custom quote")
            return entry.snapshot
        } catch {
            AppLog.persistence.error(
                "[Persistence] Custom quote save failed: \(error.localizedDescription, privacy: .public)"
            )
            throw CustomQuoteRepositoryError.saveFailed(underlying: error)
        }
    }

    private func fetchAllEntries() throws -> [CustomQuoteEntry] {
        do {
            return try context.fetch(FetchDescriptor<CustomQuoteEntry>())
        } catch {
            AppLog.persistence.error(
                "[Persistence] Custom quote fetch failed: \(error.localizedDescription, privacy: .public)"
            )
            throw CustomQuoteRepositoryError.fetchFailed(underlying: error)
        }
    }
}
