//
//  WindowShell.swift
//  QuoteBar — Views
//
//  Wraps a borderless window's content in its own header and vibrancy, so both
//  auxiliary windows get identical chrome from one place rather than each view
//  re-deriving it.
//

import SwiftUI

struct WindowShell<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            WindowHeader(title: title)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .vibrantBackground(.content)
    }
}
