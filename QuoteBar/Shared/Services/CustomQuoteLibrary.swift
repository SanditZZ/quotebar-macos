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

    private(set) var installedPacks: [InstalledPackSummary] = []
    private(set) var lastPackActionSummary: String?

    private let repository: any CustomQuoteRepository

    init(repository: any CustomQuoteRepository) {
        self.repository = repository
        refresh()
    }

    // MARK: - Actions

    func refresh() {
        do {
            entries = try repository.allEntries()
            installedPacks = try repository.installedPackSummaries()
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

    /// Read and parse a pack file the user picked via `.fileImporter`, then
    /// install every non-duplicate quote in it. Files only, per issue #31 —
    /// no registry or URL fetching.
    func installPack(at url: URL) {
        guard url.pathExtension.lowercased() == "json" else {
            errorMessage = "\"\(url.lastPathComponent)\" isn't a QuoteBar pack file (expected .json)."
            return
        }

        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let pack = try QuotePackSerializer.decode(data)
            let result = try repository.installPack(pack)

            lastPackActionSummary = Self.installSummary(for: result, packName: pack.name)
            errorMessage = nil
            refresh()
        } catch is QuotePackSerializationError {
            errorMessage = "\"\(url.lastPathComponent)\" needs a newer version of QuoteBar to install."
        } catch {
            AppLog.persistence.error("[Persistence] Pack install failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't install \"\(url.lastPathComponent)\"."
        }
    }

    func uninstallPack(packId: String) {
        do {
            let removed = try repository.uninstallPack(packId: packId)
            lastPackActionSummary = "Removed \(removed) quote\(removed == 1 ? "" : "s")."
            errorMessage = nil
            refresh()
        } catch {
            AppLog.persistence.error("[Persistence] Pack uninstall failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't remove that pack."
        }
    }

    private static func installSummary(for result: QuotePackInstallResult, packName: String) -> String {
        var parts = ["Installed \"\(packName)\": \(result.added) quote\(result.added == 1 ? "" : "s") added"]
        if result.skippedDuplicates > 0 {
            parts.append("\(result.skippedDuplicates) duplicate\(result.skippedDuplicates == 1 ? "" : "s") skipped")
        }
        return parts.joined(separator: ", ") + "."
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
