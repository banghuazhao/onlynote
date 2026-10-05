import WidgetKit
import SwiftUI

struct NotesEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload
    var selectedNoteId: String? = nil
}

struct NotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> NotesEntry {
        NotesEntry(date: Date(), payload: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (NotesEntry) -> Void) {
        // The widget gallery shows the snapshot. Real notes there would be a
        // privacy leak on a shared screen and look empty on a fresh install,
        // so previews always get the sample content.
        let payload = context.isPreview ? WidgetPayload.sample : WidgetPayload.load()
        completion(NotesEntry(date: Date(), payload: payload))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NotesEntry>) -> Void) {
        // `.never`: the app reloads this timeline itself whenever a note
        // changes, so there's nothing to gain from a scheduled refresh — and
        // WidgetKit's refresh budget is better left unspent.
        let entry = NotesEntry(date: Date(), payload: .load())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

extension WidgetPayload {
    /// Content for the widget gallery and Xcode previews.
    static var sample: WidgetPayload {
        func localized(_ key: String) -> String {
            NSLocalizedString(key, comment: "Sample note shown in the widget gallery")
        }

        return WidgetPayload(
            total: 5,
            notes: [
                WidgetNote(
                    id: "sample-1",
                    title: localized("widget.sample.1.title"),
                    body: localized("widget.sample.1.body"),
                    colorValue: 0xFFF7D9A0,
                    isPinned: true
                ),
                WidgetNote(
                    id: "sample-2",
                    title: localized("widget.sample.2.title"),
                    colorValue: 0xFFB8E0D2,
                    todoTotal: 3,
                    todoDone: 1,
                    todos: [
                        WidgetTodo(title: localized("widget.sample.2.todo.1"), completed: true),
                        WidgetTodo(title: localized("widget.sample.2.todo.2"), completed: false),
                        WidgetTodo(title: localized("widget.sample.2.todo.3"), completed: false),
                    ]
                ),
                WidgetNote(
                    id: "sample-3",
                    title: localized("widget.sample.3.title"),
                    body: localized("widget.sample.3.body"),
                    colorValue: 0xFFA7C6E0
                ),
                WidgetNote(
                    id: "sample-4",
                    title: localized("widget.sample.4.title"),
                    colorValue: 0xFFF6C6C6,
                    imageCount: 2
                ),
                WidgetNote(
                    id: "sample-5",
                    title: localized("widget.sample.5.title"),
                    body: localized("widget.sample.5.body"),
                    colorValue: 0xFFCBB8E0
                ),
            ]
        )
    }
}


@available(iOS 17.0, *)
struct ConfigurableNotesProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NotesEntry {
        NotesEntry(date: Date(), payload: .sample)
    }
    func snapshot(for configuration: NoteWidgetConfiguration, in context: Context) async -> NotesEntry {
        entry(for: configuration, preview: context.isPreview)
    }
    func timeline(for configuration: NoteWidgetConfiguration, in context: Context) async -> Timeline<NotesEntry> {
        Timeline(entries: [entry(for: configuration, preview: false)], policy: .never)
    }
    private func entry(for configuration: NoteWidgetConfiguration, preview: Bool) -> NotesEntry {
        let id = configuration.note?.id
        let selectedId = id == WidgetNoteEntity.all.id ? nil : id
        let payload = preview ? WidgetPayload.sample : WidgetPayload.load()
        let displayId = preview && selectedId != nil ? payload.notes.first(where: { $0.hasChecklist })?.id : selectedId
        return NotesEntry(date: Date(), payload: payload, selectedNoteId: displayId)
    }
}
