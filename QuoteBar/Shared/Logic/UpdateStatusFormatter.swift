//
//  UpdateStatusFormatter.swift
//  QuoteBar — Update status wording
//
//  The pure half of the update feature. `UpdateService` talks to Sparkle and
//  reduces whatever it reports to an `UpdateCheckOutcome`; everything the user
//  actually reads is decided here, where it can be tested without an updater,
//  a network, or a published appcast.
//

import Foundation

/// How the most recent update check ended.
enum UpdateCheckOutcome: Equatable {
    /// A check is in flight.
    case checking
    /// Sparkle reached the feed and found nothing newer.
    case upToDate
    /// Sparkle found an update and is presenting it.
    case updateAvailable(version: String)
    /// The feed could not be reached or could not be read.
    case unreachable
}

/// Pure wording for the Updates settings section.
enum UpdateStatusFormatter {

    /// One line describing the last check, or nil before anything has happened.
    ///
    /// `unreachable` deliberately avoids the underlying network error. Until
    /// the appcast is published this is the expected path, not a fault, and a
    /// raw URLError is something the user can neither act on nor understand.
    /// It is also what an offline user sees, which is the same story to them.
    static func message(for outcome: UpdateCheckOutcome?) -> String? {
        switch outcome {
        case .none:
            return nil
        case .checking:
            return "Checking for updates…"
        case .upToDate:
            return "QuoteBar is up to date."
        case .updateAvailable(let version):
            return "Version \(version) is available."
        case .unreachable:
            return "Could not reach the update feed."
        }
    }

    /// Whether `message(for:)` describes a problem, so the view can colour it.
    static func isWarning(_ outcome: UpdateCheckOutcome?) -> Bool {
        outcome == .unreachable
    }

    /// "Last checked 3 hours ago", and friends.
    ///
    /// Bucketed by hand rather than handed to `RelativeDateTimeFormatter`,
    /// which varies by locale and by OS version and would make this untestable
    /// for the sake of wording nobody reads twice.
    ///
    /// - Parameters:
    ///   - lastCheck: When Sparkle last completed a check, or nil if never.
    ///   - now: The current time. Injected so tests do not depend on the clock.
    static func lastCheckedDescription(lastCheck: Date?, now: Date = Date()) -> String {
        guard let lastCheck else { return "Never checked." }

        // A store carried across from another machine, or a corrected clock,
        // can put the last check in the future. "In 3 hours" would be nonsense;
        // treat anything not in the past as having just happened.
        let elapsed = max(0, now.timeIntervalSince(lastCheck))

        let minutes = Int(elapsed / 60)
        if minutes < 1 { return "Last checked just now." }
        if minutes < 60 { return "Last checked \(pluralized(minutes, "minute")) ago." }

        let hours = minutes / 60
        if hours < 24 { return "Last checked \(pluralized(hours, "hour")) ago." }

        return "Last checked \(pluralized(hours / 24, "day")) ago."
    }

    private static func pluralized(_ count: Int, _ noun: String) -> String {
        "\(count) \(noun)\(count == 1 ? "" : "s")"
    }
}
