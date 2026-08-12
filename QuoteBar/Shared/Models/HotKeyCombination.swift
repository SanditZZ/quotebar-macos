//
//  HotKeyCombination.swift
//  QuoteBar — Data
//
//  A key + modifier combination for the global "New Quote" shortcut. Plain
//  data, no logic — see `Shared/Logic/HotKeyDisplayFormatter.swift` for
//  rendering it and `Shared/Services/GlobalHotKeyService.swift` for
//  registering it.
//
//  `keyCode` is a virtual key code (the same numbering `NSEvent.keyCode` and
//  Carbon's `kVK_*` constants share). `modifierFlags` is stored pre-converted
//  to Carbon's modifier bitmask (`cmdKey`/`optionKey`/`controlKey`/`shiftKey`
//  from `Carbon.HIToolbox`), since that's what registering the hot key needs
//  — converting once, when the combination is recorded, keeps every other
//  layer free of the AppKit/Carbon split.
//

import Foundation
import Carbon.HIToolbox

struct HotKeyCombination: Codable, Sendable, Equatable {
    let keyCode: UInt16
    let modifierFlags: UInt32

    /// Shipped default so the feature works before the user ever opens
    /// Settings: Control+Option+Q. `0x0C` is `kVK_ANSI_Q`.
    static let `default` = HotKeyCombination(
        keyCode: 0x0C,
        modifierFlags: UInt32(controlKey) | UInt32(optionKey)
    )
}
