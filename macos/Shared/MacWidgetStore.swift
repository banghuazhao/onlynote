import Foundation

/// The app publishes immutable snapshots; widget intents write separate
/// command files. Neither process opens the other process's Hive database.
struct MacWidgetStore: Sendable {
    static let appGroupId = Bundle.main.object(forInfoDictionaryKey: "OnlynoteWidgetAppGroup") as? String
        ?? "F694X76A5X.com.appsbay.onlynote"
    static let snapshotFile = "onlynote_widget_payload.json"
    static let commandNotification = "com.appsbay.onlynote.widget_commands"

    let directory: URL

    init(directory: URL? = nil) throws {
        if let directory {
            self.directory = directory
        } else if let group = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupId
        ) {
            self.directory = group
        } else {
            throw CocoaError(.fileReadNoPermission)
        }
    }

    var snapshotURL: URL { directory.appendingPathComponent(Self.snapshotFile) }
    var commandDirectory: URL {
        directory.appendingPathComponent("widget_commands", isDirectory: true)
    }

    func saveSnapshot(_ payload: String) throws {
        guard let data = payload.data(using: .utf8),
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              object["notes"] is [[String: Any]], object["total"] is Int else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: snapshotURL, options: .atomic)
    }

    func readSnapshot() throws -> Data { try Data(contentsOf: snapshotURL) }

    func readPending() throws -> [[String: Any]] {
        guard FileManager.default.fileExists(atPath: commandDirectory.path) else { return [] }
        let files = try FileManager.default.contentsOfDirectory(
            at: commandDirectory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]
        )
        return files.filter { $0.pathExtension == "json" }.compactMap { file in
            guard (try? file.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true,
                  let data = try? Data(contentsOf: file),
                  let command = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            return command
        }
    }

    func acknowledge(_ identifiers: [String]) throws {
        for id in identifiers where Self.validCommandId(id) {
            let file = commandDirectory.appendingPathComponent(id).appendingPathExtension("json")
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
        }
    }

    private static func validCommandId(_ value: String) -> Bool {
        !value.isEmpty && value.count <= 128 && value.allSatisfy {
            $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-")
        }
    }
}
