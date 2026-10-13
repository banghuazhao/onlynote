import SwiftUI
import WidgetKit

@main
struct OnlynoteMacWidgetBundle: WidgetBundle {
    var body: some Widget {
        PaperNoteWidget()
        PaperOverviewWidget()
    }
}
