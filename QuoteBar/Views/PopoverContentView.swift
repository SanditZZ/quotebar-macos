//
//  PopoverContentView.swift
//  QuoteBar — Views
//
//  The main interface: a quote card and a "New Quote" button. Presentational
//  only — everything here delegates to `QuoteTracker`.
//

import SwiftUI

struct PopoverContentView: View {
    var tracker: QuoteTracker
    let onOpenHistory: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            QuoteCardView(
                quote: tracker.currentQuote,
                isFetching: tracker.isFetching,
                onToggleFavorite: {
                    guard let id = tracker.currentQuote?.id else { return }
                    tracker.toggleFavorite(id: id)
                }
            )

            if let errorMessage = tracker.errorMessage {
                Text(errorMessage)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if tracker.isEphemeral {
                Label("History isn't being saved right now.", systemImage: "exclamationmark.triangle")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task { await tracker.requestNewQuote() }
            } label: {
                Label("New Quote", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(tracker.isFetching)

            footer
        }
        .padding(DesignTokens.Spacing.popoverPadding)
        .frame(width: DesignTokens.Layout.popoverWidth)
        .background(AppColors.popoverSurface)
    }

    private var footer: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            footerButton("History", systemImage: "clock", action: onOpenHistory)
            footerButton("Settings", systemImage: "gearshape", action: onOpenSettings)
            Spacer()
            footerButton("Quit", systemImage: "power", action: onQuit)
        }
        .buttonStyle(.plain)
        .font(DesignTokens.Typography.caption)
        .foregroundStyle(AppColors.textSecondary)
    }

    private func footerButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
    }
}

#Preview {
    PopoverContentView(
        tracker: QuoteTracker(
            repository: SwiftDataQuoteRepository(container: try! ModelContainerFactory.makeInMemory()),
            provider: QuoteProviderService(),
            isEphemeral: false
        ),
        onOpenHistory: {},
        onOpenSettings: {},
        onQuit: {}
    )
}
