//
//  StatusItemRenderer.swift
//  QuoteBar — Menu bar presentation
//
//  Pure formatting for the status item, kept out of the controller so it can
//  be reasoned about on its own. Unlike idle-tapper-macos's status item,
//  QuoteBar's has no counter to render — it's icon-only — so this is much
//  smaller than its sibling.
//

import AppKit

enum StatusItemRenderer {

    /// SF Symbol used as the menu bar icon.
    static let symbolName = "quote.bubble.fill"

    /// Accessibility description for the icon.
    static let symbolDescription = "QuoteBar"

    /// The icon image, template-rendered so macOS can invert it for light/dark
    /// menu bars and the "reduce transparency" appearance.
    static var image: NSImage? {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: symbolDescription)
        image?.isTemplate = true
        return image
    }
}
