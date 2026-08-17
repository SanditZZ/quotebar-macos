# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Homebrew is now documented as the easiest way to install QuoteBar, with `brew install sanditzz/tap/quotebar` leading the Install section. The cask has been kept in step with every release since 0.2.0 and clears the Gatekeeper quarantine flag as it installs, so that route needs no terminal step and no trip through Privacy and Security, but the README had never mentioned it and sent everyone down the manual path instead
- The manual download instructions now say plainly that the Gatekeeper step applies only to a browser download, so anyone who used Homebrew can skip it

### Fixed

- The README sent people to General for the Check Now button, which has had its own Updates tab in Settings since 0.4.0

## [0.4.0] - 2026-08-14

Settings gains an Updates tab, and the menu bar menu stops offering actions it cannot carry out.

### Changed

- MOVED: the update controls now have their own Updates tab in Settings, instead of sitting at the bottom of General under Notifications. The switch, the Check Now button and the last-checked line are unchanged, and the "Check for Updates..." item in the menu bar menu still works as before

### Fixed

- Share Quote, Read Aloud and Check for Updates in the menu bar's right-click menu looked available when there was nothing for them to act on, and clicking them did nothing. They are now greyed out with no quote to share or read, and while an update check is already running

## [0.3.0] - 2026-08-13

Window chrome rework, and QuoteBar now appears in the Command-Tab switcher while a window is open.

### Added

- QuoteBar joins the Command-Tab switcher while History or Settings is open, and leaves it again once the last window closes. A Dock icon appears for as long as a window is open, since macOS ties the two together
- A standard menu bar, so Cut, Copy, Paste and Select All work in every text field

### Changed

- Settings now has a full-height sidebar with the traffic lights inside it, in place of the header strip across the top. History keeps its header, since it has no sidebar

### Fixed

- Borderless windows lost their rounded corners as soon as content was attached, leaving square corners on History and Settings
- Command-comma opened a second, plain grey Settings window instead of the real one
- QuoteBar stayed in the Command-Tab switcher with no windows open, but only after both History and Settings had been opened at least once

## [0.2.0] - 2026-08-13

First public release. QuoteBar can now update itself, which is what makes every later release reachable.

### Added

- Initial scaffold: menu bar popover with a quote card and a "New Quote" button
- Four-tier quote provider chain — on-device Apple Foundation Models, then ZenQuotes, then DummyJSON, then a bundled offline set — so a quote is always available
- History window with seen quotes and favorites
- SwiftData-backed local history, no accounts, no sync
- App icon, generated from the same SF Symbol the menu bar uses
- Accessibility labels on the icon-only controls, so each is announced by name and state instead of as "0", "circle" or "Trash"
- Automatic updates via Sparkle: QuoteBar checks for a new version once a day in the background, and offers it when one is found
- An Updates section in Settings, under General, with a switch for the daily check, a Check Now button, and a line saying when the last check happened
- A "Check for Updates..." item in the menu bar menu, disabled while a check is already running
- A warning in Settings when QuoteBar is running from a disk image or from somewhere other than Applications, since it updates itself in place and a copy left elsewhere would never pick up new versions
- A release pipeline that builds, signs, packages a zip and a DMG, publishes the release, regenerates the signed update feed, and refreshes the Homebrew cask when the version changes
- RELEASING.md, covering how to cut a version and what is still needed before automatic updates reach users

### Changed

- Popover footer actions are now icon-only, with the name kept as a tooltip and an accessibility label
- History and Settings are now translucent windows with their own header and traffic lights, in place of the standard opaque grey title bar
- Settings is organized into General, Quotes, Sharing, Data and About tabs down the left, instead of one long scroll of eleven sections that buried Backup and About at the bottom
- Settings opens larger, at 660x560, to make room for the tab sidebar
- Switches in Settings now carry a short line of explanatory text under the name
- The app is no longer sandboxed, because Sparkle installs an update by replacing the application bundle and a sandboxed app cannot do that
- Quote history now lives in ~/Library/Application Support/QuoteBar/ instead of inside the sandbox container. Existing history, favorites, custom quotes and tags are copied across on the first launch after updating, and the original is left in place untouched

### Fixed

- History and Settings opened collapsed to roughly a title bar (128x122 and 440x28), below their own stated minimum size
- A tag rename that was never submitted with Return left the row stuck in edit mode, hiding the tag's real name, with no way out but committing the unwanted text
- Popover footer captions wrapped to one or two characters per line, because five labelled buttons cannot fit the popover width
- The two backup export buttons never opened a save panel, because all three file panels were attached to the same view and SwiftUI keeps only the last one
- The app would have crashed on launch once Sparkle was added, because the bundle embedded the framework without declaring a runpath to reach it. CI now inspects the built binary, which the test suite cannot do

[Unreleased]: https://github.com/SanditZZ/quotebar-macos/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/SanditZZ/quotebar-macos/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/SanditZZ/quotebar-macos/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/SanditZZ/quotebar-macos/releases/tag/v0.2.0
