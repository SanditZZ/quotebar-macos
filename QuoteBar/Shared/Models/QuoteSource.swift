//
//  QuoteSource.swift
//  QuoteBar — Data
//
//  Which of the four tiers in the provider chain produced a quote. Plain enum,
//  no logic — see `Shared/Services/QuoteProviderService.swift` for the chain
//  itself and `Shared/Logic/QuoteTextFormatter.swift` for display formatting.
//

import Foundation

enum QuoteSource: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Generated on-device by Apple's Foundation Models framework. Always an
    /// original line — never a claimed reproduction of a real quote, since the
    /// on-device model can hallucinate attributions.
    case onDeviceAI

    /// Fetched from the ZenQuotes public API.
    case zenQuotes

    /// Fetched from the DummyJSON public API, used only if ZenQuotes fails.
    case dummyJSON

    /// Served from the bundled offline set (`Resources/BackupQuotes.json`).
    case bundled

    /// Added or imported by the user into their own library. Unlike the
    /// other three tiers, this is never part of the automatic fallback
    /// order — it only serves quotes when explicitly pinned via
    /// `AppSettings.preferredSource`, since silently mixing a user's own
    /// quotes into automatic rotation would surprise anyone who added one
    /// without expecting their whole rotation to change.
    case custom

    var id: String { rawValue }

    /// Short label for the source badge on the quote card.
    var badgeLabel: String {
        switch self {
        case .onDeviceAI: return "AI"
        case .zenQuotes, .dummyJSON: return "WEB"
        case .bundled: return "OFFLINE"
        case .custom: return "MINE"
        }
    }

    /// Full name for Settings and the history list.
    var displayName: String {
        switch self {
        case .onDeviceAI: return "On-device AI"
        case .zenQuotes: return "ZenQuotes"
        case .dummyJSON: return "DummyJSON"
        case .bundled: return "Bundled offline set"
        case .custom: return "Your Quotes"
        }
    }

    /// SF Symbol shown alongside `displayName`.
    var symbolName: String {
        switch self {
        case .onDeviceAI: return "apple.intelligence"
        case .zenQuotes, .dummyJSON: return "network"
        case .bundled: return "internaldrive"
        case .custom: return "text.badge.plus"
        }
    }
}
