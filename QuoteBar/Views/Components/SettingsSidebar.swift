//
//  SettingsSidebar.swift
//  QuoteBar — Views
//
//  Tab list down the left of the Settings window. Settings used to be a single
//  scrolling column of eleven sections, which buried Backup and About at the
//  bottom where nobody found them.
//

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

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Settings categories")
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
