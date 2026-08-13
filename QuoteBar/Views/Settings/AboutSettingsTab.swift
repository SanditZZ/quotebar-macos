//
//  AboutSettingsTab.swift
//  QuoteBar — Views
//
//  Version, source, and the privacy statement.
//

import SwiftUI

struct AboutSettingsTab: View {

    var body: some View {
        SettingsTabScroll {
            SettingsSection("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Self.versionString)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .font(DesignTokens.Typography.body)

                Link("View on GitHub", destination: URL(string: "https://github.com/SanditZZ/quotebar-macos")!)
                    .font(DesignTokens.Typography.body)

                Text("MIT licensed. No accounts, no analytics, no tracking beyond the two quote APIs described in SECURITY.md.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private static var versionString: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(version) (\(build))"
    }
}
