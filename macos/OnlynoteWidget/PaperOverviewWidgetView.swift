import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperOverviewWidgetView: View {
    let entry: NotesEntry

    var body: some View {
        PaperOverviewWidgetContent(entry: entry)
            .containerBackground(for: .widget) { PaperWidgetBackground() }
    }
}
