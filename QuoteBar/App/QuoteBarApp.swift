//
//  QuoteBarApp.swift
//  QuoteBar
//
//  Menu bar only: the app is an accessory (`LSUIElement`) with no Dock icon and
//  no default window. All presentation is driven from `AppDelegate`.
//
//  A classic AppKit entry point rather than a SwiftUI `App`, because every
//  `App` needs at least one `Scene`, and for a windowless menu bar app the only
//  candidate is `Settings { … }`. That scene does not hand its content to
//  `WindowCoordinator` — it builds a *second*, system-chrome Settings window of
//  its own. The result was two different Settings windows: the borderless one
//  with the custom sidebar from the status item, and a standard titled one from
//  Cmd+comma. Both could be open at once.
//
//  Dropping the SwiftUI `App` removes that scene, so there is exactly one
//  Settings window. The cost is that the standard menu bar goes with it, which
//  is why `MainMenu` exists — without it Cmd+C, Cmd+V and Cmd+A would silently
//  stop working in every text field the app has.
//

import AppKit

@main
enum QuoteBarMain {

    /// Retained for the lifetime of the process: `NSApplication.delegate` is a
    /// weak reference, so a local would be deallocated immediately and the app
    /// would launch with no delegate and no menu bar item.
    ///
    /// Main-actor isolated because `AppDelegate` is, and everything it touches
    /// — the status item, the windows, the SwiftData container — belongs to
    /// the main thread anyway.
    @MainActor private static let delegate = AppDelegate()

    @MainActor static func main() {
        let application = NSApplication.shared
        application.delegate = delegate
        application.run()
    }
}
