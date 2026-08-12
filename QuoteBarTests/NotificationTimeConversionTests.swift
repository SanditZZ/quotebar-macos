//
//  NotificationTimeConversionTests.swift
//  QuoteBarTests
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Notification time conversion")
struct NotificationTimeConversionTests {

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test("Converts a time to a Date carrying the same hour and minute")
    func convertsTimeToDate() {
        let time = NotificationTime(hour: 14, minute: 30)
        let date = NotificationTimeConversion.date(from: time, calendar: utcCalendar)
        let components = utcCalendar.dateComponents([.hour, .minute], from: date)

        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }

    @Test("Round-trips through Date and back to the same time")
    func roundTripsThroughDate() {
        let time = NotificationTime(hour: 7, minute: 45)
        let date = NotificationTimeConversion.date(from: time, calendar: utcCalendar)

        #expect(NotificationTimeConversion.time(from: date, calendar: utcCalendar) == time)
    }

    @Test("Reads back hour and minute from an arbitrary Date, ignoring day/month/year")
    func readsBackFromArbitraryDate() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 17
        components.hour = 9
        components.minute = 5
        let date = utcCalendar.date(from: components)!

        #expect(NotificationTimeConversion.time(from: date, calendar: utcCalendar) == NotificationTime(hour: 9, minute: 5))
    }

    @Test("Midnight round-trips correctly")
    func midnightRoundTrips() {
        let time = NotificationTime(hour: 0, minute: 0)
        let date = NotificationTimeConversion.date(from: time, calendar: utcCalendar)

        #expect(NotificationTimeConversion.time(from: date, calendar: utcCalendar) == time)
    }

    @Test("Trigger components set only hour and minute, leaving day/month/year nil so the trigger repeats daily")
    func triggerComponentsAreHourMinuteOnly() {
        let components = NotificationTimeConversion.triggerComponents(for: NotificationTime(hour: 18, minute: 0))

        #expect(components.hour == 18)
        #expect(components.minute == 0)
        #expect(components.day == nil)
        #expect(components.month == nil)
        #expect(components.year == nil)
    }
}
