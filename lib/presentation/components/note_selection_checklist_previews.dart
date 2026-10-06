import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_selection_menu.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_checklist.dart';

@Preview(name: 'Selected lines add checklist items', size: Size(390, 600))
Widget selectionChecklistPreview() => const _ChecklistSelectionPreview();

@Preview(
    name: 'Selected lines add checklist items dark',
    size: Size(390, 600),
    brightness: Brightness.dark)
Widget selectionChecklistDarkPreview() =>
    const _ChecklistSelectionPreview(dark: true);

class _ChecklistSelectionPreview extends StatefulWidget {
  const _ChecklistSelectionPreview({this.dark = false});
  final bool dark;

  @override
  State<_ChecklistSelectionPreview> createState() =>
      _ChecklistSelectionPreviewState();
}

class _ChecklistSelectionPreviewState
    extends State<_ChecklistSelectionPreview> {
  static const _prose =
      'Weekend errands\n• Coffee\n2. Fresh bread\n☐ Pick up flowers';
  Note _note =
      Note(description: _prose, todo: [Todo(id: 'old', title: 'Bring a bag')]);
  List<String> _addedIds = const [];

  void _addSelection(NoteTextSelection selection) {
    final result = appendSelectionToChecklist(_note, selection);
    if (result.note == null) return;
    setState(() {
      _note = result.note!;
      _addedIds = result.addedTodoIds;
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: widget.dark ? AppTheme.dark : AppTheme.light,
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(children: [
              const Text(
                  'Select the errand lines, then choose Add to checklist.'),
              const SizedBox(height: 20),
              SelectableText(
                _prose,
                contextMenuBuilder: (context, state) =>
                    buildNoteSelectionContextMenu(context, state,
                        onAddSelectionToChecklist: _addSelection),
              ),
              const SizedBox(height: 24),
              for (final todo in _note.todo)
                CheckboxListTile(
                  value: todo.completed,
                  title: Text(todo.title ?? ''),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (completed) => setState(() {
                    _note = _note.copyWith(todo: [
                      for (final item in _note.todo)
                        if (item.id == todo.id)
                          item.copyWith(completed: completed ?? false)
                        else
                          item,
                    ]);
                  }),
                ),
              if (_addedIds.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _note = undoSelectionChecklist(_note, _addedIds);
                    _addedIds = const [];
                  }),
                  child: const Text('Undo added items'),
                ),
            ]),
          ),
        ),
      );
}
