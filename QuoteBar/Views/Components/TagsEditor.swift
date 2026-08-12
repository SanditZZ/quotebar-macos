//
//  TagsEditor.swift
//  QuoteBar — Views
//
//  The "Tags" editor embedded in Settings: create, rename, and delete tags.
//  Presentational only — everything delegates to `QuoteTagLibrary`.
//  Assigning a tag to a specific quote happens in `HistoryView` instead, via
//  `QuoteTagPicker` — this editor manages the tag vocabulary itself.
//

import SwiftUI

struct TagsEditor: View {
    var library: QuoteTagLibrary

    @State private var newName = ""
    @State private var editingID: UUID?
    @State private var editingText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            addForm

            if let errorMessage = library.errorMessage {
                Text(errorMessage)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.warning)
            }

            if library.tags.isEmpty {
                Text("No tags yet.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            } else {
                tagList
            }
        }
    }

    private var addForm: some View {
        HStack {
            TextField("New tag", text: $newName)
                .textFieldStyle(.roundedBorder)
            Button("Add") {
                library.add(name: newName)
                newName = ""
            }
            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .font(DesignTokens.Typography.body)
    }

    private var tagList: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
            ForEach(library.tags) { tag in
                row(for: tag)
            }
        }
    }

    private func row(for tag: TagSnapshot) -> some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            if editingID == tag.id {
                TextField("Tag name", text: $editingText)
                    .textFieldStyle(.roundedBorder)
                    .font(DesignTokens.Typography.body)
                    .onSubmit {
                        library.rename(id: tag.id, to: editingText)
                        editingID = nil
                    }
            } else {
                Button {
                    editingID = tag.id
                    editingText = tag.name
                } label: {
                    Text(tag.name)
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }

            Button {
                library.remove(id: tag.id)
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
    TagsEditor(
        library: QuoteTagLibrary(
            repository: SwiftDataQuoteTagRepository(container: try! ModelContainerFactory.makeInMemory())
        )
    )
    .padding()
    .frame(width: 380)
}
