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
        static let preferredSource = "preferredSource"
        static let hotKeyCombination = "hotKeyCombination"
        static let hotKeyEnabled = "hotKeyEnabled"
        static let shareCardStyle = "shareCardStyle"
    }

    // MARK: - Data

    @ObservationIgnored private let defaults: UserDefaults

    /// Whether clearing history from Settings asks for confirmation first.
    var confirmBeforeClearHistory: Bool {
        didSet { defaults.set(confirmBeforeClearHistory, forKey: Key.confirmBeforeClearHistory) }
    }

    /// Pin the provider chain to a single source instead of the automatic
    /// fallback order. `nil` means automatic — the default.
    var preferredSource: QuoteSource? {
        didSet { defaults.set(preferredSource?.rawValue, forKey: Key.preferredSource) }
    }

    /// Which look the exported share-quote image uses. Always has a value —
    /// unlike `preferredSource`, there's no "automatic" option here.
    var shareCardStyle: ShareCardStyle {
        didSet { defaults.set(shareCardStyle.rawValue, forKey: Key.shareCardStyle) }
    }

    /// The global "New Quote" shortcut. `nil` means the user explicitly
    /// cleared it — distinct from a fresh install, which starts at
    /// `HotKeyCombination.default` so the feature works before Settings is
    /// ever opened. `Key.hotKeyEnabled` is what tells the two apart, since
    /// UserDefaults has no way to distinguish "never set" from "set to nil".
    var hotKeyCombination: HotKeyCombination? {
        didSet {
            defaults.set(hotKeyCombination != nil, forKey: Key.hotKeyEnabled)
            if let hotKeyCombination, let encoded = try? JSONEncoder().encode(hotKeyCombination) {
                defaults.set(encoded, forKey: Key.hotKeyCombination)
            }
        }
    }

    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.confirmBeforeClearHistory =
            defaults.object(forKey: Key.confirmBeforeClearHistory) as? Bool ?? true
        self.preferredSource =
            (defaults.string(forKey: Key.preferredSource)).flatMap(QuoteSource.init(rawValue:))
        self.shareCardStyle =
            (defaults.string(forKey: Key.shareCardStyle)).flatMap(ShareCardStyle.init(rawValue:)) ?? .midnight

        let hotKeyEnabled = defaults.object(forKey: Key.hotKeyEnabled) as? Bool ?? true
        let storedCombination = defaults.data(forKey: Key.hotKeyCombination)
            .flatMap { try? JSONDecoder().decode(HotKeyCombination.self, from: $0) }
        self.hotKeyCombination = hotKeyEnabled ? (storedCombination ?? .default) : nil
    }

    // MARK: - Actions

    func resetToDefaults() {
        confirmBeforeClearHistory = true
        preferredSource = nil
        hotKeyCombination = .default
        shareCardStyle = .midnight
        AppLog.settings.info("[Settings] Restored defaults")
    }
}
