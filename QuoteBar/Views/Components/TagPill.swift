//
//  TagPill.swift
//  QuoteBar — Views
//
//  A small read-only pill naming one tag on a quote row. Same shape as
//  `SourceBadge` (`Capsule` fill of a translucent tint) so the two pill
//  styles read as one system.
//

import SwiftUI

struct TagPill: View {
    let name: String

    var body: some View {
        Text(name)
            .font(DesignTokens.Typography.tiny)
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, DesignTokens.Spacing.small)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(AppColors.tint(AppColors.accent))
            )
    }
}

#Preview {
    HStack {
        TagPill(name: "stoic")
        TagPill(name: "funny")
    }
    .padding()
}
