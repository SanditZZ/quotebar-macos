//
//  UpdateService.swift
//  QuoteBar — Automatic updates
//
//  Wraps Sparkle. The app is not notarized by Apple — that needs the paid
//  Developer Program — so Sparkle's own EdDSA signature is what makes an
//  update trustworthy: it refuses any archive that does not verify against the
//  public key baked into Info.plist.
//
//  A pleasant side effect is that Gatekeeper's quarantine prompt becomes a
//  one-time cost. Sparkle performs the install itself, so updates after the
//  first manual download never re-trigger it.
//
//  All wording lives in `UpdateStatusFormatter`; this file only decides which
//  outcome occurred.
//

import Foundation
import Observation
import Sparkle

/// Observable façade over Sparkle's updater.
@MainActor
@Observable
final class UpdateService {

    /// Shared instance. Sparkle expects a single long-lived updater, and the
    /// scheduled check has to survive the Settings window closing.
    static let shared = UpdateService()

    // MARK: - Data

    @ObservationIgnored private let controller: SPUStandardUpdaterController
    @ObservationIgnored private let driverDelegate: GentleReminderDelegate
    @ObservationIgnored private let updaterDelegate: UpdaterDelegate
    @ObservationIgnored private var canCheckObservation: NSKeyValueObservation?

    /// False while a check is already running, so the button can disable.
    private(set) var canCheck: Bool = true

    /// How the most recent check ended, or nil if none has run this launch.
    private(set) var lastOutcome: UpdateCheckOutcome?

    /// Whether Sparkle checks on its own schedule. Sparkle persists this to
    /// user defaults itself; `Info.plist` supplies the initial value (on).
    var automaticallyChecks: Bool {
        didSet {
            controller.updater.automaticallyChecksForUpdates = automaticallyChecks
            AppLog.updates.info(
                "[Updates] Automatic checks \(self.automaticallyChecks ? "enabled" : "disabled", privacy: .public)"
            )
        }
    }

    /// When Sparkle last completed a check, or nil if it never has.
    var lastCheckDate: Date? { controller.updater.lastUpdateCheckDate }

    /// Set when the app is running somewhere an update cannot land properly.
    ///
    /// Resolved once at startup rather than on every read: the bundle cannot
    /// move while the app is running, so re-checking would be pure noise.
    let installLocationWarning: String?

    // MARK: - Lifecycle

    private init() {
        driverDelegate = GentleReminderDelegate()
        updaterDelegate = UpdaterDelegate()

        let location = InstallLocationCheck.classify(bundleURL: Bundle.main.bundleURL)
        installLocationWarning = InstallLocationCheck.warning(for: location)
        if location.needsWarning {
            AppLog.updates.warning(
                "[Updates] Running from \(String(describing: location), privacy: .public) — an update would not land in Applications"
            )
        }

        // `startingUpdater: true` begins the background schedule immediately.
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: updaterDelegate,
            userDriverDelegate: driverDelegate
        )

        automaticallyChecks = controller.updater.automaticallyChecksForUpdates
        canCheck = controller.updater.canCheckForUpdates

        // `canCheckForUpdates` flips while a check is in flight; observing it
        // keeps the Settings button honest instead of letting the user start a
        // second check that Sparkle would ignore.
        canCheckObservation = controller.updater.observe(
            \.canCheckForUpdates,
            options: [.new]
        ) { [weak self] _, change in
            guard let value = change.newValue else { return }
            Task { @MainActor in self?.canCheck = value }
        }

        driverDelegate.onUpdatePresented = { [weak self] version in
            Task { @MainActor in self?.lastOutcome = .updateAvailable(version: version) }
        }
        updaterDelegate.onCycleFinished = { [weak self] outcome in
            Task { @MainActor in self?.applyCycleOutcome(outcome) }
        }

        AppLog.updates.info(
            "[Updates] Sparkle ready (automatic: \(self.automaticallyChecks, privacy: .public), feed: \(self.controller.updater.feedURL?.absoluteString ?? "none", privacy: .public))"
        )
    }

    // MARK: - Actions

    /// Check now, showing Sparkle's standard UI.
    func checkForUpdates() {
        AppLog.updates.info("[Updates] Manual check requested")
        lastOutcome = .checking
        controller.checkForUpdates(nil)
    }

    /// Fold a finished update cycle into the status the user sees.
    ///
    /// Sparkle finishes the cycle *after* an update has been presented and
    /// dismissed, and reports no error when that happens. Taking that at face
    /// value would replace "Version 0.2.0 is available" with "QuoteBar is up
    /// to date" the moment the user closed the prompt, which is the opposite
    /// of true — so a version already offered this cycle wins.
    private func applyCycleOutcome(_ outcome: UpdateCheckOutcome) {
        if case .updateAvailable = lastOutcome, outcome == .upToDate { return }
        lastOutcome = outcome
    }
}

// MARK: - Delegates

/// Lets a menu bar app show update prompts at all.
///
/// Sparkle assumes a regular app that can bring a window forward. Without
/// `supportsGentleScheduledUpdateReminders`, a scheduled update found by an
/// accessory app is discovered and then never surfaced — the user is simply
/// never told. This is required, not an enhancement.
private final class GentleReminderDelegate: NSObject, SPUStandardUserDriverDelegate {

    /// Reports the version being presented, so Settings can name it.
    var onUpdatePresented: ((String) -> Void)?

    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        // Let Sparkle present it. QuoteBar has no window of its own that a
        // scheduled prompt would interrupt, so there is nothing to be polite
        // about — and staying quiet here is how an accessory app ends up never
        // telling the user an update exists.
        true
    }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        AppLog.updates.info(
            "[Updates] Presenting update \(update.displayVersionString, privacy: .public)"
        )
        onUpdatePresented?(update.displayVersionString)
    }
}

/// Reports check outcomes back to the UI.
private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {

    /// Called with how the last cycle ended.
    var onCycleFinished: ((UpdateCheckOutcome) -> Void)?

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: (any Error)?
    ) {
        guard let error else {
            AppLog.updates.info("[Updates] Check finished: up to date or update offered")
            onCycleFinished?(.upToDate)
            return
        }

        // Sparkle reports "no update found" as an error. It is not one.
        let noUpdate = (error as NSError).code == Int(Sparkle.SUError.noUpdateError.rawValue)
        if noUpdate {
            AppLog.updates.info("[Updates] Check finished: no update available")
            onCycleFinished?(.upToDate)
            return
        }

        AppLog.updates.error(
            "[Updates] Check failed: \(error.localizedDescription, privacy: .public)"
        )
        // Until the appcast is published this is the expected path, and saying
        // so beats a bare network error the user cannot act on.
        onCycleFinished?(.unreachable)
    }
}
