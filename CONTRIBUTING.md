# Contributing to QuoteBar

Thanks for your interest. This document covers how to get set up, the architecture rules that keep the codebase coherent, and what a good pull request looks like.

The rules below are specific, and there are a fair number of them. Do not read that as a high bar — they exist so that review is about your idea rather than about house style, and none of them are hard to follow once the project is open in front of you.

---

## Finding something to work on

- **[Good first issues](https://github.com/SanditZZ/quotebar-macos/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)** — small, self-contained, and written so the finish line is obvious. Start here if you are new to the codebase.
- **[All open issues](https://github.com/SanditZZ/quotebar-macos/issues)**.
- **[docs/potential-features.md](docs/potential-features.md)** — the longer-term backlog. Each entry records the constraint that makes it non-trivial, which is usually the interesting part. Open an issue to discuss before building one of these.

**Comment on the issue before you start**, so two people do not quietly build the same thing. Nobody will mind you asking a question that turns out to be obvious.

Something not listed? Open an issue describing the problem before writing the fix. Small bug fixes can go straight to a pull request.

### One thing that will confuse you first

The app has no window and no Dock icon — it is a menu bar item, just like the interaction model this project borrows its architecture from. There is also no guaranteed AI quote generator: **Apple's Foundation Models framework only exists on macOS 26+, on Apple Intelligence–capable hardware, with the feature turned on.** Everywhere else, `QuoteProviderService` falls through to a network API, and then to the bundled offline set. If you are testing on an older Mac or a Mac without Apple Intelligence enabled, seeing network- or bundled-sourced quotes instead of AI-generated ones is expected, not a bug — check the source badge on the quote card.

---

## Getting started

```bash
git clone https://github.com/SanditZZ/quotebar-macos.git
cd quotebar-macos
open QuoteBar.xcodeproj
```

There is nothing to install by hand — no third-party dependencies. The project signs ad-hoc, so you do **not** need an Apple Developer account to build or run it. You do need **Xcode 26 or later**: the `FoundationModels` framework only ships in that SDK, and code referencing it (even behind `#available`) will not compile against an older one.

## Before you push

Run the CI checks locally. They must pass:

```bash
./scripts/ci-local.sh
```

That runs exactly what GitHub Actions runs — the same two `xcodebuild` invocations with the same flags — so a red pipeline is caught before you push rather than after.

```bash
./scripts/ci-local.sh build   # build only
./scripts/ci-local.sh test    # tests only
```

The build must stay **warning-free**; CI treats Swift warnings as errors. If your change introduces a warning you genuinely cannot avoid, say so in the pull request and explain why — do not weaken the check.

If you change the flags in `scripts/ci-local.sh`, change `.github/workflows/ci.yml` to match, and vice versa. If the two drift, "it passed locally" stops meaning anything.

CI runs on pull requests and on `main`, not on every branch push — a push that fired both events produced a duplicate run, one of which was cancelled and then counted against the pull request. So `ci-local.sh` is the only check covering the window before you open a PR, which is exactly why it must pass.

Once the pull request exists, confirm the real run went green — a local pass is strong evidence, not proof, since the runner has a different Xcode and a clean checkout:

```bash
./scripts/ci-watch.sh
```

---

## Architecture rules

The codebase separates Actions, Calculations and Data. Please keep changes on the right side of those lines — it is what makes the logic testable.

### Calculations are pure

Anything in `Shared/Logic/` must be a pure function: same input, same output, no I/O, no mutation, no reactive reads, no SwiftData types, no network. `RecentQuoteFilter`, `QuoteHistoryStats` and `QuoteTextFormatter` follow this strictly.

If you need to compute something in a view or a service, write the computation as a pure function in `Shared/Logic/`, unit-test it, and call it. Do not inline logic into a `body` or a `didSet`.

### Actions own the side effects

Database writes, network requests, the on-device model call, and window management live in `Shared/Services/`, `Shared/Persistence/` and `MenuBar/`. These may be stateful and main-actor bound.

### Views are presentational

A SwiftUI view imports and calls logic; it does not implement it. Reactive lines (`@State`, `.onChange`, `.task`) stay in the view, but their **bodies** should delegate to a service or a pure function.

### Never talk to SwiftData directly outside the persistence layer

Views and services use the `QuoteRepository` protocol. `ModelContext`, `FetchDescriptor` and `@Model` types appear only inside `Shared/Persistence/`. `QuoteRecord` must not leak past that boundary — convert to `QuoteSnapshot` instead.

### The provider chain is additive, not branching

`QuoteProviderService` tries each `QuoteProvider` in a fixed order and falls through on `nil`/failure — it never throws, because there is always a last resort. If you add a new source (another API, a paid key-based one, whatever), implement `QuoteProvider` and add it to the chain; do not special-case it inside the orchestrator.

### Keep files small

If a file approaches roughly 400 lines, split it before adding more. Extract pure functions into a logic module, or split self-contained markup plus its styling into a child view. This is much cheaper done as you go than as a retrofit.

---

## Design system

**Do not hardcode fonts, spacing, radii or colors.** Use `DesignTokens` and `AppColors`:

```swift
// Yes
.font(DesignTokens.Typography.bodyMedium)
.padding(DesignTokens.Spacing.medium)
.foregroundStyle(AppColors.textSecondary)

// No
.font(.system(size: 13, weight: .medium))
.padding(12)
.foregroundStyle(.secondary)
```

If a token does not exist, add it to `DesignTokens` or `AppColors` rather than writing a one-off literal. Colors must be appearance-adaptive or translucent so they work on the popover's vibrancy material in both light and dark mode — check both before submitting.

**Icons are SF Symbols**, never emoji. Emoji render differently across systems and cannot be tinted or sized reliably.

---

## Error handling

The app should never crash on a recoverable condition, and it should never fail silently.

- Catch errors, log them with the relevant `AppLog` category, and degrade gracefully
- A failed fetch from one provider must fall through to the next, not interrupt the user
- Every default value must be valid and functional; no placeholder defaults
- Validate inputs at boundaries and handle `nil` explicitly

---

## Logging

Use the `AppLog` namespace, with a `[Module]` prefix in the message:

```swift
AppLog.persistence.info("[Persistence] Saved")
AppLog.network.error("[Network] ZenQuotes request failed: \(error.localizedDescription, privacy: .public)")
```

Log success, failure and significant state transitions. Mark interpolations `privacy: .public` only when the value is genuinely not user data.

---

## Testing

Tests use [Swift Testing](https://developer.apple.com/documentation/testing) (`import Testing`, `@Test`, `#expect`), not XCTest.

Write **high-value tests only**. We want tests for:

- Core logic and its edge cases — quote selection avoiding recent repeats, stats aggregation over empty/large history
- Failure scenarios — empty bundled set, all providers failing, malformed API responses
- Anything that could silently corrupt a user's history

We do not want tests that assert a property returns what was just assigned to it, or that exercise SwiftUI layout.

Repository tests run against a real SwiftData stack via `ModelContainerFactory.makeInMemory()` — no mocks, no disk.

---

## Contributing a quote pack

A pack is a themed collection of quotes a user installs from a file (Settings → Quotes → Packs → "Install Pack…"). See issue #31 for the full design discussion; this section is the short version for a content-only pull request.

**Format** — a JSON file matching `QuotePack` (`Shared/Models/QuotePack.swift`):

```json
{
  "formatVersion": 1,
  "packId": "stoicism-basics",
  "name": "Stoicism Basics",
  "maintainer": "Your name or handle",
  "license": "Public Domain",
  "attribution": "Optional free-text credit line",
  "quotes": [
    { "text": "You have power over your mind, not outside events.", "author": "Marcus Aurelius" }
  ]
}
```

- `packId` is a stable, lowercase, hyphenated slug (`stoicism-basics`, not `Stoicism Basics` or `stoicismBasics`) — it is what `PackIdFormatter` turns back into a display name once installed, and it is never reused for different content once published.
- `license` is **required**, not optional. Packs are redistributed content: only public-domain or permissively-licensed text is accepted, with attribution where the license calls for it. This mirrors the standard the bundled offline set (`Resources/BackupQuotes.json`) already holds itself to, and why the on-device AI provider is never asked to attribute a quote to a real person — see `CLAUDE.md` §7 if you're curious why that rule exists.
- Keep pack pull requests **content-only** — a new pack file plus, if it's the first one, an entry in a packs index/README. Don't mix in code changes; those go through the design/implementation issue (#31) instead.
- See `docs/example-packs/stoicism-basics.json` for a complete, working example you can copy.

---

## Commits and pull requests

**Commit messages** are one sentence, capitalised, past tense, describing one logical change:

```
Added a favorite toggle to the quote card
Fixed ZenQuotes responses being treated as an object instead of an array
```

Split unrelated changes into separate commits.

**Pull requests** should:

- Describe what changed and why, not just what
- Note anything you deliberately did not do, and why
- Include tests for new logic
- Confirm the build is warning-free and all tests pass
- For UI changes, say what you checked manually — including light mode, dark mode, and any empty or error state

Keep pull requests focused. A large mixed change is hard to review and hard to revert.

---

## Reporting bugs

Open an issue with:

- Your macOS version and whether Apple Intelligence is enabled
- What you expected and what happened instead
- Reproduction steps, and whether it is consistent
- Anything relevant from Console.app filtered by the `QuoteBar` subsystem

---

## Security

Do not open a public issue for a security problem. See [SECURITY.md](SECURITY.md).
