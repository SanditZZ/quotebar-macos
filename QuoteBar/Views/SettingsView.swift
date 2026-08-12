//
//  SettingsView.swift
//  QuoteBar — Views
//
//  Preferences, data management, and About. Sections share one width, per
//  this project's design conventions (see idle-tapper-macos's UI review).
//

import SwiftUI

struct SettingsView: View {
    var tracker: QuoteTracker
    var settings: AppSettings
    var launchAtLogin: LaunchAtLoginService
    var hotKeyService: GlobalHotKeyService
    var notificationService: QuoteNotificationService
    var customQuoteLibrary: CustomQuoteLibrary

    @State private var showingClearConfirmation = false

    private static let sectionWidth: CGFloat = 400

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                generalSection
                shortcutSection
                notificationsSection
                quoteSourceSection
                yourQuotesSection
                sharingSection
                dataSection
                aboutSection
            }
            .padding(DesignTokens.Spacing.popoverPadding)
            .frame(width: Self.sectionWidth)
        }
        .onAppear {
            launchAtLogin.refresh()
            Task { await notificationService.refreshAuthorizationStatus() }
        }
        .onChange(of: settings.hotKeyCombination) { _, newValue in
            hotKeyService.updateCombination(newValue)
        }
        .onChange(of: settings.notificationTime) { _, newValue in
            guard settings.notificationsEnabled else { return }
            Task { await notificationService.apply(enabled: true, time: newValue) }
        }
    }

    // MARK: - Shortcut

    private var shortcutSection: some View {
        section(title: "Shortcut") {
            HStack {
                Text("New Quote")
                Spacer()
                ShortcutRecorderField(combination: hotKeyBinding)
            }
            .font(DesignTokens.Typography.body)

            Text("Works system-wide, even while QuoteBar isn't in front. Opens the popover and fetches a new quote.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private var hotKeyBinding: Binding<HotKeyCombination?> {
        Binding(
            get: { settings.hotKeyCombination },
            set: { settings.hotKeyCombination = $0 }
        )
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        section(title: "Notifications") {
            Toggle("Quote of the Day", isOn: notificationsEnabledBinding)
                .toggleStyle(.switch)

            DatePicker("Time", selection: notificationTimeBinding, displayedComponents: .hourAndMinute)
                .disabled(!settings.notificationsEnabled)
                .font(DesignTokens.Typography.body)

            if let message = notificationService.lastErrorMessage {
                Text(message)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            } else {
                Text("A daily reminder that opens the popover and fetches a fresh quote when tapped.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    /// Reflects both the user's stored intent and whatever the OS actually
    /// granted — if authorization was denied, the toggle shows off even
    /// though `settings.notificationsEnabled` is still `true`, rather than
    /// showing on for a notification that will never fire.
    private var notificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled && notificationService.lastErrorMessage == nil },
            set: { newValue in
                settings.notificationsEnabled = newValue
                Task { await notificationService.apply(enabled: newValue, time: settings.notificationTime) }
            }
        )
    }

    private var notificationTimeBinding: Binding<Date> {
        Binding(
            get: { NotificationTimeConversion.date(from: settings.notificationTime) },
            set: { settings.notificationTime = NotificationTimeConversion.time(from: $0) }
        )
    }

    // MARK: - General

    private var generalSection: some View {
        section(title: "General") {
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))
            .toggleStyle(.switch)

            if let message = launchAtLogin.lastErrorMessage {
                Text(message)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            }
        }
    }

    // MARK: - Quote Source

    private var quoteSourceSection: some View {
        section(title: "Quote Source") {
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

    // MARK: - Your Quotes

    private var yourQuotesSection: some View {
        section(title: "Your Quotes") {
            CustomQuotesEditor(library: customQuoteLibrary)
        }
    }

    // MARK: - Sharing

    private var sharingSection: some View {
        section(title: "Sharing") {
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
    }

    // MARK: - Data

    private var dataSection: some View {
        section(title: "Data") {
            let stats = tracker.stats

            HStack {
                Text("Quotes stored")
                Spacer()
                Text("\(stats.totalSeen)")
                    .foregroundStyle(AppColors.textSecondary)
            }
            .font(DesignTokens.Typography.body)

            if tracker.isEphemeral {
                Label("The database couldn't be opened, so nothing is being saved.", systemImage: "exclamationmark.triangle")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            }

            Toggle("Confirm before clearing history", isOn: Binding(
                get: { settings.confirmBeforeClearHistory },
                set: { settings.confirmBeforeClearHistory = $0 }
            ))
            .toggleStyle(.checkbox)

            Button("Clear History…", role: .destructive) {
                if settings.confirmBeforeClearHistory {
                    showingClearConfirmation = true
                } else {
                    tracker.clearHistory()
                }
            }
            .confirmationDialog(
                "Clear all quote history?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) { tracker.clearHistory() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes every saved quote and favorite. This cannot be undone.")
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        section(title: "About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Self.versionString)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .font(DesignTokens.Typography.body)

            Link("View on GitHub", destination: URL(string: "https://github.com/SanditZZ/quotebar-macos")!)
                .font(DesignTokens.Typography.body)

            Text("MIT licensed. No accounts, no analytics, no tracking beyond the two quote APIs described in SECURITY.md.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private static var versionString: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(version) (\(build))"
    }

    // MARK: - Section Helper

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(title)
                .font(DesignTokens.Typography.sectionTitle)
                .foregroundStyle(AppColors.textSecondary)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        }
    }
}

#Preview {
    let container = try! ModelContainerFactory.makeInMemory()
    SettingsView(
        tracker: QuoteTracker(
            repository: SwiftDataQuoteRepository(container: container),
            provider: QuoteProviderService(),
            settings: AppSettings(defaults: UserDefaults(suiteName: "preview")!),
            isEphemeral: false
        ),
        settings: AppSettings(defaults: UserDefaults(suiteName: "preview")!),
        launchAtLogin: LaunchAtLoginService(),
        hotKeyService: GlobalHotKeyService(),
        notificationService: QuoteNotificationService(),
        customQuoteLibrary: CustomQuoteLibrary(repository: SwiftDataCustomQuoteRepository(container: container))
    )
}
