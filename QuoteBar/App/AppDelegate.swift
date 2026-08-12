//
//  AppDelegate.swift
//  QuoteBar
//
//  Owns the menu bar controller and makes sure pending changes reach disk
//  before the process goes away.
//

import AppKit
import SwiftUI

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
            customQuoteLibrary: environment.customQuoteLibrary
        )
        menuBarController?.install()

        environment.hotKeyService.start { [weak menuBarController] in
            menuBarController?.triggerFromGlobalHotKey()
        }
        environment.hotKeyService.updateCombination(environment.settings.hotKeyCombination)

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
