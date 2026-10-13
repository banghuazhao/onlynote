import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperWidgetSnapshotView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: NotesEntry
    let kind: PaperWidgetSnapshotKind
    let family: WidgetFamily

    var body: some View {
        ZStack {
            // The desktop supplies its own surface in monochrome/tinted modes.
            // A neutral material here lets exported snapshots exercise contrast.
            if renderingMode != .fullColor {
                Color.gray.opacity(0.12)
            }
            PaperWidgetBackground()
            switch kind {
            case .note: PaperNoteWidgetContent(entry: entry, family: family)
            case .overview: PaperOverviewWidgetContent(entry: entry, family: family)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
