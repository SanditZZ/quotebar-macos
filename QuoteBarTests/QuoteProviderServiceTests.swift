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

        let quote = await service.nextQuote(recentTexts: [])

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

        let quote = await service.nextQuote(recentTexts: [])

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

        let quote = await service.nextQuote(recentTexts: [])

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

        let quote = await service.nextQuote(recentTexts: [])

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

        let quote = await service.nextQuote(recentTexts: ["Already Seen"]) // case-insensitive match

        #expect(quote.source == .zenQuotes)
        #expect(quote.text == "Fresh one")
    }
}
