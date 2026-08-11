//
//  FoundationModelsQuoteProvider.swift
//  QuoteBar — Actions
//
//  Tier 1 of the provider chain: an original quote generated on-device by
//  Apple's Foundation Models framework (macOS 26+, Apple Intelligence–capable
//  hardware, feature enabled).
//
//  IMPORTANT — verify against Xcode 26 before relying on this: this file was
//  written on a Linux machine with no Xcode 26 install to compile against, so
//  the `FoundationModels` API surface below (`SystemLanguageModel`,
//  `.availability`, `LanguageModelSession`, `.respond(to:)`) reflects the
//  framework as publicly documented as of mid-2026, not a verified build.
//  Confirm the symbol names against current framework documentation the first
//  time this is built on an actual Mac, via `./scripts/ci-local.sh`.
//
//  Deliberately never asks the model to reproduce or attribute a real quote —
//  the on-device model is small enough to hallucinate attributions, so every
//  quote from this tier is original and carries no author. See CLAUDE.md §7.
//

import Foundation
import FoundationModels

struct FoundationModelsQuoteProvider: QuoteProvider {
    let source = QuoteSource.onDeviceAI

    private static let instructions = """
        You write a single short, original, inspiring quote of your own invention. \
        Never quote or paraphrase a real person, book, or existing work, and never \
        attribute the line to anyone. Respond with only the quote text itself — no \
        quotation marks, no author, no preamble, one or two sentences at most.
        """

    private static let prompt = "Write one original quote."

    func nextQuote() async -> Quote? {
        guard #available(macOS 26.0, *) else {
            AppLog.quote.debug("[Quote] FoundationModels requires macOS 26 — skipping")
            return nil
        }
        return await generate()
    }

    @available(macOS 26.0, *)
    private func generate() async -> Quote? {
        let model = SystemLanguageModel.default

        guard case .available = model.availability else {
            AppLog.quote.debug(
                "[Quote] On-device model unavailable: \(String(describing: model.availability), privacy: .public)"
            )
            return nil
        }

        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(to: Self.prompt)
            let text = QuoteTextFormatter.normalize(response.content)

            guard !text.isEmpty else {
                AppLog.quote.error("[Quote] On-device model returned empty text")
                return nil
            }

            return Quote(text: text, author: nil, source: .onDeviceAI)
        } catch {
            AppLog.quote.error(
                "[Quote] On-device generation failed: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
}
