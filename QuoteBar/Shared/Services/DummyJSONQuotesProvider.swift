//
//  DummyJSONQuotesProvider.swift
//  QuoteBar — Actions
//
//  Tier 3 of the provider chain: https://dummyjson.com — free, keyless, no
//  setup. Tried only if ZenQuotes fails. Verified live and responding
//  2026-08-12:
//    curl https://dummyjson.com/quotes/random
//    → {"id":42,"quote":"...","author":"..."}
//

import Foundation

struct DummyJSONQuotesProvider: QuoteProvider {
    let source = QuoteSource.dummyJSON

    private let session: URLSession
    private let timeout: TimeInterval

    init(session: URLSession = .shared, timeout: TimeInterval = 6) {
        self.session = session
        self.timeout = timeout
    }

    private struct Response: Decodable {
        let quote: String
        let author: String?
    }

    func nextQuote() async -> Quote? {
        var request = URLRequest(url: URL(string: "https://dummyjson.com/quotes/random")!)
        request.timeoutInterval = timeout

        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                AppLog.network.error("[Network] DummyJSON returned a non-2xx status")
                return nil
            }

            let decoded = try JSONDecoder().decode(Response.self, from: data)
            let text = QuoteTextFormatter.normalize(decoded.quote)
            guard !text.isEmpty else { return nil }

            return Quote(text: text, author: decoded.author, source: .dummyJSON)
        } catch {
            AppLog.network.error(
                "[Network] DummyJSON request failed: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
}
