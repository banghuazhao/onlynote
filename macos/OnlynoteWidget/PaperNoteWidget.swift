import AppIntents
import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperNoteWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: WidgetConstants.kind,
            intent: NoteWidgetConfiguration.self,
            provider: ConfigurableNotesProvider()
        ) { entry in
            PaperNoteWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.mac.note_name")
        .description("widget.mac.note_description")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
