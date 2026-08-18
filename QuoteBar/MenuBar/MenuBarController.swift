//
//  MenuBarController.swift
//  QuoteBar — Menu bar presentation
//
//  Owns the `NSStatusItem` and the popover that hosts the SwiftUI interface.
//  AppKit rather than `MenuBarExtra` because the popover needs precise control
//  over dismissal and over how an accessory app takes focus. Mirrors
//  idle-tapper-macos's `MenuBarController`.
//

import AppKit
import SwiftUI

@MainActor
final class MenuBarController {

    private let tracker: QuoteTracker
    private let settings: AppSettings
    private let windowCoordinator: WindowCoordinator
    private let updateService: UpdateService

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    /// Held for the duration of a share presentation. `NSSharingServicePicker`
    /// isn't retained by anything else while its popover is on screen — a
    /// purely local instance would be freed by ARC the moment
    /// `shareCurrentQuote()` returns, before the user has picked anything.
    private var sharingPicker: NSSharingServicePicker?

    /// Monitors clicks outside the popover so it dismisses like a menu.
    private lazy var outsideClickMonitor = EventMonitor(
        mask: [.leftMouseDown, .rightMouseDown]
    ) { [weak self] _ in
        MainActor.assumeIsolated {
            self?.closePopover()
        }
    }

    /// Timestamp of the last popover close. Clicking the status item while the
    /// popover is open both dismisses it and fires the click handler again,
    /// which would immediately reopen it; ignoring a click within a few
    /// milliseconds of a close fixes that.
    private var lastCloseDate: Date = .distantPast

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
        self.updateService = updateService
        self.windowCoordinator = WindowCoordinator(
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
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = item.button else {
            AppLog.menuBar.error("[MenuBar] Status item has no button — cannot install")
            return
        }

        button.image = StatusItemRenderer.image
        button.toolTip = StatusItemRenderer.symbolDescription
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        statusItem = item
        AppLog.menuBar.info("[MenuBar] Status item installed")
    }

    // MARK: - Actions

    /// Fired by the global "New Quote" shortcut. Opens the popover if it
    /// wasn't already showing, then always fetches a new quote — the same
    /// outcome as clicking the status item and pressing "New Quote".
    /// Open Settings from outside the status item menu — the application
    /// menu's Cmd+comma item routes here, so that shortcut opens the app's own
    /// borderless window rather than a second, system-chrome one.
    func openSettingsWindow() {
        windowCoordinator.showSettings()
    }

