import Foundation

/// Atomic, file-backed inbox shared by the extension and the app. Attachment
/// names are private; no caller can acknowledge a path outside this directory.
enum ShareInbox {
    static let group = "group.com.appsbay.onlynote"
    static let maxImageBytes: Int64 = 25 * 1024 * 1024
    static let maxTotalBytes: Int64 = 100 * 1024 * 1024

    static func root() throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: group
        ) else { throw InboxError.unavailable }
        let root = container.appendingPathComponent("ShareInbox", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func pending() throws -> [[String: Any]] {
        let root = try root()
        let folders = try FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: nil
        ).filter { UUID(uuidString: $0.lastPathComponent) != nil }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return try folders.map { folder in
            let data = try Data(contentsOf: folder.appendingPathComponent("entry.json"))
            guard var entry = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  entry["version"] as? Int == 1,
                  let id = entry["id"] as? String,
                  id == folder.lastPathComponent,
                  let title = entry["title"] as? String,
                  title.utf16.count <= 1000,
                  let text = entry["text"] as? String,
                  text.utf16.count <= 100000,
                  let names = entry["images"] as? [String],
                  names.count <= 10,
                  !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || !names.isEmpty,
                  names.allSatisfy({ name in
                      !name.isEmpty && !name.contains("/") && !name.contains("\\")
                          && !name.contains("..")
                  }) else { throw InboxError.invalid }
            entry["images"] = names.map { folder.appendingPathComponent($0).path }
            return entry
        }.sorted { ($0["createdAt"] as? Double ?? 0) < ($1["createdAt"] as? Double ?? 0) }
    }

    static func acknowledge(_ id: String) throws {
        guard UUID(uuidString: id) != nil else { throw InboxError.invalid }
        let folder = try root().appendingPathComponent(id, isDirectory: true)
        if FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.removeItem(at: folder)
        }
    }

    enum InboxError: Error { case unavailable, invalid, tooLarge, unsupported }
}
