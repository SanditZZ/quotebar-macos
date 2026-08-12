//
//  HotKeyEncoding.swift
//  QuoteBar — Calculations
//
//  Pure bit-flag translation between AppKit's NSEvent.ModifierFlags (used
//  while recording a shortcut in Settings) and Carbon's modifier bitmask
//  (used to register it). No I/O, no event capture — see
//  `Views/Components/ShortcutRecorderField.swift` for where an actual
//  NSEvent gets turned into a `HotKeyCombination` using these.
//

import AppKit
import Carbon.HIToolbox

enum HotKeyEncoding {
    /// The only modifiers a global hot key cares about — caps lock, function,
    /// and device-independent flag bits are masked out.
    static let relevantModifierFlags: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    /// A combination with no modifier at all would fire on every press of an
    /// ordinary key system-wide — never something a global shortcut should
    /// accept.
    static func hasUsableModifier(_ carbonModifiers: UInt32) -> Bool {
        carbonModifiers != 0
    }
}
