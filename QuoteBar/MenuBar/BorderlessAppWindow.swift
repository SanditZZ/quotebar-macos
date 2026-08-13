//
//  BorderlessAppWindow.swift
//  QuoteBar — Window management
//
//  A window with no system title bar, so the content can run edge to edge
//  behind its own header and the vibrancy material fills the whole frame.
//
//  Everything the system frame normally provides has to be re-supplied:
//
//  - Rounded corners come from the content view's layer, since there is no
//    system frame to round.
//  - Dragging comes from `isMovableByWindowBackground`, since there is no
//    title bar to grab.
//  - Key/main status needs the overrides below; a borderless window refuses
//    both by default, which would leave text fields unfocusable.
//  - Cmd+W has to be handled directly. AppKit routes it to `performClose:`,
//    which requires a close button, and a borderless window has none — so the
//    shortcut is silently dead without this.
//
//  `.resizable` is kept in the style mask deliberately. The windows stay
//  user-resizable with their existing minimum sizes and frame autosave, which
//  the collapsed-window fix depends on.
//

import AppKit

final class BorderlessAppWindow: NSWindow {

    override init(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask,
        backing: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .miniaturizable, .resizable],
            backing: backing,
            defer: flag
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true

        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = DesignTokens.Layout.windowCornerRadius
        contentView?.layer?.masksToBounds = true
    }

    /// A borderless window declines both by default, which would stop text
    /// fields from taking focus and stop the window from ever looking active.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "w" {
            close()
            return
        }
        super.keyDown(with: event)
    }
}
