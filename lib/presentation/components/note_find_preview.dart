import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'note_document_view.dart';
import 'note_image_block.dart';
import 'note_search_text.dart';

/// A read-only view of the current editor draft while its find bar owns the
/// keyboard. It needs no recording service or native player.
class NoteFindPreview extends StatelessWidget {
  const NoteFindPreview({
    super.key,
    required this.note,
    required this.controller,
    this.imageBuilder,
  });
  final Note note;
  final NoteSearchController controller;
  final NoteBlockImageBuilder? imageBuilder;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.title?.isNotEmpty == true) ...[
            NoteSearchText(
              controller: controller,
              fieldId: 'title',
              text: note.title!,
              style: AppTypography.headline3,
            ),
            const SizedBox(height: 24),
          ],
          for (final completed in [false, true])
            for (final (index, todo) in note.todo.indexed)
              if (todo.completed == completed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                            todo.completed
                                ? Icons.check_box_outlined
                                : Icons.check_box_outline_blank,
                            color: AppTypography.formText.color,
                            size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                            child: NoteSearchText(
                          controller: controller,
                          fieldId: 'todo:${todo.id ?? index}',
                          text: todo.title ?? '',
                          style: AppTypography.formText.copyWith(
                            decoration: todo.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        )),
                      ]),
                ),
          if (note.todo.isNotEmpty) const SizedBox(height: 24),
          NoteDocumentView(
            text: note.description ?? '',
            styles: note.textStyles,
            imagePaths: note.imagePaths,
            imageLayouts: note.imageLayouts,
            imageBuilder: imageBuilder,
            textBuilder: (text, styles, start, _) => NoteSearchText(
              controller: controller,
              fieldId: 'body',
              text: text,
              textOffset: start,
              styles: styles,
              style: AppTypography.formText,
            ),
          ),
          for (final memo in note.voiceMemos)
            if (memo.transcript?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 24),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.mic_none_rounded,
                    color: AppTypography.formText.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                    child: NoteSearchText(
                  controller: controller,
                  fieldId: 'voice:${memo.id}',
                  text: memo.transcript!,
                  style: AppTypography.formText,
                )),
              ]),
            ],
        ],
      );
}
