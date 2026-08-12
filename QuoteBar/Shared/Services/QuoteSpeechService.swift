//
//  QuoteSpeechService.swift
//  QuoteBar — Actions
//
//  Thin wrapper around AVSpeechSynthesizer. Exists as its own NSObject-based
//  type because AVSpeechSynthesizerDelegate requires NSObject conformance,
//  which QuoteTracker (a plain @Observable class) doesn't have — QuoteTracker
//  owns one of these internally and mirrors its state via `isSpeaking`.
//
//  IMPORTANT — verify against Xcode 26 before relying on this: written on a
//  Linux machine with no AVFoundation headers to compile against, so the
//  exact delegate signatures below reflect AVFoundation's long-documented,
//  unchanged public API, not a verified build. Confirm the first time this
//  builds, via CI (see CLAUDE.md §8 — this machine can't run
//  ./scripts/ci-local.sh).
//
//  AVSpeechSynthesizerDelegate's methods aren't `@MainActor` and their
//  `AVSpeechSynthesizer`/`AVSpeechUtterance` parameters aren't `Sendable`, so
//  a `@MainActor`-isolated implementation can't accept them directly under
//  Swift 6's strict concurrency checking — same shape as AppDelegate's
//  UNUserNotificationCenterDelegate conformance, confirmed there by a real CI
//  build failure. `nonisolated` on each method avoids the isolation
//  crossing; hopping back via `Task { @MainActor in }` updates state only
//  for what's needed.
//

import AVFoundation

@MainActor
final class QuoteSpeechService: NSObject {

    private let synthesizer = AVSpeechSynthesizer()
    private var onSpeakingChanged: ((Bool) -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Call once at launch. Wires what happens when speech starts/stops;
    /// mirrors `GlobalHotKeyService.start(onFire:)`.
    func start(onSpeakingChanged: @escaping (Bool) -> Void) {
        self.onSpeakingChanged = onSpeakingChanged
    }

    /// Speak `text`, cancelling any narration already in progress first.
    func speak(text: String, voiceIdentifier: String?, rate: Float) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        if let voiceIdentifier {
            utterance.voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
        }
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    /// Stop any in-progress narration immediately.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension QuoteSpeechService: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in self?.onSpeakingChanged?(true) }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in self?.onSpeakingChanged?(false) }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in self?.onSpeakingChanged?(false) }
    }
}
