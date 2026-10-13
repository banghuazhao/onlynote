import SwiftUI
import WidgetKit

/// The entire paper treatment is removable by WidgetKit. Desktop monochrome
/// and accented appearances retain real text, without a second opaque panel.
@available(macOS 14.0, *)
struct PaperWidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        if renderingMode == .fullColor {
            ZStack {
                colorScheme == .dark ? PaperWidgetTheme.darkPaper : PaperWidgetTheme.lightPaper
                Canvas { context, size in
                    var rules = Path()
                    var y: CGFloat = 39
                    while y < size.height {
                        rules.move(to: CGPoint(x: 0, y: y))
                        rules.addLine(to: CGPoint(x: size.width, y: y))
                        y += PaperWidgetTheme.lineSpacing
                    }
                    context.stroke(rules,
                        with: .color(PaperWidgetTheme.rule.opacity(colorScheme == .dark ? 0.14 : 0.15)),
                        lineWidth: 0.5)
                    var margin = Path()
                    margin.move(to: CGPoint(x: 17, y: 0))
                    margin.addLine(to: CGPoint(x: 17, y: size.height))
                    context.stroke(margin,
                        with: .color(PaperWidgetTheme.margin.opacity(colorScheme == .dark ? 0.48 : 0.38)),
                        lineWidth: 0.8)
                }
                LinearGradient(colors: [.white.opacity(0.12), .clear, .black.opacity(0.035)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            .accessibilityHidden(true)
        }
    }
}
