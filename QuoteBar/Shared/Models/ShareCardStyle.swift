//
//  ShareCardStyle.swift
//  QuoteBar — Data
//
//  Which look the exported share-quote image uses. Plain enum, no logic —
//  see `Shared/Services/QuoteImageRenderer.swift` for the render itself and
//  `Views/Components/ShareableQuoteView.swift` for the layout. Both looks are
//  fixed-tone rather than system-appearance-adaptive: an exported image
//  travels outside the app, so it should look the same to whoever it's
//  shared with, not vary with the sharer's light/dark mode at the moment
//  they happened to export it.
//

import Foundation

enum ShareCardStyle: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Fixed dark navy card.
    case midnight

    /// Fixed warm, light card.
    case paper

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnight: return String(localized: "Midnight", comment: "Dark share card style")
        case .paper: return String(localized: "Paper", comment: "Light share card style")
        }
    }
}
