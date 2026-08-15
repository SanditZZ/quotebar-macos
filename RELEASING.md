# Releasing QuoteBar

How a version reaches users, what is automated, and what is still outstanding.

QuoteBar updates itself with [Sparkle](https://sparkle-project.org). Sparkle downloads a signed
archive and replaces the application bundle in place, which is why the app is **not sandboxed** (a
sandboxed app cannot replace its own bundle) and why the database lives outside the old container.

---

## The short version

1. Bump `MARKETING_VERSION` in the Xcode project.
2. Add a `## [x.y.z]` section to `CHANGELOG.md`.
3. Merge to `main`.

That is the whole release. The workflow reads the version, notices there is no matching tag, and
builds, signs, packages, publishes the release, regenerates the signed appcast, and updates the
Homebrew cask. Ordinary commits produce no release, because the tag already exists.

Rehearse the build and packaging locally first:

```bash
scripts/ci-local.sh all        # must be green before anything
scripts/package-release.sh     # mirrors the workflow, minus notarization and publishing
```

---

## Before the first release: what is not set up yet

Three things are outstanding. The release itself works without them; automatic updating does not.

### 1. GitHub Pages and the `gh-pages` branch — REQUIRED for updates

`SUFeedURL` points at `https://sanditzz.github.io/quotebar-macos/appcast.xml`. Nothing serves that
yet. The repository is public, so Pages is available; it just needs a branch and a one-time switch:

```bash
git checkout --orphan gh-pages
git rm -rf .
mkdir -p releases
printf 'QuoteBar update feed.\n' > index.html
git add index.html
git commit -m "Added the gh-pages branch for the update feed"
git push origin gh-pages
git checkout main
```

Then enable Pages, serving from the `gh-pages` branch, root directory:

```bash
gh api -X POST repos/SanditZZ/quotebar-macos/pages \
  -f 'source[branch]=gh-pages' -f 'source[path]=/'
```

Until this exists, `generate-appcast.yml` fails on its checkout step. That failure is loud but
harmless: the release is already published by then, and users just do not get automatic updates.

### 2. A Developer ID certificate — RECOMMENDED, not required

There is no Developer ID Application certificate on the development machine today, only an
`Apple Development` one, which cannot sign software for distribution outside the App Store.

The release workflow handles this deliberately. With no certificate it emits a `::warning::` and
ships an **ad-hoc signed, unnotarized** build rather than failing. The cost lands on users:

- macOS refuses to open the app the first time. The release notes tell them to run
  `xattr -dr com.apple.quarantine /Applications/QuoteBar.app`, or use **Open Anyway** in
  System Settings → Privacy & Security. Control-clicking no longer works on macOS 15+.
- Sparkle's own EdDSA signature still protects updates. Notarization is Apple vouching for the
  app; the EdDSA key is what stops a tampered update installing, and that is already in place.
- Gatekeeper's prompt is a **one-time** cost. Sparkle performs later installs itself, so updates
  after the first manual download do not re-trigger it.

To switch the signed and notarized path on, add these secrets. No file needs to change.

| Secret | What it is |
|---|---|
| `DEVELOPER_CERTIFICATE_BASE64` | The Developer ID Application `.p12`, base64 encoded |
| `CERTIFICATE_PASSWORD` | The password for that `.p12` |
| `APPLE_ID` | The Apple ID used for notarization |
| `APPLE_ID_PASSWORD` | An **app-specific** password, not the account password |
| `APPLE_TEAM_ID` | The team ID (`4A2R8VCQ4C`) |

The workflow switches mode when both `DEVELOPER_CERTIFICATE_BASE64` and `APPLE_ID` are present.

### 3. The Homebrew cask — OPTIONAL

`update-homebrew-tap.yml` keeps `SanditZZ/homebrew-tap` current, but only updates a cask that
already exists. Create `Casks/quotebar.rb` in the tap once by hand, then set a
`HOMEBREW_TAP_DEPLOY_KEY` secret. Without both, that job fails and the release is otherwise
unaffected.

The secret is the **private half of an SSH deploy key** registered on the tap with write access,
not a personal access token. A PAT with `contents:write` can write to every repository the account
owns, so leaking one from CI costs the whole account; a deploy key can write to the tap and nothing
else, and it does not expire.

To create or rotate one:

```bash
ssh-keygen -t ed25519 -N "" -C "quotebar-macos release workflow -> SanditZZ/homebrew-tap" -f tap-deploy-key
gh api repos/SanditZZ/homebrew-tap/keys -f title="quotebar-macos release workflow" \
  -f key="$(cat tap-deploy-key.pub)" -F read_only=false
gh secret set HOMEBREW_TAP_DEPLOY_KEY --repo SanditZZ/quotebar-macos < tap-deploy-key
```

Keep the private key out of the repository, and revoke an old key from the tap's Deploy keys
settings after rotating. To re-sync the cask without cutting a release, run the workflow manually:

```bash
gh workflow run update-homebrew-tap.yml --repo SanditZZ/quotebar-macos -f release_tag=v0.4.0
```

Note this only keeps a *fresh* `brew install` current. Sparkle is what updates installs that
already exist; the two are independent.

---

## The signing key

QuoteBar has its **own** EdDSA key pair, deliberately not the one `idle-tapper-macos` uses.

- **Public half**: `SUPublicEDKey` in `QuoteBar/Info.plist`. Safe to publish, and it must never
  change once a release is out. Every installed copy verifies against the key it shipped with, so
  replacing it strands every existing user on their current version, permanently.
- **Private half**: in the login keychain under the account `QuoteBar`, and in the
  `SPARKLE_PRIVATE_KEY` repository secret. It must never enter the repository.

To export it again (for a new machine, or to re-set the secret):

```bash
generate_keys --account QuoteBar -x /path/outside/the/repo/key.txt
gh secret set SPARKLE_PRIVATE_KEY --repo SanditZZ/quotebar-macos < /path/outside/the/repo/key.txt
```

`generate_keys` ships with Sparkle; after `xcodebuild -resolvePackageDependencies` it is under
`~/Library/Developer/Xcode/DerivedData/QuoteBar-*/SourcePackages/artifacts/sparkle/Sparkle/bin/`.

**Lose the private key and you cannot ship another update to anyone.** Back it up somewhere real.

---

## What the workflows do

| Workflow | Trigger | Does |
|---|---|---|
| `ci.yml` | PRs and pushes to `main` | Builds warnings-as-errors, checks embedded frameworks, runs tests |
| `release.yml` | Push to `main` with a new `MARKETING_VERSION` | Builds, signs, notarizes if it can, packages a zip and DMG, publishes the release |
| `generate-appcast.yml` | Called by `release.yml` | Signs the zip with the EdDSA key, regenerates `appcast.xml`, commits it to `gh-pages` |
| `update-homebrew-tap.yml` | Called by `release.yml` | Points the cask at the new version and checksum |

`generate-appcast.yml` is **called as a job**, not triggered by the `release: published` event.
A release created by a workflow is created by `GITHUB_TOKEN`, and GitHub will not start new
workflow runs from events that token raises, so the event never arrives. The sibling project
shipped a release with no appcast for exactly this reason. The failure is silent: the release looks
perfect while no installed copy is ever told about it.

Note the two runner images differ on purpose. Anything that compiles the app needs `macos-26`,
because `FoundationModels` exists only in the macOS 26 SDK and the app references it. The appcast
job compiles nothing and stays on `macos-15`.

---

## Verifying a release actually works

Publishing is not the same as updating. To confirm the loop closes:

1. Check the feed is live and signed: `curl -s https://sanditzz.github.io/quotebar-macos/appcast.xml`
   should list the new version, and each `<enclosure>` should carry an `sparkle:edSignature`.
2. Install the **previous** version from its DMG into `/Applications`, and launch it.
3. Settings → General → Updates → **Check Now**. The new version should be offered by name.
4. Install it, and confirm the app relaunches on the new version with its history intact.

Step 4 is the one worth doing properly. An update that installs but loses the user's quotes is
worse than no update.

**Run the copy under test from `/Applications`.** Sparkle replaces the bundle where it currently
sits, so a copy launched from the mounted DMG or from `~/Downloads` updates *that* copy and leaves
`/Applications` untouched. The app now warns about this in Settings when it notices, but the test
is only meaningful from the real location.

---

## Things that will bite

- **Never `zip` the app.** Both the workflow and `package-release.sh` use `ditto -c -k --keepParent`.
  Plain `zip` mangles symlinks and bundle structure and silently invalidates the signature, and
  Sparkle verifies that exact archive on every user's machine.
- **Do not roll `SUPublicEDKey` back or forward casually.** See above: it strands existing users.
- **Keep the `SPARKLE_VERSION` in `generate-appcast.yml` in step with `Package.resolved`.** The
  tools and the framework need not match exactly, but a signing tool from a different era than the
  installed updater is the kind of drift nobody notices until an update refuses to install.
- **The framework check is not optional.** `scripts/check-embedded-frameworks.sh` exists because
  adding Sparkle produced a bundle that passed all 145 tests and crashed instantly on launch with
  `Library not loaded: @rpath/Sparkle.framework`. Tests run in a host that resolves frameworks
  differently, so they cannot see this. CI, `ci-local.sh` and `package-release.sh` all run it.
- **The first unsandboxed launch migrates the database.** `StoreMigrator` copies the old container
  store to `~/Library/Application Support/QuoteBar/`, leaving the original in place as a backup. It
  never overwrites an occupied destination. If a user reports missing history after updating, their
  data is still at
  `~/Library/Containers/com.kkpon3.QuoteBar/Data/Library/Application Support/default.store`
  along with its `-wal` and `-shm` sidecars, and all three matter.
