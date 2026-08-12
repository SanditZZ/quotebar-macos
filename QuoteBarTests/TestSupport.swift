//
//  TestSupport.swift
//  QuoteBarTests
//
//  Shared fixtures.
//

import Foundation
@testable import QuoteBar

enum TestSupport {

    /// A fixed reference date so tests never depend on when the suite runs.
    static var referenceDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 15
        components.hour = 12
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: components)!
    }

    static func quote(
        text: String,
        author: String? = "Test Author",
        source: QuoteSource = .bundled
    ) -> Quote {
        Quote(text: text, author: author, source: source)
    }

    static func snapshot(
        text: String,
        author: String? = "Test Author",
        source: QuoteSource = .bundled,
        seenAt: Date = referenceDate,
        isFavorite: Bool = false,
        tags: [TagSnapshot] = []
    ) -> QuoteSnapshot {
        QuoteSnapshot(
            id: UUID(),
            text: text,
            author: author,
            source: source,
            seenAt: seenAt,
            isFavorite: isFavorite,
            tags: tags
        )
    }

    static func customQuoteSnapshot(
        text: String,
        author: String? = "Test Author",
        addedAt: Date = referenceDate
    ) -> CustomQuoteSnapshot {
        CustomQuoteSnapshot(id: UUID(), text: text, author: author, addedAt: addedAt)
    }

    static func tag(name: String, createdAt: Date = referenceDate) -> TagSnapshot {
        TagSnapshot(id: UUID(), name: name, createdAt: createdAt)
    }
}
