//
//  GlobalHotKeyService.swift
//  QuoteBar — Global "New Quote" shortcut
//
//  Wraps Carbon's RegisterEventHotKey — the only way to get a system-wide
//  keyboard shortcut in a sandboxed app with zero third-party dependencies
//  and no Input Monitoring permission prompt (unlike an NSEvent global
//  monitor, which needs one).
//
//  IMPORTANT — verify against Xcode 26 before relying on this: written on a
//  Linux machine with no Carbon.framework headers to compile against, so the
//  exact signatures below (`RegisterEventHotKey`, `InstallEventHandler`,
//  `EventTypeSpec`) reflect Carbon's long-documented, unchanged public API,
//  not a verified build. Confirm the first time this builds on a Mac, via
//  `./scripts/ci-local.sh`. Also assumes the Carbon hot-key event fires on the
//  main thread via `GetEventDispatcherTarget()`, matching how every other
//  Carbon hot-key wrapper in the wild behaves.
//

import AppKit
import Carbon.HIToolbox

@MainActor
final class GlobalHotKeyService {

    /// Namespaces this app's hot key IDs from any other Carbon hot key
    /// running in the same process. 'QUOT' as a four-char code.
    private static let signature: FourCharCode = 0x51554F54

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var onFire: (() -> Void)?

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
    }

    /// Call once at launch, before the first `updateCombination(_:)`. Wires
    /// what happens when the shortcut fires; the combination itself is set
    /// separately so Settings can change it later without re-wiring this.
    func start(onFire: @escaping () -> Void) {
        self.onFire = onFire
        installEventHandlerIfNeeded()
    }

    /// Replace whatever is currently registered with `combination`. Pass
    /// `nil` to unregister without installing a new one. Safe to call
    /// repeatedly — e.g. every time `AppSettings.hotKeyCombination` changes.
    func updateCombination(_ combination: HotKeyCombination?) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        guard let combination else { return }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        var newRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(combination.keyCode),
            combination.modifierFlags,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &newRef
        )

        guard status == noErr else {
            AppLog.app.error("[HotKey] RegisterEventHotKey failed with status \(status, privacy: .public)")
            return
        }

        hotKeyRef = newRef
    }

    // MARK: - Carbon Event Handler

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let service = Unmanaged<GlobalHotKeyService>.fromOpaque(userData).takeUnretainedValue()
                MainActor.assumeIsolated {
                    service.onFire?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
    }
}
