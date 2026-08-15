# Potential features

A backlog of ideas that are not trivial enough to just build. Each entry notes the constraint that makes it non-trivial. Read this before proposing something new — add to it rather than duplicating it.

## Notarized releases

Auto-update via Sparkle has shipped, but releases are ad-hoc signed and unnotarized, so macOS refuses to open the app until the user clears the quarantine flag by hand. Non-trivial part: needs a paid Apple Developer Program membership and a Developer ID Application certificate, neither of which exists yet. The release workflow already takes the signed and notarized path the moment the secrets are present, so this is a purchase and a key handover rather than a code change. See RELEASING.md.

## iCloud sync

Sync quote history and favorites across a user's Macs. Non-trivial part: SwiftData's `CloudKit` integration requires schema constraints (every attribute needs a default or be optional, no unique constraints) that `QuoteRecord` does not currently follow, and favorites conflict resolution needs a policy.

## Topic-filtered quote requests

Not to be confused with the user-assigned tags that already shipped. Those label quotes the user has *already seen*, and filter history. This entry is the opposite direction: asking a source for a quote *about* a mood or topic ("motivational", "stoic", "funny") at fetch time, before there is a quote to label.

Let users request quotes filtered to a mood or topic. Non-trivial part: the on-device model can take a topic in its prompt reasonably well; the two network APIs have inconsistent (or no) topic support, so a mixed source model has to either fabricate a topic match for network-sourced quotes or hide the filter when the AI path isn't active.

## Widget

A macOS widget showing today's quote. Non-trivial part: widgets run in a separate process/extension with their own timeline provider — the provider chain (especially the on-device AI call, which is not guaranteed to be fast) needs a timeout-and-cache strategy so the widget never shows a blank state while waiting.

## Live duplicate feedback in the "Add Quote" form

`CustomQuotesEditor`'s manual add form only reports a duplicate after the user clicks "Add" and the repository throws — the check happens server-side (in `SwiftDataCustomQuoteRepository.add`), not as the user types. Non-trivial part: `CustomQuoteDeduplicator` is already a pure function, so the calculation itself is cheap to call on every keystroke; the real work is deciding how much of `CustomQuoteLibrary.entries` (already loaded) versus the bundled set (currently only read inside the repository, via `BundledQuoteProvider.allTexts`) needs to be threaded into the view layer without violating "views are presentational."

## Automatic scheduled backups

Now that a versioned `QuoteBackup` JSON format and `QuoteBackupService.makeJSONExportData()` exist (manual export/import only, shipped alongside bulk-delete), the natural next step is backing up on a schedule instead of only on demand. Non-trivial part: a sandboxed app can't silently write to an arbitrary location — `.fileExporter` always prompts — so a truly automatic backup needs either a one-time user-granted security-scoped bookmark to a folder (persisted across launches, with its own re-authorization-if-revoked handling) or accepting a periodic *reminder* to export manually rather than a fully silent write.

## Drag-and-drop file import

Both "Your Quotes" and the new "Backup" section only accept files via an explicit `.fileImporter` button; dropping a `.json`/`.csv` file onto the popover or the relevant Settings section would be faster. Non-trivial part: `.onDrop`/`DropDelegate` hands back a security-scoped `NSItemProvider` reference rather than a ready `URL`, and the existing `importFile`/`importBackup` methods assume they're handed a `URL` from `.fileImporter`'s completion handler — reusing them cleanly means resolving the provider to a URL first without breaking the "read it, don't retain sandbox access" pattern importers already use.

## "Last backup" timestamp in Settings

`QuoteBackupService` currently reports only a one-line summary immediately after an export/import ("Exported N quotes as JSON."), which disappears the next time Settings is reopened — there's no persistent way to tell whether (or how long ago) a backup was last made. Non-trivial part: needs a new `AppSettings` field for the last export date, but has to be careful about *when* it's considered "backed up" — an export the user cancelled partway through the save panel shouldn't count, so it can only be set from `.fileExporter`'s `.success` completion, not from `makeJSONExportData()` being called.

## Set quote as desktop wallpaper

Reuse the existing `QuoteImageRenderer`/`ShareCardStyle` pipeline (built for sharing) to render the current quote and set it as the desktop picture instead of just sharing it. Non-trivial part: a sandboxed app can't call `NSWorkspace.setDesktopImageURL` on an arbitrary path — the rendered image has to be written to a location the app can pass a `file://` URL for (e.g. its own container's `Application Support`), and multi-display setups mean iterating `NSScreen.screens` rather than assuming a single screen.

## Menu bar marquee text mode

A toggle to show a short excerpt of the quote directly in the menu bar (as title text next to or instead of the icon), not just an icon. Non-trivial part: `StatusItemRenderer` is icon-only today; adding text means truncation/ellipsis logic, correct `NSStatusItem` auto-resizing, and refreshing the title whenever `QuoteTracker.currentQuote` changes even while the popover is closed — nothing currently observes the tracker outside SwiftUI views.

## "On this day" favorites resurfacing

Occasionally show a favorite from N days (or a year) ago instead of fetching new, framed as a memory rather than a fresh quote. Non-trivial part: `QuoteRepository` only exposes `recentTexts`/`allQuotes`/`toggleFavorite` today — this needs a new date-range query, plus a policy for how it competes with `QuoteProviderService`'s chain, which is currently strictly additive tiers, not a branching decision.

## Favorites-only rotation mode

A "Favorites Mode" toggle that serves only from the user's already-favorited quotes, as a quieter alternative to pinning `preferredSource: .custom`. Non-trivial part: this is a rotation over *history* (favorited `QuoteRecord`s), not a `QuoteProvider` tier, so it doesn't fit `ProviderChainSelector`'s source-based model — it needs its own path in `QuoteTracker.requestNewQuote()` that bypasses the provider chain entirely and dedups via `RecentQuoteFilter` differently, since there's no live "provider" backing it.

## Quick actions from the menu bar right-click menu

Extend the right-click `NSMenu` in `MenuBarController` with "Copy Quote" and "Favorite This Quote" so common actions don't require opening the popover at all (Read Aloud already shipped there). Non-trivial part: `showContextMenu()` currently rebuilds the menu synchronously from `tracker.currentQuote`, but favoriting/copying needs to update state and (for copy) write to `NSPasteboard` while respecting the same `isFetching`/error-message invariants `PopoverContentView` already encodes — duplicating that logic outside SwiftUI risks it drifting out of sync with the view's behavior.
