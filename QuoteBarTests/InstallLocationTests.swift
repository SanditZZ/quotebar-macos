//
//  InstallLocationTests.swift
//  QuoteBarTests
//
//  Running from the wrong place makes updates fail silently, so the
//  classification is worth pinning down — particularly the disk-image case,
//  which is both the most likely and the most confusing.
//

import Foundation
import Testing
@testable import QuoteBar

@Suite("Install location")
struct InstallLocationTests {

    private let home = URL(fileURLWithPath: "/Users/example")

    private func classify(_ path: String) -> InstallLocation {
        InstallLocationCheck.classify(
            bundleURL: URL(fileURLWithPath: path),
            homeDirectory: home
        )
    }

    // MARK: - The happy case

    @Test("/Applications is the expected home and says nothing")
    func applicationsIsSilent() {
        #expect(classify("/Applications/QuoteBar.app") == .applications)
        #expect(!InstallLocation.applications.needsWarning)
        #expect(InstallLocationCheck.warning(for: .applications) == nil)
    }

    @Test("A per-user Applications folder counts too")
    func userApplicationsIsFine() {
        // ~/Applications is a legitimate install location that Sparkle handles
        // exactly as well as /Applications. Warning about it would be wrong.
        #expect(classify("/Users/example/Applications/QuoteBar.app") == .applications)
    }

    // MARK: - The cases that break updating

    @Test("A mounted disk image is read-only, so it cannot be updated in place")
    func diskImageIsDetected() {
        #expect(classify("/Volumes/QuoteBar/QuoteBar.app") == .diskImage)
    }

    @Test("A DMG's own Applications symlink is still a disk image")
    func diskImageWinsOverApplications() {
        // Every drag-to-install DMG contains a folder called "Applications".
        // Classifying by that name first would call the read-only volume a
        // normal install and suppress the one warning that matters most.
        #expect(classify("/Volumes/QuoteBar/Applications/QuoteBar.app") == .diskImage)
    }

    @Test("Downloads is the silent-failure case: the update lands there instead")
    func downloadsIsElsewhere() {
        #expect(classify("/Users/example/Downloads/QuoteBar.app") == .elsewhere)
    }

    @Test("A path merely starting with the word Applications does not count")
    func prefixMatchingIsNotSloppy() {
        // "/ApplicationsOld/…" shares a textual prefix with "/Applications"
        // but is a different directory.
        #expect(classify("/ApplicationsOld/QuoteBar.app") == .elsewhere)
        #expect(classify("/Users/example/ApplicationsOld/QuoteBar.app") == .elsewhere)
    }

    // MARK: - What the user is told

    @Test("Every warning explains the consequence, not just the instruction")
    func warningsGiveAReason() {
        for location in [InstallLocation.diskImage, .elsewhere] {
            let message = InstallLocationCheck.warning(for: location)
            #expect(location.needsWarning)

            guard let message else {
                Issue.record("\(location) needs a warning but has none")
                continue
            }

            // "Move it to Applications" with no reason reads as nagging, so
            // each message has to name updating as the thing at stake. Matched
            // case-insensitively: a message opening with "Updates will be…" is
            // just as clear as one saying "cannot update itself".
            #expect(message.lowercased().contains("update"))
            #expect(message.contains("Applications"))
        }
    }
}
