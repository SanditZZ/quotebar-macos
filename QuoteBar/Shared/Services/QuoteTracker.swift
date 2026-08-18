//
//  QuoteTracker.swift
//  QuoteBar — Actions
//
//  The single observable object the UI watches, mirroring idle-tapper-macos's
//  `TapTracker`. Owns the provider chain and the repository; views never talk
//  to either directly.
//

import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class QuoteTracker {

    // MARK: - Observable State

    /// The quote currently shown in the popover. `nil` only before the first
    /// fetch completes.
    private(set) var currentQuote: QuoteSnapshot?

    /// Full seen-quote history, most recent first. Assign through
    /// `setHistory(_:)` rather than directly, so `stats` cannot fall behind it.
    private(set) var history: [QuoteSnapshot] = []

    /// Aggregate statistics over `history`, recomputed only when history
    /// changes. Deliberately stored rather than computed: it is read from
    /// inside SwiftUI view bodies, which run on every redraw — every window
    /// resize and every keystroke in a filter — and the aggregation walks the
    /// whole store and sorts two ranked lists. Computing that per redraw would
    /// scale with how long someone has been using the app, which is exactly
    /// backwards.
    private(set) var stats: QuoteHistoryStatsResult = .empty

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

    /// True while "Read Aloud" is speaking the current quote.
    private(set) var isSpeaking = false

    // MARK: - Dependencies

    private let repository: any QuoteRepository
    private let provider: any QuoteProviderServicing
    private let settings: AppSettings
    private let speechService: QuoteSpeechService

    /// How many recent quotes to avoid repeating.
    private let recentHistoryWindow: Int

    // MARK: - Lifecycle

    init(
        repository: any QuoteRepository,
        provider: any QuoteProviderServicing,
        settings: AppSettings,
        isEphemeral: Bool,
        speechService: QuoteSpeechService? = nil,
        recentHistoryWindow: Int = 10
    ) {
        self.repository = repository
        self.provider = provider
        self.settings = settings
        self.isEphemeral = isEphemeral
        // A default-value expression in the signature above would run in the
        // caller's (nonisolated) context and couldn't call this @MainActor
        // initializer — confirmed by a real CI build failure — so the
        // fallback instance is constructed here instead, inside this
        // @MainActor init's body.
        self.speechService = speechService ?? QuoteSpeechService()
        self.recentHistoryWindow = recentHistoryWindow
        refresh()
        self.speechService.start { [weak self] isSpeaking in
            self?.isSpeaking = isSpeaking
        }
    }

    // MARK: - Actions

    /// Fetch and persist a new quote, replacing `currentQuote`.
    func requestNewQuote() async {
        guard !isFetching else { return }
        stopSpeaking()
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
            setHistory([snapshot] + history)
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
                isFavorite: false,
                tags: []
            )
        }
    }

    /// Reload history from disk. Call when a window reopens, in case another
    /// part of the app changed something.
    func refresh() {
        do {
            let stored = try repository.allQuotes()
            setHistory(stored)
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

    func toggleTag(_ tagID: UUID, onQuote quoteID: UUID) {
        do {
            try repository.toggleTag(tagID, onQuote: quoteID)
            refresh()
        } catch {
            AppLog.quote.error("[Quote] Failed to toggle tag: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't update that tag."
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

    /// Speak the current quote's text and attribution aloud.
    func speakCurrentQuote() {
        guard let quote = currentQuote else { return }
        let availableIdentifiers = AVSpeechSynthesisVoice.speechVoices().map(\.identifier)
        let voiceIdentifier = SpeechVoiceResolver.resolve(
            storedIdentifier: settings.preferredVoiceIdentifier,
            availableIdentifiers: availableIdentifiers
        )
        speechService.speak(
            text: QuoteTextFormatter.spokenText(text: quote.text, author: quote.author),
            voiceIdentifier: voiceIdentifier,
            rate: settings.speechRate
        )
    }

    /// Stop any in-progress narration immediately.
    func stopSpeaking() {
        speechService.stop()
    }

    // MARK: - Calculations

    /// The one place `history` is written. Keeps `stats` in step with it, so no
    /// caller has to remember to — and so no view ever aggregates in its body.
    private func setHistory(_ snapshots: [QuoteSnapshot]) {
        history = snapshots
        stats = QuoteHistoryStats.compute(from: snapshots)
    }
}
