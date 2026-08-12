//
//  ShortcutRecorderField.swift
//  QuoteBar — Views
//
//  A hand-built shortcut recorder — no third-party dependency provides one.
//  Reactive lines stay here per CONTRIBUTING.md; the actual key-code and
//  modifier translation is delegated to `HotKeyEncoding`.
//

import SwiftUI

struct ShortcutRecorderField: View {
    @Binding var combination: HotKeyCombination?

    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Text(fieldText)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(isRecording ? AppColors.textSecondary : AppColors.textPrimary)
                .frame(minWidth: 110, alignment: .leading)
                .padding(.horizontal, DesignTokens.Spacing.small)
                .padding(.vertical, DesignTokens.Spacing.extraSmall)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small))

            Button(isRecording ? "Cancel" : "Record") {
                isRecording ? stopRecording() : startRecording()
            }

            if combination != nil {
                Button("Clear") {
                    stopRecording()
                    combination = nil
                }
            }
        }
        .onDisappear { stopRecording() }
    }

    private var fieldText: String {
        if isRecording { return "Press a key combination…" }
        return combination.map(HotKeyDisplayFormatter.format) ?? "Not set"
    }

    // MARK: - Recording

    private func startRecording() {
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
        }
    }

    private func stopRecording() {
        isRecording = false
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        localMonitor = nil
    }

    /// Returning `nil` swallows the key event so it never reaches whatever
    /// text field or control happened to have focus underneath; returning
    /// `event` lets an unmodified key press (which cannot become a usable
    /// global shortcut) type normally instead of silently vanishing while
    /// "recording".
    private func handle(_ event: NSEvent) -> NSEvent? {
        let modifiers = HotKeyEncoding.carbonModifiers(
            from: event.modifierFlags.intersection(HotKeyEncoding.relevantModifierFlags)
        )

        guard HotKeyEncoding.hasUsableModifier(modifiers) else { return event }

        combination = HotKeyCombination(keyCode: event.keyCode, modifierFlags: modifiers)
        stopRecording()
        return nil
    }
}

#Preview {
    ShortcutRecorderField(combination: .constant(.default))
        .padding()
}
