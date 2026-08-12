//
//  AppDelegate.swift
//  QuoteBar
//
//  Owns the menu bar controller and makes sure pending changes reach disk
//  before the process goes away.
//

import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarController: MenuBarController?
    private let observers = ObserverBag()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLog.app.info("[App] Launching")

        // Accessory app: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)

        let environment = AppEnvironment.shared
        menuBarController = MenuBarController(
            tracker: environment.tracker,
            settings: environment.settings,
            launchAtLogin: environment.launchAtLogin,
            hotKeyService: environment.hotKeyService,
            notificationService: environment.notificationService,
            customQuoteLibrary: environment.customQuoteLibrary
        )
        menuBarController?.install()

        environment.hotKeyService.start { [weak menuBarController] in
            menuBarController?.triggerFromGlobalHotKey()
        }
        environment.hotKeyService.updateCombination(environment.settings.hotKeyCombination)

        UNUserNotificationCenter.current().delegate = self
        Task {
            await environment.notificationService.apply(
                enabled: environment.settings.notificationsEnabled,
                time: environment.settings.notificationTime
            )
        }

        // Show a first quote immediately so the popover is never empty on
        // first open.
        if environment.tracker.currentQuote == nil {
            Task { await environment.tracker.requestNewQuote() }
        }

        observeSleep()

        AppLog.app.info("[App] Ready")
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppLog.app.info("[App] Terminating — flushing pending changes")
        AppEnvironment.shared.tracker.flush()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Durability

    private func observeSleep() {
        observers.observe(
            NSWorkspace.willSleepNotification,
            on: NSWorkspace.shared.notificationCenter
        ) { _ in
            MainActor.assumeIsolated {
                AppLog.app.debug("[App] Sleeping — flushing pending changes")
                AppEnvironment.shared.tracker.flush()
            }
        }

        observers.observe(
            NSWorkspace.sessionDidResignActiveNotification,
            on: NSWorkspace.shared.notificationCenter
        ) { _ in
            MainActor.assumeIsolated {
                AppEnvironment.shared.tracker.flush()
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

// `UNUserNotificationCenterDelegate`'s methods aren't `@MainActor` and their
// parameters (`UNUserNotificationCenter`, `UNNotification`,
// `UNNotificationResponse`) aren't `Sendable`, so a `@MainActor`-isolated
// implementation can't accept them directly under Swift 6's strict
// concurrency checking — confirmed by a real CI build failure, not a
// hypothetical. `nonisolated` on each method avoids the isolation crossing;
// `MainActor.run` hops back in only for the main-actor state each one needs.
extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Shows the banner and plays the sound even while QuoteBar happens to
    /// be frontmost — an accessory app rarely is, but a silently-swallowed
    /// notification would violate "never fail silently" if it ever is.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// Fired when the user taps the daily quote notification. Same outcome
    /// as the global "New Quote" shortcut: open the popover, then fetch a
    /// fresh quote through the existing provider chain.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        AppLog.notifications.info("[Notifications] Tapped daily quote notification")
        await MainActor.run {
            self.menuBarController?.triggerFromGlobalHotKey()
        }
    }
}
