//
//  AppLog.swift
//  QuoteBar — Structured logging
//
//  One logger per module so Console.app can be filtered by category. Messages
//  carry a `[Module]` prefix as well, which keeps them readable when logs are
//  exported as plain text.
//

import Foundation
import OSLog

/// Namespaced loggers. Use the logger matching the module you are in.
enum AppLog {
    /// Reverse-DNS subsystem, resolved from the bundle so forks get their own.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.kkpon3.QuoteBar"

    /// App lifecycle: launch, termination, window coordination.
    static let app = Logger(subsystem: subsystem, category: "App")

    /// Menu bar item and popover presentation.
    static let menuBar = Logger(subsystem: subsystem, category: "MenuBar")

    /// The quote provider chain: on-device AI, network, bundled.
    static let quote = Logger(subsystem: subsystem, category: "Quote")

    /// Network requests to the quote APIs.
    static let network = Logger(subsystem: subsystem, category: "Network")

    /// SwiftData container, fetches and saves.
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")

    /// User settings and preferences.
    static let settings = Logger(subsystem: subsystem, category: "Settings")

    /// The daily "Quote of the Day" notification: authorization, scheduling, taps.
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")

    /// Sparkle: scheduled and manual update checks, downloads, installs.
    static let updates = Logger(subsystem: subsystem, category: "Updates")
}
