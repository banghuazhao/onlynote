import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperWidgetPreviews: PreviewProvider {
    private static let sample = NotesEntry(date: Date(), payload: .sample)
    private static var checklist: NotesEntry {
        NotesEntry(date: Date(), payload: .sample,
            selectedNoteId: WidgetPayload.sample.notes.first { $0.hasChecklist }?.id)
    }

    static var previews: some View {
        Group {
            PaperWidgetSnapshotView(entry: sample, kind: .note, family: .systemSmall)
                .frame(width: 164, height: 164)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Paper note · small")
            PaperWidgetSnapshotView(entry: checklist, kind: .note, family: .systemMedium)
                .frame(width: 344, height: 164)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Checklist · medium")
            PaperWidgetSnapshotView(entry: checklist, kind: .note, family: .systemLarge)
                .environment(\.colorScheme, .dark)
                .frame(width: 344, height: 344)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Checklist · dark large")
            PaperWidgetSnapshotView(entry: sample, kind: .overview, family: .systemMedium)
                .frame(width: 344, height: 164)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Paper library · medium")
            PaperWidgetSnapshotView(entry: sample, kind: .overview, family: .systemLarge)
                .environment(\.widgetRenderingMode, .vibrant)
                .frame(width: 344, height: 344)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Library · desktop monochrome")
            PaperWidgetSnapshotView(entry: NotesEntry(date: Date(), payload: .empty), kind: .note, family: .systemSmall)
                .frame(width: 164, height: 164)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Real empty state")
            PaperNoteWidgetView(entry: checklist)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Native WidgetKit container")
        }
    }
}
