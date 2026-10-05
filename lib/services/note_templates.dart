import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:uuid/uuid.dart';

/// Choosing a template creates an ordinary, fully editable note.
enum NoteTemplate {
  shopping,
  packing,
  dailyPlan,
  meeting;

  NoteTemplateContent content(S strings) => switch (this) {
        shopping => NoteTemplateContent(
            title: strings.Template_Shopping_Title,
            summary: strings.Template_Shopping_Summary,
            items: _items(strings.Template_Shopping_Items),
          ),
        packing => NoteTemplateContent(
            title: strings.Template_Packing_Title,
            summary: strings.Template_Packing_Summary,
            items: _items(strings.Template_Packing_Items),
          ),
        dailyPlan => NoteTemplateContent(
            title: strings.Template_Daily_Plan_Title,
            summary: strings.Template_Daily_Plan_Summary,
            body: strings.Template_Daily_Plan_Body,
            items: _items(strings.Template_Daily_Plan_Items),
          ),
        meeting => NoteTemplateContent(
            title: strings.Template_Meeting_Title,
            summary: strings.Template_Meeting_Summary,
            body: strings.Template_Meeting_Body,
            items: _items(strings.Template_Meeting_Items),
          ),
      };

  /// No storage is touched; the editor uses its usual save and draft flow.
  Note createNote(S strings, {String? folderId, DateTime? now}) {
    final copy = content(strings);
    final createdAt = now ?? DateTime.now();
    const uuid = Uuid();
    return Note(
      id: uuid.v4(),
      title: copy.title,
      description: copy.body,
      todo: [
        for (final item in copy.items)
          Todo(id: uuid.v4(), title: item, completed: false),
      ],
      color: colors[switch (this) {
        shopping => 8,
        packing => 7,
        dailyPlan => 0,
        meeting => 10,
      }],
      dateTime: createdAt,
      sortOrder: -createdAt.millisecondsSinceEpoch,
      folderId: folderId,
    );
  }

  static List<String> _items(String copy) => List.unmodifiable(
        copy
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
}

class NoteTemplateContent {
  const NoteTemplateContent({
    required this.title,
    required this.summary,
    required this.items,
    this.body = '',
  });

  final String title;
  final String summary;
  final String body;
  final List<String> items;
}
