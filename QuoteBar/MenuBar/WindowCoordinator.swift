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
    private let notificationService: QuoteNotificationService
    private let customQuoteLibrary: CustomQuoteLibrary
    private let tagLibrary: QuoteTagLibrary
    private let backupService: QuoteBackupService
    private let updateService: UpdateService

    private var historyWindow: NSWindow?
    private var settingsWindow: NSWindow?

    init(
        tracker: QuoteTracker,
        settings: AppSettings,
        launchAtLogin: LaunchAtLoginService,
        hotKeyService: GlobalHotKeyService,
        notificationService: QuoteNotificationService,
        customQuoteLibrary: CustomQuoteLibrary,
        tagLibrary: QuoteTagLibrary,
        backupService: QuoteBackupService,
        updateService: UpdateService
    ) {
        self.tracker = tracker
        self.settings = settings
        self.launchAtLogin = launchAtLogin
        self.hotKeyService = hotKeyService
        self.notificationService = notificationService
        self.customQuoteLibrary = customQuoteLibrary
        self.tagLibrary = tagLibrary
        self.backupService = backupService
        self.updateService = updateService
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
            content: HistoryView(tracker: tracker, settings: settings, tagLibrary: tagLibrary)
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
                hotKeyService: hotKeyService,
                notificationService: notificationService,
                customQuoteLibrary: customQuoteLibrary,
                tagLibrary: tagLibrary,
                backupService: backupService,
                updateService: updateService
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
        // `BorderlessAppWindow` fixes its own style mask, so the one passed
        // here is ignored — the window has no system title bar. The title is
        // still set, because the frame autosave name is derived from it and the
        // window still reports it to accessibility and the window list.
        let window = BorderlessAppWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false

        // Assigning `contentViewController` makes AppKit resize the window to
        // the hosting controller's fitting size, discarding the `contentRect`
        // above. A SwiftUI root of `ScrollView` (Settings) or a `VStack`
        // wrapping a `List` (History) has no useful ideal height, so that
        // fitting size collapses to roughly nothing — Settings opened 440×28,
        // History 128×122, both below their own `contentMinSize`. Opting the
        // hosting controller out of driving the size, then applying the
        // intended size afterwards, is what keeps these windows usable.
        let hosting = NSHostingController(
            rootView: WindowShell(title: title) { content }
        )
        hosting.sizingOptions = []
        window.contentViewController = hosting

        // `contentMinSize` has to be set before the autosave name, because
        // that is what restores a saved frame — and AppKit clamps the restored
        // frame to the minimum on the way in. That is what rescues anyone who
        // ran a build from before this fix and has a collapsed frame saved.
        window.contentMinSize = minSize
        window.setContentSize(size)
        window.center()
        window.setFrameAutosaveName("QuoteBar.\(title).1")

        return window
    }

    private func present(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
