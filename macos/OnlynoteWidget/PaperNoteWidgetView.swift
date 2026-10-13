import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperNoteWidgetView: View {
    let entry: NotesEntry

    var body: some View {
        PaperNoteWidgetContent(entry: entry)
            .containerBackground(for: .widget) { PaperWidgetBackground() }
    }
}
