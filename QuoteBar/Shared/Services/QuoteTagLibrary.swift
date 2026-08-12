//
//  QuoteTagLibrary.swift
//  QuoteBar — Actions
//
//  The observable object Settings' "Tags" section and History's per-quote
//  tag picker both watch, mirroring how `CustomQuoteLibrary` wraps
//  `CustomQuoteRepository`. Kept separate from `QuoteTracker`: this owns the
//  tag vocabulary itself (create/rename/delete), a distinct concern from
//  acting on a specific quote sighting.
//

import Foundation
import Observation

@MainActor
@Observable
final class QuoteTagLibrary {

    private(set) var tags: [TagSnapshot] = []
    private(set) var errorMessage: String?

    private let repository: any QuoteTagRepository

    init(repository: any QuoteTagRepository) {
        self.repository = repository
        refresh()
    }

    // MARK: - Actions

    func refresh() {
        do {
            tags = try repository.allTags()
            errorMessage = nil
        } catch {
            AppLog.persistence.error("[Persistence] Failed to load tags: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't load your tags."
        }
    }

    /// Returns the new tag's snapshot on success, so a caller (e.g. the
    /// History tag picker) can immediately assign it to a quote without a
    /// second lookup.
    @discardableResult
    func add(name: String) -> TagSnapshot? {
        do {
            let snapshot = try repository.add(name: name)
            refresh()
            return snapshot
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func rename(id: UUID, to newName: String) {
        do {
            try repository.rename(id: id, to: newName)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(id: UUID) {
        do {
            try repository.remove(id: id)
            refresh()
        } catch {
            AppLog.persistence.error("[Persistence] Failed to remove a tag: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't remove that tag."
        }
    }
}
