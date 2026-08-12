//
//  HotKeyDisplayFormatter.swift
//  QuoteBar — Calculations
//
//  Renders a `HotKeyCombination` as the symbol string macOS conventionally
//  shows for a shortcut, e.g. "⌃⌥Q". Pure: a static lookup table, no keyboard
//  layout queried at runtime — so an unusual physical layout may show the
//  wrong letter for a given key code, a known, accepted simplification rather
//  than pulling in `UCKeyTranslate` for a cosmetic label.
//

import Carbon.HIToolbox

enum HotKeyDisplayFormatter {

    static func format(_ combination: HotKeyCombination) -> String {
        modifierSymbols(combination.modifierFlags) + keySymbol(for: combination.keyCode)
    }

    // MARK: - Modifiers

    /// Fixed order macOS uses everywhere: Control, Option, Shift, Command.
    private static func modifierSymbols(_ carbonModifiers: UInt32) -> String {
        var symbols = ""
        if carbonModifiers & UInt32(controlKey) != 0 { symbols += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { symbols += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { symbols += "⌘" }
        return symbols
    }

    // MARK: - Key

    /// US ANSI virtual key codes for the keys a shortcut is realistically
    /// bound to. Anything outside this table (an unusual key, or a layout
    /// where the physical key differs) falls back to a numbered label rather
    /// than guessing.
    private static let keySymbols: [UInt16: String] = [
        0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G",
        0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
        0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T", 0x1F: "O",
        0x20: "U", 0x22: "I", 0x23: "P", 0x25: "L", 0x26: "J", 0x28: "K",
        0x2D: "N", 0x2E: "M",
        0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5",
        0x19: "9", 0x1A: "7", 0x1C: "8", 0x1D: "0",
        0x24: "⏎", 0x30: "⇥", 0x31: "Space", 0x33: "⌫", 0x35: "⎋",
        0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑",
    ]

    private static func keySymbol(for keyCode: UInt16) -> String {
        keySymbols[keyCode] ?? "Key \(keyCode)"
    }
}
