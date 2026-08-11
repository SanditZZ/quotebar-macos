# Potential features

A backlog of ideas that are not trivial enough to just build. Each entry notes the constraint that makes it non-trivial. Read this before proposing something new — add to it rather than duplicating it.

## Auto-update (Sparkle)

Idle Tapper (this project's sibling) ships automatic updates via Sparkle, signed with an EdDSA key kept out of the repo. QuoteBar does not have this yet. Non-trivial part: needs a generated appcast, a private key in a GitHub Actions secret, and — because the app is sandboxed here (unlike Idle Tapper) — Sparkle's XPC installer service rather than the simpler unsandboxed install path.

## Preferred-source setting

Let the user pin a specific provider (always AI, always a specific API, always offline) instead of the automatic fallback chain. Non-trivial part: the Settings UI needs to explain *why* a pinned choice might silently fail (e.g. "always AI" on a Mac without Apple Intelligence) rather than just stop producing quotes.

## Custom/imported quotes

Let users add their own quotes to the rotation, or import a JSON/CSV file. Non-trivial part: needs de-duplication against the bundled set and a schema migration path in `QuoteRecord` for a `isUserAdded` flag.

## Global keyboard shortcut for "New Quote"

A system-wide hotkey that fetches a new quote without opening the popover — mirrors Idle Tapper's potential-features entry for a global tap shortcut. Non-trivial part: needs a way to surface the new quote (notification banner? menu bar flash?) since there is no guaranteed visible surface if the popover is closed.

## iCloud sync

Sync quote history and favorites across a user's Macs. Non-trivial part: SwiftData's `CloudKit` integration requires schema constraints (every attribute needs a default or be optional, no unique constraints) that `QuoteRecord` does not currently follow, and favorites conflict resolution needs a policy.

## Categories/tags

Let users request quotes filtered to a mood or topic ("motivational", "stoic", "funny"). Non-trivial part: the on-device model can take a topic in its prompt reasonably well; the two network APIs have inconsistent (or no) tag support, so a mixed source model has to either fake tags for network-sourced quotes or hide the filter when the AI path isn't active.

## Widget

A macOS widget showing today's quote. Non-trivial part: widgets run in a separate process/extension with their own timeline provider — the provider chain (especially the on-device AI call, which is not guaranteed to be fast) needs a timeout-and-cache strategy so the widget never shows a blank state while waiting.
