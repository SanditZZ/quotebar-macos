//
//  WindowShell.swift
//  QuoteBar — Views
//
//  Wraps a borderless window's content in its own header and vibrancy, so both
//  auxiliary windows get identical chrome from one place rather than each view
//  re-deriving it.
//

import SwiftUI

/// How a window supplies the chrome a borderless window has to replace.
enum WindowChrome {
    /// A full-width header strip above the content, with the title centred and
    /// the traffic lights on the left. Right for a single-column window.
    case header

    /// No header at all — the content view places the traffic lights itself.
    ///
    /// A full-width strip forces every column beneath it to start below the
    /// strip, which is exactly what a sidebar must not do: it leaves a band
    /// across the top of the window with the sidebar boxed in underneath.
    /// Settings puts the traffic lights inside its own sidebar instead, so the
    /// sidebar runs the full height of the window.
    case none
}

struct WindowShell<Content: View>: View {
    let title: String
    let chrome: WindowChrome
    let content: Content

    /// - Parameter chrome: Defaults to `.header`, so a window that has not
    ///   opted into supplying its own keeps the standard strip.
    init(
        title: String,
        chrome: WindowChrome = .header,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.chrome = chrome
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            if chrome == .header {
                WindowHeader(title: title)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .vibrantBackground(.content)
    }
}
