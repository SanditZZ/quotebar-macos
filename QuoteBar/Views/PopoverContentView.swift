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
    let onShare: () -> Void
    let onSpeak: () -> Void
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

            if let fallbackMessage = tracker.pinnedSourceFallbackMessage {
                Text(fallbackMessage)
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
        HStack(spacing: DesignTokens.Spacing.extraSmall) {
            footerButton("History", systemImage: "clock", action: onOpenHistory)
            footerButton("Share", systemImage: "square.and.arrow.up", action: onShare)
                .disabled(tracker.currentQuote == nil)
            footerButton(
                tracker.isSpeaking ? "Stop" : "Read Aloud",
                systemImage: tracker.isSpeaking ? "stop.fill" : "speaker.wave.2",
                action: onSpeak
            )
            .disabled(tracker.currentQuote == nil)
            footerButton("Settings", systemImage: "gearshape", action: onOpenSettings)
            Spacer()
            footerButton("Quit", systemImage: "power", action: onQuit)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColors.textSecondary)
    }

    /// Icon-only: the five captions together are far wider than
    /// `popoverWidth`, and as visible text they wrapped to one or two
    /// characters per line. The name survives as a tooltip on hover and as the
    /// accessibility label, so nothing is lost to a pointer or to VoiceOver.
    private func footerButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: DesignTokens.Icons.standard))
                .frame(
                    width: DesignTokens.Layout.footerButtonSize.width,
                    height: DesignTokens.Layout.footerButtonSize.height
                )
                // The glyph alone is a small target; the frame is the button.
                .contentShape(Rectangle())
        }
        .help(title)
        .accessibilityLabel(title)
    }
}

#Preview {
    PopoverContentView(
        tracker: QuoteTracker(
            repository: SwiftDataQuoteRepository(container: try! ModelContainerFactory.makeInMemory()),
            provider: QuoteProviderService(),
            settings: AppSettings(defaults: UserDefaults(suiteName: "preview")!),
            isEphemeral: false
        ),
        onOpenHistory: {},
        onOpenSettings: {},
        onShare: {},
        onSpeak: {},
        onQuit: {}
    )
}
