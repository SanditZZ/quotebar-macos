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
