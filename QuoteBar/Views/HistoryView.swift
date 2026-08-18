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
    var tagLibrary: QuoteTagLibrary

    @State private var favoritesOnly = false
    @State private var selectedTagIDs: Set<UUID> = []

    private var visibleQuotes: [QuoteSnapshot] {
        let base = favoritesOnly ? tracker.history.filter(\.isFavorite) : tracker.history
        return QuoteTagFilter.matching(base, selectedTagIDs: selectedTagIDs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            statsRow

            // Nothing to break down before the first quote lands, and an empty
            // disclosure row would only be something else to click on.
            if tracker.stats.totalSeen > 0 {
                HistoryInsightsView(stats: tracker.stats)
            }

            HStack {
                Toggle("Favorites only", isOn: $favoritesOnly)
                    .toggleStyle(.checkbox)

                tagFilterMenu
            }
            .font(DesignTokens.Typography.bodyMedium)

            if visibleQuotes.isEmpty {
                emptyState
            } else {
                List(visibleQuotes) { quote in
                    row(for: quote)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.inset)
                // The window is vibrant now, and a List paints its own opaque
                // backing over it, which would leave a flat grey slab in an
                // otherwise translucent window.
                .scrollContentBackground(.hidden)
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

    // The label is a `LocalizedStringKey` and is uppercased by `textCase`
    // rather than by `String.uppercased()`: a `Text` built from a plain
    // `String` is never looked up in the string catalog, so uppercasing first
    // would quietly opt these three labels out of translation.
    private func statTile(_ label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(DesignTokens.Typography.statLabel)
                .foregroundStyle(AppColors.textTertiary)
                .textCase(.uppercase)
            Text(value)
                .font(DesignTokens.Typography.pageTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: DesignTokens.Spacing.small)
    }

    private var tagFilterMenu: some View {
        Menu(tagFilterLabel) {
            if tagLibrary.tags.isEmpty {
                Text("No tags yet")
            } else {
                ForEach(tagLibrary.tags) { tag in
                    Toggle(tag.name, isOn: Binding(
                        get: { selectedTagIDs.contains(tag.id) },
                        set: { isOn in
                            if isOn {
                                selectedTagIDs.insert(tag.id)
                            } else {
                                selectedTagIDs.remove(tag.id)
                            }
                        }
                    ))
                }
                if !selectedTagIDs.isEmpty {
                    Divider()
                    Button("Clear Tag Filter") { selectedTagIDs.removeAll() }
                }
            }
        }
    }

    private var tagFilterLabel: String {
        selectedTagIDs.isEmpty ? "Tags" : "Tags (\(selectedTagIDs.count))"
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.textTertiary)
            Text(emptyStateText)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateText: String {
        if favoritesOnly { return "No favorites yet" }
        if !selectedTagIDs.isEmpty { return "No quotes with that tag" }
        return "No quotes yet"
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
                HStack(spacing: DesignTokens.Spacing.extraSmall) {
                    SourceBadge(source: quote.source)
                    if !quote.tags.isEmpty {
                        ForEach(quote.tags) { tag in
                            TagPill(name: tag.name)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            QuoteTagPicker(quote: quote, tracker: tracker, tagLibrary: tagLibrary)

            Button {
                tracker.toggleFavorite(id: quote.id)
            } label: {
                Image(systemName: quote.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(quote.isFavorite ? AppColors.warning : AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            // One row per quote, so the label has to name the quote or every
            // star in the list announces identically.
            .accessibilityLabel("Favorite: \(quote.text)")
            .accessibilityValue(quote.isFavorite ? "On" : "Off")
        }
        .padding(.vertical, DesignTokens.Spacing.extraSmall)
    }
}

#Preview {
    let container = try! ModelContainerFactory.makeInMemory()
    HistoryView(
        tracker: QuoteTracker(
            repository: SwiftDataQuoteRepository(container: container),
            provider: QuoteProviderService(),
            settings: AppSettings(defaults: UserDefaults(suiteName: "preview")!),
            isEphemeral: false
        ),
        settings: AppSettings(defaults: UserDefaults(suiteName: "preview")!),
        tagLibrary: QuoteTagLibrary(repository: SwiftDataQuoteTagRepository(container: container))
    )
    .frame(width: 480, height: 480)
}
