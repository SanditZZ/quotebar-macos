//
//  StoreMigrationTests.swift
//  QuoteBarTests
//
//  Removing the app sandbox relocates the database. These cover the decision
//  and the copy, because getting either wrong looks identical to the user:
//  their entire quote history, favorites, custom quotes and tags are gone.
//

import Foundation
import Testing
@testable import QuoteBar

@Suite("Store migration")
struct StoreMigrationTests {

    // MARK: - The decision

    @Test("Copies when a legacy store exists and the destination is empty")
    func migratesOnFirstUnsandboxedLaunch() {
        #expect(
            StoreMigration.plan(legacyStoreExists: true, destinationStoreExists: false) == .copy
        )
    }

    @Test("Never overwrites an occupied destination, even with a legacy store present")
    func neverClobbersTheDestination() {
        // Once the app has run unsandboxed even once, the destination holds the
        // live database. Replacing it with the frozen container copy would undo
        // every quote seen since, so the migration must not be able to destroy
        // data it did not create.
        #expect(
            StoreMigration.plan(legacyStoreExists: true, destinationStoreExists: true)
                == .destinationOccupied
        )
    }

    @Test("Does nothing on a clean install")
    func cleanInstallIsNotAMigration() {
        #expect(
            StoreMigration.plan(legacyStoreExists: false, destinationStoreExists: false)
                == .nothingToMigrate
        )
    }

    @Test("Second launch is a no-op once the destination is populated")
    func isIdempotent() {
        #expect(
            StoreMigration.plan(legacyStoreExists: false, destinationStoreExists: true)
                == .destinationOccupied
        )
    }

    // MARK: - The file set

    @Test("A store is three files: the database and both WAL sidecars")
    func storeIsThreeFiles() {
        let url = URL(fileURLWithPath: "/tmp/example/QuoteBar.store")
        let files = StoreMigration.storeFiles(for: url)

        #expect(files.map(\.lastPathComponent) == [
            "QuoteBar.store",
            "QuoteBar.store-wal",
            "QuoteBar.store-shm",
        ])
        // Sidecars must sit beside the store, not in a subdirectory of it.
        #expect(files.allSatisfy { $0.deletingLastPathComponent().path == "/tmp/example" })
    }

    // MARK: - The copy

    @Test("Copies every present file and leaves the original untouched")
    func copiesAllFilesNonDestructively() throws {
        let root = try TemporaryDirectory()
        let legacy = root.url.appendingPathComponent("container/default.store")
        let destination = root.url.appendingPathComponent("support/QuoteBar/QuoteBar.store")

        try FileManager.default.createDirectory(
            at: legacy.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try "database".write(to: legacy, atomically: true, encoding: .utf8)
        try "log".write(
            to: legacy.deletingLastPathComponent().appendingPathComponent("default.store-wal"),
            atomically: true, encoding: .utf8
        )

        let outcome = StoreMigrator.migrateIfNeeded(from: legacy, to: destination)

        // Two of three: no -shm was present, which is normal and not a failure.
        #expect(outcome == .migrated(fileCount: 2))
        #expect(try String(contentsOf: destination, encoding: .utf8) == "database")
        #expect(
            try String(
                contentsOf: destination.deletingLastPathComponent()
                    .appendingPathComponent("QuoteBar.store-wal"),
                encoding: .utf8
            ) == "log"
        )
        // The container copy is the backup — it must survive.
        #expect(FileManager.default.fileExists(atPath: legacy.path))
    }

    @Test("The write-ahead log is carried across, not dropped")
    func bringsTheWriteAheadLog() throws {
        // The real container store was 100 KB with a 1.5 MB -wal holding the
        // recent quotes. Copying only the .store would lose them silently.
        let root = try TemporaryDirectory()
        let legacy = root.url.appendingPathComponent("old/default.store")
        let destination = root.url.appendingPathComponent("new/QuoteBar.store")

        try FileManager.default.createDirectory(
            at: legacy.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        for suffix in StoreMigration.sidecarSuffixes {
            try "x".write(
                to: legacy.deletingLastPathComponent()
                    .appendingPathComponent("default.store" + suffix),
                atomically: true, encoding: .utf8
            )
        }

        #expect(StoreMigrator.migrateIfNeeded(from: legacy, to: destination) == .migrated(fileCount: 3))
    }

    @Test("Running twice does not copy twice")
    func repeatedRunsAreSafe() throws {
        let root = try TemporaryDirectory()
        let legacy = root.url.appendingPathComponent("old/default.store")
        let destination = root.url.appendingPathComponent("new/QuoteBar.store")

        try FileManager.default.createDirectory(
            at: legacy.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try "original".write(to: legacy, atomically: true, encoding: .utf8)

        #expect(StoreMigrator.migrateIfNeeded(from: legacy, to: destination) == .migrated(fileCount: 1))

        // Simulate the app having written since: the second run must not
        // replace live data with the stale container copy.
        try "live data".write(to: destination, atomically: true, encoding: .utf8)

        #expect(
            StoreMigrator.migrateIfNeeded(from: legacy, to: destination)
                == .skipped(.destinationOccupied)
        )
        #expect(try String(contentsOf: destination, encoding: .utf8) == "live data")
    }

    @Test("A missing legacy store is not an error")
    func absentSourceIsFine() throws {
        let root = try TemporaryDirectory()
        let outcome = StoreMigrator.migrateIfNeeded(
            from: root.url.appendingPathComponent("nothing/here.store"),
            to: root.url.appendingPathComponent("new/QuoteBar.store")
        )
        #expect(outcome == .skipped(.nothingToMigrate))
    }

    // MARK: - Locations

    @Test("The store is namespaced, not a bare file in shared Application Support")
    func storeIsNamespaced() {
        // A bare `default.store` in ~/Library/Application Support collides with
        // every other app that accepted SwiftData's default. One was already
        // sitting there on the development machine, left by something else.
        let url = StoreLocations.storeURL
        #expect(url.lastPathComponent == "QuoteBar.store")
        #expect(url.deletingLastPathComponent().lastPathComponent == "QuoteBar")
    }

    @Test("The legacy path points into the sandbox container")
    func legacyPathIsTheContainer() {
        let url = StoreLocations.legacyContainerStoreURL(bundleIdentifier: "com.example.App")
        #expect(url.path.hasSuffix(
            "Library/Containers/com.example.App/Data/Library/Application Support/default.store"
        ))
    }
}

/// A scratch directory that removes itself when the test finishes.
private final class TemporaryDirectory {
    let url: URL

    init() throws {
        url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("QuoteBarTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
