//
//  PacksEditor.swift
//  QuoteBar — Views
//
//  Installed quote packs, embedded in Settings alongside "Your Quotes":
//  install one from a file, see what's installed, remove one. Presentational
//  only — everything delegates to `CustomQuoteLibrary`, same pattern as
//  `CustomQuotesEditor`.
//

import SwiftUI
import UniformTypeIdentifiers

struct PacksEditor: View {
    var library: CustomQuoteLibrary

    @State private var showingImporter = false
    @State private var pendingRemoval: InstalledPackSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack {
                Button("Install Pack…") { showingImporter = true }
                Spacer()
                Text("\(library.installedPacks.count) pack\(library.installedPacks.count == 1 ? "" : "s")")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }

            if let summary = library.lastPackActionSummary {
                Text(summary)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if let errorMessage = library.errorMessage {
                Text(errorMessage)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            }

            if library.installedPacks.isEmpty {
                Text("No packs installed. A pack is a themed collection of quotes you install from a file — its quotes join \"Your Quotes\" above.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            } else {
                packList
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json]
        ) { result in
            if case .success(let url) = result {
                library.installPack(at: url)
            }
        }
        .confirmationDialog(
            removalTitle,
            isPresented: isPresentingRemovalConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let pack = pendingRemoval {
                    library.uninstallPack(packId: pack.packId)
                }
                pendingRemoval = nil
            }
            Button("Cancel", role: .cancel) { pendingRemoval = nil }
        } message: {
            Text(removalMessage)
        }
    }

    private var packList: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
            ForEach(library.installedPacks) { pack in
                row(for: pack)
            }
        }
    }

    private func row(for pack: InstalledPackSummary) -> some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text(PackIdFormatter.displayName(for: pack.packId))
                    .font(DesignTokens.Typography.body)
                Text("\(pack.quoteCount) quote\(pack.quoteCount == 1 ? "" : "s")")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                pendingRemoval = pack
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            // Every row's remove button would otherwise be announced
            // identically as "Trash", giving no way to tell which pack it
            // removes — same reasoning as `CustomQuotesEditor`'s row delete.
            .accessibilityLabel("Remove pack: \(PackIdFormatter.displayName(for: pack.packId))")
        }
        .padding(.vertical, DesignTokens.Spacing.extraSmall)
    }

    // MARK: - Removal confirmation

    private var isPresentingRemovalConfirmation: Binding<Bool> {
        Binding(
            get: { pendingRemoval != nil },
            set: { isPresented in if !isPresented { pendingRemoval = nil } }
        )
    }

    private var removalTitle: String {
        guard let pendingRemoval else { return "Remove pack?" }
        return "Remove \"\(PackIdFormatter.displayName(for: pendingRemoval.packId))\"?"
    }

    private var removalMessage: String {
        let count = pendingRemoval?.quoteCount ?? 0
        return "This removes its \(count) quote\(count == 1 ? "" : "s") from Your Quotes. This cannot be undone."
    }
}

#Preview {
    PacksEditor(
        library: CustomQuoteLibrary(
            repository: SwiftDataCustomQuoteRepository(container: try! ModelContainerFactory.makeInMemory())
        )
    )
    .padding()
    .frame(width: 380)
}
