//
//  QuoteTagPicker.swift
//  QuoteBar — Views
//
//  Per-row tag assignment control for `HistoryView`. A `.popover` rather
//  than a `Menu`: the inline "create a new tag" field below needs to stay
//  reliably focusable and typeable, which a live `TextField` embedded in a
//  `Menu` cannot be counted on for in SwiftUI/AppKit.
//

import SwiftUI

struct QuoteTagPicker: View {
    var quote: QuoteSnapshot
    var tracker: QuoteTracker
    var tagLibrary: QuoteTagLibrary

    @State private var isPresented = false
    @State private var newTagName = ""

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: quote.tags.isEmpty ? "tag" : "tag.fill")
                .foregroundStyle(quote.tags.isEmpty ? AppColors.textTertiary : AppColors.accent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tags for: \(quote.text)")
        .accessibilityValue(quote.tags.isEmpty ? "None" : quote.tags.map(\.name).joined(separator: ", "))
        .popover(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                if tagLibrary.tags.isEmpty {
                    Text("No tags yet.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                } else {
                    ForEach(tagLibrary.tags) { tag in
                        Toggle(tag.name, isOn: Binding(
                            get: { quote.tags.contains { $0.id == tag.id } },
                            set: { _ in tracker.toggleTag(tag.id, onQuote: quote.id) }
                        ))
                        .toggleStyle(.checkbox)
                        .font(DesignTokens.Typography.body)
                    }
                }

                Divider()

                HStack {
                    TextField("New tag", text: $newTagName)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        if let created = tagLibrary.add(name: newTagName) {
                            tracker.toggleTag(created.id, onQuote: quote.id)
                        }
                        newTagName = ""
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .font(DesignTokens.Typography.body)
            }
            .padding(DesignTokens.Spacing.small)
            .frame(width: 220)
        }
    }
}

#Preview {
    let container = try! ModelContainerFactory.makeInMemory()
    let repository = SwiftDataQuoteRepository(container: container)
    let quote = try! repository.record(Quote(text: "The unexamined life is not worth living.", author: "Socrates", source: .bundled))
    let tracker = QuoteTracker(
        repository: repository,
        provider: QuoteProviderService(),
        settings: AppSettings(defaults: UserDefaults(suiteName: "preview")!),
        isEphemeral: false
    )

    return QuoteTagPicker(
        quote: quote,
        tracker: tracker,
        tagLibrary: QuoteTagLibrary(repository: SwiftDataQuoteTagRepository(container: container))
    )
    .padding()
}
