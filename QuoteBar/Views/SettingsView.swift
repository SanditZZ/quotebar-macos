//
//  SettingsView.swift
//  QuoteBar — Views
//
//  The Settings shell: a sidebar of tabs beside the selected tab's content.
//
//  This was one scrolling column of eleven sections. The sections themselves
//  are unchanged, but they now live in their own tab files rather than in this
//  one, which keeps each file small enough to read and means a tab only takes
//  the services it actually uses.
//

import SwiftUI

struct SettingsView: View {
    var tracker: QuoteTracker
    var settings: AppSettings
    var launchAtLogin: LaunchAtLoginService
    var hotKeyService: GlobalHotKeyService
    var notificationService: QuoteNotificationService
    var customQuoteLibrary: CustomQuoteLibrary
    var tagLibrary: QuoteTagLibrary
    var backupService: QuoteBackupService
    var updateService: UpdateService

    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selection: $selectedTab)

            // No divider: the sidebar's darker vibrancy already separates the
            // two columns, and a line drawn on top of that edge reads as a
            // seam rather than a boundary.
            selectedContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsTab(
                settings: settings,
                launchAtLogin: launchAtLogin,
                hotKeyService: hotKeyService,
                notificationService: notificationService
            )
        case .quotes:
            QuotesSettingsTab(
                settings: settings,
                customQuoteLibrary: customQuoteLibrary,
                tagLibrary: tagLibrary
            )
        case .sharing:
            SharingSettingsTab(settings: settings)
        case .data:
            DataSettingsTab(
                tracker: tracker,
                settings: settings,
                backupService: backupService
            )
        case .updates:
            UpdatesSettingsTab(updateService: updateService)
        case .about:
            AboutSettingsTab()
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
        customQuoteLibrary: CustomQuoteLibrary(repository: SwiftDataCustomQuoteRepository(container: container)),
        tagLibrary: QuoteTagLibrary(repository: SwiftDataQuoteTagRepository(container: container)),
        backupService: QuoteBackupService(
            quoteRepository: SwiftDataQuoteRepository(container: container),
            customQuoteRepository: SwiftDataCustomQuoteRepository(container: container)
        ),
        updateService: .shared
    )
    .frame(width: 640, height: 520)
}
