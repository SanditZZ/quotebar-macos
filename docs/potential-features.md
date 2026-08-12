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

## Export/backup of quote history

Let users export their full quote history (and, once it exists, their imported/custom quotes) to a file, and re-import it. Non-trivial part: needs a stable serialization format for `QuoteRecord`/`QuoteSnapshot` chosen up front so it survives schema changes — and doing this before iCloud sync de-risks that later work by proving the format out.

## Bulk-delete for imported quotes

Once users can add their own quotes, they'll want to prune them in bulk rather than one at a time. Non-trivial part: needs a selection UI in a currently single-item-focused history view, and a repository method that removes many `QuoteRecord`s in one transaction rather than N individual deletes.

## CSV export of the custom quote library

The custom/imported quotes feature added JSON/CSV import (`CustomQuoteImportParsing`) but no matching export — users can add or import quotes but have no way to get their library back out, e.g. to back it up or move it to another Mac before iCloud sync exists. Non-trivial part: needs a serializer that's the mirror image of the CSV import parser (same quoting/escaping rules, so a round-tripped file re-imports identically), and pairs naturally with the already-backlogged "Export/backup of quote history" — likely worth building as one combined export feature rather than two.

## Live duplicate feedback in the "Add Quote" form

`CustomQuotesEditor`'s manual add form only reports a duplicate after the user clicks "Add" and the repository throws — the check happens server-side (in `SwiftDataCustomQuoteRepository.add`), not as the user types. Non-trivial part: `CustomQuoteDeduplicator` is already a pure function, so the calculation itself is cheap to call on every keystroke; the real work is deciding how much of `CustomQuoteLibrary.entries` (already loaded) versus the bundled set (currently only read inside the repository, via `BundledQuoteProvider.allTexts`) needs to be threaded into the view layer without violating "views are presentational."

## User-assigned tags on quotes

Let users add their own freeform tags to a quote already in their history or favorites, and browse/filter by tag — distinct from the "Categories/tags" entry above, which is about requesting a quote filtered by mood/topic *from the provider chain* at fetch time. This is the opposite direction: labeling quotes already seen, closer in spirit to how `QuoteRecord.isFavorite` already works than to anything provider-related. Non-trivial part: a quote can have multiple tags and a tag applies to multiple quotes, so unlike the single `isFavorite` boolean this needs a real many-to-many relationship in SwiftData (a `QuoteTag` `@Model` plus a relationship on `QuoteRecord`), tag management UI (create/rename/delete a tag, assign/unassign per quote), and a tag filter in `HistoryView` alongside the existing "Favorites only" toggle.
