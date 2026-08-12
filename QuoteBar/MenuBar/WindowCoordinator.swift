//
//  WindowCoordinator.swift
//  QuoteBar — Window management
//
//  Creates and reuses the auxiliary windows. An accessory app has to activate
//  itself explicitly, otherwise its windows open behind whatever the user was
//  using. Mirrors idle-tapper-macos's `WindowCoordinator`.
//

import AppKit
import SwiftUI

@MainActor
final class WindowCoordinator {

    private let tracker: QuoteTracker
    private let settings: AppSettings
    private let launchAtLogin: LaunchAtLoginService
    private let hotKeyService: GlobalHotKeyService

    private var historyWindow: NSWindow?
    private var settingsWindow: NSWindow?

    init(
        tracker: QuoteTracker,
        settings: AppSettings,
        launchAtLogin: LaunchAtLoginService,
        hotKeyService: GlobalHotKeyService
    ) {
        self.tracker = tracker
        self.settings = settings
        self.launchAtLogin = launchAtLogin
        self.hotKeyService = hotKeyService
    }

    // MARK: - Actions

    func showHistory() {
        tracker.refresh()

        if let historyWindow {
            present(historyWindow)
            return
        }

        let window = makeWindow(
            title: "Quote History",
            size: DesignTokens.Layout.historyWindowSize,
            minSize: DesignTokens.Layout.historyWindowMinSize,
            content: HistoryView(tracker: tracker, settings: settings)
        )
        historyWindow = window
        present(window)

        AppLog.app.info("[App] Opened history window")
    }

    func showSettings() {
        if let settingsWindow {
            present(settingsWindow)
            return
        }

        let window = makeWindow(
            title: "QuoteBar Settings",
            size: DesignTokens.Layout.settingsWindowSize,
            minSize: DesignTokens.Layout.settingsWindowMinSize,
            content: SettingsView(
                tracker: tracker,
                settings: settings,
                launchAtLogin: launchAtLogin,
                hotKeyService: hotKeyService
            )
        )
        settingsWindow = window
        present(window)

        AppLog.app.info("[App] Opened settings window")
    }

    // MARK: - Helpers

    private func makeWindow(
        title: String,
        size: CGSize,
        minSize: CGSize,
        content: some View
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentViewController = NSHostingController(rootView: content)
        window.isReleasedWhenClosed = false
        window.center()
        window.contentMinSize = minSize
        window.setFrameAutosaveName("QuoteBar.\(title).1")

        return window
    }

    private func present(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
