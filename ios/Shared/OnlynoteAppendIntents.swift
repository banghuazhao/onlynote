import AppIntents
import Foundation

@available(iOS 16.0, macOS 13.0, *)
struct AppendNoteEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("Note", table: "ShortcutActions"))
    static var defaultQuery: AppendNoteQuery { AppendNoteQuery() }

    let id: String
    let title: String
    let modifiedAt: Date?

    var displayRepresentation: DisplayRepresentation {
        if let modifiedAt {
            return DisplayRepresentation(title: "\(title)", subtitle: "\(modifiedAt.formatted(date: .abbreviated, time: .shortened))")
        }
        return DisplayRepresentation(title: "\(title)")
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct AppendNoteQuery: EntityStringQuery {
    private func notes() throws -> [AppendNoteEntity] {
        try ShortcutsAppendStore().catalog().compactMap { row in
            guard let id = row["id"] as? String, !id.isEmpty,
                  let title = row["title"] as? String else { return nil }
            let modifiedAt = (row["modifiedAt"] as? NSNumber).map {
                Date(timeIntervalSince1970: $0.doubleValue / 1000)
            }
            return AppendNoteEntity(id: id, title: title, modifiedAt: modifiedAt)
        }
    }

    func entities(for identifiers: [String]) async throws -> [AppendNoteEntity] {
        let notes = try notes()
        return identifiers.compactMap { id in notes.first { $0.id == id } }
    }

    func suggestedEntities() async throws -> [AppendNoteEntity] { Array(try notes().prefix(50)) }

    func entities(matching string: String) async throws -> [AppendNoteEntity] {
        try notes().filter { $0.title.localizedStandardContains(string) }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct AppendToTodayNoteIntent: AppIntent {
    static let title = LocalizedStringResource("Append to Today’s Note", table: "ShortcutActions")
    static let description = IntentDescription(LocalizedStringResource("Open Onlynote and append text to today’s daily note.", table: "ShortcutActions"))
    static let openAppWhenRun: Bool = true

    @Parameter(title: LocalizedStringResource("Text", table: "ShortcutActions"), inputOptions: String.IntentInputOptions(multiline: true))
    var text: String


    func perform() async throws -> some IntentResult & ProvidesDialog {
        try ShortcutsAppendStore().enqueue(destination: "today", text: text)
        return .result(dialog: IntentDialog(LocalizedStringResource("Opening Onlynote to finish adding your text.", table: "ShortcutActions")))
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct AppendToNoteIntent: AppIntent {
    static let title = LocalizedStringResource("Append to Note", table: "ShortcutActions")
    static let description = IntentDescription(LocalizedStringResource("Choose a note, then open Onlynote to append text.", table: "ShortcutActions"))
    static let openAppWhenRun: Bool = true

    @Parameter(title: LocalizedStringResource("Text", table: "ShortcutActions"), inputOptions: String.IntentInputOptions(multiline: true))
    var text: String
    @Parameter(title: LocalizedStringResource("Note", table: "ShortcutActions")) var note: AppendNoteEntity


    func perform() async throws -> some IntentResult & ProvidesDialog {
        try ShortcutsAppendStore().enqueue(destination: "note", text: text, noteID: note.id)
        return .result(dialog: IntentDialog(LocalizedStringResource("Opening Onlynote to finish adding your text.", table: "ShortcutActions")))
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SaveTextToInboxIntent: AppIntent {
    static let title = LocalizedStringResource("Save Text to Inbox", table: "ShortcutActions")
    static let description = IntentDescription(LocalizedStringResource("Pass text or the Clipboard variable to Onlynote’s Inbox note.", table: "ShortcutActions"))
    static let openAppWhenRun: Bool = true

    @Parameter(title: LocalizedStringResource("Text", table: "ShortcutActions"), inputOptions: String.IntentInputOptions(multiline: true))
    var text: String


    func perform() async throws -> some IntentResult & ProvidesDialog {
        try ShortcutsAppendStore().enqueue(destination: "inbox", text: text)
        return .result(dialog: IntentDialog(LocalizedStringResource("Opening Onlynote to finish adding your text.", table: "ShortcutActions")))
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct OnlynoteAppendShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AppendToTodayNoteIntent(), phrases: [
            "Append to today’s note in \(.applicationName)",
            "Add to today’s note in \(.applicationName)"
        ], shortTitle: LocalizedStringResource("Append to Today", table: "ShortcutActions"), systemImageName: "calendar.badge.plus")
        AppShortcut(intent: AppendToNoteIntent(), phrases: [
            "Append to a note in \(.applicationName)",
            "Add to a note in \(.applicationName)"
        ], shortTitle: LocalizedStringResource("Append to Note", table: "ShortcutActions"), systemImageName: "note.text.badge.plus")
        AppShortcut(intent: SaveTextToInboxIntent(), phrases: [
            "Save to Inbox in \(.applicationName)",
            "Capture text in \(.applicationName)"
        ], shortTitle: LocalizedStringResource("Save to Inbox", table: "ShortcutActions"), systemImageName: "tray.and.arrow.down")
    }
}
