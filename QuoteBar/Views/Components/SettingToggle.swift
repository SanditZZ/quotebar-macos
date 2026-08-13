//
//  SettingToggle.swift
//  QuoteBar — Views
//
//  A switch with a title and an optional explanatory line beneath it.
//
//  Beyond looking tidier than a bare `Toggle`, this fixes a real accessibility
//  defect: a `.switch` Toggle renders its title as a sibling label that is not
//  associated with the control, so VoiceOver announced these as a bare "0" or
//  "1" with no name. Combining the children into one element and supplying the
//  label here means every switch in the app is announced correctly by default,
//  instead of each call site having to remember `.accessibilityLabel`.
//

import SwiftUI

struct SettingToggle: View {
    let title: String
    var description: String?
    @Binding var isOn: Bool

    init(_ title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                Text(title)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(AppColors.textPrimary)

                if let description {
                    Text(description)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.medium)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard let description else { return title }
        return "\(title). \(description)"
    }
}
