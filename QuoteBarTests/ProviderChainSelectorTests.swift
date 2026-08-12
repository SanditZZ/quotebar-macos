//
//  ProviderChainSelectorTests.swift
//  QuoteBarTests
//

import Testing
import Foundation
@testable import QuoteBar

@Suite("Provider chain selector")
struct ProviderChainSelectorTests {

    private static let defaultOrder: [QuoteSource] = [.onDeviceAI, .zenQuotes, .dummyJSON]

    @Test("Automatic (nil) preference returns the default order unchanged")
    func automaticReturnsDefaultOrder() {
        let order = ProviderChainSelector.resolvedOrder(
            preference: nil,
            defaultOrder: Self.defaultOrder,
            bundled: .bundled
        )

        #expect(order == Self.defaultOrder)
    }

    @Test("Pinning a source tries only that source, then bundled")
    func pinnedSourceTriesOnlyItselfThenBundled() {
        let order = ProviderChainSelector.resolvedOrder(
            preference: .zenQuotes,
            defaultOrder: Self.defaultOrder,
            bundled: .bundled
        )

        #expect(order == [.zenQuotes, .bundled])
    }

    @Test("Pinning on-device AI skips both network tiers")
    func pinnedOnDeviceAISkipsNetworkTiers() {
        let order = ProviderChainSelector.resolvedOrder(
            preference: .onDeviceAI,
            defaultOrder: Self.defaultOrder,
            bundled: .bundled
        )

        #expect(order == [.onDeviceAI, .bundled])
    }

    @Test("Pinning bundled itself does not duplicate it")
    func pinnedBundledIsNotDuplicated() {
        let order = ProviderChainSelector.resolvedOrder(
            preference: .bundled,
            defaultOrder: Self.defaultOrder,
            bundled: .bundled
        )

        #expect(order == [.bundled])
    }
}
