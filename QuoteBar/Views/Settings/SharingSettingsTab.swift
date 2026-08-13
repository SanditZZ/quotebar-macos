//
//  SharingSettingsTab.swift
//  QuoteBar — Views
//
//  The share image's look, and the Read Aloud voice.
//

import AVFoundation
import SwiftUI

struct SharingSettingsTab: View {
    var settings: AppSettings

    @State private var voices: [AVSpeechSynthesisVoice] = []

    var body: some View {
        SettingsTabScroll {
            sharingSection
            readAloudSection
        }
        .onAppear {
            voices = AVSpeechSynthesisVoice.speechVoices().sorted { $0.name < $1.name }
        }
    }

    // MARK: - Sharing

    private var sharingSection: some View {
        SettingsSection("Sharing") {
            HStack(spacing: DesignTokens.Spacing.medium) {
                ForEach(ShareCardStyle.allCases) { style in
                    shareStyleSwatch(style)
                }
            }

            Text("Used when you share a quote as an image from the popover or the menu bar's right-click menu.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private func shareStyleSwatch(_ style: ShareCardStyle) -> some View {
        let isSelected = settings.shareCardStyle == style
        let background = style == .midnight ? AppColors.shareMidnightBackgroundBottom : AppColors.sharePaperBackground
        let foreground = style == .midnight ? AppColors.shareMidnightText : AppColors.sharePaperText

        return Button {
            settings.shareCardStyle = style
        } label: {
            VStack(spacing: DesignTokens.Spacing.extraSmall) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                    .fill(background)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text("Aa")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundStyle(foreground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                            .strokeBorder(isSelected ? AppColors.accent : Color.clear, lineWidth: 2)
                    )

                Text(style.displayName)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(style.displayName) share style")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Read Aloud

    private var readAloudSection: some View {
        SettingsSection("Read Aloud") {
            Picker("Voice", selection: voiceBinding) {
                Text("System Default").tag(String?.none)
                ForEach(voices, id: \.identifier) { voice in
                    Text(voice.name).tag(String?.some(voice.identifier))
                }
            }
            .pickerStyle(.menu)

            HStack {
                Text("Speed")
                Slider(
                    value: speechRateBinding,
                    in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate
                )
                .accessibilityLabel("Speech speed")
            }
            .font(DesignTokens.Typography.body)

            Text("Used by the \"Read Aloud\" button in the popover and the menu bar's right-click menu.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private var voiceBinding: Binding<String?> {
        Binding(
            get: { settings.preferredVoiceIdentifier },
            set: { settings.preferredVoiceIdentifier = $0 }
        )
    }

    private var speechRateBinding: Binding<Float> {
        Binding(
            get: { settings.speechRate },
            set: { settings.speechRate = $0 }
        )
    }
}
