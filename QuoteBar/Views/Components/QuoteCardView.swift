//
//  QuoteCardView.swift
//  QuoteBar — Views
//
//  The popover's focal point: the quote itself, its author, and a badge
//  naming its source.
//

import SwiftUI

struct QuoteCardView: View {
    let quote: QuoteSnapshot?
    let isFetching: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                if let quote {
                    SourceBadge(source: quote.source)
                }
                Spacer()
                if let quote {
                    Button(action: onToggleFavorite) {
                        Image(systemName: quote.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(quote.isFavorite ? AppColors.warning : AppColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help(quote.isFavorite ? "Remove from favorites" : "Add to favorites")
                }
            }

            if let quote {
                Text(quote.text)
                    .font(quote.text.count < 90 ? DesignTokens.Typography.quoteLarge : DesignTokens.Typography.quote)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text(QuoteTextFormatter.attribution(author: quote.author))
                    .font(DesignTokens.Typography.author)
                    .foregroundStyle(AppColors.textSecondary)
            } else if isFetching {
                Text("Fetching your first quote…")
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                Text("No quote yet.")
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: DesignTokens.Layout.quoteCardMinHeight, alignment: .topLeading)
        .appCard(radius: DesignTokens.Radius.quoteCard, background: AppColors.quoteCardBackground)
        .opacity(isFetching ? 0.55 : 1)
        .animation(DesignTokens.Motion.quoteChange, value: quote)
    }
}

#Preview {
    QuoteCardView(
        quote: QuoteSnapshot(
            id: UUID(),
            text: "The unexamined life is not worth living.",
            author: "Socrates",
            source: .bundled,
            seenAt: Date(),
            isFavorite: true,
            tags: []
        ),
        isFetching: false,
        onToggleFavorite: {}
    )
    .frame(width: DesignTokens.Layout.popoverWidth)
    .padding()
}
