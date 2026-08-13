# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial scaffold: menu bar popover with a quote card and a "New Quote" button
- Four-tier quote provider chain — on-device Apple Foundation Models, then ZenQuotes, then DummyJSON, then a bundled offline set — so a quote is always available
- History window with seen quotes and favorites
- SwiftData-backed local history, no accounts, no sync
- App icon, generated from the same SF Symbol the menu bar uses
- Accessibility labels on the icon-only controls, so each is announced by name and state instead of as "0", "circle" or "Trash"

### Changed

- Popover footer actions are now icon-only, with the name kept as a tooltip and an accessibility label

### Fixed

- History and Settings opened collapsed to roughly a title bar (128x122 and 440x28), below their own stated minimum size
- A tag rename that was never submitted with Return left the row stuck in edit mode, hiding the tag's real name, with no way out but committing the unwanted text
- Popover footer captions wrapped to one or two characters per line, because five labelled buttons cannot fit the popover width
