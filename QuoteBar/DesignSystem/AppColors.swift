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

    // MARK: - Window Chrome

    /// Custom traffic lights on the borderless windows. These are fixed tones
    /// rather than adaptive ones on purpose: they reproduce the system's own
    /// button colors, which do not change between light and dark. Only the
    /// inactive state adapts, matching how macOS greys out a background
    /// window's controls.

    static let trafficLightClose = Color(red: 1.0, green: 0.38, blue: 0.34)
    static let trafficLightMiniaturize = Color(red: 1.0, green: 0.74, blue: 0.18)

    /// Traffic light on an inactive window.
    static let trafficLightInactive = Color.primary.opacity(0.15)

    /// The glyph revealed inside a traffic light on hover.
    static let trafficLightGlyph = Color.black.opacity(0.5)

    /// Background of the selected sidebar row.
    static let sidebarSelection = Color.accentColor.opacity(0.16)

    /// Background of a sidebar row under the pointer.
    static let sidebarHover = Color.primary.opacity(0.06)

    // MARK: - Helpers

    /// A translucent tint of any color, for badge backgrounds and soft fills.
    static func tint(_ color: Color, opacity: Double = 0.14) -> Color {
        color.opacity(opacity)
    }

    // MARK: - Share Card

    /// Fixed-tone colors for the exported share image — deliberately not
    /// appearance-adaptive, unlike everything else in this file. See
    /// `ShareCardStyle`'s doc comment for why.

    static let shareMidnightBackgroundTop = Color(red: 0.075, green: 0.102, blue: 0.169)
    static let shareMidnightBackgroundBottom = Color(red: 0.043, green: 0.059, blue: 0.102)
    static let shareMidnightText = Color(red: 0.953, green: 0.961, blue: 0.980)
    static let shareMidnightTextSecondary = Color(red: 0.953, green: 0.961, blue: 0.980).opacity(0.6)
    static let shareMidnightAccent = Color(red: 0.353, green: 0.588, blue: 1.0)

    static let sharePaperBackground = Color(red: 0.957, green: 0.941, blue: 0.910)
    static let sharePaperText = Color(red: 0.102, green: 0.110, blue: 0.122)
    static let sharePaperTextSecondary = Color(red: 0.102, green: 0.110, blue: 0.122).opacity(0.58)
    static let sharePaperAccent = Color(red: 0.196, green: 0.478, blue: 0.918)
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
