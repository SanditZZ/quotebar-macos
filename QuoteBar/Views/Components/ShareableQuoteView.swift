//
//  ShareableQuoteView.swift
//  QuoteBar — Views
//
//  The layout rendered to a PNG for sharing — not shown live in the app
//  itself. Deliberately simpler than `QuoteCardView`: no favorite button, no
//  source badge (an in-app detail, not something worth showing to whoever
//  the image gets shared with). Fixed-tone per `style`, not appearance
//  adaptive — see `ShareCardStyle`.
//

import SwiftUI

struct ShareableQuoteView: View {
    let quote: QuoteSnapshot
    let style: ShareCardStyle

    var body: some View {
        ZStack(alignment: .topLeading) {
            background

            Image(systemName: StatusItemRenderer.symbolName)
                .font(.system(size: DesignTokens.Layout.shareImageSize.width * 0.14))
                .foregroundStyle(accentColor.opacity(0.14))
                .padding(DesignTokens.Spacing.sharePadding * 0.6)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text(quote.text)
                    .font(DesignTokens.Typography.shareQuote)
                    .foregroundStyle(textColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, DesignTokens.Spacing.section)

                HStack(spacing: DesignTokens.Spacing.small) {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 28, height: 2)
                    Text(QuoteTextFormatter.authorDisplay(quote.author))
                        .font(DesignTokens.Typography.shareAuthor)
                        .foregroundStyle(textColor.opacity(0.92))
                }

                Spacer()

                HStack(spacing: 7) {
                    Image(systemName: StatusItemRenderer.symbolName)
                        .foregroundStyle(accentColor)
                    Text("QuoteBar")
                }
                .font(DesignTokens.Typography.shareWatermark)
                .foregroundStyle(textSecondaryColor)
            }
            .padding(DesignTokens.Spacing.sharePadding)
        }
        .frame(width: DesignTokens.Layout.shareImageSize.width, height: DesignTokens.Layout.shareImageSize.height)
    }

    // MARK: - Style

    private var background: some View {
        switch style {
        case .midnight:
            AnyView(
                LinearGradient(
                    colors: [AppColors.shareMidnightBackgroundTop, AppColors.shareMidnightBackgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .paper:
            AnyView(AppColors.sharePaperBackground)
        }
    }

    private var textColor: Color {
        switch style {
        case .midnight: return AppColors.shareMidnightText
        case .paper: return AppColors.sharePaperText
        }
    }

    private var textSecondaryColor: Color {
        switch style {
        case .midnight: return AppColors.shareMidnightTextSecondary
        case .paper: return AppColors.sharePaperTextSecondary
        }
    }

    private var accentColor: Color {
        switch style {
        case .midnight: return AppColors.shareMidnightAccent
        case .paper: return AppColors.sharePaperAccent
        }
    }
}

#Preview("Midnight") {
    ShareableQuoteView(
        quote: QuoteSnapshot(
            id: UUID(),
            text: "The unexamined life is not worth living.",
            author: "Socrates",
            source: .bundled,
            seenAt: Date(),
            isFavorite: false,
            tags: []
        ),
        style: .midnight
    )
    .scaleEffect(0.35)
    .frame(width: 380, height: 380)
}

#Preview("Paper") {
    ShareableQuoteView(
        quote: QuoteSnapshot(
            id: UUID(),
            text: "The unexamined life is not worth living.",
            author: "Socrates",
            source: .bundled,
            seenAt: Date(),
            isFavorite: false,
            tags: []
        ),
        style: .paper
    )
    .scaleEffect(0.35)
    .frame(width: 380, height: 380)
}
