import 'package:onlynote/domain/model/note.dart';

/// Returns the unfinished titles as saved, excluding empty editor placeholders.
///
/// Trimming only the outer whitespace preserves internal spacing, line breaks,
/// and duplicate titles. Neither the items nor their completion/order changes.
List<String> unfinishedChecklistTitles(Iterable<Todo> todos) =>
    List<String>.unmodifiable([
      for (final todo in todos)
        if (!todo.completed && (todo.title?.trim().isNotEmpty ?? false))
          todo.title!.trim(),
    ]);
