//
//  NotificationTime.swift
//  QuoteBar — Data
//
//  The user's chosen time of day for the daily quote notification. Plain
//  hour/minute rather than a full `Date` — a `Date` carries a day, month and
//  year that are meaningless for a repeating daily trigger and would need to
//  be stripped back out at every use site. See
//  `Shared/Logic/NotificationTimeConversion.swift` for converting to/from a
//  `Date` (for the Settings time picker) and to `DateComponents` (for
//  scheduling), and `Shared/Services/QuoteNotificationService.swift` for the
//  scheduling itself.
//

import Foundation

struct NotificationTime: Codable, Sendable, Equatable {
    var hour: Int
    var minute: Int

    /// Shipped default: 9:00 AM.
    static let `default` = NotificationTime(hour: 9, minute: 0)
}
