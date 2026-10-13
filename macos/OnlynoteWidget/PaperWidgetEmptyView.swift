import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperWidgetEmptyView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.dynamicTypeSize) private var typeSize
    let unavailable: Bool
    private let familyOverride: WidgetFamily?

    init(unavailable: Bool, family: WidgetFamily? = nil) {
        self.unavailable = unavailable
        familyOverride = family
    }

    private var family: WidgetFamily { familyOverride ?? widgetFamily }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("widget.app_name", systemImage: "note.text")
                .font(.caption)
                .foregroundStyle(PaperWidgetTheme.secondaryInk(colorScheme, mode: renderingMode))
            Spacer(minLength: 0)
            Text(LocalizedStringKey(unavailable ? "widget.note_unavailable" : "widget.mac.empty_title"))
                .font(.system(.headline, design: .serif))
                .bold()
                .lineLimit(typeSize.isAccessibilitySize ? 1 : 2)
            Text(LocalizedStringKey(unavailable ? "widget.choose_another_note" : "widget.mac.empty_body"))
                .font(.callout)
                .foregroundStyle(PaperWidgetTheme.secondaryInk(colorScheme, mode: renderingMode))
                .lineLimit(typeSize.isAccessibilitySize ? 1 : (family == .systemSmall ? 2 : 3))
            Spacer(minLength: 0)
            Link(destination: unavailable ? WidgetConstants.openAppURL : WidgetConstants.newNoteURL) {
                Label(LocalizedStringKey(unavailable ? "widget.mac.open_library" : "widget.mac.new_note"), systemImage: "arrow.up.right")
                    .font(.caption)
                    .bold()
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(PaperWidgetTheme.ink(colorScheme, mode: renderingMode))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(PaperWidgetTheme.contentInsets)
        .widgetURL(unavailable ? WidgetConstants.openAppURL : WidgetConstants.newNoteURL)
    }
}
