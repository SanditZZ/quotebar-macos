//
//  QuoteBarApp.swift
//  QuoteBar
//
//  Menu bar only: the app is an accessory (`LSUIElement`) with no Dock icon and
//  no default window. All presentation is driven from `AppDelegate`.
//

import SwiftUI

@main
struct QuoteBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Provides the standard ⌘, Settings integration. The window it shows
        // is the same one WindowCoordinator manages from the status item menu.
        Settings {
            SettingsView(
                tracker: AppEnvironment.shared.tracker,
                settings: AppEnvironment.shared.settings,
                launchAtLogin: AppEnvironment.shared.launchAtLogin,
                hotKeyService: AppEnvironment.shared.hotKeyService,
                notificationService: AppEnvironment.shared.notificationService,
                customQuoteLibrary: AppEnvironment.shared.customQuoteLibrary,
                tagLibrary: AppEnvironment.shared.tagLibrary,
                backupService: AppEnvironment.shared.backupService
            )
        }
    }
}