    func triggerFromGlobalHotKey() {
        guard let button = statusItem?.button else { return }

        if popover?.isShown != true {
            showPopover(from: button)
        }

        Task { await tracker.requestNewQuote() }
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else {
            togglePopover()
            return
        }

        let isSecondaryClick = event.type == .rightMouseUp || event.modifierFlags.contains(.control)

        if isSecondaryClick {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover, popover.isShown {
            closePopover()
            return
        }

        guard Date().timeIntervalSince(lastCloseDate) > 0.2 else { return }
        showPopover(from: button)
    }

    private func showPopover(from button: NSStatusBarButton) {
        tracker.refresh()

        let popover = popover ?? makePopover()
        self.popover = popover

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // An accessory app is not frontmost by default; without this the
        // popover renders inactive.
        NSApp.activate(ignoringOtherApps: true)

        outsideClickMonitor.start()
        AppLog.menuBar.debug("[MenuBar] Popover shown")
    }

    private func closePopover() {
        popover?.performClose(nil)
        lastCloseDate = Date()
        outsideClickMonitor.stop()
        tracker.stopSpeaking()
        tracker.flush()
        AppLog.menuBar.debug("[MenuBar] Popover closed")
    }

    private func showContextMenu() {
        guard let statusItem else { return }

        let menu = NSMenu()

        // Without this, every `isEnabled = false` below is discarded. AppKit
        // re-derives each item's enabled state just before the menu is shown,
        // and with automatic enabling it enables anything whose target
        // responds to the action — which is every item here. Share, Read Aloud
        // and Check for Updates then look available with nothing to act on,
        // and clicking them does nothing at all.
        menu.autoenablesItems = false

        menu.addItem(withTitle: String(localized: "New Quote"), action: #selector(requestNewQuoteFromMenu), keyEquivalent: "n")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: String(localized: "History…"), action: #selector(openHistory), keyEquivalent: "")
            .target = self
        menu.addItem(withTitle: String(localized: "Share Quote…"), action: #selector(shareCurrentQuoteFromMenu), keyEquivalent: "")
            .target = self
        menu.items.last?.isEnabled = tracker.currentQuote != nil
        menu.addItem(
            withTitle: tracker.isSpeaking ? "Stop Reading" : "Read Aloud",
            action: #selector(speakOrStopCurrentQuoteFromMenu),
            keyEquivalent: ""
        ).target = self
        menu.items.last?.isEnabled = tracker.isSpeaking || tracker.currentQuote != nil
        menu.addItem(withTitle: String(localized: "Settings…"), action: #selector(openSettings), keyEquivalent: ",")
            .target = self
        menu.addItem(withTitle: String(localized: "Check for Updates…"), action: #selector(checkForUpdatesFromMenu), keyEquivalent: "")
            .target = self
        // Sparkle ignores a second check while one is in flight, so the item
        // reflects that rather than looking like it did nothing.
        menu.items.last?.isEnabled = updateService.canCheck
        menu.addItem(.separator())
        menu.addItem(withTitle: String(localized: "Quit QuoteBar"), action: #selector(quit), keyEquivalent: "q")
            .target = self

        // Attaching the menu makes the status item present it, then detaching
        // restores normal click-to-toggle behaviour.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func requestNewQuoteFromMenu() {
        Task { await tracker.requestNewQuote() }
    }

    @objc private func checkForUpdatesFromMenu() {
        updateService.checkForUpdates()
    }

    @objc private func openHistory() {
        windowCoordinator.showHistory()
    }

    @objc private func shareCurrentQuoteFromMenu() {
        shareCurrentQuote()
    }

    @objc private func speakOrStopCurrentQuoteFromMenu() {
        speakOrStopCurrentQuote()
    }

    /// Toggles narration: starts reading the current quote aloud, or stops
    /// it if already speaking. Shared by the popover's "Read Aloud" button
    /// and this right-click menu item.
    private func speakOrStopCurrentQuote() {
        if tracker.isSpeaking {
            tracker.stopSpeaking()
        } else {
            tracker.speakCurrentQuote()
        }
    }

    /// Renders the current quote and presents the system share picker,
    /// anchored to the status item so it works whether triggered from the
    /// popover's footer or the right-click menu. No-ops rather than showing
    /// an error if there's no current quote or rendering fails — both are
    /// edge cases already guarded against at the call sites (the footer
    /// button is disabled, the menu item is un-enabled) when there's no
    /// quote to share.
    private func shareCurrentQuote() {
        guard
            let quote = tracker.currentQuote,
            let image = QuoteImageRenderer.renderImage(for: quote, style: settings.shareCardStyle),
            let button = statusItem?.button
        else { return }

        let picker = NSSharingServicePicker(items: [image])
        sharingPicker = picker
        picker.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        AppLog.menuBar.debug("[MenuBar] Presented share picker")
    }

    @objc private func openSettings() {
        windowCoordinator.showSettings()
    }

    @objc private func quit() {
        tracker.flush()
        NSApp.terminate(nil)
    }

    // MARK: - Popover Content

    private func makePopover() -> NSPopover {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true

        let content = PopoverContentView(
            tracker: tracker,
            onOpenHistory: { [weak self] in
                self?.closePopover()
                self?.windowCoordinator.showHistory()
            },
            onOpenSettings: { [weak self] in
                self?.closePopover()
                self?.windowCoordinator.showSettings()
            },
            onShare: { [weak self] in
                self?.shareCurrentQuote()
            },
            onSpeak: { [weak self] in
                self?.speakOrStopCurrentQuote()
            },
            onQuit: { [weak self] in
                self?.quit()
            }
        )

        let hosting = NSHostingController(rootView: content)
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting

        return popover
    }
}
