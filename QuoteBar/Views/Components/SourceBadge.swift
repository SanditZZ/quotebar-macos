//
//  SourceBadge.swift
//  QuoteBar — Views
//
//  A small pill naming which tier of the provider chain produced a quote —
//  the app never lets an AI-generated line pass as a real historical quote,
//  or vice versa.
//

import SwiftUI

struct SourceBadge: View {
    let source: QuoteSource

    private var tint: Color {
        switch source {
        case .onDeviceAI: return AppColors.sourceAI
        case .zenQuotes, .dummyJSON: return AppColors.sourceNetwork
        case .bundled: return AppColors.sourceBundled
        case .custom: return AppColors.sourceCustom
        }
    }

    var body: some View {
        Label(source.badgeLabel, systemImage: source.symbolName)
            .labelStyle(.titleAndIcon)
            .font(DesignTokens.Typography.tiny)
            .foregroundStyle(tint)
            .padding(.horizontal, DesignTokens.Spacing.small)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(AppColors.tint(tint))
            )
            .help(source.displayName)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(QuoteSource.allCases) { source in
            SourceBadge(source: source)
        }
    }
    .padding()
}
