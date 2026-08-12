//
//  ModelContainerFactory.swift
//  QuoteBar — Persistence setup
//
//  Builds the SwiftData container. A menu bar app has no `WindowGroup` to
//  attach `.modelContainer(...)` to, so the container is created here and
//  injected explicitly by the app delegate.
//

import Foundation
import SwiftData

/// Creates `ModelContainer` instances for the app and for tests.
enum ModelContainerFactory {

    /// Every `@Model` type the app persists. Adding a model here is all that is
    /// required for it to be included in the schema.
    static let schema = Schema([QuoteRecord.self, CustomQuoteEntry.self, QuoteTag.self])

    /// Container backed by the on-disk SQLite store.
    ///
    /// No explicit URL is passed: the app is sandboxed, so SwiftData's default
    /// location already lives inside the app's own container — unlike
    /// idle-tapper-macos, there's no unsandboxed-store migration to do here.
    static func makePersistent() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            AppLog.persistence.info("[Persistence] Opened persistent store")
            return container
        } catch {
            AppLog.persistence.error(
                "[Persistence] Failed to open persistent store: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }

    /// Ephemeral container that never touches disk. Used by unit tests and
    /// SwiftUI previews.
    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Last-resort container used when the on-disk store cannot be opened —
    /// for example a corrupt or unreadable database.
    ///
    /// The app stays usable and quotes are still shown; only persistence
    /// across launches is lost. Preferred over crashing on launch, and the
    /// caller is expected to tell the user.
    static func makeFallback() -> ModelContainer? {
        do {
            let container = try makeInMemory()
            AppLog.persistence.warning("[Persistence] Falling back to an in-memory store — history will not persist")
            return container
        } catch {
            AppLog.persistence.error(
                "[Persistence] Fallback in-memory store also failed: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
}
