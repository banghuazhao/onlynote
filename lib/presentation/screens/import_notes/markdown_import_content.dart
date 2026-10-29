import 'package:flutter/material.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/markdown_import.dart';

/// Pure preview content; file picking and note persistence belong to the route.
class MarkdownImportContent extends StatelessWidget {
  const MarkdownImportContent(
      {super.key,
      required this.batch,
      required this.selected,
      required this.onSelected,
      required this.onToggleAll,
      this.busy = false,
      this.failed = false});
  final MarkdownImportBatch batch;
  final Set<int> selected;
  final void Function(int, bool) onSelected;
  final VoidCallback onToggleAll;
  final bool busy;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    final warnings = {
      for (final document in batch.documents) ...document.warnings
    };
    return ListView.builder(
      key: const ValueKey('markdown-import-preview'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: batch.documents.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(strings.Markdown_Import_Description,
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                if (failed)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                          liveRegion: true,
                          child: Text(strings.Markdown_Import_Save_Failed,
                              style:
                                  TextStyle(color: theme.colorScheme.error)))),
                if (batch.skippedEmpty > 0)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(strings.Markdown_Import_Skipped)),
                if (warnings
                    .contains(MarkdownImportWarning.plainTextFormatting))
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(strings.Markdown_Import_Unsupported)),
                if (warnings.contains(MarkdownImportWarning.missingImages))
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(strings.Markdown_Import_Missing_Images)),
                if (batch.documents.isEmpty)
                  Text(strings.Markdown_Import_Empty),
                if (batch.documents.isNotEmpty)
                  Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        Semantics(
                            liveRegion: true,
                            child: Text(
                                '${strings.Markdown_Import_Review} · ${selected.length}/${batch.documents.length}',
                                key: const ValueKey(
                                    'markdown-import-selection-count'),
                                style: theme.textTheme.titleMedium)),
                        TextButton(
                            onPressed: busy ? null : onToggleAll,
                            child: Text(
                                selected.length == batch.documents.length
                                    ? strings.Markdown_Import_Deselect_All
                                    : strings.Markdown_Import_Select_All)),
                      ]),
                const SizedBox(height: 12),
              ]);
        }
        final documentIndex = index - 1;
        final document = batch.documents[documentIndex];
        final note = document.note;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CheckboxListTile(
                      key: ValueKey('markdown-import-note-$documentIndex'),
                      value: selected.contains(documentIndex),
                      onChanged: busy
                          ? null
                          : (value) => onSelected(documentIndex, value == true),
                      title: Text(
                          note.title?.trim().isNotEmpty == true
                              ? note.title!
                              : strings.Note_Untitled,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(document.sourceName,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (note.description?.isNotEmpty == true)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.textScalerOf(context)
                                              .scale(140)),
                                  child: SingleChildScrollView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    child: NoteDocumentView(
                                      text: note.description!.characters
                                          .take(350)
                                          .toString(),
                                      styles: note.textStyles,
                                      imagePaths: const [],
                                      imageLayouts: const [],
                                      selectable: false,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              if (note.todo.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                for (final todo in note.todo.take(3))
                                  Text(
                                      '${todo.completed ? '[x]' : '[ ]'} ${todo.title ?? ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                              ],
                              if (document.images.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(strings.History_Photos(
                                    document.images.length)),
                                const SizedBox(height: 8),
                                SizedBox(
                                    height: 120,
                                    child: Image.memory(
                                        document.images.first.bytes,
                                        fit: BoxFit.contain,
                                        cacheHeight: (120 *
                                                MediaQuery.devicePixelRatioOf(
                                                    context))
                                            .round()
                                            .clamp(1, 4096),
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                                child: Icon(Icons
                                                    .broken_image_outlined)))),
                              ],
                            ])),
                  ])),
        );
      },
    );
  }
}
