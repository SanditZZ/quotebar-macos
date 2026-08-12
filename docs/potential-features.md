# Potential features

A backlog of ideas that are not trivial enough to just build. Each entry notes the constraint that makes it non-trivial. Read this before proposing something new — add to it rather than duplicating it.

## Auto-update (Sparkle)

Idle Tapper (this project's sibling) ships automatic updates via Sparkle, signed with an EdDSA key kept out of the repo. QuoteBar does not have this yet. Non-trivial part: needs a generated appcast, a private key in a GitHub Actions secret, and — because the app is sandboxed here (unlike Idle Tapper) — Sparkle's XPC installer service rather than the simpler unsandboxed install path.

## Custom/imported quotes

Let users add their own quotes to the rotation, or import a JSON/CSV file. Non-trivial part: needs de-duplication against the bundled set and a schema migration path in `QuoteRecord` for a `isUserAdded` flag.

## iCloud sync

Sync quote history and favorites across a user's Macs. Non-trivial part: SwiftData's `CloudKit` integration requires schema constraints (every attribute needs a default or be optional, no unique constraints) that `QuoteRecord` does not currently follow, and favorites conflict resolution needs a policy.

## Categories/tags

Let users request quotes filtered to a mood or topic ("motivational", "stoic", "funny"). Non-trivial part: the on-device model can take a topic in its prompt reasonably well; the two network APIs have inconsistent (or no) tag support, so a mixed source model has to either fake tags for network-sourced quotes or hide the filter when the AI path isn't active.

## Widget

A macOS widget showing today's quote. Non-trivial part: widgets run in a separate process/extension with their own timeline provider — the provider chain (especially the on-device AI call, which is not guaranteed to be fast) needs a timeout-and-cache strategy so the widget never shows a blank state while waiting.

## Quote source badge for user-added quotes

Once custom/imported quotes exist, the popover's existing per-source badge needs a distinct label for them so they don't read as AI/network/bundled. Non-trivial part: the badge logic currently maps 1:1 to `QuoteSource` cases from the fixed provider chain; a user-added quote isn't produced by any provider in that chain, so the badge/source model needs a case that doesn't imply "this came from a fallback attempt."

## Export/backup of quote history

Let users export their full quote history (and, once it exists, their imported/custom quotes) to a file, and re-import it. Non-trivial part: needs a stable serialization format for `QuoteRecord`/`QuoteSnapshot` chosen up front so it survives schema changes — and doing this before iCloud sync de-risks that later work by proving the format out.

## Bulk-delete for imported quotes

Once users can add their own quotes, they'll want to prune them in bulk rather than one at a time. Non-trivial part: needs a selection UI in a currently single-item-focused history view, and a repository method that removes many `QuoteRecord`s in one transaction rather than N individual deletes.
