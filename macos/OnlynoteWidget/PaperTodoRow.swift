import AppIntents
import SwiftUI
import WidgetKit

@available(macOS 14.0, *)
struct PaperTodoRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode
    let note: WidgetNote
    let todo: WidgetTodo

    var body: some View {
        if let todoID = todo.id, !todoID.isEmpty {
            Button(intent: CompleteWidgetTodoIntent(
                noteId: note.id, todoId: todoID, completed: !todo.completed)) {
                label
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.title)
            .accessibilityValue(Text(LocalizedStringKey(todo.completed ? "widget.completed" : "widget.not_completed")))
            .accessibilityHint(Text(LocalizedStringKey(todo.completed ? "widget.mark_unfinished" : "widget.complete_item")))
        } else {
            Link(destination: WidgetConstants.noteURL(id: note.id)) { label }
                .buttonStyle(.plain)
        }
    }

    private var label: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: todo.completed ? "checkmark.square.fill" : "square")
                .foregroundStyle(todo.completed
                    ? (renderingMode == .fullColor ? PaperWidgetTheme.accent : .primary)
                    : PaperWidgetTheme.secondaryInk(colorScheme, mode: renderingMode))
                .widgetAccentable(todo.completed)
                .accessibilityHidden(true)
            Text(todo.title)
                .strikethrough(todo.completed)
                .foregroundStyle(todo.completed
                    ? PaperWidgetTheme.secondaryInk(colorScheme, mode: renderingMode)
                    : PaperWidgetTheme.ink(colorScheme, mode: renderingMode))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, minHeight: 23, alignment: .leading)
        .contentShape(Rectangle())
    }
}
