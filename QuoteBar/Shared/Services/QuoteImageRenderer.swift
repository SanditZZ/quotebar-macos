//
//  QuoteImageRenderer.swift
//  QuoteBar — Actions
//
//  Rendering a quote to a bitmap for sharing. Touches AppKit/SwiftUI's
//  rendering pipeline, so this is an action, not a calculation — the layout
//  it renders (`ShareableQuoteView`) is pure/presentational, but turning a
//  view into pixels is a side effect.
//

import SwiftUI

@MainActor
enum QuoteImageRenderer {

    /// Renders `quote` as a fixed `DesignTokens.Layout.shareImageSize` PNG,
    /// at retina scale. `nil` only if SwiftUI's renderer itself fails, which
    /// in practice means a bug in `ShareableQuoteView`, not a runtime
    /// condition — there's no user-facing recovery for that, so callers
    /// treat `nil` as "sharing isn't available right now" and no-op.
    static func renderImage(for quote: QuoteSnapshot, style: ShareCardStyle) -> NSImage? {
        let renderer = ImageRenderer(content: ShareableQuoteView(quote: quote, style: style))
        renderer.scale = 2
        return renderer.nsImage
    }
}
