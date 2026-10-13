import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperOverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: MacWidgetConstants.overviewKind, provider: NotesProvider()) { entry in
            PaperOverviewWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.mac.overview_name")
        .description("widget.mac.overview_description")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
