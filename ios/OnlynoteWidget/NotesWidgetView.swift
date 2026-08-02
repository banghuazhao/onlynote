import WidgetKit
import SwiftUI

struct NotesWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    let entry: NotesEntry

    var body: some View {
        Group {
            if entry.payload.notes.isEmpty {
                EmptyStateView()
            } else {
                switch family {
                case .systemSmall:
                    SmallNoteView(note: entry.payload.notes[0])
                default:
                    NoteListView(payload: entry.payload, rowCount: rowCount)
                }
            }
        }
        .widgetContainerBackground(WidgetTheme.background(colorScheme))
    }

    private var rowCount: Int {
        family == .systemLarge ? 6 : 3
    }
}

// MARK: - Small

/// systemSmall ignores `Link`, so the whole widget is one tap target and the
/// quick-add shortcut only appears from medium up.
private struct SmallNoteView: View {
    @Environment(\.colorScheme) private var colorScheme

    let note: WidgetNote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Circle()
                    .fill(note.accentColor)
                    .frame(width: 10, height: 10)
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(WidgetTheme.amber)
                }
                Spacer(minLength: 0)
            }

            Text(note.displayTitle)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(WidgetTheme.primaryText(colorScheme))
                .lineLimit(2)

            if !note.subtitle.isEmpty {
                Text(note.subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)

            NoteBadge(note: note)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(WidgetConstants.noteURL(id: note.id))
    }
}

// MARK: - Medium & Large

private struct NoteListView: View {
    @Environment(\.widgetFamily) private var family

    let payload: WidgetPayload
    let rowCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HeaderView()

            VStack(spacing: 0) {
                ForEach(Array(visibleNotes.enumerated()), id: \.element.id) { index, note in
                    if index > 0 {
                        Divider().opacity(0.35)
                    }
                    Link(destination: WidgetConstants.noteURL(id: note.id)) {
                        NoteRow(note: note)
                    }
                }
            }

            Spacer(minLength: 0)

            // Medium is only about 150pt tall once three rows are in; the
            // footer is what pushed the header off the top edge, so it's
            // large-only.
            if family == .systemLarge && remainingCount > 0 {
                Link(destination: WidgetConstants.openAppURL) {
                    Text(String(format: NSLocalizedString("widget.more", comment: "More notes"), remainingCount))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var visibleNotes: [WidgetNote] {
        Array(payload.notes.prefix(rowCount))
    }

    private var remainingCount: Int {
        max(0, payload.total - visibleNotes.count)
    }
}

private struct HeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Text("widget.app_name")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(WidgetTheme.primaryText(colorScheme).opacity(0.7))

            Spacer(minLength: 0)

            Link(destination: WidgetConstants.newNoteURL) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 11, weight: .bold))
                    Text("widget.new_note")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                }
                .foregroundColor(WidgetTheme.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(WidgetTheme.amber)
                )
            }
        }
    }
}

private struct NoteRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let note: WidgetNote

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(note.accentColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundColor(WidgetTheme.amber)
                    }
                    Text(note.displayTitle)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(WidgetTheme.primaryText(colorScheme))
                        .lineLimit(1)
                }

                if !note.subtitle.isEmpty {
                    Text(note.subtitle)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            NoteBadge(note: note)
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        // The stripe is a Shape, which greedily fills the height offered to it
        // and would stretch every row to fill the widget. Pinning the row to
        // its ideal height lets the text decide, and the stripe follows.
        .fixedSize(horizontal: false, vertical: true)
        // Without this the Link only responds to taps on the text itself.
        .contentShape(Rectangle())
    }
}

/// Trailing indicator: checklist progress takes priority over the photo count,
/// matching which of the two the row's subtitle is already describing.
private struct NoteBadge: View {
    let note: WidgetNote

    var body: some View {
        if note.hasChecklist {
            HStack(spacing: 3) {
                Image(systemName: note.todoDone == note.todoTotal
                      ? "checkmark.circle.fill"
                      : "checklist")
                    .font(.system(size: 9))
                Text("\(note.todoDone)/\(note.todoTotal)")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
            }
            .foregroundColor(.secondary)
        } else if note.imageCount > 0 {
            HStack(spacing: 3) {
                Image(systemName: "photo")
                    .font(.system(size: 9))
                if note.imageCount > 1 {
                    Text("\(note.imageCount)")
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                }
            }
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Empty state

private struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(WidgetTheme.amber)

            Text("widget.empty.title")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(WidgetTheme.primaryText(colorScheme))

            Text("widget.empty.action")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(WidgetConstants.newNoteURL)
    }
}

// MARK: - Version compatibility

private extension View {
    /// iOS 17 inset widget content automatically and requires
    /// `containerBackground`; earlier versions need the padding and background
    /// applied by hand. Keeping both here means the layout code above doesn't
    /// have to care which one it's running on.
    @ViewBuilder
    func widgetContainerBackground(_ background: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(background, for: .widget)
        } else {
            self
                .padding(11)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(background)
        }
    }
}
