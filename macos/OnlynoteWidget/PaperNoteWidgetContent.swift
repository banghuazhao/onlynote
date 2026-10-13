import SwiftUI
import WidgetKit

/// Pure presentation also used by ImageRenderer; sample data is supplied only
/// by the provider's gallery placeholder/snapshot and explicit preview code.
@available(macOS 14.0, *)
struct PaperNoteWidgetContent: View {
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

    private var selectedNote: WidgetNote? {
        if let id = entry.selectedNoteId {
            return entry.payload.allNotes.first { $0.id == id }
        }
        return entry.payload.notes.first
    }

    private var todoLimit: Int {
        if typeSize.isAccessibilitySize { return family == .systemLarge ? 3 : 1 }
        switch family {
        case .systemLarge: return 7
        case .systemMedium: return 3
        default: return 2
        }
    }

    var body: some View {
        if let note = selectedNote {
            noteContent(note)
                .widgetURL(WidgetConstants.noteURL(id: note.id))
        } else {
            PaperWidgetEmptyView(unavailable: entry.selectedNoteId != nil, family: family)
        }
    }

    private func noteContent(_ note: WidgetNote) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Text("widget.app_name")
                    .font(.caption)
                    .foregroundStyle(PaperWidgetTheme.secondaryInk(colorScheme, mode: renderingMode))
                Spacer(minLength: 0)
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(PaperWidgetTheme.noteAccent(note, mode: renderingMode))
                        .widgetAccentable()
                        .accessibilityLabel(Text("widget.mac.pinned"))
                }
            }
            Link(destination: WidgetConstants.noteURL(id: note.id)) {
                Text(note.title.isEmpty
                    ? NSLocalizedString("widget.untitled", comment: "Untitled note")
                    : note.title)
                    .font(.system(.headline, design: .serif))
                    .bold()
                    .lineLimit(family == .systemSmall && !typeSize.isAccessibilitySize ? 2 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)

            if note.hasChecklist {
                if family == .systemLarge && !note.body.isEmpty {
                    bodyText(note.body, noteID: note.id, lineLimit: 2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(note.todos.prefix(todoLimit).enumerated()), id: \.offset) { _, todo in
                        PaperTodoRow(note: note, todo: todo)
                    }
                }
            } else if !note.body.isEmpty {
                bodyText(note.body, noteID: note.id)
            }

            Spacer(minLength: 0)
            footer(note)
        }
        .foregroundStyle(PaperWidgetTheme.ink(colorScheme, mode: renderingMode))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(PaperWidgetTheme.contentInsets)
    }

    private func bodyText(_ text: String, noteID: String, lineLimit: Int? = nil) -> some View {
        Link(destination: WidgetConstants.noteURL(id: noteID)) {
            Text(text)
                .font(.system(.callout, design: .serif))
                .foregroundStyle(PaperWidgetTheme.secondaryInk(colorScheme, mode: renderingMode))
                .lineSpacing(3)
                .lineLimit(lineLimit ?? (typeSize.isAccessibilitySize
                    ? (family == .systemLarge ? 6 : 1)
                    : (family == .systemLarge ? 10 : 3)))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func footer(_ note: WidgetNote) -> some View {
        HStack(spacing: 8) {
            if note.hasChecklist {
                Label {
                    Text(String(format: NSLocalizedString("widget.mac.checklist_progress", comment: "Checklist progress"), note.todoDone, note.todoTotal))
                } icon: {
                    Image(systemName: "checklist").accessibilityHidden(true)
                }
                .lineLimit(1)
            } else if note.imageCount > 0 {
                Label {
                    Text(String(format: NSLocalizedString("widget.mac.photo_count", comment: "Attached photo count"), note.imageCount))
                } icon: {
                    Image(systemName: "photo").accessibilityHidden(true)
                }
                .lineLimit(1)
            } else {
                Text("widget.mac.open_note")
            }
            Spacer(minLength: 0)
            if family != .systemSmall {
                Link(destination: WidgetConstants.newNoteURL) {
                    Label("widget.mac.new_note", systemImage: "square.and.pencil")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .widgetAccentable()
            }
        }
        .font(.caption)
        .foregroundStyle(PaperWidgetTheme.secondaryInk(colorScheme, mode: renderingMode))
    }
}
