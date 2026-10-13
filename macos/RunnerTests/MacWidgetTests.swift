import AppKit
import SwiftUI
import WidgetKit
import XCTest
@testable import Onlynote

final class MacWidgetTests: XCTestCase {
    private func scratchDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("onlynote-widget-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    func testSnapshotRoundTripAndInvalidWritePreservesPreviousData() throws {
        let root = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try MacWidgetStore(directory: root)
        let payload = #"{"total":1,"notes":[{"id":"paper","title":"Tomorrow","body":"First paragraph.\n\n第二段 ✨"}]}"#
        try store.saveSnapshot(payload)
        let original = try store.readSnapshot()
        let decoded = try JSONDecoder().decode(WidgetPayload.self, from: original)
        XCTAssertEqual(decoded.notes.first?.body, "First paragraph.\n\n第二段 ✨")
        XCTAssertEqual(decoded.allNotes.first?.id, "paper")
        XCTAssertThrowsError(try store.saveSnapshot(#"{"notes":"invalid"}"#))
        XCTAssertEqual(try store.readSnapshot(), original)
    }

    func testAcknowledgementKeepsOtherCommandsAndRejectsTraversal() throws {
        let root = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try MacWidgetStore(directory: root)
        try FileManager.default.createDirectory(at: store.commandDirectory, withIntermediateDirectories: true)
        for id in ["first", "second"] {
            try Data("{\"id\":\"\(id)\",\"noteId\":\"paper\",\"todoId\":\"item\",\"completed\":true,\"createdAt\":1}".utf8)
                .write(to: store.commandDirectory.appendingPathComponent("\(id).json"))
        }
        let protected = root.appendingPathComponent("outside.json")
        try Data("keep".utf8).write(to: protected)
        try store.acknowledge(["first", "../outside", "missing"])
        XCTAssertEqual(try store.readPending().compactMap { $0["id"] as? String }, ["second"])
        XCTAssertEqual(try String(contentsOf: protected, encoding: .utf8), "keep")
    }

    @MainActor
    func testWidgetLinksAcceptEncodedNoteIDsAndRejectUnrelatedURLs() {
        XCTAssertTrue(MacWidgetBridge.accepts(WidgetConstants.noteURL(id: "中文 & space")))
        XCTAssertTrue(MacWidgetBridge.accepts(WidgetConstants.openAppURL))
        XCTAssertTrue(MacWidgetBridge.accepts(WidgetConstants.newNoteURL))
        XCTAssertTrue(MacWidgetBridge.accepts(WidgetConstants.voiceNoteURL))
        for raw in ["https://note?id=abc&homeWidget=true", "onlynote://note?homeWidget=true", "onlynote://note?id=&homeWidget=true", "onlynote://unknown?homeWidget=true", "onlynote://open"] {
            XCTAssertFalse(MacWidgetBridge.accepts(URL(string: raw)!))
        }
    }

    func testSignedAppGroupContainerIsWritable() throws {
        let store = try MacWidgetStore()
        XCTAssertEqual(MacWidgetStore.appGroupId, WidgetConstants.appGroupId)
        let probe = store.directory.appendingPathComponent("widget-probe-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: probe) }
        try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
        try Data("paper".utf8).write(to: probe, options: .atomic)
        XCTAssertEqual(try String(contentsOf: probe, encoding: .utf8), "paper")
    }

    @MainActor
    func testPaperWidgetRendering() throws {
        guard #available(macOS 14.0, *) else { throw XCTSkip("Desktop widgets require macOS 14") }
        let note = WidgetNote(id: "writing", title: "A little room to think", body: "Leave space for the good ideas.\n\nA walk, a coffee, and a fresh page.\nBring the notebook along.", colorValue: 0xFFF7D9A0, isPinned: true)
        let checklist = WidgetNote(id: "weekend", title: "Weekend plans", colorValue: 0xFFB8E0D2, todoTotal: 3, todoDone: 1, todos: [
            WidgetTodo(id: "one", title: "Pick up fresh flowers", completed: true),
            WidgetTodo(id: "two", title: "Walk by the waterfront", completed: false),
            WidgetTodo(id: "three", title: "Make something delicious", completed: false),
        ])
        let chinese = WidgetNote(id: "chinese", title: "留一點時間給自己", body: "把今天的小靈感記下來。\n\n喝一杯咖啡，散散步，慢慢寫。", colorValue: 0xFFA7C6E0)
        let payload = WidgetPayload(total: 5, notes: [note, checklist, chinese])
        let entry = NotesEntry(date: Date(), payload: payload)
        let root = try scratchDirectory()
        let fixtures: [(String, NotesEntry, PaperWidgetSnapshotKind, WidgetFamily, CGSize, ColorScheme, WidgetRenderingMode, Locale)] = [
            ("note-small", entry, .note, .systemSmall, CGSize(width: 164, height: 164), .light, .fullColor, Locale(identifier: "en")),
            ("note-medium", entry, .note, .systemMedium, CGSize(width: 344, height: 164), .light, .fullColor, Locale(identifier: "en")),
            ("checklist-large", NotesEntry(date: Date(), payload: payload, selectedNoteId: "weekend"), .note, .systemLarge, CGSize(width: 344, height: 344), .light, .fullColor, Locale(identifier: "en")),
            ("overview-medium", entry, .overview, .systemMedium, CGSize(width: 344, height: 164), .light, .fullColor, Locale(identifier: "en")),
            ("overview-small", entry, .overview, .systemSmall, CGSize(width: 164, height: 164), .light, .fullColor, Locale(identifier: "en")),
            ("overview-dark", entry, .overview, .systemLarge, CGSize(width: 344, height: 344), .dark, .fullColor, Locale(identifier: "en")),
            ("note-tinted", entry, .note, .systemSmall, CGSize(width: 164, height: 164), .light, .accented, Locale(identifier: "en")),
            ("note-empty", NotesEntry(date: Date(), payload: .empty), .note, .systemSmall, CGSize(width: 164, height: 164), .light, .fullColor, Locale(identifier: "en")),
            ("note-unavailable", NotesEntry(date: Date(), payload: payload, selectedNoteId: "removed"), .note, .systemSmall, CGSize(width: 164, height: 164), .light, .fullColor, Locale(identifier: "en")),
            ("note-chinese", NotesEntry(date: Date(), payload: payload, selectedNoteId: "chinese"), .note, .systemMedium, CGSize(width: 344, height: 164), .light, .fullColor, Locale(identifier: "zh-Hant")),
        ]
        for (name, fixture, kind, family, size, scheme, mode, locale) in fixtures {
            let data = try XCTUnwrap(WidgetSnapshotRenderer.png(entry: fixture, kind: kind, family: family, size: size, colorScheme: scheme, renderingMode: mode, locale: locale))
            let bitmap = try XCTUnwrap(NSBitmapImageRep(data: data))
            XCTAssertEqual(bitmap.pixelsWide, Int(size.width * 2))
            XCTAssertEqual(bitmap.pixelsHigh, Int(size.height * 2))
            XCTAssertGreaterThan(data.count, 3000)
            try data.write(to: root.appendingPathComponent("\(name).png"))
        }
        print("ONLYNOTE_WIDGET_PREVIEWS=\(root.path)")
    }
}
