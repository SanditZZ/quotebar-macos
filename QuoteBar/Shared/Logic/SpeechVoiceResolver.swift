//
//  SpeechVoiceResolver.swift
//  QuoteBar — Calculations
//

import Foundation

enum SpeechVoiceResolver {

    /// Resolves a stored voice identifier against what's actually installed.
    /// Falls back to `nil` (system default) if the stored voice is no longer
    /// present — e.g. removed via System Settings — rather than handing
    /// AVSpeechSynthesizer a dead identifier.
    static func resolve(storedIdentifier: String?, availableIdentifiers: [String]) -> String? {
        guard let storedIdentifier, availableIdentifiers.contains(storedIdentifier) else { return nil }
        return storedIdentifier
    }
}
