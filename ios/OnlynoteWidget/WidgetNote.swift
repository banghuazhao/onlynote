import Foundation
import SwiftUI
import AppIntents
import WidgetKit
import CoreFoundation

/// The snapshot the Flutter app writes into the shared App Group container.
///
/// Every field is decoded defensively: a single unexpected value in the
/// payload must not blank out the whole widget, so missing keys fall back to
/// empty rather than throwing.
struct WidgetPayload: Decodable, Sendable {
    /// Total number of active notes, which can exceed `notes.count` — the app
    /// only serializes the first handful.
    let total: Int
    let notes: [WidgetNote]
    let allNotes: [WidgetNote]

    init(total: Int, notes: [WidgetNote], allNotes: [WidgetNote]? = nil) {
        self.total = total
        self.notes = notes
        self.allNotes = allNotes ?? notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notes = (try? container.decode([WidgetNote].self, forKey: .notes)) ?? []
        total = (try? container.decode(Int.self, forKey: .total)) ?? notes.count
        allNotes = (try? container.decode([WidgetNote].self, forKey: .allNotes)) ?? notes
    }

    private enum CodingKeys: String, CodingKey {
        case total, notes, allNotes
    }

    static let empty = WidgetPayload(total: 0, notes: [])

    /// Reads the payload the app last wrote. Returns `.empty` when the app has
    /// never run, the App Group isn't reachable, or the JSON is unreadable.
    static func load() -> WidgetPayload {
        #if os(macOS)
        guard let store = try? MacWidgetStore(),
              let data = try? store.readSnapshot(),
              let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data) else {
            return .empty
        }
        #else
        guard
            let defaults = UserDefaults(suiteName: WidgetConstants.appGroupId),
            let raw = defaults.string(forKey: WidgetConstants.payloadKey),
            let data = raw.data(using: .utf8),
            let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
        else {
            return .empty
        }
        #endif
        return WidgetCommandJournal.overlay(payload)
    }
}

struct WidgetNote: Decodable, Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
    let colorValue: Int?
    let isPinned: Bool
    let imageCount: Int
    let todoTotal: Int
    let todoDone: Int
    let todos: [WidgetTodo]

    init(
        id: String,
        title: String,
        body: String = "",
        colorValue: Int? = nil,
        isPinned: Bool = false,
        imageCount: Int = 0,
        todoTotal: Int = 0,
        todoDone: Int = 0,
        todos: [WidgetTodo] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.colorValue = colorValue
        self.isPinned = isPinned
        self.imageCount = imageCount
        self.todoTotal = todoTotal
        self.todoDone = todoDone
        self.todos = todos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        body = (try? container.decode(String.self, forKey: .body)) ?? ""
        colorValue = try? container.decode(Int.self, forKey: .color)
        isPinned = (try? container.decode(Bool.self, forKey: .pinned)) ?? false
        imageCount = (try? container.decode(Int.self, forKey: .images)) ?? 0
        todoTotal = (try? container.decode(Int.self, forKey: .todoTotal)) ?? 0
        todoDone = (try? container.decode(Int.self, forKey: .todoDone)) ?? 0
        todos = (try? container.decode([WidgetTodo].self, forKey: .todos)) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, body, color, pinned, images, todoTotal, todoDone, todos
    }

    /// Notes are saveable with no title at all, so fall back to the body
    /// before giving up and showing a placeholder.
    var displayTitle: String {
        if !title.isEmpty { return title }
        if !body.isEmpty { return body }
        return NSLocalizedString("widget.untitled", comment: "Title shown for a note with no text")
    }

    /// The single line under the title. Checklists are more informative than
    /// their description, so they win when a note has both.
    var subtitle: String {
        if todoTotal > 0 {
            if let next = todos.first(where: { !$0.completed }) {
                return next.title
            }
            return NSLocalizedString("widget.all_done", comment: "All checklist items completed")
        }
        if !body.isEmpty { return body }
        if !title.isEmpty && title != displayTitle { return title }
        return ""
    }

    var accentColor: Color {
        guard let colorValue else { return WidgetTheme.defaultNoteColor }
        return Color(argb: colorValue)
    }

    var hasChecklist: Bool { todoTotal > 0 }
}

struct WidgetTodo: Decodable, Sendable {
    let id: String?
    let title: String
    let completed: Bool

    init(id: String? = nil, title: String, completed: Bool) {
        self.id = id
        self.title = title
        self.completed = completed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(String.self, forKey: .id)
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        completed = (try? container.decode(Bool.self, forKey: .completed)) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title = "t"
        case completed = "c"
    }
}

extension Color {
    /// Note colors arrive as Flutter ARGB ints (`Color.toARGB32`).
    init(argb: Int) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: Double((argb >> 24) & 0xFF) / 255
        )
    }
}


