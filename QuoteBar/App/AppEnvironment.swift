//
//  AppEnvironment.swift
//  QuoteBar — Composition root
//
//  Builds the object graph once and hands it to whoever needs it. Concrete
//  types are chosen here and nowhere else, so swapping the persistence
//  backend or the provider chain is a one-line change.
//

import Foundation
import SwiftData

@MainActor
final class AppEnvironment {

    /// Shared graph used by the app. Tests build their own instances directly
    /// rather than going through this.
    static let shared = AppEnvironment()

    let settings: AppSettings
    let tracker: QuoteTracker
    let launchAtLogin: LaunchAtLoginService
    let hotKeyService = GlobalHotKeyService()
    let notificationService = QuoteNotificationService()
    let customQuoteLibrary: CustomQuoteLibrary

    /// True when the on-disk store could not be opened and history is being
    /// held in memory only. Surfaced in the UI rather than failing silently.
    let isEphemeral: Bool

    private init() {
        let settings = AppSettings.shared
        self.settings = settings

        var container: ModelContainer?
        var ephemeral = false

        do {
            container = try ModelContainerFactory.makePersistent()
        } catch {
            AppLog.app.error(
                "[App] Persistent store unavailable, falling back to memory: \(error.localizedDescription, privacy: .public)"
            )
            container = ModelContainerFactory.makeFallback()
            ephemeral = true
        }

        guard let container else {
            // Both the persistent and in-memory stores failed, which indicates
            // a broken SwiftData runtime rather than a recoverable condition.
            fatalError("[App] Could not create any model container")
        }

        self.isEphemeral = ephemeral
        self.launchAtLogin = LaunchAtLoginService()

        let customQuoteRepository = SwiftDataCustomQuoteRepository(container: container)
        self.customQuoteLibrary = CustomQuoteLibrary(repository: customQuoteRepository)

        self.tracker = QuoteTracker(
            repository: SwiftDataQuoteRepository(container: container),
            provider: QuoteProviderService(
                pinnedOnlyProviders: [CustomQuoteProvider(repository: customQuoteRepository)]
            ),
            settings: settings,
            isEphemeral: ephemeral
        )

        AppLog.app.info("[App] Environment ready (ephemeral: \(ephemeral, privacy: .public))")
    }
}
