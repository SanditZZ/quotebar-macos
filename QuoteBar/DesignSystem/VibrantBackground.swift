//
//  VibrantBackground.swift
//  QuoteBar — Design system
//
//  Full-bleed window vibrancy, used behind the History and Settings content.
//
//  Two notes on why this is an `NSViewRepresentable` rather than a window-level
//  background:
//
//  1. Keeping the whole view tree SwiftUI-managed avoids the opaque flash that
//     an AppKit background produces on deminiaturize or appearance change.
//  2. The material samples whatever sits behind the window, so contrast would
//     otherwise be a property of the user's wallpaper. A tint layered on top
//     bounds it, which is why this is a material *plus* a tint rather than a
//     bare `NSVisualEffectView`.
//

import AppKit
import SwiftUI

/// Which plane of the window a vibrancy background is filling. The sidebar is
/// tinted more heavily than the content so the two read as separate surfaces.
enum VibrancyPlane {
    case content
    case sidebar

    /// Tint alpha for the given appearance. Dark and light need different
    /// values: dark mode tints toward black, light mode toward white, and the
    /// material's own brightness differs between them.
    func tintAlpha(isDark: Bool) -> CGFloat {
        switch self {
        case .content:
            return isDark ? DesignTokens.Vibrancy.contentTintDark : DesignTokens.Vibrancy.contentTintLight
        case .sidebar:
            return isDark ? DesignTokens.Vibrancy.sidebarTintDark : DesignTokens.Vibrancy.sidebarTintLight
        }
    }
}

/// A vibrancy material with a bounded tint over it.
struct VibrantBackground: NSViewRepresentable {
    var plane: VibrancyPlane = .content

    func makeNSView(context: Context) -> NSView {
        VibrancyContainerView(plane: plane)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? VibrancyContainerView)?.apply(plane: plane)
    }
}

/// Owns the material and its tint.
///
/// This is a custom `NSView` rather than a plain container so it can override
/// `viewDidChangeEffectiveAppearance`. SwiftUI does not reliably call
/// `updateNSView` when the system switches between light and dark, so a tint
/// applied only from there gets stranded at the previous appearance's alpha.
private final class VibrancyContainerView: NSView {

    private let effectView = NSVisualEffectView()
    private let tintView = NSView()
    private var plane: VibrancyPlane

    init(plane: VibrancyPlane) {
        self.plane = plane
        super.init(frame: .zero)

        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.isEmphasized = true
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        tintView.wantsLayer = true
        tintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tintView)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tintView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tintView.topAnchor.constraint(equalTo: topAnchor),
            tintView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        refreshTint()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("VibrancyContainerView is created in code only")
    }

    func apply(plane: VibrancyPlane) {
        guard self.plane != plane else { return }
        self.plane = plane
        refreshTint()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshTint()
    }

    private func refreshTint() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let alpha = plane.tintAlpha(isDark: isDark)
        let base: NSColor = isDark ? .black : .white
        tintView.layer?.backgroundColor = base.withAlphaComponent(alpha).cgColor
    }
}

extension View {
    /// Fill this view's background with the window vibrancy material.
    func vibrantBackground(_ plane: VibrancyPlane = .content) -> some View {
        background(VibrantBackground(plane: plane).ignoresSafeArea())
    }
}
