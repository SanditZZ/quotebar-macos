//
//  CustomQuotesEditor.swift
//  QuoteBar — Views
//
//  The "Your Quotes" editor embedded in Settings: add one manually, import a
//  file, remove entries. Presentational only — everything delegates to
//  `CustomQuoteLibrary`.
//

import SwiftUI
import UniformTypeIdentifiers

struct CustomQuotesEditor: View {
    var library: CustomQuoteLibrary

    @State private var newText = ""
    @State private var newAuthor = ""
    @State private var showingImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            addForm

            HStack {
                Button("Import…") { showingImporter = true }
                Spacer()
                Text("\(library.entries.count) quote\(library.entries.count == 1 ? "" : "s")")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }

            if let summary = library.lastImportSummary {
                Text(summary)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if let errorMessage = library.errorMessage {
                Text(errorMessage)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            }

            if !library.entries.isEmpty {
                entryList
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: UTType.customQuoteImportTypes
        ) { result in
            if case .success(let url) = result {
                library.importFile(at: url)
            }
        }
    }

    private var addForm: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
            TextField("Quote text", text: $newText)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("Author (optional)", text: $newAuthor)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    library.add(text: newText, author: newAuthor.isEmpty ? nil : newAuthor)
                    newText = ""
                    newAuthor = ""
                }
                .disabled(newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .font(DesignTokens.Typography.body)
    }

    private var entryList: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
            ForEach(library.entries) { entry in
                row(for: entry)
            }
        }
    }

    private func row(for entry: CustomQuoteSnapshot) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text)
                    .font(DesignTokens.Typography.body)
                    .lineLimit(2)
                Text(QuoteTextFormatter.attribution(author: entry.author))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                library.remove(id: entry.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DesignTokens.Spacing.extraSmall)
    }
}

#Preview {
    CustomQuotesEditor(
        library: CustomQuoteLibrary(
            repository: SwiftDataCustomQuoteRepository(container: try! ModelContainerFactory.makeInMemory())
        )
    )
    .padding()
    .frame(width: 380)
}
