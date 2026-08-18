//
//  HistoryInsightsView.swift
//  QuoteBar — Views
//
//  The breakdowns behind History's three stat tiles: where quotes came from,
//  which authors come round most, and which tags are actually used.
//
//  Presentational only — every number here is computed once by
//  `QuoteHistoryStats` and handed over already ranked. Nothing in this file
//  counts, sorts or divides.
//

import SwiftUI

struct HistoryInsightsView: View {
    let stats: QuoteHistoryStatsResult

    /// Collapsed by default: History's job is the quote list, and the three
    /// tiles above already answer the common question. This is the detail
    /// behind them, for whoever wants it.
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                block("Sources") {
                    ForEach(stats.sourceCounts) { item in
                        sourceRow(item)
                    }
                }

                if !stats.topAuthors.isEmpty {
                    block("Top Authors") {
                        ForEach(stats.topAuthors) { item in
                            authorRow(item)
                        }
                    }
                }

                if !stats.topTags.isEmpty {
                    block("Top Tags") {
                        ForEach(stats.topTags) { item in
                            tagRow(item)
                        }
                    }
                }
            }
            .padding(.top, DesignTokens.Spacing.small)
        } label: {
            Text("Insights")
                .font(DesignTokens.Typography.bodyMedium)
        }
    }

    // MARK: - Blocks

    private func block<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
            Text(title)
                .font(DesignTokens.Typography.statLabel)
                .foregroundStyle(AppColors.textTertiary)
                .textCase(.uppercase)
            content()
        }
    }

    // MARK: - Rows

    private func sourceRow(_ item: QuoteSourceCount) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
            HStack(spacing: DesignTokens.Spacing.small) {
                SourceBadge(source: item.source)
                Spacer(minLength: DesignTokens.Spacing.small)
                Text(item.share, format: .percent.precision(.fractionLength(0)))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .monospacedDigit()
                tally(item.count)
            }
            shareBar(item.share, tint: AppColors.sourceTint(for: item.source))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(item.source.displayName): \(item.count)"))
        .accessibilityValue(Text(item.share, format: .percent.precision(.fractionLength(0))))
    }

    private func authorRow(_ item: QuoteAuthorCount) -> some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Text(item.name)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(AppColors.textPrimary)
                // An author line can be long enough to push the tally off the
                // row in a narrow window, so it truncates rather than wraps.
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            tally(item.count)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(item.name): \(item.count)"))
    }

    private func tagRow(_ item: QuoteTagCount) -> some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            TagPill(name: item.name)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            tally(item.count)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(item.name): \(item.count)"))
    }

    // MARK: - Pieces

    private func tally(_ count: Int) -> some View {
        Text("\(count)")
            .font(DesignTokens.Typography.bodyMedium)
            .foregroundStyle(AppColors.textSecondary)
            .monospacedDigit()
            .frame(width: DesignTokens.Layout.insightCountWidth, alignment: .trailing)
    }

    /// A proportion drawn as a filled track. `GeometryReader` rather than a
    /// `ProgressView`: this is a share of a whole, not progress toward
    /// something, and the row's own accessibility label already speaks the
    /// number — so the bar itself is decoration and stays out of the tree.
    private func shareBar(_ share: Double, tint: Color) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.tint(tint, opacity: 0.12))
                Capsule()
                    .fill(AppColors.tint(tint, opacity: 0.55))
                    .frame(
                        width: max(
                            DesignTokens.Layout.insightBarMinWidth,
                            proxy.size.width * share
                        )
                    )
            }
        }
        .frame(height: DesignTokens.Layout.insightBarHeight)
        .accessibilityHidden(true)
    }
}

#Preview {
    HistoryInsightsView(
        stats: QuoteHistoryStatsResult(
            totalSeen: 42,
            favoriteCount: 7,
            uniqueAuthorCount: 12,
            sourceCounts: [
                QuoteSourceCount(source: .onDeviceAI, count: 20, share: 20.0 / 42),
                QuoteSourceCount(source: .zenQuotes, count: 15, share: 15.0 / 42),
                QuoteSourceCount(source: .bundled, count: 7, share: 7.0 / 42),
            ],
            topAuthors: [
                QuoteAuthorCount(name: "Marcus Aurelius", count: 9),
                QuoteAuthorCount(name: "Seneca", count: 6),
            ],
            topTags: [
                QuoteTagCount(id: UUID(), name: "stoic", count: 11),
                QuoteTagCount(id: UUID(), name: "morning", count: 3),
            ]
        )
    )
    .frame(width: 420)
    .padding()
}
