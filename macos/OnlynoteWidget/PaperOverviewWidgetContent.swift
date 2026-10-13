import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperOverviewWidgetContent: View {
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: NotesEntry
    private let familyOverride: WidgetFamily?

    init(entry: NotesEntry, family: WidgetFamily? = nil) {
        self.entry = entry
        familyOverride = family
    }

    private var family: WidgetFamily { familyOverride ?? widgetFamily }

    private var spacing: CGFloat {
        family == .systemMedium ? 5 : (family == .systemSmall ? 7 : 9)
    }

    private var visibleNotes: [WidgetNote] {
        let limit: Int
        if typeSize.isAccessibilitySize {
            limit = family == .systemLarge ? 3 : 1
        } else {
            limit = family == .systemLarge ? 4 : (family == .systemMedium ? 3 : 2)
        }
        return Array(entry.payload.notes.prefix(limit))
    }

    var body: some View {
        if entry.payload.notes.isEmpty {
            PaperWidgetEmptyView(unavailable: false, family: family)
        } else {
            VStack(alignment: .leading, spacing: spacing) {
                VStack(alignment: .leading, spacing: spacing) {
                    header
                    ForEach(visibleNotes) { note in
                        PaperOverviewNoteRow(note: note, compact: family != .systemLarge)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                Link(destination: WidgetConstants.openAppURL) {
                    HStack {
                        Text("widget.mac.open_library")
                        Spacer(minLength: 0)
                        if entry.payload.total > visibleNotes.count {
                            Text(String(format: NSLocalizedString("widget.more", comment: "More notes"), entry.payload.total - visibleNotes.count))
                        }
                        Image(systemName: "arrow.up.right").accessibilityHidden(true)
                    }
                    .font(.caption)
                    .foregroundStyle(PaperWidgetTheme.secondaryInk(colorScheme, mode: renderingMode))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(PaperWidgetTheme.ink(colorScheme, mode: renderingMode))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(PaperWidgetTheme.contentInsets)
            .widgetURL(WidgetConstants.openAppURL)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("widget.mac.overview_heading")
                .font(.system(.headline, design: .serif))
                .bold()
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if family != .systemSmall {
                Link(destination: WidgetConstants.newNoteURL) {
                    Label("widget.mac.new_note", systemImage: "square.and.pencil")
                        .labelStyle(.iconOnly)
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .widgetAccentable()
            }
        }
    }
}
