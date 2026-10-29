import Foundation
import CoreFoundation

/// App Intents publish atomic request files. Only the foreground Flutter engine
/// opens the notes database; the native side never edits Hive or widget data.
struct ShortcutsAppendStore: Sendable {
    static let notification = "com.appsbay.onlynote.shortcuts_append"
    static var group: String {
        #if os(macOS)
        return Bundle.main.object(forInfoDictionaryKey: "OnlynoteWidgetAppGroup") as? String
            ?? "F694X76A5X.com.appsbay.onlynote"
        #else
        return "group.com.appsbay.onlynote"
        #endif
    }

    let directory: URL

    init(directory: URL? = nil) throws {
        if let directory {
            self.directory = directory
        } else if let group = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.group
        ) {
            self.directory = group.appendingPathComponent("ShortcutsAppend", isDirectory: true)
        } else {
            throw AppendError.storageUnavailable
        }
        try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func enqueue(destination: String, text: String, noteID: String? = nil) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, text.utf16.count <= 100_000,
              ["today", "note", "inbox"].contains(destination),
              destination != "note" || (noteID?.isEmpty == false && (noteID?.utf16.count ?? 0) <= 512)
        else { throw AppendError.invalidText }
        guard try requestFiles().count < 100 else { throw AppendError.inboxFull }
        let id = UUID().uuidString.lowercased()
        var entry: [String: Any] = [
            "version": 1, "id": id, "destination": destination, "text": text,
            "createdAt": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        if let noteID { entry["noteId"] = noteID }
        let bytes = try JSONSerialization.data(withJSONObject: entry, options: [.sortedKeys])
        try bytes.write(to: directory.appendingPathComponent("\(id).json"), options: .atomic)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(Self.notification as CFString), nil, nil, true
        )
    }

    func pending() throws -> [[String: Any]] {
        return try requestFiles().compactMap { path in
            let bytes: Data
            do {
                bytes = try Data(contentsOf: path)
            } catch CocoaError.fileReadNoSuchFile {
                // Another engine may acknowledge a file after this directory
                // snapshot. It is already handled and must not block peers.
                return nil
            }
            guard bytes.count <= 1_000_000,
                  var value = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: Any],
                  let version = value["version"] as? NSNumber,
                  CFGetTypeID(version) != CFBooleanGetTypeID(), version.doubleValue == 1,
                  let id = value["id"] as? String,
                  id == id.lowercased(),
                  id == path.deletingPathExtension().lastPathComponent,
                  let text = value["text"] as? String, text.utf16.count <= 100_000,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let destination = value["destination"] as? String,
                  ["today", "note", "inbox"].contains(destination),
                  destination != "note" || (value["noteId"] as? String)?.isEmpty == false,
                  value["noteId"] == nil || (value["noteId"] is String && (value["noteId"] as? String)?.utf16.count ?? 0 <= 512),
                  let createdAt = value["createdAt"] as? NSNumber,
                  CFGetTypeID(createdAt) != CFBooleanGetTypeID(),
                  createdAt.doubleValue.isFinite,
                  createdAt.doubleValue >= 0, createdAt.doubleValue <= 8_640_000_000_000_000,
                  createdAt.doubleValue.rounded(.towardZero) == createdAt.doubleValue
            else {
                // Keep the original bytes for recovery. A damaged capture must
                // not prevent unrelated valid requests from being delivered.
                return nil
            }
            // MethodChannel must deliver integer values to Dart's strict parser,
            // including JSON numbers originally encoded with a decimal suffix.
            value["version"] = 1
            value["createdAt"] = createdAt.int64Value
            return value
        }.sorted {
            let a = ($0["createdAt"] as? NSNumber)?.int64Value ?? 0
            let b = ($1["createdAt"] as? NSNumber)?.int64Value ?? 0
            return a == b ? ($0["id"] as? String ?? "") < ($1["id"] as? String ?? "") : a < b
        }
    }

    private func requestFiles() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" && UUID(uuidString: $0.deletingPathExtension().lastPathComponent) != nil }
    }

    func acknowledge(_ id: String) throws {
        guard UUID(uuidString: id) != nil else { throw AppendError.invalidRequest }
        let file = directory.appendingPathComponent("\(id.lowercased()).json")
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
    }

    func saveCatalog(_ notes: [[String: Any]]) throws {
        guard notes.count <= 10_000, notes.allSatisfy({
            guard let id = $0["id"] as? String, !id.isEmpty, id.utf16.count <= 512,
                  let title = $0["title"] as? String, title.utf16.count <= 500 else { return false }
            return true
        }) else { throw AppendError.invalidRequest }
        let bytes = try JSONSerialization.data(withJSONObject: notes, options: [.sortedKeys])
        try bytes.write(to: directory.appendingPathComponent("catalog.json"), options: .atomic)
    }

    func catalog() throws -> [[String: Any]] {
        let file = directory.appendingPathComponent("catalog.json")
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        let data = try Data(contentsOf: file)
        guard data.count <= 20 * 1024 * 1024,
              let notes = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              notes.count <= 10_000 else { throw AppendError.invalidRequest }
        return notes
    }

    enum AppendError: LocalizedError {
        case storageUnavailable, invalidText, invalidRequest, inboxFull

        var errorDescription: String? {
            switch self {
            case .storageUnavailable: return NSLocalizedString("shortcut.storageUnavailable", tableName: "ShortcutActions", value: "Open Onlynote once to finish setting up Shortcuts.", comment: "")
            case .invalidText: return NSLocalizedString("shortcut.invalidText", tableName: "ShortcutActions", value: "Enter text between 1 and 100,000 characters.", comment: "")
            case .invalidRequest: return NSLocalizedString("shortcut.invalidRequest", tableName: "ShortcutActions", value: "This shortcut request could not be read.", comment: "")
            case .inboxFull: return NSLocalizedString("shortcut.inboxFull", tableName: "ShortcutActions", value: "Open Onlynote to finish the pending shortcut requests.", comment: "")
            }
        }
    }
}
