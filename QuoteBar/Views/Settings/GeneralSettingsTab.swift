//
//  GeneralSettingsTab.swift
//  QuoteBar — Views
//
//  Launch behaviour, the global shortcut, the daily notification, and updates.
//

import SwiftUI

struct GeneralSettingsTab: View {
    var settings: AppSettings
    var launchAtLogin: LaunchAtLoginService
    var hotKeyService: GlobalHotKeyService
    var notificationService: QuoteNotificationService
    var updateService: UpdateService

    var body: some View {
        SettingsTabScroll {
            generalSection
            shortcutSection
            notificationsSection
            updatesSection
        }
        .onAppear {
            launchAtLogin.refresh()
            Task { await notificationService.refreshAuthorizationStatus() }
        }
        .onChange(of: settings.hotKeyCombination) { _, newValue in
            hotKeyService.updateCombination(newValue)
        }
        .onChange(of: settings.notificationTime) { _, newValue in
            guard settings.notificationsEnabled else { return }
            Task { await notificationService.apply(enabled: true, time: newValue) }
        }
    }

    // MARK: - General

    private var generalSection: some View {
        SettingsSection("General") {
            SettingToggle(
                "Launch at login",
                description: "Start QuoteBar automatically when you log in.",
                isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setEnabled($0) }
                )
            )

            if let message = launchAtLogin.lastErrorMessage {
                Text(message)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            }
        }
    }

    // MARK: - Shortcut

    private var shortcutSection: some View {
        SettingsSection("Shortcut") {
            HStack {
                Text("New Quote")
                Spacer()
                ShortcutRecorderField(combination: hotKeyBinding)
            }
            .font(DesignTokens.Typography.body)

            Text("Works system-wide, even while QuoteBar isn't in front. Opens the popover and fetches a new quote.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private var hotKeyBinding: Binding<HotKeyCombination?> {
        Binding(
            get: { settings.hotKeyCombination },
            set: { settings.hotKeyCombination = $0 }
        )
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        SettingsSection("Notifications") {
            SettingToggle("Quote of the Day", isOn: notificationsEnabledBinding)

            DatePicker("Time", selection: notificationTimeBinding, displayedComponents: .hourAndMinute)
                .disabled(!settings.notificationsEnabled)
                .font(DesignTokens.Typography.body)

            if let message = notificationService.lastErrorMessage {
                Text(message)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            } else {
                Text("A daily reminder that opens the popover and fetches a fresh quote when tapped.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    /// Reflects both the user's stored intent and whatever the OS actually
    /// granted — if authorization was denied, the toggle shows off even
    /// though `settings.notificationsEnabled` is still `true`, rather than
    /// showing on for a notification that will never fire.
    private var notificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled && notificationService.lastErrorMessage == nil },
            set: { newValue in
                settings.notificationsEnabled = newValue
                Task { await notificationService.apply(enabled: newValue, time: settings.notificationTime) }
            }
        )
    }

    private var notificationTimeBinding: Binding<Date> {
        Binding(
            get: { NotificationTimeConversion.date(from: settings.notificationTime) },
            set: { settings.notificationTime = NotificationTimeConversion.time(from: $0) }
        )
    }

    // MARK: - Updates

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
