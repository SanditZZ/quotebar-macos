//
//  QuoteNotificationService.swift
//  QuoteBar — Daily "Quote of the Day" notification
//
//  Wraps `UNUserNotificationCenter`. Mirrors `LaunchAtLoginService`'s shape:
//  a system-level registration that's re-applied whenever the relevant
//  setting changes, with authorization state read back from the OS rather
//  than assumed.
//
//  The scheduled notification's body is static ("Time for your daily
//  quote!") rather than a specific fresh quote — a scheduled
//  `UNNotificationRequest`'s content is fixed at schedule time, so baking in
//  a *specific* quote would need either a Notification Service Extension or
//  a batch-scheduling scheme kept topped up by the app running periodically.
//  Tapping the notification opens the popover and fetches a fresh quote
//  through the existing provider chain instead, reusing all of it as-is.
//

import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class QuoteNotificationService {

    /// The one notification this app ever schedules. Reusing the identifier
    /// on every reschedule replaces the pending request instead of
    /// duplicating it.
    private static let identifier = "com.kkpon3.QuoteBar.dailyQuote"

    private let center: UNUserNotificationCenter

    /// Message for a failure the user should see, e.g. denied authorization.
    /// `nil` means notifications are either off or working normally.
    private(set) var lastErrorMessage: String?

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    // MARK: - Actions

    /// Re-read the real authorization status from the system.
    ///
    /// Call when Settings appears: the user may have revoked notification
    /// permission in System Settings since the app launched.
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        lastErrorMessage = settings.authorizationStatus == .denied ? Self.deniedMessage : nil
    }

    /// Apply the user's current settings: request authorization if needed,
    /// then schedule or cancel to match. Never throws — a failure leaves
    /// `lastErrorMessage` set and the toggle reflecting reality rather than
    /// interrupting the user, same bar every other setting here holds
    /// itself to.
    func apply(enabled: Bool, time: NotificationTime) async {
        guard enabled else {
            cancel()
            lastErrorMessage = nil
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                lastErrorMessage = Self.deniedMessage
                cancel()
                return
            }
            lastErrorMessage = nil
            try await schedule(at: time)
        } catch {
            lastErrorMessage = "Could not enable notifications: \(error.localizedDescription)"
            AppLog.notifications.error(
                "[Notifications] Failed to enable: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    // MARK: - Scheduling

    private func schedule(at time: NotificationTime) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Quote of the Day"
        content.body = "Time for your daily quote!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: NotificationTimeConversion.triggerComponents(for: time),
            repeats: true
        )

        let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
        try await center.add(request)

        AppLog.notifications.info(
            "[Notifications] Scheduled daily quote at \(time.hour, privacy: .public):\(time.minute, privacy: .public)"
        )
    }

    private func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        AppLog.notifications.info("[Notifications] Cancelled daily quote")
    }

    private static let deniedMessage = "Allow notifications for QuoteBar in System Settings › Notifications."
}
