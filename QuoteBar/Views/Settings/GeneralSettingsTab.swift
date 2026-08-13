//
//  GeneralSettingsTab.swift
//  QuoteBar — Views
//
//  Launch behaviour, the global shortcut, and the daily notification.
//
//  Updates used to be a fourth section here. It now has its own tab, since
//  updating is not a general preference and being last under Notifications hid
//  it.
//

import SwiftUI

struct GeneralSettingsTab: View {
    var settings: AppSettings
    var launchAtLogin: LaunchAtLoginService
    var hotKeyService: GlobalHotKeyService
    var notificationService: QuoteNotificationService

    var body: some View {
        SettingsTabScroll {
            generalSection
            shortcutSection
            notificationsSection
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
}
