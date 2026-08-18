# QuoteBar

**A native macOS menu bar app that serves a random quote, powered by Apple's on-device Foundation Models — with live and offline fallbacks so it always has something to say.**

![macOS](https://img.shields.io/badge/macOS-14.0+-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-blue?style=flat-square&logo=swift)
![SwiftData](https://img.shields.io/badge/SwiftData-purple?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![README hits](https://hits.sh/github.com/SanditZZ/quotebar-macos.svg?style=flat-square&label=README%20hits&color=lightgrey)

---

## Overview

QuoteBar lives in your menu bar. Click the status item and a popover drops down with a quote, its author, and a **New Quote** button. That's the whole interaction.

Where the quote comes from is the interesting part. QuoteBar tries, in order:

1. **Apple's on-device Foundation Models** — a genuinely original quote generated locally by the ~3B parameter model behind Apple Intelligence, if your Mac supports it and it's turned on
2. **[ZenQuotes](https://zenquotes.io)** — a free, keyless public API of real, attributed quotes
3. **[DummyJSON](https://dummyjson.com)** — a second free, keyless public API, tried only if ZenQuotes is unreachable
4. **A bundled offline set** — ~70 curated, public-domain-safe quotes shipped inside the app, used if there is no network at all

Every quote is tagged with which of the four produced it, so the source badge on the card tells you exactly what you're looking at — the app never pretends an AI-generated line is a real historical quote, or vice versa.

### Features

- **Menu bar native** — an accessory app with no Dock icon and no window in your way
- **On-device AI, when available** — original quotes generated locally by Apple's Foundation Models framework; nothing leaves your Mac for this path
- **Never empty-handed** — a four-tier fallback chain means a tap on **New Quote** always produces something, online or off
- **History that persists** — every quote you've seen is kept, with favorites and per-source counts
- **Local and private** — a SwiftData-backed app that keeps everything on your Mac; the only network requests are the two quote API calls above, and only when the on-device model isn't available, plus the update check
- **Updates itself** — checks once a day in the background via [Sparkle](https://sparkle-project.org) and offers a new version when there is one
- **Launch at login** — switchable in Settings, via the system login items API

---

## Install

### Homebrew

```bash
brew install sanditzz/tap/quotebar
```

The easiest route. This installs the same DMG the release page offers, drops the app in `/Applications`, and clears the Gatekeeper quarantine flag for you, so there is nothing to get past on first launch. The cask is updated as soon as a new version is published.

### Download a release

Download the latest `QuoteBar-x.y.z.dmg` from **[Releases](https://github.com/SanditZZ/quotebar-macos/releases)**, open it, and drag **QuoteBar** to your Applications folder.

> [!IMPORTANT]
> **Skip this if you installed with Homebrew** — the cask clears the quarantine flag for you. It applies only to a manual download, which macOS treats like anything else that arrived through a browser.
>
> Builds are **not notarized by Apple**, so macOS refuses to open the app the first time. After moving it to Applications, run this once:
>
> ```bash
> xattr -dr com.apple.quarantine /Applications/QuoteBar.app
> ```
>
> Or open it once, then go to **System Settings → Privacy & Security** and click **Open Anyway**. On macOS 15 and later, Control-clicking the app no longer works as a bypass.

This is a one-time cost. QuoteBar installs its own updates after that, so the prompt does not come back on every new version.

**Run it from Applications**, not from the disk image or your Downloads folder. QuoteBar updates itself in place, so a copy left elsewhere quietly never picks up new versions. The app says so in Settings if it notices.

### Updating

QuoteBar checks for a new version once a day and offers it when one appears. To check immediately, use **Settings → Updates → Check Now**, or **Check for Updates…** in the menu bar menu. The daily check can be switched off in the same place.

Updates are verified against an EdDSA public key built into the app, so a tampered or unsigned update is refused regardless of where it came from.

---

## Requirements

| | |
|---|---|
| macOS | 14.0 (Sonoma) or later to **run** |
| macOS + Apple Intelligence | 26 (Tahoe) or later, on Apple Intelligence–capable hardware, to get **AI-generated** quotes — otherwise QuoteBar automatically uses the network/offline fallbacks |
| Xcode | 26.0 or later to **build** (the `FoundationModels` framework is only in that SDK) |
| Swift | 5.0 language mode |

One third-party dependency: **[Sparkle](https://github.com/sparkle-project/Sparkle)**, for automatic updates, resolved through Swift Package Manager.

---

## Building

```bash
git clone https://github.com/SanditZZ/quotebar-macos.git
cd quotebar-macos
open QuoteBar.xcodeproj
```

Then press ⌘R.

From the command line:

```bash
# Build
xcodebuild -project QuoteBar.xcodeproj -scheme QuoteBar -configuration Debug build

# Test
xcodebuild -project QuoteBar.xcodeproj -scheme QuoteBar -configuration Debug test
```

The project signs ad-hoc (`CODE_SIGN_IDENTITY = "-"`), so **no Apple Developer account is needed** to build and run it locally.

---

## Why a four-tier fallback chain

Apple's Foundation Models framework is the best fit for "generate me a fresh quote" — it's free, private, and available on-device — but it has real limits worth designing around from day one:

- It requires **macOS 26+**, Apple Intelligence–capable hardware, and the feature switched on. A large share of real Macs will not meet all three for a while yet.
- It's a small (~3B parameter) model. It's good at short creative generation, but it can **hallucinate attributions** if asked to reproduce a real historical quote — so QuoteBar never asks it to; AI-sourced quotes are original and carry no fabricated author.

So the app never *requires* the AI path. `QuoteProviderService` walks the chain above and returns the first success, logging (not surfacing as an error) anything that falls through. The two network APIs were picked after checking they're both live, keyless, and require no setup — see [SECURITY.md](SECURITY.md) for exactly what they're sent. The bundled set exists so the app works with **no network and no Apple Intelligence at all**.

---

## Architecture

The codebase separates **Actions**, **Calculations** and **Data**, and keeps views presentational — the same layering as [idle-tapper-macos](https://github.com/SanditZZ/idle-tapper-macos), this project's sibling.

```
QuoteBar/
├── App/
│   ├── QuoteBarApp.swift          @main — menu bar only, no default window
│   ├── AppDelegate.swift          Lifecycle
│   └── AppEnvironment.swift       Composition root — the only place concrete types are chosen
├── MenuBar/
│   ├── MenuBarController.swift    NSStatusItem + NSPopover
│   ├── StatusItemRenderer.swift   Status item icon
│   └── WindowCoordinator.swift    History and Settings windows
├── Views/
│   ├── PopoverContentView.swift   The main interface
│   ├── HistoryView.swift          Seen quotes, favorites
│   ├── SettingsView.swift         Preferences
│   └── Components/                QuoteCardView, SourceBadge
├── DesignSystem/
│   ├── DesignTokens.swift         Typography, spacing, radii, motion
│   ├── AppColors.swift            Semantic, appearance-adaptive palette
│   └── CardModifier.swift         Shared container styling
├── Shared/
│   ├── Models/                    Quote, QuoteSource, QuoteRecord (@Model), QuoteSnapshot
│   ├── Logic/                     RecentQuoteFilter, QuoteHistoryStats, QuoteTextFormatter — pure
│   ├── Persistence/                QuoteRepository protocol + SwiftData implementation
│   ├── Services/                  QuoteProviderService + the four QuoteProvider implementations, AppSettings, LaunchAtLoginService
│   └── Support/                   AppLog
└── Resources/
    ├── BackupQuotes.json          The offline fallback set
    └── Localizable.xcstrings      String catalog: every user-facing string, ready to translate
```

**Calculations** (`Shared/Logic/`) are pure functions over value types — no I/O, no SwiftData, no network. Every branch is unit-tested.

**Actions** (`Shared/Services/`, `Shared/Persistence/`, `MenuBar/`) hold every side effect: the on-device model call, the two network requests, database writes, window management.

**Data** (`Shared/Models/`) is split deliberately. `QuoteRecord` is the `@Model` class bound to a `ModelContext`; `QuoteSnapshot` is the plain `Sendable` value type that crosses into the calculation layer. Pure logic never sees a managed object.

### Why `QuoteRepository` exists

Views and services talk to a protocol, never to `ModelContext`. That gives three things: SwiftData stays swappable, tests run against an in-memory container without ceremony, and adding a new persisted field doesn't ripple through the UI layer.

---

## Where your data lives

```
~/Library/Application Support/QuoteBar/
    QuoteBar.store        ← the SQLite database
    QuoteBar.store-wal    ← write-ahead log
    QuoteBar.store-shm    ← shared memory
```

All three files are the database. The `-wal` in particular routinely holds recent quotes that have not been folded into the main file yet, so copying only `QuoteBar.store` loses data.

Preferences live in `UserDefaults`, not in the database.

### If you used a build from before automatic updates

Earlier versions were sandboxed and kept the database inside the app container. Sparkle installs an update by replacing the application bundle, which a sandboxed app cannot do, so the sandbox had to go — and that changes where SwiftData writes.

The first launch after updating copies the old store to the new location automatically, so history, favorites, custom quotes and tags come across on their own. It **copies rather than moves**, leaving the original untouched as a backup, and it never overwrites a database already at the destination.

If anything looks missing, the original is still at:

```
~/Library/Containers/com.kkpon3.QuoteBar/Data/Library/Application Support/
    default.store, default.store-wal, default.store-shm
```

---

## Roadmap

The full backlog — including what makes each item non-trivial — is in **[docs/potential-features.md](docs/potential-features.md)**.

---

## Contributing

Contributions are welcome. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the architecture rules, coding standards and pull request process, and **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** for community expectations.

Security issues: please follow **[SECURITY.md](SECURITY.md)** rather than opening a public issue.

---

## License

MIT — see [LICENSE](LICENSE).
