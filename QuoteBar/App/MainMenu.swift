//
//  MainMenu.swift
//  QuoteBar — The application menu bar
//
//  A SwiftUI `App` supplies a menu bar for free. This app is a classic AppKit
//  entry point instead (see `QuoteBarApp`), so the menu has to be built by
//  hand — and it is not optional decoration:
//
//  - **Edit is load-bearing.** Cut, Copy, Paste and Select All reach a focused
//    text field through the responder chain *via menu items*. With no Edit
//    menu, Cmd+C and Cmd+V silently do nothing everywhere in the app: the
//    shortcut recorder, the tag editor, the custom quotes editor.
//  - **Settings needs a home for Cmd+comma.** The status item menu's own
//    "Settings…" only responds while that menu is open.
//
//  The menu is only visible while the app is `.regular`, which it becomes
//  while a window is open (see `WindowCoordinator`). The shortcuts work
//  whenever the app is active regardless.
//

import AppKit

@MainActor
enum MainMenu {

    /// Build and install the application menu.
    ///
    /// - Parameters:
    ///   - openSettings: Action for the Settings item, so Cmd+comma opens the
    ///     app's own borderless Settings window rather than a second one.
    ///   - target: Receiver for `openSettings`.
    static func install(openSettings: Selector, target: AnyObject) {
        let mainMenu = NSMenu()

        mainMenu.addItem(appMenuItem(openSettings: openSettings, target: target))
        mainMenu.addItem(editMenuItem())

        let windowItem = windowMenuItem()
        mainMenu.addItem(windowItem)

        NSApp.mainMenu = mainMenu
        // Lets AppKit keep the window list current and enables the standard
        // window cycling shortcut between History and Settings.
        NSApp.windowsMenu = windowItem.submenu

        AppLog.app.debug("[App] Main menu installed")
    }

    // MARK: - Menus

    private static func appMenuItem(openSettings: Selector, target: AnyObject) -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu()

        menu.addItem(
            withTitle: "About QuoteBar",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: openSettings, keyEquivalent: ",")
        settings.target = target
        menu.addItem(settings)
        menu.addItem(.separator())

        menu.addItem(
            withTitle: "Hide QuoteBar",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        menu.addItem(
            withTitle: "Quit QuoteBar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        item.submenu = menu
        return item
    }

    private static func editMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Edit")

        // Undo and redo are not on a concrete class the way the clipboard
        // actions are; they are resolved through the responder chain by name.
        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )

        item.submenu = menu
        return item
    }

    private static func windowMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Window")

        menu.addItem(
            withTitle: "Minimize",
            action: #selector(NSWindow.performMiniaturize(_:)),
            keyEquivalent: "m"
        )
        // `performClose:` normally requires a close button, which a borderless
        // window has none of — `BorderlessAppWindow` overrides it so this item
        // and Cmd+W both work.
        menu.addItem(
            withTitle: "Close",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )

        item.submenu = menu
        return item
    }
}
