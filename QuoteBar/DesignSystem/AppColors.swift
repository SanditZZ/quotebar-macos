//
//  AppColors.swift
//  QuoteBar — Semantic color palette
//
//  All colors are translucent or appearance-adaptive so they sit correctly on
//  the popover's vibrancy material in both light and dark mode. Ported from
//  this project's sibling, idle-tapper-macos, which tuned these values
//  against real screenshots — see the comments below for why each one is
//  shaped the way it is.
//

import SwiftUI
import AppKit

/// Semantic colors used across the app. Views reference these names, never raw
/// literals, so a palette change lands in one place.
enum AppColors {

    // MARK: - Surfaces

    /// Surface sitting behind the popover's content. Bounded translucency so
    /// contrast is a property of the design rather than of whatever window
    /// happens to be behind the popover.
    static let popoverSurface = Color.adaptivePopoverSurface

    /// Card background — translucent so vibrancy shows through.
    static let cardBackground = Color.primary.opacity(0.04)

    /// Card border — deliberately subtle.
    static let cardBorder = Color.primary.opacity(0.08)

    /// The quote card's background — a touch stronger than an ordinary card,
    /// since it is the popover's sole focal point.
    static let quoteCardBackground = Color.primary.opacity(0.05)

    // MARK: - Brand

    /// Primary action color, driven by the asset catalog accent color.
    static let accent = Color.accentColor

    /// The accent, adjusted so it can be used as text. See `AppColors.textSecondary`
    /// for why a plain opacity of `Color.secondary` is not used instead.
    static let accentOnText = Color.adaptiveAccentText

    // MARK: - Source Badges

    /// Badge tint for a quote generated on-device by Apple's Foundation Models.
    static let sourceAI = Color.purple

    /// Badge tint for a quote fetched from a network API.
    static let sourceNetwork = Color.adaptiveGreen

    /// Badge tint for a quote served from the bundled offline set.
    static let sourceBundled = Color.adaptiveTextSecondary

    /// Badge tint for a quote from the user's own custom/imported library.
    static let sourceCustom = Color.pink

    // MARK: - Status

    /// Success / positive state.
    static let success = Color.adaptiveGreen

    /// Error state.
    static let error = Color.red

    /// Warning state.
    static let warning = Color.orange

    /// Informational state.
    static let info = Color.blue

    // MARK: - Text

    /// Primary text.
    static let textPrimary = Color.primary

    /// Secondary / supporting text. Deliberately *not* `Color.secondary`, which
    /// measured only 3.0:1 in light mode against these surfaces.
    static let textSecondary = Color.adaptiveTextSecondary

    /// Tertiary text, e.g. timestamps and captions.
    static let textTertiary = Color.adaptiveTextTertiary

    // MARK: - Helpers

    /// A translucent tint of any color, for badge backgrounds and soft fills.
    static func tint(_ color: Color, opacity: Double = 0.14) -> Color {
        color.opacity(opacity)
    }
}

// MARK: - Adaptive Colors

extension Color {
    /// Green with good contrast in both appearances. The system green is too
    /// light to read against light translucent surfaces, so light mode uses a
    /// darker forest green.
    static let adaptiveGreen = Color(nsColor: .adaptiveGreen)

    /// See `AppColors.accentOnText`.
    static let adaptiveAccentText = Color(nsColor: .adaptiveAccentText)

    /// See `AppColors.textSecondary`.
    static let adaptiveTextSecondary = Color(nsColor: .adaptiveTextSecondary)

    /// See `AppColors.textTertiary`.
    static let adaptiveTextTertiary = Color(nsColor: .adaptiveTextTertiary)

    /// See `AppColors.popoverSurface`.
    static let adaptivePopoverSurface = Color(nsColor: .adaptivePopoverSurface)
}

extension NSColor {
    /// See `Color.adaptiveGreen`.
    static let adaptiveGreen = NSColor(name: nil) { appearance in
        appearance.isDark
            ? NSColor(srgbRed: 60 / 255, green: 199 / 255, blue: 95 / 255, alpha: 1.0)
            : NSColor(srgbRed: 27 / 255, green: 107 / 255, blue: 52 / 255, alpha: 1.0)
    }

    /// See `AppColors.accentOnText`.
    static let adaptiveAccentText = NSColor(name: nil) { appearance in
        appearance.isDark
            ? NSColor(srgbRed: 90 / 255, green: 150 / 255, blue: 255 / 255, alpha: 1.0)
            : NSColor(srgbRed: 24 / 255, green: 64 / 255, blue: 190 / 255, alpha: 1.0)
    }

    /// See `AppColors.textSecondary` and `AppColors.textTertiary`.
    static let adaptiveTextSecondary = NSColor(name: nil) { appearance in
        appearance.isDark ? NSColor(white: 1.0, alpha: 0.78) : NSColor(white: 0.0, alpha: 0.88)
    }

    /// See `adaptiveTextSecondary`.
    static let adaptiveTextTertiary = NSColor(name: nil) { appearance in
        appearance.isDark ? NSColor(white: 1.0, alpha: 0.62) : NSColor(white: 0.0, alpha: 0.72)
    }

    /// See `AppColors.popoverSurface`.
    static let adaptivePopoverSurface = NSColor(name: nil) { appearance in
        appearance.isDark
            ? NSColor(white: 0.137, alpha: 0.92)
            : NSColor(white: 0.925, alpha: 0.92)
    }
}

extension NSAppearance {
    /// Whether this appearance is one of the dark ones.
    ///
    /// `bestMatch` rather than comparing `name` directly, because the popover
    /// and the windows report different appearance names for the same
    /// appearance — vibrant dark is still dark.
    var isDark: Bool {
        bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}
