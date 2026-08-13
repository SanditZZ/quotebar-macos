//
//  UpdateStatusFormatterTests.swift
//  QuoteBarTests
//
//  The update feature's only testable half. Sparkle itself needs a published
//  appcast and a signed build to exercise, so the wording is where correctness
//  can actually be pinned down.
//

import Foundation
import Testing
@testable import QuoteBar

@Suite("Update status wording")
struct UpdateStatusFormatterTests {

    // MARK: - Outcome messages

    @Test("No message before a check has run")
    func silentUntilSomethingHappens() {
        #expect(UpdateStatusFormatter.message(for: nil) == nil)
    }

    @Test("An available update is named by version")
    func namesTheAvailableVersion() {
        #expect(
            UpdateStatusFormatter.message(for: .updateAvailable(version: "0.2.0"))
                == "Version 0.2.0 is available."
        )
    }

    @Test("An unreachable feed reads as a feed problem, not a raw network error")
    func unreachableIsPlainlyWorded() {
        // Until the repository goes public and Pages serves the appcast, this
        // is the expected path on every check. It has to read as a state the
        // user can ignore, not as a fault they must fix.
        #expect(
            UpdateStatusFormatter.message(for: .unreachable) == "Could not reach the update feed."
        )
    }

    @Test("Only an unreachable feed is styled as a warning")
    func onlyFailuresWarn() {
        #expect(UpdateStatusFormatter.isWarning(.unreachable))
        #expect(!UpdateStatusFormatter.isWarning(.upToDate))
        #expect(!UpdateStatusFormatter.isWarning(.checking))
        #expect(!UpdateStatusFormatter.isWarning(.updateAvailable(version: "0.2.0")))
        #expect(!UpdateStatusFormatter.isWarning(nil))
    }

    // MARK: - Last checked

    @Test("Never having checked says so, rather than showing an empty line")
    func neverChecked() {
        #expect(UpdateStatusFormatter.lastCheckedDescription(lastCheck: nil) == "Never checked.")
    }

    @Test(
        "Elapsed time is described in the largest sensible unit",
        arguments: [
            (0.0, "Last checked just now."),
            (59.0, "Last checked just now."),
            (60.0, "Last checked 1 minute ago."),
            (120.0, "Last checked 2 minutes ago."),
            (3_599.0, "Last checked 59 minutes ago."),
            (3_600.0, "Last checked 1 hour ago."),
            (7_200.0, "Last checked 2 hours ago."),
            (86_399.0, "Last checked 23 hours ago."),
            (86_400.0, "Last checked 1 day ago."),
            (172_800.0, "Last checked 2 days ago."),
        ]
    )
    func describesElapsedTime(elapsed: Double, expected: String) {
        let now = TestSupport.referenceDate
        #expect(
            UpdateStatusFormatter.lastCheckedDescription(
                lastCheck: now.addingTimeInterval(-elapsed),
                now: now
            ) == expected
        )
    }

    @Test("A last check in the future reads as just now, not as a negative age")
    func futureDatesDoNotProduceNonsense() {
        // A store carried across from another machine, or a clock correction,
        // can leave the recorded check ahead of now. "Last checked -3 hours
        // ago" would be a visible bug for a case nobody would think to try.
        let now = TestSupport.referenceDate
        #expect(
            UpdateStatusFormatter.lastCheckedDescription(
                lastCheck: now.addingTimeInterval(3_600),
                now: now
            ) == "Last checked just now."
        )
    }
}
