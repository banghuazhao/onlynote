// Run from the repository root:
// xcrun swiftc -swift-version 6 -strict-concurrency=complete \
//   ios/Shared/ShortcutsAppendStore.swift tool/tests/shortcuts_append_store_tests.swift \
//   -o /private/tmp/onlynote-shortcuts-store-tests && /private/tmp/onlynote-shortcuts-store-tests
import Foundation

@main
struct ShortcutsAppendStoreTests {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    static func require(_ value: @autoclosure () throws -> Bool, _ message: String) throws {
        if try !value() { throw Failure(description: message) }
    }

    static func main() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("onlynote-shortcuts-store-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try ShortcutsAppendStore(directory: directory)
        let broken = directory.appendingPathComponent("12345678-1234-1234-1234-000000000001.json")
        let brokenBytes = Data("{unfinished capture".utf8)
        try brokenBytes.write(to: broken)
        try store.enqueue(destination: "inbox", text: "Valid capture")
        let requests = try store.pending()
        try require(requests.count == 1, "A malformed peer must not block valid captures")
        try require(requests.first?["text"] as? String == "Valid capture", "The valid capture must survive")
        try require(Data(contentsOf: broken) == brokenBytes, "Malformed capture bytes must remain untouched")
        try store.acknowledge(requests[0]["id"] as! String)
        try require(store.pending().isEmpty, "Acknowledgement must remove only the valid capture")
        try require(FileManager.default.fileExists(atPath: broken.path), "Acknowledgement must preserve malformed peers")

        let id = "12345678-1234-1234-1234-000000000002"
        let file = directory.appendingPathComponent("\(id).json")
        let base: [String: Any] = [
            "id": id, "version": 1, "createdAt": 1_793_280_000_000 as Int64,
            "destination": "note", "noteId": "target", "text": "Retained text"
        ]
        let invalid: [[String: Any]] = [
            ["createdAt": -1], ["createdAt": true], ["createdAt": 0.5],
            ["createdAt": 8_640_000_000_000_001 as Int64], ["version": true],
            ["noteId": String(repeating: "x", count: 513)],
            ["destination": "inbox", "noteId": ["invalid": "type"]]
        ]
        for changes in invalid {
            let bytes = try JSONSerialization.data(withJSONObject: base.merging(changes) { _, next in next })
            try bytes.write(to: file, options: .atomic)
            try require(store.pending().isEmpty, "Invalid field must not poison the Flutter queue: \(changes.keys)")
            try require(Data(contentsOf: file) == bytes, "Invalid request must remain recoverable")
        }
        try JSONSerialization.data(withJSONObject: base).write(to: file, options: .atomic)
        try require(store.pending().count == 1, "A corrected request must be readable again")

        // Retained malformed files still consume capacity, so ignoring a bad
        // peer cannot grow the durable native queue without a bound.
        for sequence in 3...100 {
            let name = String(format: "12345678-1234-1234-1234-%012d.json", sequence)
            try brokenBytes.write(to: directory.appendingPathComponent(name))
        }
        do {
            try store.enqueue(destination: "inbox", text: "At capacity")
            throw Failure(description: "Malformed records must count toward queue capacity")
        } catch ShortcutsAppendStore.AppendError.inboxFull { }
        print("ShortcutsAppendStore regression checks passed")
    }
}
