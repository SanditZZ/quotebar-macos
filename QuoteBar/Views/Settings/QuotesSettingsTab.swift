//
//  QuotesSettingsTab.swift
//  QuoteBar — Views
//
//  Where quotes come from, the user's own library, and tags.
//

import SwiftUI

struct QuotesSettingsTab: View {
    var settings: AppSettings
    var customQuoteLibrary: CustomQuoteLibrary
    var tagLibrary: QuoteTagLibrary

    var body: some View {
        SettingsTabScroll {
            quoteSourceSection

            SettingsSection("Your Quotes") {
                CustomQuotesEditor(library: customQuoteLibrary)
            }

            SettingsSection("Tags") {
                TagsEditor(library: tagLibrary)
            }
        }
    }

    // MARK: - Quote Source

    private var quoteSourceSection: some View {
        SettingsSection("Quote Source") {
            Picker("Preferred source", selection: preferredSourceBinding) {
                Text("Automatic").tag(QuoteSource?.none)
                ForEach(QuoteSource.allCases) { source in
                    Text(source.displayName).tag(QuoteSource?.some(source))
                }
            }
            .pickerStyle(.menu)

            Text(quoteSourceCaption)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(settings.preferredSource == .onDeviceAI ? AppColors.warning : AppColors.textTertiary)
        }
    }

    private var preferredSourceBinding: Binding<QuoteSource?> {
        Binding(
            get: { settings.preferredSource },
            set: { settings.preferredSource = $0 }
        )
    }

    private var quoteSourceCaption: String {
        switch settings.preferredSource {
        case .none:
            return "Tries on-device AI, then the web, then the offline set — whichever responds first."
        case .onDeviceAI:
            return "Only works on macOS 26+ with Apple Intelligence enabled on this Mac. If it isn't available, a quote is still shown from another source, and that's noted on the card."
        case .zenQuotes, .dummyJSON:
            return "Requires a network connection. If the request fails, a quote is still shown from another source, and that's noted on the card."
        case .bundled:
            return "Always available offline — no network or on-device model needed."
        case .custom:
            return "Only quotes from your library below. If it's empty, a quote is still shown from another source, and that's noted on the card."
        }
    }
}
