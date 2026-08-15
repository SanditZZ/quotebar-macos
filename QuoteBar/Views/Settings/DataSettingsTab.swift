//
//  DataSettingsTab.swift
//  QuoteBar — Views
//
//  What is stored locally, clearing it, and backup export/import.
//

import SwiftUI

struct DataSettingsTab: View {
    var tracker: QuoteTracker
    var settings: AppSettings
    var backupService: QuoteBackupService

    @State private var showingClearConfirmation = false

    var body: some View {
        SettingsTabScroll {
            dataSection

            SettingsSection("Backup") {
                BackupExportImportView(backupService: backupService)
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        SettingsSection("Data") {
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

            SettingToggle(
                "Confirm before clearing history",
                description: "Ask first, so history cannot be wiped by a stray click.",
                isOn: Binding(
                    get: { settings.confirmBeforeClearHistory },
                    set: { settings.confirmBeforeClearHistory = $0 }
                )
            )

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
}
