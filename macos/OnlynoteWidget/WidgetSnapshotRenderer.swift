import AppKit
import SwiftUI
import WidgetKit

/// Renders the same pure view used inside WidgetKit. Tests can supply real
/// decoded payloads and verify light, dark, empty, and desktop rendering modes.
@MainActor
@available(macOS 14.0, *)
enum WidgetSnapshotRenderer {
    static func png(
        entry: NotesEntry,
        kind: PaperWidgetSnapshotKind,
        family: WidgetFamily,
        size: CGSize,
        colorScheme: ColorScheme = .light,
        renderingMode: WidgetRenderingMode = .fullColor,
        locale: Locale = Locale(identifier: "en"),
        scale: CGFloat = 2
    ) -> Data? {
        let renderer = ImageRenderer(content: PaperWidgetSnapshotView(entry: entry, kind: kind, family: family)
            .environment(\.colorScheme, colorScheme)
            .environment(\.widgetRenderingMode, renderingMode)
            .environment(\.locale, locale)
            .frame(width: size.width, height: size.height))
        renderer.scale = scale
        guard let image = renderer.cgImage else { return nil }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }
}
