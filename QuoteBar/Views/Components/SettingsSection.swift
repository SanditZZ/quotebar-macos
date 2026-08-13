//
//  SettingsSection.swift
//  QuoteBar — Views
//
//  A titled group of settings: a small caption above a card. Was a private
//  helper inside `SettingsView`; it became a component when the settings split
//  across tab views, which all need the identical treatment.
//

import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(title)
                .font(DesignTokens.Typography.sectionTitle)
                .foregroundStyle(AppColors.textSecondary)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        }
    }
}

/// The scrolling column every settings tab shares, so each tab file carries
/// only its own sections rather than repeating the padding and spacing.
struct SettingsTabScroll<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                content
            }
            .padding(DesignTokens.Spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
