//
//  UpdatesSettingsTab.swift
//  QuoteBar — Views
//
//  Whether QuoteBar checks for new versions, and what the last check found.
//
//  These controls started at the bottom of General, below Notifications, where
//  they read as an afterthought to the daily reminder. Updating is how every
//  later version reaches anyone, so it gets its own tab rather than the last
//  section of an unrelated one.
//

import SwiftUI

struct UpdatesSettingsTab: View {
    var updateService: UpdateService

    var body: some View {
        SettingsTabScroll {
            updatesSection
        }
    }

    private var updatesSection: some View {
        SettingsSection("Updates") {
            SettingToggle(
                "Check for updates automatically",
                description: "Looks for a new version once a day in the background.",
                isOn: automaticUpdatesBinding
            )

            HStack {
                Text(UpdateStatusFormatter.lastCheckedDescription(lastCheck: updateService.lastCheckDate))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textTertiary)

                Spacer(minLength: DesignTokens.Spacing.medium)

                Button("Check Now") { updateService.checkForUpdates() }
                    .disabled(!updateService.canCheck)
            }

            if let message = UpdateStatusFormatter.message(for: updateService.lastOutcome) {
                Text(message)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(
                        UpdateStatusFormatter.isWarning(updateService.lastOutcome)
                            ? AppColors.warning
                            : AppColors.textTertiary
                    )
            }

            // Shown whatever the check reported: an app running from a disk
            // image or Downloads updates the copy sitting there, which looks
            // like updates silently never arriving.
            if let message = updateService.installLocationWarning {
                Text(message)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Sparkle owns this preference — it persists the value itself and reads it
    /// on its own schedule — so the binding writes through to the service
    /// rather than storing a copy in `AppSettings` that could drift out of step.
    private var automaticUpdatesBinding: Binding<Bool> {
        Binding(
            get: { updateService.automaticallyChecks },
            set: { updateService.automaticallyChecks = $0 }
        )
    }
}
