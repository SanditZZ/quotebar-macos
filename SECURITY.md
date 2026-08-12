# Security Policy

## Supported versions

QuoteBar is developed on the `main` branch. Security fixes are applied to the latest release only.

| Version | Supported |
|---|---|
| Latest release | Yes |
| Older releases | No |

## Reporting a vulnerability

**Please do not open a public GitHub issue for a security problem.**

Report it privately using [GitHub's private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) on this repository, or by emailing the maintainer.

Please include:

- A description of the issue and its impact
- Steps to reproduce
- The affected version and your macOS version
- Any suggested fix, if you have one

You can expect an acknowledgement within a few days and an assessment shortly after. If the report is valid, we will agree a disclosure timeline with you and credit you in the release notes unless you prefer otherwise.

## Scope

QuoteBar is a local menu bar app with no accounts and no telemetry. It has no third-party dependencies, and it makes network requests to fetch a quote when the on-device model is unavailable (see below).

The app **is sandboxed** (`com.apple.security.app-sandbox`), with two additional entitlements: `com.apple.security.network.client`, used only to reach the two public quote APIs described below, and `com.apple.security.files.user-selected.read-only`, used only to read a JSON/CSV file you explicitly pick via Settings' "Your Quotes" import — the app cannot read any other file on disk.

Areas that are in scope:

- Anything that lets a fetched quote execute code, inject markup, or otherwise be treated as more than plain text
- Privilege escalation, or writing outside the app's sandbox container
- Unauthorised reading or modification of the app's local database by another process
- Any route to bypassing the sandbox

Out of scope:

- The SwiftData database being readable by the user who owns it — this is expected; it is that user's own data on their own machine
- Denial of service that requires physical access to an unlocked Mac
- The third-party quote APIs' own availability or content — report issues with them upstream

## Data handling

For clarity, since it affects what a vulnerability could expose:

- Quote history (text, author, source, favorite flag, timestamp seen) and your custom/imported quote library are stored in a local SwiftData/SQLite database inside the app's sandbox container
- Preferences are stored in `UserDefaults`
- No identifier, usage information, or history is transmitted anywhere; there is no server, no analytics and no crash reporting
- When the on-device model is unavailable, the app requests a quote from **[ZenQuotes](https://zenquotes.io)** or **[DummyJSON](https://dummyjson.com)** — both public, keyless, unauthenticated APIs. These requests carry no identifying information beyond what any HTTP request discloses (IP address, standard headers). Neither call is made if you have no network connection; the app falls back to its bundled offline quote set instead
- Quote generation via Apple's Foundation Models framework happens entirely on-device — nothing about the prompt or the result leaves your Mac
