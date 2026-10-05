import WidgetKit
import SwiftUI
import AppIntents

/// WidgetConfiguration has no availability result builder. Select the bundle
/// at launch so both OS versions register one widget with the existing kind.
@main
struct OnlynoteWidgetBundle {
    @MainActor
    static func main() {
        if #available(iOSApplicationExtension 17.0, *) {
            ConfigurableNotesBundle.main()
        } else {
            LegacyNotesBundle.main()
        }
    }
}

@available(iOS 17.0, *)
private struct ConfigurableNotesBundle: WidgetBundle {
    var body: some Widget { NotesWidget() }
}

private struct LegacyNotesBundle: WidgetBundle {
    var body: some Widget { LegacyNotesWidget() }
}

@available(iOS 17.0, *)
struct NotesWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetConstants.kind, intent: NoteWidgetConfiguration.self,
                               provider: ConfigurableNotesProvider()) { entry in
            NotesWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.display_name")
        .description("widget.description")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct LegacyNotesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetConstants.kind, provider: NotesProvider()) { entry in
            NotesWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.display_name")
        .description("widget.description")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
