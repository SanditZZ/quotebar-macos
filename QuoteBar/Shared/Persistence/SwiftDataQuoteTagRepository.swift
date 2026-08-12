//
//  SwiftDataQuoteTagRepository.swift
//  QuoteBar — Persistence implementation
//
//  SwiftData-backed `QuoteTagRepository`.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataQuoteTagRepository: QuoteTagRepository {

    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
        AppLog.persistence.debug("[Persistence] Tag repository ready")
    }

    // MARK: - Writes

    @discardableResult
    func add(name: String) throws -> TagSnapshot {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw QuoteTagRepositoryError.emptyName }

        let existingNames = try allTags().map(\.name)
        guard !CustomQuoteDeduplicator.isDuplicate(trimmed, against: existingNames) else {
            throw QuoteTagRepositoryError.duplicate
        }

        let tag = QuoteTag(name: trimmed)
        context.insert(tag)

        do {
            try context.save()
            AppLog.persistence.debug("[Persistence] Added a tag")
            return tag.snapshot
        } catch {
            AppLog.persistence.error(
                "[Persistence] Tag save failed: \(error.localizedDescription, privacy: .public)"
            )
            throw QuoteTagRepositoryError.saveFailed(underlying: error)
        }
    }

    func rename(id: UUID, to newName: String) throws {
        guard let tag = try fetchAllTags().first(where: { $0.id == id }) else {
            throw QuoteTagRepositoryError.notFound
        }

        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw QuoteTagRepositoryError.emptyName }

        let otherNames = try allTags().filter { $0.id != id }.map(\.name)
        guard !CustomQuoteDeduplicator.isDuplicate(trimmed, against: otherNames) else {
            throw QuoteTagRepositoryError.duplicate
        }

        tag.name = trimmed

        do {
            try context.save()
        } catch {
            AppLog.persistence.error(
                "[Persistence] Tag rename failed: \(error.localizedDescription, privacy: .public)"
            )
            throw QuoteTagRepositoryError.saveFailed(underlying: error)
        }
    }

    func remove(id: UUID) throws {
        guard let tag = try fetchAllTags().first(where: { $0.id == id }) else {
            throw QuoteTagRepositoryError.notFound
        }

        context.delete(tag)

        do {
            try context.save()
            AppLog.persistence.info("[Persistence] Deleted a tag")
        } catch {
            AppLog.persistence.error(
                "[Persistence] Tag delete failed: \(error.localizedDescription, privacy: .public)"
            )
            throw QuoteTagRepositoryError.saveFailed(underlying: error)
        }
    }

    // MARK: - Reads

    func allTags() throws -> [TagSnapshot] {
        try fetchAllTags()
            .map(\.snapshot)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Helpers

    private func fetchAllTags() throws -> [QuoteTag] {
        do {
            return try context.fetch(FetchDescriptor<QuoteTag>())
        } catch {
            AppLog.persistence.error(
                "[Persistence] Tag fetch failed: \(error.localizedDescription, privacy: .public)"
            )
            throw QuoteTagRepositoryError.fetchFailed(underlying: error)
        }
    }
}