/// Individual atomic files avoid lost updates between the extension and Runner.
/// Acknowledgement removes only the IDs that Dart durably applied.
enum WidgetCommandJournal {
    private static let writeLock = NSLock()
    static var directory: URL? {
        #if os(macOS)
        return try? MacWidgetStore().commandDirectory
        #else
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetConstants.appGroupId)?
            .appendingPathComponent("widget_commands", isDirectory: true)
        #endif
    }

    static func pending() -> [[String: Any]] {
        guard let root = directory,
              let files = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.filter { $0.pathExtension == "json" }.compactMap { file in
            guard let data = try? Data(contentsOf: file),
                  let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  value["noteId"] is String, value["todoId"] is String,
                  value["completed"] is Bool, value["createdAt"] is NSNumber else { return nil }
            return value
        }.sorted {
            let lhs = ($0["createdAt"] as? NSNumber)?.int64Value ?? 0
            let rhs = ($1["createdAt"] as? NSNumber)?.int64Value ?? 0
            return lhs == rhs ? ($0["id"] as? String ?? "") < ($1["id"] as? String ?? "") : lhs < rhs
        }
    }

    static func enqueue(noteId: String, todoId: String, completed: Bool) throws {
        writeLock.lock()
        defer { writeLock.unlock() }
        guard let root = directory else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let id = UUID().uuidString
        let previousTime = pending().compactMap { ($0["createdAt"] as? NSNumber)?.int64Value }.max() ?? 0
        let timestamp = max(Int64(Date().timeIntervalSince1970 * 1_000_000), previousTime + 1)
        let value: [String: Any] = [
            "id": id, "noteId": noteId, "todoId": todoId, "completed": completed,
            "createdAt": timestamp,
        ]
        let data = try JSONSerialization.data(withJSONObject: value)
        try data.write(to: root.appendingPathComponent(id).appendingPathExtension("json"), options: .atomic)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(rawValue: "com.appsbay.onlynote.widget_commands" as CFString), nil, nil, true
        )
    }

    static func overlay(_ payload: WidgetPayload) -> WidgetPayload {
        let commands = pending()
        func apply(_ note: WidgetNote) -> WidgetNote {
            var todos = note.todos
            for command in commands where command["noteId"] as? String == note.id {
                todos = todos.map { todo in
                    guard let id = todo.id, id == command["todoId"] as? String,
                          let completed = command["completed"] as? Bool else { return todo }
                    return WidgetTodo(id: id, title: todo.title, completed: completed)
                }
            }
            let delta = todos.filter(\.completed).count - note.todos.filter(\.completed).count
            return WidgetNote(
                id: note.id, title: note.title, body: note.body, colorValue: note.colorValue,
                isPinned: note.isPinned, imageCount: note.imageCount, todoTotal: note.todoTotal,
                todoDone: min(note.todoTotal, max(0, note.todoDone + delta)), todos: todos
            )
        }
        return WidgetPayload(total: payload.total, notes: payload.notes.map(apply), allNotes: payload.allNotes.map(apply))
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct WidgetNoteEntity: AppEntity, Sendable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "widget.choose_note"
    static let defaultQuery = WidgetNoteQuery()
    let id: String
    let title: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }

    static var all: WidgetNoteEntity {
        #if os(macOS)
        WidgetNoteEntity(id: "__all_notes__", title: NSLocalizedString("widget.mac.latest_note", comment: "Automatically show the latest note"))
        #else
        WidgetNoteEntity(id: "__all_notes__", title: NSLocalizedString("widget.all_notes", comment: "Widget selection"))
        #endif
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct WidgetNoteQuery: EntityStringQuery, Sendable {
    func entities(for identifiers: [String]) async throws -> [WidgetNoteEntity] {
        let notes = WidgetPayload.load().allNotes
        return identifiers.map { id in
            if id == WidgetNoteEntity.all.id { return .all }
            let note = notes.first { $0.id == id }
            return WidgetNoteEntity(id: id, title: note?.displayTitle ?? NSLocalizedString("widget.note_unavailable", comment: "Removed note"))
        }
    }
    func entities(matching string: String) async throws -> [WidgetNoteEntity] {
        try await suggestedEntities().filter { $0.title.localizedCaseInsensitiveContains(string) }
    }
    func suggestedEntities() async throws -> [WidgetNoteEntity] {
        [.all] + WidgetPayload.load().allNotes.map { WidgetNoteEntity(id: $0.id, title: $0.displayTitle) }
    }
    func defaultResult() async -> WidgetNoteEntity? { .all }
}

@available(iOS 17.0, macOS 14.0, *)
struct NoteWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "widget.choose_note"
    static let description = IntentDescription("widget.selection_description")
    @Parameter(title: "widget.choose_note") var note: WidgetNoteEntity?
}

@available(iOS 17.0, macOS 14.0, *)
struct CompleteWidgetTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "widget.complete_item"
    static let openAppWhenRun: Bool = false
    @Parameter(title: "Note ID") var noteId: String
    @Parameter(title: "Item ID") var todoId: String
    @Parameter(title: "Completed") var completed: Bool

    init() {}
    init(noteId: String, todoId: String, completed: Bool) {
        self.noteId = noteId
        self.todoId = todoId
        self.completed = completed
    }
    func perform() async throws -> some IntentResult {
        let note = WidgetPayload.load().allNotes.first { $0.id == noteId }
        guard let note, note.todos.contains(where: { $0.id == todoId }) else { return .result() }
        try WidgetCommandJournal.enqueue(noteId: noteId, todoId: todoId, completed: completed)
        #if os(macOS)
        WidgetCenter.shared.reloadAllTimelines()
        #else
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.kind)
        #endif
        return .result()
    }
}
