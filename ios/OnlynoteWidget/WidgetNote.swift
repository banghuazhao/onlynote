import Foundation
import SwiftUI

/// The snapshot the Flutter app writes into the shared App Group container.
///
/// Every field is decoded defensively: a single unexpected value in the
/// payload must not blank out the whole widget, so missing keys fall back to
/// empty rather than throwing.
struct WidgetPayload: Decodable {
    /// Total number of active notes, which can exceed `notes.count` — the app
    /// only serializes the first handful.
    let total: Int
    let notes: [WidgetNote]

    init(total: Int, notes: [WidgetNote]) {
        self.total = total
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notes = (try? container.decode([WidgetNote].self, forKey: .notes)) ?? []
        total = (try? container.decode(Int.self, forKey: .total)) ?? notes.count
    }

    private enum CodingKeys: String, CodingKey {
        case total, notes
    }

    static let empty = WidgetPayload(total: 0, notes: [])

    /// Reads the payload the app last wrote. Returns `.empty` when the app has
    /// never run, the App Group isn't reachable, or the JSON is unreadable.
    static func load() -> WidgetPayload {
        guard
            let defaults = UserDefaults(suiteName: WidgetConstants.appGroupId),
            let raw = defaults.string(forKey: WidgetConstants.payloadKey),
            let data = raw.data(using: .utf8),
            let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
        else {
            return .empty
        }
        return payload
    }
}

struct WidgetNote: Decodable, Identifiable {
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

struct WidgetTodo: Decodable {
    let title: String
    let completed: Bool

    init(title: String, completed: Bool) {
        self.title = title
        self.completed = completed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        completed = (try? container.decode(Bool.self, forKey: .completed)) ?? false
    }

    private enum CodingKeys: String, CodingKey {
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
