//
//  AppSettings.swift
//  QuoteBar — Preferences
//
//  User preferences live in `UserDefaults`; quote history lives in SwiftData.
//  Every property has a valid, functional default so a fresh install behaves
//  correctly with no setup.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {

    /// Shared instance used by the app. Tests construct their own against a
    /// scratch `UserDefaults` suite.
    static let shared = AppSettings()

    // MARK: - Keys

    private enum Key {
        static let confirmBeforeClearHistory = "confirmBeforeClearHistory"
    }

    // MARK: - Data

    @ObservationIgnored private let defaults: UserDefaults

    /// Whether clearing history from Settings asks for confirmation first.
    var confirmBeforeClearHistory: Bool {
        didSet { defaults.set(confirmBeforeClearHistory, forKey: Key.confirmBeforeClearHistory) }
    }

    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.confirmBeforeClearHistory =
            defaults.object(forKey: Key.confirmBeforeClearHistory) as? Bool ?? true
    }

    // MARK: - Actions

    func resetToDefaults() {
        confirmBeforeClearHistory = true
        AppLog.settings.info("[Settings] Restored defaults")
    }
}
