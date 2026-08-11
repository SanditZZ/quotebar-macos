//
//  SettingsView.swift
//  QuoteBar — Views
//
//  Preferences, data management, and About. Sections share one width, per
//  this project's design conventions (see idle-tapper-macos's UI review).
//

import SwiftUI

struct SettingsView: View {
    var tracker: QuoteTracker
    var settings: AppSettings
    var launchAtLogin: LaunchAtLoginService

    @State private var showingClearConfirmation = false

    private static let sectionWidth: CGFloat = 400

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                generalSection
                dataSection
                aboutSection
            }
            .padding(DesignTokens.Spacing.popoverPadding)
            .frame(width: Self.sectionWidth)
        }
        .onAppear { launchAtLogin.refresh() }
    }

    // MARK: - General

    private var generalSection: some View {
        section(title: "General") {
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))
            .toggleStyle(.switch)

            if let message = launchAtLogin.lastErrorMessage {
                Text(message)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        section(title: "Data") {
            let stats = tracker.stats

            HStack {
                Text("Quotes stored")
                Spacer()
                Text("\(stats.totalSeen)")
                    .foregroundStyle(AppColors.textSecondary)
            }
            .font(DesignTokens.Typography.body)

            if tracker.isEphemeral {
                Label("The database couldn't be opened, so nothing is being saved.", systemImage: "exclamationmark.triangle")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            }

            Toggle("Confirm before clearing history", isOn: Binding(
                get: { settings.confirmBeforeClearHistory },
                set: { settings.confirmBeforeClearHistory = $0 }
            ))
            .toggleStyle(.checkbox)

            Button("Clear History…", role: .destructive) {
                if settings.confirmBeforeClearHistory {
                    showingClearConfirmation = true
                } else {
                    tracker.clearHistory()
                }
            }
            .confirmationDialog(
                "Clear all quote history?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) { tracker.clearHistory() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes every saved quote and favorite. This cannot be undone.")
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        section(title: "About") {
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

    private static var versionString: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(version) (\(build))"
    }

    // MARK: - Section Helper

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(title)
                .font(DesignTokens.Typography.sectionTitle)
                .foregroundStyle(AppColors.textSecondary)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        }
    }
}

#Preview {
    SettingsView(
        tracker: QuoteTracker(
            repository: SwiftDataQuoteRepository(container: try! ModelContainerFactory.makeInMemory()),
            provider: QuoteProviderService(),
            isEphemeral: false
        ),
        settings: AppSettings(defaults: UserDefaults(suiteName: "preview")!),
        launchAtLogin: LaunchAtLoginService()
    )
}
