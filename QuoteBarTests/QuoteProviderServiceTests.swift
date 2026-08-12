//
//  QuoteProviderServiceTests.swift
//  QuoteBarTests
//
//  Exercises the fallback chain itself using fake providers — no real network
//  or on-device model calls in a test.
//

import Testing
import Foundation
@testable import QuoteBar

private struct FakeProvider: QuoteProvider {
    let source: QuoteSource
    let result: Quote?

    func nextQuote() async -> Quote? { result }
}

@Suite("Quote provider service")
struct QuoteProviderServiceTests {

    @Test("Uses the on-device AI result when it succeeds")
    func usesOnDeviceWhenAvailable() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: TestSupport.quote(text: "AI line", author: nil, source: .onDeviceAI)),
            networkProviders: [FakeProvider(source: .zenQuotes, result: TestSupport.quote(text: "Should not be used"))],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: nil)

        #expect(quote.source == .onDeviceAI)
        #expect(quote.text == "AI line")
    }

    @Test("Falls through to the first network provider when AI fails")
    func fallsThroughToFirstNetworkProvider() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: nil),
            networkProviders: [
                FakeProvider(source: .zenQuotes, result: TestSupport.quote(text: "Zen line", source: .zenQuotes)),
                FakeProvider(source: .dummyJSON, result: TestSupport.quote(text: "Dummy line", source: .dummyJSON)),
            ],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: nil)

        #expect(quote.source == .zenQuotes)
    }

    @Test("Falls through to the second network provider when the first fails")
    func fallsThroughToSecondNetworkProvider() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: nil),
            networkProviders: [
                FakeProvider(source: .zenQuotes, result: nil),
                FakeProvider(source: .dummyJSON, result: TestSupport.quote(text: "Dummy line", source: .dummyJSON)),
            ],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: nil)

        #expect(quote.source == .dummyJSON)
    }

    @Test("Falls through to bundled when every other tier fails")
    func fallsThroughToBundled() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: nil),
            networkProviders: [
                FakeProvider(source: .zenQuotes, result: nil),
                FakeProvider(source: .dummyJSON, result: nil),
            ],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: nil)

        #expect(quote.source == .bundled)
    }

    @Test("A tier whose result repeats a recent quote is treated as a failure")
    func repeatedResultIsSkipped() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: TestSupport.quote(text: "Already seen", source: .onDeviceAI)),
            networkProviders: [
                FakeProvider(source: .zenQuotes, result: TestSupport.quote(text: "Fresh one", source: .zenQuotes)),
            ],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: ["Already Seen"], preference: nil) // case-insensitive match

        #expect(quote.source == .zenQuotes)
        #expect(quote.text == "Fresh one")
    }

    @Test("A pinned source that succeeds is served, skipping every other tier")
    func pinnedSourceIsServedWhenItSucceeds() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: TestSupport.quote(text: "Should not be used", source: .onDeviceAI)),
            networkProviders: [
                FakeProvider(source: .zenQuotes, result: TestSupport.quote(text: "Zen line", source: .zenQuotes)),
                FakeProvider(source: .dummyJSON, result: TestSupport.quote(text: "Should not be used either", source: .dummyJSON)),
            ],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: .zenQuotes)

        #expect(quote.source == .zenQuotes)
        #expect(quote.text == "Zen line")
    }

    @Test("A pinned source that fails falls straight to bundled, skipping other network tiers")
    func pinnedSourceFallsThroughToBundledOnly() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: nil),
            networkProviders: [
                FakeProvider(source: .zenQuotes, result: nil),
                FakeProvider(source: .dummyJSON, result: TestSupport.quote(text: "Should be skipped, not pinned", source: .dummyJSON)),
            ],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: .zenQuotes)

        #expect(quote.source == .bundled)
    }

    @Test("Pinning on-device AI skips both network tiers when it fails")
    func pinnedOnDeviceAISkipsNetworkTiers() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: nil),
            networkProviders: [
                FakeProvider(source: .zenQuotes, result: TestSupport.quote(text: "Should be skipped, not pinned", source: .zenQuotes)),
            ],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: .onDeviceAI)

        #expect(quote.source == .bundled)
    }

    @Test("A pin-only provider is never tried in automatic mode")
    func pinOnlyProviderNeverAutomaticallyTried() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: nil),
            networkProviders: [FakeProvider(source: .zenQuotes, result: nil)],
            pinnedOnlyProviders: [FakeProvider(source: .custom, result: TestSupport.quote(text: "Should never appear automatically", source: .custom))],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: nil)

        #expect(quote.source == .bundled)
    }

    @Test("A pin-only provider is served once explicitly pinned")
    func pinOnlyProviderServedWhenPinned() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: TestSupport.quote(text: "Should not be used", source: .onDeviceAI)),
            networkProviders: [],
            pinnedOnlyProviders: [FakeProvider(source: .custom, result: TestSupport.quote(text: "My own quote", source: .custom))],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: .custom)

        #expect(quote.source == .custom)
        #expect(quote.text == "My own quote")
    }

    @Test("A pinned pin-only provider that fails falls straight to bundled")
    func pinOnlyProviderFallsThroughToBundledOnFailure() async {
        let service = QuoteProviderService(
            onDeviceAI: FakeProvider(source: .onDeviceAI, result: nil),
            networkProviders: [],
            pinnedOnlyProviders: [FakeProvider(source: .custom, result: nil)],
            bundled: BundledQuoteProvider()
        )

        let quote = await service.nextQuote(recentTexts: [], preference: .custom)

        #expect(quote.source == .bundled)
    }
}
