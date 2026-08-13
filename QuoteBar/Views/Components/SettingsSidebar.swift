//
//  SettingsSidebar.swift
//  QuoteBar — Views
//
//  Tab list down the left of the Settings window. Settings used to be a single
//  scrolling column of eleven sections, which buried Backup and About at the
//  bottom where nobody found them.
//
//  The sidebar also carries the window's traffic lights. That looks like a
//  layering mistake and is not: a full-width header strip above the content
//  would push the sidebar down, leaving a band across the top of the window
//  with the sidebar boxed in beneath it. Putting the controls inside the
//  sidebar is what lets it run the full height of the window.
//

import AppKit
import SwiftUI

/// The Settings tabs, in sidebar order.
enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case quotes
    case sharing
    case data
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .quotes: return "Quotes"
        case .sharing: return "Sharing"
        case .data: return "Data"
        case .about: return "About"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .quotes: return "quote.bubble"
        case .sharing: return "square.and.arrow.up"
        case .data: return "externaldrive"
        case .about: return "info.circle"
        }
    }
}

struct SettingsSidebar: View {
    @Binding var selection: SettingsTab

    @State private var window: NSWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
            windowControls

            ForEach(SettingsTab.allCases) { tab in
                SettingsSidebarRow(
                    tab: tab,
                    isSelected: tab == selection,
                    select: { selection = tab }
                )
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.small)
        .frame(width: DesignTokens.Layout.settingsSidebarWidth)
        .frame(maxHeight: .infinity)
        .vibrantBackground(.sidebar)
        .background(SettingsWindowAccessor { window = $0 })
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Settings categories")
    }

    /// Close and minimise, sitting where the system's own controls would.
    private var windowControls: some View {
        HStack(spacing: DesignTokens.Layout.trafficLightSpacing) {
            TrafficLightButton(kind: .close, window: window)
            TrafficLightButton(kind: .miniaturize, window: window)
            Spacer(minLength: 0)
        }
        .padding(.leading, DesignTokens.Spacing.extraSmall)
        .frame(height: DesignTokens.Layout.windowHeaderHeight)
    }
}

/// Reports the `NSWindow` hosting the sidebar.
///
/// The traffic lights have to act on the window that contains them rather than
/// on `NSApp.keyWindow`: macOS lets you click a background window's close
/// button directly, so keying off the focused window would close the wrong one
/// whenever History and Settings are both open.
private struct SettingsWindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // `view.window` is nil until the view is in a window, so the lookup is
        // deferred rather than read during `makeNSView`.
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { onResolve(nsView.window) }
    }
}

private struct SettingsSidebarRow: View {
    let tab: SettingsTab
    let isSelected: Bool
    let select: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: select) {
            HStack(spacing: DesignTokens.Spacing.small) {
                Image(systemName: tab.icon)
                    .font(.system(size: DesignTokens.Icons.standard))
                    .frame(width: DesignTokens.Spacing.iconFrame)

                Text(tab.title)
                    .font(DesignTokens.Typography.bodyMedium)

                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? AppColors.accent : AppColors.textSecondary)
            .padding(.horizontal, DesignTokens.Spacing.small)
            .frame(height: DesignTokens.Layout.sidebarRowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                    .fill(background)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var background: Color {
        if isSelected { return AppColors.sidebarSelection }
        return isHovered ? AppColors.sidebarHover : .clear
    }
}
