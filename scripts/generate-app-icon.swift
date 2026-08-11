#!/usr/bin/env swift
//
//  generate-app-icon.swift
//  QuoteBar — asset generation
//
//  Renders the app icon from the same SF Symbol the menu bar uses, so the two
//  can never drift apart. Re-runnable: it overwrites the icon set in place.
//  Ported from idle-tapper-macos's script of the same name.
//
//  Usage:
//      swift scripts/generate-app-icon.swift
//      swift scripts/generate-app-icon.swift <output-directory>
//
//  Requires AppKit, so this only runs on macOS — it cannot be executed on the
//  Linux machine this project was scaffolded on. Run it once on a Mac, then
//  scripts/refresh-icon-cache.sh if a stale icon is cached.
//
//  Writes the ten PNGs macOS requires (16/32/128/256/512 at 1× and 2×) plus a
//  matching Contents.json.
//

import AppKit
import Foundation

// MARK: - Configuration

enum IconSpec {
    /// Must match `StatusItemRenderer.symbolName`.
    static let symbolName = "quote.bubble.fill"

    /// Fraction of the canvas the rounded background occupies.
    static let artworkScale: CGFloat = 0.82

    /// Corner radius as a fraction of the artwork's width, matching the
    /// proportions Apple uses for macOS app icons (roughly 185/824).
    static let cornerRadiusRatio: CGFloat = 0.2237

    /// Glyph width as a fraction of the canvas.
    static let glyphScale: CGFloat = 0.46

    /// Background gradient, lighter at the top. Matches the app's accent
    /// color (see Assets.xcassets/AccentColor.colorset) so the icon and the
    /// UI agree.
    static let gradientTop = NSColor(srgbRed: 0.298, green: 0.576, blue: 0.976, alpha: 1)
    static let gradientBottom = NSColor(srgbRed: 0.145, green: 0.404, blue: 0.855, alpha: 1)

    /// Every (point size, scale) pair macOS asks for.
    static let variants: [(points: Int, scale: Int)] = [
        (16, 1), (16, 2),
        (32, 1), (32, 2),
        (128, 1), (128, 2),
        (256, 1), (256, 2),
        (512, 1), (512, 2),
    ]

    static func filename(points: Int, scale: Int) -> String {
        let suffix = scale == 1 ? "" : "@\(scale)x"
        return "icon_\(points)x\(points)\(suffix).png"
    }
}

// MARK: - Drawing

/// The SF Symbol, recoloured white and sized for a given canvas.
func glyphImage(width: CGFloat) -> NSImage? {
    let configuration = NSImage.SymbolConfiguration(pointSize: width, weight: .medium)

    guard
        let symbol = NSImage(systemSymbolName: IconSpec.symbolName, accessibilityDescription: nil),
        let sized = symbol.withSymbolConfiguration(configuration)
    else {
        return nil
    }

    let tinted = NSImage(size: sized.size)
    tinted.lockFocus()
    let bounds = NSRect(origin: .zero, size: sized.size)
    sized.draw(in: bounds)
    NSColor.white.set()
    bounds.fill(using: .sourceAtop)
    tinted.unlockFocus()

    return tinted
}

/// Render one icon at the given pixel size.
func renderIcon(pixels: Int) -> NSBitmapImageRep? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        return nil
    }

    rep.size = NSSize(width: pixels, height: pixels)

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let canvas = CGFloat(pixels)
    let artSize = canvas * IconSpec.artworkScale
    let origin = (canvas - artSize) / 2
    let artRect = NSRect(x: origin, y: origin, width: artSize, height: artSize)
    let radius = artSize * IconSpec.cornerRadiusRatio

    let shape = NSBezierPath(roundedRect: artRect, xRadius: radius, yRadius: radius)
    let gradient = NSGradient(starting: IconSpec.gradientBottom, ending: IconSpec.gradientTop)
    gradient?.draw(in: shape, angle: 90)

    NSColor.white.withAlphaComponent(0.18).setStroke()
    shape.lineWidth = max(canvas * 0.006, 0.5)
    shape.stroke()

    if let glyph = glyphImage(width: canvas * IconSpec.glyphScale) {
        let size = glyph.size
        let rect = NSRect(
            x: (canvas - size.width) / 2,
            y: (canvas - size.height) / 2,
            width: size.width,
            height: size.height
        )
        glyph.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// MARK: - Contents.json

func contentsJSON() -> String {
    let images = IconSpec.variants.map { variant in
        """
            {
              "filename" : "\(IconSpec.filename(points: variant.points, scale: variant.scale))",
              "idiom" : "mac",
              "scale" : "\(variant.scale)x",
              "size" : "\(variant.points)x\(variant.points)"
            }
        """
    }

    return """
    {
      "images" : [
    \(images.joined(separator: ",\n"))
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }

    """
}

// MARK: - Main

let arguments = CommandLine.arguments
let defaultPath = FileManager.default
    .currentDirectoryPath
    .appending("/QuoteBar/Assets.xcassets/AppIcon.appiconset")
let outputPath = arguments.count > 1 ? arguments[1] : defaultPath
let outputURL = URL(fileURLWithPath: outputPath)

guard FileManager.default.fileExists(atPath: outputURL.path) else {
    FileHandle.standardError.write(
        Data("Icon set not found at \(outputURL.path)\nRun from the repository root.\n".utf8)
    )
    exit(1)
}

guard glyphImage(width: 512) != nil else {
    FileHandle.standardError.write(
        Data("Could not load SF Symbol '\(IconSpec.symbolName)'\n".utf8)
    )
    exit(1)
}

print("Generating app icon from '\(IconSpec.symbolName)'")

for variant in IconSpec.variants {
    let pixels = variant.points * variant.scale
    let name = IconSpec.filename(points: variant.points, scale: variant.scale)

    guard
        let rep = renderIcon(pixels: pixels),
        let data = rep.representation(using: .png, properties: [:])
    else {
        FileHandle.standardError.write(Data("Failed to render \(name)\n".utf8))
        exit(1)
    }

    let fileURL = outputURL.appendingPathComponent(name)
    do {
        try data.write(to: fileURL, options: .atomic)
        print("  \(name)  (\(pixels)×\(pixels))")
    } catch {
        FileHandle.standardError.write(
            Data("Failed to write \(name): \(error.localizedDescription)\n".utf8)
        )
        exit(1)
    }
}

do {
    try contentsJSON().write(
        to: outputURL.appendingPathComponent("Contents.json"),
        atomically: true,
        encoding: .utf8
    )
    print("  Contents.json")
} catch {
    FileHandle.standardError.write(
        Data("Failed to write Contents.json: \(error.localizedDescription)\n".utf8)
    )
    exit(1)
}

print("Done — \(IconSpec.variants.count) images written to \(outputURL.path)")
print("")
print("Rebuild, then run scripts/refresh-icon-cache.sh — macOS caches an app's")
print("icon against its bundle path, so a rebuilt app keeps showing the old one.")
