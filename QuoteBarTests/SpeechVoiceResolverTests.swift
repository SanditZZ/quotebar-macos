//
//  SpeechVoiceResolverTests.swift
//  QuoteBarTests
//

import Testing
@testable import QuoteBar

@Suite("Speech voice resolver")
struct SpeechVoiceResolverTests {

    @Test("No stored identifier resolves to nil (system default)")
    func nilStoredResolvesToNil() {
        let result = SpeechVoiceResolver.resolve(storedIdentifier: nil, availableIdentifiers: ["com.apple.voice.a"])
        #expect(result == nil)
    }

    @Test("A stored identifier present in the available list passes through")
    func presentIdentifierPassesThrough() {
        let result = SpeechVoiceResolver.resolve(
            storedIdentifier: "com.apple.voice.a",
            availableIdentifiers: ["com.apple.voice.a", "com.apple.voice.b"]
        )
        #expect(result == "com.apple.voice.a")
    }

    @Test("A stored identifier no longer installed falls back to nil")
    func absentIdentifierFallsBackToNil() {
        let result = SpeechVoiceResolver.resolve(
            storedIdentifier: "com.apple.voice.removed",
            availableIdentifiers: ["com.apple.voice.a", "com.apple.voice.b"]
        )
        #expect(result == nil)
    }

    @Test("An empty available list always falls back to nil")
    func emptyAvailableListFallsBackToNil() {
        let result = SpeechVoiceResolver.resolve(storedIdentifier: "com.apple.voice.a", availableIdentifiers: [])
        #expect(result == nil)
    }
}
