//
//  StoreLocations.swift
//  QuoteBar — Where the database lives
//
//  The app names its store explicitly rather than accepting SwiftData's
//  default. Unsandboxed, that default is a bare `default.store` dropped
//  directly into ~/Library/Application Support — a directory shared with every
//  other app on the Mac, where a generic filename is asking for a collision.
//  One was already sitting there on the development machine when this was
//  written, left by something else entirely.
//
//  An owned subdirectory with an owned filename removes that class of problem,
//  and makes the migration deterministic: the destination is a path only this
//  app has ever written, so "is the destination occupied?" is a question with
//  a trustworthy answer.
//

import Foundation

/// Filesystem locations for the SwiftData store.
enum StoreLocations {

    /// Directory the app keeps its database in: `~/Library/Application Support/QuoteBar`.
    static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("QuoteBar", isDirectory: true)
    }

    /// The live store: `~/Library/Application Support/QuoteBar/QuoteBar.store`.
    static var storeURL: URL {
        supportDirectory.appendingPathComponent("QuoteBar.store")
    }

    /// Where the sandboxed builds kept their database.
    ///
    /// Built from the real home directory rather than `applicationSupportDirectory`,
    /// which resolves *into* the container when sandboxed and would therefore
    /// point at the destination rather than the source.
    static func legacyContainerStoreURL(
        bundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) -> URL {
        let identifier = bundleIdentifier ?? "com.kkpon3.QuoteBar"
        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Containers")
            .appendingPathComponent(identifier)
            .appendingPathComponent("Data/Library/Application Support/default.store")
    }
}
