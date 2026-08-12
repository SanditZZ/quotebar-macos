//
//  HistoryView.swift
//  QuoteBar — Views
//
//  Every quote the user has seen, with favorites and per-source stats.
//

import SwiftUI

struct HistoryView: View {
    var tracker: QuoteTracker
    var settings: AppSettings

    @State private var favoritesOnly = false

    private var visibleQuotes: [QuoteSnapshot] {
        favoritesOnly ? tracker.history.filter(\.isFavorite) : tracker.history
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            statsRow

            Toggle("Favorites only", isOn: $favoritesOnly)
                .toggleStyle(.checkbox)
                .font(DesignTokens.Typography.bodyMedium)

            if visibleQuotes.isEmpty {
                emptyState
            } else {
                List(visibleQuotes) { quote in
                    row(for: quote)
                }
                .listStyle(.inset)
            }
        }
        .padding(DesignTokens.Spacing.popoverPadding)
        .onAppear { tracker.refresh() }
    }

    private var statsRow: some View {
        let stats = tracker.stats
        return HStack(spacing: DesignTokens.Spacing.section) {
            statTile("Seen", value: "\(stats.totalSeen)")
            statTile("Favorites", value: "\(stats.favoriteCount)")
            statTile("Authors", value: "\(stats.uniqueAuthorCount)")
        }
    }

    private func statTile(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(DesignTokens.Typography.statLabel)
                .foregroundStyle(AppColors.textTertiary)
            Text(value)
                .font(DesignTokens.Typography.pageTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: DesignTokens.Spacing.small)
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.textTertiary)
            Text(favoritesOnly ? "No favorites yet" : "No quotes yet")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(for quote: QuoteSnapshot) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(quote.text)
                    .font(DesignTokens.Typography.body)
                    .lineLimit(3)
                Text(QuoteTextFormatter.attribution(author: quote.author))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                SourceBadge(source: quote.source)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                tracker.toggleFavorite(id: quote.id)
            } label: {
                Image(systemName: quote.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(quote.isFavorite ? AppColors.warning : AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DesignTokens.Spacing.extraSmall)
    }
}

#Preview {
    HistoryView(
        tracker: QuoteTracker(
            repository: SwiftDataQuoteRepository(container: try! ModelContainerFactory.makeInMemory()),
            provider: QuoteProviderService(),
            settings: AppSettings(defaults: UserDefaults(suiteName: "preview")!),
            isEphemeral: false
        ),
        settings: AppSettings(defaults: UserDefaults(suiteName: "preview")!)
    )
    .frame(width: 480, height: 480)
}
