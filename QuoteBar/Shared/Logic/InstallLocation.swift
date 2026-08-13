//
//  InstallLocation.swift
//  QuoteBar — Where the app is running from
//
//  Sparkle updates by replacing the application bundle *where it currently
//  is*. That is fine from /Applications and quietly wrong everywhere else:
//
//    - Run from a mounted DMG and the volume is read-only, so the update
//      cannot be installed at all.
//    - Run from ~/Downloads and the update lands in ~/Downloads, while the
//      copy the user later drags to Applications stays at the old version
//      forever. Nothing errors; the app simply never appears to update.
//
//  Neither case announces itself, which is what makes it worth a check. This
//  is the pure half — classifying a path — so it can be tested without moving
//  the app around.
//

import Foundation

/// Where the running bundle lives, as far as updating is concerned.
enum InstallLocation: Equatable {
    /// /Applications or ~/Applications. Updates install normally.
    case applications
    /// A mounted disk image. Read-only, so an update cannot be written.
    case diskImage
    /// Anywhere else — Downloads, Desktop, a build directory.
    case elsewhere

    /// Whether the user should be told. Only `.applications` is silent.
    var needsWarning: Bool { self != .applications }
}

/// Pure classification of a bundle path.
enum InstallLocationCheck {

    /// Where an app at `bundleURL` is running from.
    ///
    /// - Parameters:
    ///   - bundleURL: The bundle's own location (`Bundle.main.bundleURL`).
    ///   - homeDirectory: The user's home, injected so tests do not depend on
    ///     the account running them.
    static func classify(
        bundleURL: URL,
        homeDirectory: URL = URL(fileURLWithPath: NSHomeDirectory())
    ) -> InstallLocation {
        let path = bundleURL.resolvingSymlinksInPath().path

        // Checked before /Applications: a DMG can contain a folder named
        // "Applications" (the install-target symlink is exactly that), and a
        // read-only volume is the more specific and more serious case.
        if path.hasPrefix("/Volumes/") { return .diskImage }

        if path.hasPrefix("/Applications/") { return .applications }

        let userApplications = homeDirectory
            .appendingPathComponent("Applications", isDirectory: true)
            .resolvingSymlinksInPath().path
        if path.hasPrefix(userApplications + "/") { return .applications }

        return .elsewhere
    }

    /// What to tell the user, or nil when there is nothing worth saying.
    ///
    /// Deliberately explains the consequence rather than the mechanism. "Move
    /// QuoteBar to Applications" with no reason reads as nagging; the reason
    /// is the only part that makes someone act.
    static func warning(for location: InstallLocation) -> String? {
        switch location {
        case .applications:
            return nil
        case .diskImage:
            return "QuoteBar is running from a disk image, so it cannot update itself. Drag it to your Applications folder."
        case .elsewhere:
            return "QuoteBar isn't in your Applications folder. Updates will be installed wherever it is now, so move it to Applications to keep it up to date."
        }
    }
}
