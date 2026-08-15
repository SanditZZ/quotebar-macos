//
//  QuoteBackupService.swift
//  QuoteBar — Actions
//
//  The observable object Settings' "Backup" section watches. A distinct
//  concern from `CustomQuoteLibrary`/`QuoteTracker`: it spans both
//  repositories (history and the custom quote library) and owns its own
//  export/import summary and error state, same reasoning that already split
//  `CustomQuoteLibrary` off from `QuoteTracker`.
//

import Foundation
import Observation

@MainActor
@Observable
final class QuoteBackupService {

    private(set) var errorMessage: String?
    private(set) var lastOperationSummary: String?

    private let quoteRepository: any QuoteRepository
    private let customQuoteRepository: any CustomQuoteRepository

    /// Counts from the most recently built export, read back by
    /// `handleExportResult` once the user actually confirms a save location
    /// — a `.fileExporter` may be cancelled, so nothing is reported until it
    /// succeeds.
    private var pendingHistoryExportCount = 0
    private var pendingCustomExportCount = 0

    init(quoteRepository: any QuoteRepository, customQuoteRepository: any CustomQuoteRepository) {
        self.quoteRepository = quoteRepository
        self.customQuoteRepository = customQuoteRepository
    }

    // MARK: - Export

    /// Builds the full JSON backup (history + custom quotes). Called
    /// synchronously right before presenting `.fileExporter`, so the
    /// document's bytes are ready at presentation time.
    func makeJSONExportData() -> Data {
        do {
            let history = try quoteRepository.allQuotes()
            let customQuotes = try customQuoteRepository.allEntries()
            pendingHistoryExportCount = history.count
            pendingCustomExportCount = customQuotes.count

            let backup = QuoteBackup(
                formatVersion: QuoteBackup.currentFormatVersion,
                exportedAt: Date(),
                history: history,
                customQuotes: customQuotes
            )
            return try QuoteBackupSerializer.encode(backup)
        } catch {
            AppLog.persistence.error("[Persistence] JSON backup export failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't build the backup."
            return Data()
        }
    }

    /// Builds a CSV export of the custom quote library only — see
    /// `QuoteBackup`'s doc comment for why CSV doesn't carry history/tags.
    func makeCSVExportData() -> Data {
        do {
            let customQuotes = try customQuoteRepository.allEntries()
            pendingHistoryExportCount = 0
            pendingCustomExportCount = customQuotes.count
            return CustomQuoteCSVFormatter.format(customQuotes)
        } catch {
            AppLog.persistence.error("[Persistence] CSV export failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't build the CSV export."
            return Data()
        }
    }

    /// Handles a `.fileExporter` completion for either format.
    func handleExportResult(_ result: Result<URL, Error>, formatName: String) {
        switch result {
        case .success:
            lastOperationSummary = Self.exportSummary(
                historyCount: pendingHistoryExportCount,
                customCount: pendingCustomExportCount,
                formatName: formatName
            )
            errorMessage = nil
        case .failure(let error):
            AppLog.persistence.error("[Persistence] Backup export failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't save the export."
        }
    }

    // MARK: - Import

    /// Reads a JSON backup the user picked via `.fileImporter` and imports
    /// its history and custom quotes. History is imported by id (skips
    /// sightings already present); custom quotes reuse the existing
    /// text-based dedup in `CustomQuoteRepository.importMany`.
    func importBackup(at url: URL) {
        // Sandboxed apps only get read access to a user-picked file for the
        // duration of this scope.
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let backup = try QuoteBackupSerializer.decode(data)

            let historyAdded = try quoteRepository.importHistory(backup.history)
            // Carries `$0.packId` through so a restored quote that was
            // pack-installed when exported comes back pack-owned, not
            // silently reassigned to the user — see `ParsedCustomQuote.packId`.
            let parsedCustomQuotes = backup.customQuotes.map {
                ParsedCustomQuote(text: $0.text, author: $0.author, packId: $0.packId)
            }
            let customResult = try customQuoteRepository.importMany(parsedCustomQuotes)

            lastOperationSummary = Self.importSummary(
                historyAdded: historyAdded,
                customAdded: customResult.added,
                customSkippedDuplicates: customResult.skippedDuplicates
            )
            errorMessage = nil
        } catch {
            AppLog.persistence.error("[Persistence] Backup import failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't read \"\(url.lastPathComponent)\"."
        }
    }

    // MARK: - Summary text

    private static func exportSummary(historyCount: Int, customCount: Int, formatName: String) -> String {
        if historyCount == 0 {
            return "Exported \(customCount) library quote\(customCount == 1 ? "" : "s") as \(formatName)."
        }
        return "Exported \(historyCount) history quote\(historyCount == 1 ? "" : "s") and \(customCount) library quote\(customCount == 1 ? "" : "s") as \(formatName)."
    }

    private static func importSummary(historyAdded: Int, customAdded: Int, customSkippedDuplicates: Int) -> String {
        var parts = ["Imported \(historyAdded) history quote\(historyAdded == 1 ? "" : "s")"]
        parts.append("\(customAdded) library quote\(customAdded == 1 ? "" : "s")")
        if customSkippedDuplicates > 0 {
            parts.append("skipped \(customSkippedDuplicates) duplicate\(customSkippedDuplicates == 1 ? "" : "s")")
        }
        return parts.joined(separator: ", ") + "."
    }
}
