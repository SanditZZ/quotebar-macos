//
//  ZenQuotesProvider.swift
//  QuoteBar — Actions
//
//  Tier 2 of the provider chain: https://zenquotes.io — free, keyless, no
//  setup. Verified live and responding 2026-08-12:
//    curl https://zenquotes.io/api/random
//    → [{"q":"...","a":"Author Name","h":"<blockquote>...</blockquote>"}]
//
//  ZenQuotes rate-limits by IP (a handful of requests per period); a 429 or
//  any other failure is treated the same as "unavailable" and falls through
//  to the next tier.
//

import Foundation

struct ZenQuotesProvider: QuoteProvider {
    let source = QuoteSource.zenQuotes

    private let session: URLSession
    private let timeout: TimeInterval

    init(session: URLSession = .shared, timeout: TimeInterval = 6) {
        self.session = session
        self.timeout = timeout
    }

    private struct Entry: Decodable {
        let q: String
        let a: String?
    }

    func nextQuote() async -> Quote? {
        var request = URLRequest(url: URL(string: "https://zenquotes.io/api/random")!)
        request.timeoutInterval = timeout

        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                AppLog.network.error("[Network] ZenQuotes returned a non-2xx status")
                return nil
            }

            let entries = try JSONDecoder().decode([Entry].self, from: data)
            guard let entry = entries.first else {
                AppLog.network.error("[Network] ZenQuotes returned an empty array")
                return nil
            }

            let text = QuoteTextFormatter.normalize(entry.q)
            guard !text.isEmpty else { return nil }

            return Quote(text: text, author: entry.a, source: .zenQuotes)
        } catch {
            AppLog.network.error(
                "[Network] ZenQuotes request failed: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
}
