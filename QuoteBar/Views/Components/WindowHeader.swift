//
//  WindowHeader.swift
//  QuoteBar — Views
//
//  The header strip that replaces the system title bar on a borderless window:
//  custom traffic lights on the left, the window title centred.
//
//  The traffic lights act on the window that actually contains them, resolved
//  through `WindowAccessor`, rather than on `NSApp.keyWindow`. macOS lets you
//  click a background window's close button directly, so keying off the app's
//  focused window would close the wrong one whenever History and Settings are
//  both open.
//

import AppKit
import SwiftUI

struct WindowHeader: View {
    let title: String

    @State private var window: NSWindow?

    var body: some View {
        ZStack {
            Text(title)
                .font(DesignTokens.Typography.sectionTitle)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: DesignTokens.Layout.trafficLightSpacing) {
                TrafficLightButton(kind: .close, window: window)
                TrafficLightButton(kind: .miniaturize, window: window)
                Spacer()
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .frame(height: DesignTokens.Layout.windowHeaderHeight)
        .frame(maxWidth: .infinity)
        .background(WindowAccessor { window = $0 })
    }
}

/// One custom traffic light.
struct TrafficLightButton: View {

    enum Kind {
        case close
        case miniaturize

        var tint: Color {
            switch self {
            case .close: return AppColors.trafficLightClose
            case .miniaturize: return AppColors.trafficLightMiniaturize
            }
        }

        var glyph: String {
            switch self {
            case .close: return "xmark"
            case .miniaturize: return "minus"
            }
        }

        var label: String {
            switch self {
            case .close: return "Close"
            case .miniaturize: return "Minimize"
            }
        }
    }

    let kind: Kind
    var window: NSWindow?

    @State private var isHovered = false
    @Environment(\.controlActiveState) private var controlActiveState

    /// The system dims traffic lights on an inactive window; matching that is
    /// what keeps these from looking like a foreign control.
    private var isActive: Bool { controlActiveState == .key }

    var body: some View {
        Button(action: perform) {
            Circle()
                .fill(isActive ? kind.tint : AppColors.trafficLightInactive)
                .frame(
                    width: DesignTokens.Layout.trafficLightDiameter,
                    height: DesignTokens.Layout.trafficLightDiameter
                )
                .overlay {
                    if isHovered && isActive {
                        Image(systemName: kind.glyph)
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(AppColors.trafficLightGlyph)
                    }
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(kind.label)
        .accessibilityLabel(kind.label)
    }

    private func perform() {
        guard let window else { return }
        switch kind {
        case .close: window.close()
        case .miniaturize: window.miniaturize(nil)
        }
    }
}

/// Reports the `NSWindow` hosting this part of the SwiftUI tree.
///
/// `view.window` is nil until the view is in a window, so the lookup is
/// deferred to the next runloop pass rather than read during `makeNSView`.
private struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { onResolve(nsView.window) }
    }
}
