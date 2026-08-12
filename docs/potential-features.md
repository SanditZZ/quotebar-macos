# Potential features

A backlog of ideas that are not trivial enough to just build. Each entry notes the constraint that makes it non-trivial. Read this before proposing something new — add to it rather than duplicating it.

## Auto-update (Sparkle)

Idle Tapper (this project's sibling) ships automatic updates via Sparkle, signed with an EdDSA key kept out of the repo. QuoteBar does not have this yet. Non-trivial part: needs a generated appcast, a private key in a GitHub Actions secret, and — because the app is sandboxed here (unlike Idle Tapper) — Sparkle's XPC installer service rather than the simpler unsandboxed install path.

## iCloud sync

Sync quote history and favorites across a user's Macs. Non-trivial part: SwiftData's `CloudKit` integration requires schema constraints (every attribute needs a default or be optional, no unique constraints) that `QuoteRecord` does not currently follow, and favorites conflict resolution needs a policy.

## Categories/tags

Let users request quotes filtered to a mood or topic ("motivational", "stoic", "funny"). Non-trivial part: the on-device model can take a topic in its prompt reasonably well; the two network APIs have inconsistent (or no) tag support, so a mixed source model has to either fake tags for network-sourced quotes or hide the filter when the AI path isn't active.

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
