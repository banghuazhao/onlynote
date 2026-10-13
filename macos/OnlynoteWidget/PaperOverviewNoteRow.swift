import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperOverviewNoteRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode
    let note: WidgetNote
    let compact: Bool

    var body: some View {
        Link(destination: WidgetConstants.noteURL(id: note.id)) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(note.displayTitle)
                        .font(.subheadline)
                        .bold()
                        .lineLimit(1)
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .accessibilityLabel(Text("widget.mac.pinned"))
                    }
                    Spacer(minLength: 0)
                }
                if !note.subtitle.isEmpty {
                    Label {
                        Text(note.subtitle).lineLimit(compact ? 1 : 2)
                    } icon: {
                        if note.hasChecklist {
                            Image(systemName: note.todoDone == note.todoTotal ? "checkmark.square" : "square")
                                .accessibilityHidden(true)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(PaperWidgetTheme.secondaryInk(colorScheme, mode: renderingMode))
                }
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 30 : 38, alignment: .leading)
            .padding(.leading, 11)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(PaperWidgetTheme.noteAccent(note, mode: renderingMode))
                    .frame(width: 3)
                    .widgetAccentable()
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
