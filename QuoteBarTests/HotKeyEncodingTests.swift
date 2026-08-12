//
//  HotKeyEncodingTests.swift
//  QuoteBarTests
//

import Testing
import AppKit
import Carbon.HIToolbox
@testable import QuoteBar

@Suite("Hot key encoding")
struct HotKeyEncodingTests {

    @Test("Converts each NSEvent modifier to its Carbon bit")
    func convertsEachModifier() {
        #expect(HotKeyEncoding.carbonModifiers(from: [.command]) == UInt32(cmdKey))
        #expect(HotKeyEncoding.carbonModifiers(from: [.option]) == UInt32(optionKey))
        #expect(HotKeyEncoding.carbonModifiers(from: [.control]) == UInt32(controlKey))
        #expect(HotKeyEncoding.carbonModifiers(from: [.shift]) == UInt32(shiftKey))
    }

    @Test("Combines multiple modifiers")
    func combinesModifiers() {
        let result = HotKeyEncoding.carbonModifiers(from: [.control, .option])
        #expect(result == UInt32(controlKey) | UInt32(optionKey))
    }

    @Test("Ignores modifiers outside command/option/control/shift")
    func ignoresIrrelevantModifiers() {
        let result = HotKeyEncoding.carbonModifiers(from: [.capsLock, .function])
        #expect(result == 0)
    }

    @Test("No modifiers is not a usable hot key")
    func noModifiersIsUnusable() {
        #expect(!HotKeyEncoding.hasUsableModifier(0))
    }

    @Test("Any modifier bit makes a hot key usable")
    func anyModifierIsUsable() {
        #expect(HotKeyEncoding.hasUsableModifier(UInt32(controlKey)))
    }
}
