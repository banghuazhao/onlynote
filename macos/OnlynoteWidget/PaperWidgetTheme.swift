import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
enum PaperWidgetTheme {
    static let lightPaper = Color(red: 1, green: 0.977, blue: 0.924)
    static let darkPaper = Color(red: 0.142, green: 0.131, blue: 0.108)
    static let lightInk = Color(red: 0.20, green: 0.17, blue: 0.13)
    static let darkInk = Color(red: 0.96, green: 0.91, blue: 0.82)
    static let margin = Color(red: 0.70, green: 0.34, blue: 0.29)
    static let rule = Color(red: 0.40, green: 0.48, blue: 0.50)
    static let accent = Color(red: 0.61, green: 0.39, blue: 0.18)
    static let contentInsets = EdgeInsets(top: 13, leading: 27, bottom: 12, trailing: 14)
    static let lineSpacing: CGFloat = 23

    static func ink(_ colorScheme: ColorScheme, mode: WidgetRenderingMode) -> Color {
        guard mode == .fullColor else { return .primary }
        return colorScheme == .dark ? darkInk : lightInk
    }

    static func secondaryInk(_ colorScheme: ColorScheme, mode: WidgetRenderingMode) -> Color {
        ink(colorScheme, mode: mode).opacity(mode == .fullColor ? 0.78 : 0.85)
    }

    static func noteAccent(_ note: WidgetNote?, mode: WidgetRenderingMode) -> Color {
        guard mode == .fullColor else { return .primary }
        guard let note, note.colorValue != nil else { return accent }
        return note.accentColor
    }
}
