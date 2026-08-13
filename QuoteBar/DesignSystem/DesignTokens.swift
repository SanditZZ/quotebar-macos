//
//  DesignTokens.swift
//  QuoteBar — Centralized Design System
//
//  Single source of truth for typography, spacing, radii and layout sizing.
//  Views must never hardcode these values; add a token here instead so the
//  whole app restyles from one place.
//

import SwiftUI

/// Centralized design tokens for all QuoteBar UI.
enum DesignTokens {

    // MARK: - Typography

    enum Typography {
        /// The quote itself — the largest, most prominent text in the popover.
        static let quote = Font.system(size: 17, weight: .medium, design: .serif)

        /// A shorter quote gets rendered slightly larger; see `QuoteCardView`.
        static let quoteLarge = Font.system(size: 20, weight: .medium, design: .serif)

        /// The author line beneath a quote.
        static let author = Font.system(size: 13, weight: .semibold)

        /// Main page / window title (18px, semibold).
        static let pageTitle = Font.system(size: 18, weight: .semibold)

        /// Page subtitle (13px, regular).
        static let pageSubtitle = Font.system(size: 13)

        /// Section header, e.g. "History" (13px, medium).
        static let sectionTitle = Font.system(size: 13, weight: .medium)

        /// Section subtitle (12px, regular).
        static let sectionSubtitle = Font.system(size: 12)

        /// Body text (12px).
        static let body = Font.system(size: 12)

        /// Emphasised body text (13px, medium).
        static let bodyMedium = Font.system(size: 13, weight: .medium)

        /// Helper text and captions (11px).
        static let caption = Font.system(size: 11)

        /// Very small labels, e.g. the source badge (9px, semibold, uppercase).
        static let tiny = Font.system(size: 9, weight: .semibold)

        /// Uppercase label above a statistic (10px, semibold).
        static let statLabel = Font.system(size: 10, weight: .semibold)

        /// The quote text on an exported share image — large, since the
        /// canvas is a fixed 1080×1080 rather than the narrow popover.
        static let shareQuote = Font.system(size: 44, weight: .medium, design: .serif)

        /// The author line on an exported share image.
        static let shareAuthor = Font.system(size: 22, weight: .semibold)

        /// The "QuoteBar" watermark on an exported share image.
        static let shareWatermark = Font.system(size: 15, weight: .semibold)
    }

    // MARK: - Spacing

    enum Spacing {
        /// Gap between major sections (24px).
        static let section: CGFloat = 24

        /// Padding inside a card (16px).
        static let cardPadding: CGFloat = 16

        /// Standard padding (12px).
        static let medium: CGFloat = 12

        /// Tight padding (8px).
        static let small: CGFloat = 8

        /// Hairline padding (4px).
        static let extraSmall: CGFloat = 4

        /// Gap between an icon and its label (10px).
        static let iconText: CGFloat = 10

        /// Fixed width reserved for a leading icon (20px).
        static let iconFrame: CGFloat = 20

        /// Outer padding of the popover (16px).
        static let popoverPadding: CGFloat = 16

        /// Outer padding of an exported share image — roughly 9.5% of the
        /// canvas, matched to the design mockup reviewed before building this.
        static let sharePadding: CGFloat = 104
    }

    // MARK: - Corner Radius

    enum Radius {
        /// The quote card (14px) — generously rounded, the popover's focal point.
        static let quoteCard: CGFloat = 14

        /// Card radius (8px).
        static let card: CGFloat = 8

        /// Small radius (6px).
        static let small: CGFloat = 6

        /// Hairline radius (4px), used by the source badge pill.
        static let tiny: CGFloat = 4

        /// Fully rounded pill.
        static let pill: CGFloat = 999
    }

    // MARK: - Icons

    enum Icons {
        /// Standard icon size (14px).
        static let standard: CGFloat = 14

        /// Small icon size (12px).
        static let small: CGFloat = 12

        /// Tiny icon size (10px).
        static let tiny: CGFloat = 10
    }

    // MARK: - Layout

    enum Layout {
        /// Popover content width. Kept narrow so the popover reads as a HUD.
        static let popoverWidth: CGFloat = 300

        /// Minimum height of the quote card, so short quotes don't collapse the
        /// popover into a jarringly different size than long ones.
        static let quoteCardMinHeight: CGFloat = 120

        /// Hit target for one of the popover's footer actions. They are
        /// icon-only — five labelled buttons cannot fit `popoverWidth`, and
        /// letting them try wrapped every caption down to one or two
        /// characters per line — so the frame, not the glyph, has to provide a
        /// comfortable click area. Each button carries a tooltip and an
        /// accessibility label in place of the visible caption.
        static let footerButtonSize = CGSize(width: 30, height: 24)

        /// Size the History window opens at.
        static let historyWindowSize = CGSize(width: 480, height: 480)

        /// Smallest useful History window.
        static let historyWindowMinSize = CGSize(width: 400, height: 320)

        /// Size the Settings window opens at. Wider than the old single-column
        /// layout because the sidebar now takes `settingsSidebarWidth` before
        /// the content column starts.
        static let settingsWindowSize = CGSize(width: 660, height: 560)

        /// Smallest Settings window. The content scrolls below this. Anyone
        /// carrying a saved frame from the pre-sidebar layout gets clamped up
        /// to this on restore, since `contentMinSize` is applied before the
        /// autosave name.
        static let settingsWindowMinSize = CGSize(width: 560, height: 420)

        /// Fixed square canvas for an exported share image — works for every
        /// share destination (Messages, AirDrop, Save Image, posted anywhere)
        /// without letterboxing.
        static let shareImageSize = CGSize(width: 1080, height: 1080)

        /// Corner radius of a borderless window. Applied to the content view's
        /// layer, since a borderless window has no system frame to round.
        static let windowCornerRadius: CGFloat = 10

        /// Diameter of one custom traffic light. Matches the system's own.
        static let trafficLightDiameter: CGFloat = 12

        /// Gap between traffic lights. Matches the system's own.
        static let trafficLightSpacing: CGFloat = 8

        /// Height of a borderless window's own header strip, which replaces the
        /// system title bar and carries the traffic lights and the title.
        static let windowHeaderHeight: CGFloat = 38

        /// Width of the Settings sidebar. Wide enough for the longest tab name
        /// at `sectionTitle` size without truncating.
        static let settingsSidebarWidth: CGFloat = 148

        /// Height of one sidebar tab row.
        static let sidebarRowHeight: CGFloat = 30
    }

    // MARK: - Vibrancy

    /// Tint strengths layered over the window's vibrancy material. The material
    /// alone samples whatever is behind the window, so contrast would otherwise
    /// depend on the user's wallpaper. A tint on top bounds it, and the two
    /// planes differ so the sidebar reads as recessed from the content.
    enum Vibrancy {
        /// Tint over the main content area.
        static let contentTintDark: CGFloat = 0.35
        static let contentTintLight: CGFloat = 0.40

        /// Tint over the sidebar — heavier, so it separates from the content.
        static let sidebarTintDark: CGFloat = 0.55
        static let sidebarTintLight: CGFloat = 0.50
    }

    // MARK: - Animation

    enum Motion {
        /// Transition when a new quote replaces the current one.
        static let quoteChange = Animation.easeOut(duration: 0.22)

        /// Spring used for the "New Quote" button's press feedback.
        static let buttonPress = Animation.spring(response: 0.18, dampingFraction: 0.55)

        /// Scale applied to the button while pressed.
        static let buttonPressedScale: CGFloat = 0.96
    }
}
