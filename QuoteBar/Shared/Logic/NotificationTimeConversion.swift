//
//  NotificationTimeConversion.swift
//  QuoteBar — Calculations
//
//  Converts a `NotificationTime` to and from the two shapes the rest of the
//  app needs it in: a `Date` for SwiftUI's `DatePicker`, and `DateComponents`
//  for `UNCalendarNotificationTrigger`. Pure — every function is a
//  deterministic mapping of its input, with `Calendar.current` used only to
//  read/write hour-and-minute fields, not as hidden mutable state.
//

import Foundation

enum NotificationTimeConversion {

    /// A `Date` on an arbitrary reference day carrying `time`'s hour and
    /// minute — enough for a `DatePicker` with `.hourAndMinute` components,
    /// which ignores everything else about the date.
    static func date(from time: NotificationTime, calendar: Calendar = .current) -> Date {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        components.hour = time.hour
        components.minute = time.minute
        return calendar.date(from: components) ?? Date()
    }

    /// Reads back just the hour and minute a `DatePicker` produced, dropping
    /// the day/month/year it also carries.
    static func time(from date: Date, calendar: Calendar = .current) -> NotificationTime {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return NotificationTime(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    /// The `DateComponents` a `UNCalendarNotificationTrigger` needs to fire
    /// once a day at `time`. Only `hour`/`minute` are set — leaving
    /// day/month/year `nil` is what makes the trigger repeat daily rather
    /// than fire once.
    static func triggerComponents(for time: NotificationTime) -> DateComponents {
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        return components
    }
}
