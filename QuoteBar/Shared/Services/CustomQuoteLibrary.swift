//
//  CustomQuoteLibrary.swift
//  QuoteBar — Actions
//
//  The observable object Settings' "Your Quotes" section watches, mirroring
//  how `QuoteTracker` wraps `QuoteRepository`. Kept separate from
//  `QuoteTracker` itself: that type already owns fetching and seen-quote
//  history, and this is a distinct concern (curating the library new quotes
//  get picked from) with its own error and import-summary state.
//

import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class CustomQuoteLibrary {

    private(set) var entries: [CustomQuoteSnapshot] = []
    private(set) var errorMessage: String?
    private(set) var lastImportSummary: String?

    private let repository: any CustomQuoteRepository

    init(repository: any CustomQuoteRepository) {
        self.repository = repository
        refresh()
    }

    // MARK: - Actions

    func refresh() {
        do {
            entries = try repository.allEntries()
            errorMessage = nil
        } catch {
            AppLog.persistence.error("[Persistence] Failed to load custom quote library: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't load your quote library."
        }
    }

    func add(text: String, author: String?) {
        do {
            try repository.add(text: text, author: author)
            lastImportSummary = nil
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
            AppLog.persistence.error("[Persistence] Failed to remove a custom quote: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't remove that quote."
        }
    }

    func removeMany(ids: Set<UUID>) {
        do {
            try repository.removeMany(ids: ids)
            refresh()
        } catch {
            AppLog.persistence.error("[Persistence] Failed to remove custom quotes: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't remove those quotes."
        }
    }

    /// Read and parse a file the user picked via `.fileImporter`, then add
    /// every non-duplicate row.
    func importFile(at url: URL) {
        guard let format = CustomQuoteImportFormat(fileExtension: url.pathExtension) else {
            errorMessage = "\"\(url.lastPathComponent)\" isn't a JSON or CSV file."
            return
        }

        // Sandboxed apps only get read access to a user-picked file for the
        // duration of this scope.
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let parsed = CustomQuoteImportParsing.parse(data: data, format: format)
            let result = try repository.importMany(parsed.quotes)

            lastImportSummary = Self.summary(for: result, skippedInvalidRows: parsed.skippedInvalidRows)
            errorMessage = nil
            refresh()
        } catch {
            AppLog.persistence.error("[Persistence] Custom quote import failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't read \"\(url.lastPathComponent)\"."
        }
    }

    private static func summary(for result: CustomQuoteImportResult, skippedInvalidRows: Int) -> String {
        var parts = ["Added \(result.added) quote\(result.added == 1 ? "" : "s")"]
        if result.skippedDuplicates > 0 {
            parts.append("skipped \(result.skippedDuplicates) duplicate\(result.skippedDuplicates == 1 ? "" : "s")")
        }
        if skippedInvalidRows > 0 {
            parts.append("skipped \(skippedInvalidRows) invalid row\(skippedInvalidRows == 1 ? "" : "s")")
        }
        return parts.joined(separator: ", ") + "."
    }
}

extension UTType {
    /// Accepted by the "Your Quotes" `.fileImporter`.
    static let customQuoteImportTypes: [UTType] = [.json, .commaSeparatedText]
}
