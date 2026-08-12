//
//  QuoteTracker.swift
//  QuoteBar — Actions
//
//  The single observable object the UI watches, mirroring idle-tapper-macos's
//  `TapTracker`. Owns the provider chain and the repository; views never talk
//  to either directly.
//

import Foundation
import Observation

@MainActor
@Observable
final class QuoteTracker {

    // MARK: - Observable State

    /// The quote currently shown in the popover. `nil` only before the first
    /// fetch completes.
    private(set) var currentQuote: QuoteSnapshot?

    /// Full seen-quote history, most recent first.
    private(set) var history: [QuoteSnapshot] = []

    /// True while a new quote is being fetched.
    private(set) var isFetching = false

    /// Message for a failure the user should see. Fetching itself never
    /// "fails" — the provider chain always returns something — this is for
    /// persistence errors instead.
    private(set) var errorMessage: String?

    /// True when the on-disk store could not be opened and history is being
    /// held in memory only.
    let isEphemeral: Bool

    /// Set after a fetch when `settings.preferredSource` was pinned but the
    /// served quote came from a different source — the pin failed silently
    /// otherwise, which is exactly what a pinned choice must not do. `nil`
    /// when automatic, or when the pin was honored.
    private(set) var pinnedSourceFallbackMessage: String?

    // MARK: - Dependencies

    private let repository: any QuoteRepository
    private let provider: any QuoteProviderServicing
    private let settings: AppSettings

    /// How many recent quotes to avoid repeating.
    private let recentHistoryWindow: Int

    // MARK: - Lifecycle

    init(
        repository: any QuoteRepository,
        provider: any QuoteProviderServicing,
        settings: AppSettings,
        isEphemeral: Bool,
        recentHistoryWindow: Int = 10
    ) {
        self.repository = repository
        self.provider = provider
        self.settings = settings
        self.isEphemeral = isEphemeral
        self.recentHistoryWindow = recentHistoryWindow
        refresh()
    }

    // MARK: - Actions

    /// Fetch and persist a new quote, replacing `currentQuote`.
    func requestNewQuote() async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        let preference = settings.preferredSource
        let recentTexts = (try? repository.recentTexts(limit: recentHistoryWindow)) ?? []
        let quote = await provider.nextQuote(recentTexts: recentTexts, preference: preference)

        if let preference, quote.source != preference {
            pinnedSourceFallbackMessage =
                "Pinned to \(preference.displayName), but it wasn't available just now — showing a quote from \(quote.source.displayName) instead."
        } else {
            pinnedSourceFallbackMessage = nil
        }

        do {
            let snapshot = try repository.record(quote)
            currentQuote = snapshot
            history.insert(snapshot, at: 0)
            errorMessage = nil
        } catch {
            AppLog.quote.error("[Quote] Failed to save fetched quote: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't save that quote, but here it is anyway."
            // Show it even though it couldn't be persisted — a working app
            // that silently drops your quote is worse than one that shows it
            // and admits the save failed.
            currentQuote = QuoteSnapshot(
                id: UUID(),
                text: quote.text,
                author: quote.author,
                source: quote.source,
                seenAt: Date(),
                isFavorite: false
            )
        }
    }

    /// Reload history from disk. Call when a window reopens, in case another
    /// part of the app changed something.
    func refresh() {
        do {
            history = try repository.allQuotes()
            currentQuote = history.first
            errorMessage = nil
        } catch {
            AppLog.quote.error("[Quote] Failed to load history: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't load quote history."
        }
    }

    func toggleFavorite(id: UUID) {
        do {
            try repository.toggleFavorite(id: id)
            refresh()
        } catch {
            AppLog.quote.error("[Quote] Failed to toggle favorite: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't update that favorite."
        }
    }

    func clearHistory() {
        do {
            try repository.deleteAll()
            refresh()
        } catch {
            AppLog.quote.error("[Quote] Failed to clear history: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't clear history."
        }
    }

    /// Write any pending changes to disk immediately. Call before termination
    /// or when the popover closes.
    func flush() {
        try? repository.flush()
    }

    // MARK: - Calculations

    var stats: QuoteHistoryStatsResult {
        QuoteHistoryStats.compute(from: history)
    }
}
