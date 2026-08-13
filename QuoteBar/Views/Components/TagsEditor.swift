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

    /// Tracks the inline rename field so clicking away can commit. Without it
    /// an unsubmitted rename stranded the row in edit mode indefinitely — the
    /// tag's real name stayed hidden behind the uncommitted text, and neither
    /// clicking elsewhere nor Escape got out of it.
    @FocusState private var isRenaming: Bool

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

    /// Applies the pending rename and leaves edit mode. A rejected name (blank
    /// or a duplicate) surfaces through `library.errorMessage` and the row
    /// returns to showing the tag's real name, so a failed rename can never
    /// strand the row either.
    private func commitRename(of tag: TagSnapshot) {
        library.rename(id: tag.id, to: editingText)
        editingID = nil
        editingText = ""
    }

    private func cancelRename() {
        editingID = nil
        editingText = ""
    }

    private func row(for tag: TagSnapshot) -> some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            if editingID == tag.id {
                TextField("Tag name", text: $editingText)
                    .textFieldStyle(.roundedBorder)
                    .font(DesignTokens.Typography.body)
                    .focused($isRenaming)
                    .onSubmit { commitRename(of: tag) }
                    // Escape abandons the edit, matching every other inline
                    // rename on the platform.
                    .onExitCommand { cancelRename() }
                    .onChange(of: isRenaming) { _, focused in
                        // Clicking away commits, as Finder does, rather than
                        // leaving the row stuck mid-edit.
                        if !focused, editingID == tag.id { commitRename(of: tag) }
                    }
                    .onAppear { isRenaming = true }
                    .accessibilityLabel("Rename tag \(tag.name)")
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
                .accessibilityLabel("Rename tag \(tag.name)")
            }

            Button {
                library.remove(id: tag.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            // Without a name of its own this announced only as "Trash", so a
            // VoiceOver user could not tell which tag it would delete.
            .accessibilityLabel("Delete tag \(tag.name)")
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
