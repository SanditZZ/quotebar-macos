//
//  HotKeyDisplayFormatterTests.swift
//  QuoteBarTests
//

import Testing
import Carbon.HIToolbox
@testable import QuoteBar

@Suite("Hot key display formatter")
struct HotKeyDisplayFormatterTests {

    @Test("Formats the shipped default as ⌃⌥Q")
    func formatsDefault() {
        #expect(HotKeyDisplayFormatter.format(.default) == "⌃⌥Q")
    }

    @Test("Orders modifier symbols Control, Option, Shift, Command")
    func ordersModifierSymbols() {
        let combination = HotKeyCombination(
            keyCode: 0x00,
            modifierFlags: UInt32(cmdKey) | UInt32(shiftKey) | UInt32(optionKey) | UInt32(controlKey)
        )

        #expect(HotKeyDisplayFormatter.format(combination) == "⌃⌥⇧⌘A")
    }

    @Test("Falls back to a numbered label for a key code outside the table")
    func fallsBackForUnknownKeyCode() {
        let combination = HotKeyCombination(keyCode: 999, modifierFlags: UInt32(controlKey))
        #expect(HotKeyDisplayFormatter.format(combination) == "⌃Key 999")
    }

    @Test("No modifiers formats as just the key symbol")
    func noModifiersFormatsAsKeyOnly() {
        let combination = HotKeyCombination(keyCode: 0x31, modifierFlags: 0)
        #expect(HotKeyDisplayFormatter.format(combination) == "Space")
    }
}
