import 'dart:math' as math;

import 'package:onlynote/presentation/theme/button_styles.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_image.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/note_card_typography.dart';
import 'package:onlynote/services/note_dates.dart';
import 'package:screenshot/screenshot.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.cardStyle,
    this.selected = false,
    this.searchQuery = '',
    this.photoSearchText,
    this.photoSearchImagePath,
    this.selectionMode = false,
    this.unfinishedOnly = false,
    this.onTodoToggle,
    this.onLongPress,
    this.onTap,
    this.thumbnailBuilder,
    this.screenshotController,
  });

  final Note note;

  /// A staged style for the live preview; saved cards use note.cardStyle.
  final NoteCardStyle? cardStyle;
  final String searchQuery;

  /// Derived text that explains a photo search result without changing the note.
  final String? photoSearchText;

  /// The photo responsible for the match; the stored image order is preserved.
  final String? photoSearchImagePath;
  final bool selected;
  final bool selectionMode;
  final bool unfinishedOnly;
  final ValueChanged<String>? onTodoToggle;
  final Function()? onLongPress;
  final Function()? onTap;

  /// Lets previews render thumbnails without loading files.
  final Widget Function(BuildContext context, String path)? thumbnailBuilder;

  /// Lets a parent capture the same rendered content for its own actions
  /// (e.g. a long-press context menu's "Share" item). Falls back to an
  /// internally-owned controller when not provided.
  final ScreenshotController? screenshotController;

  @override
  NoteCardState createState() => NoteCardState();
}

class NoteCardState extends State<NoteCard> {
  late final ScreenshotController _screenshotController =
      widget.screenshotController ?? ScreenshotController();
  bool _pressed = false;
  bool _exportingImage = false;

  /// Captures the visible card without tap feedback, preserving its layout.
  Future<Uint8List?> captureImage() async {
    if (!mounted || _exportingImage) return null;
    setState(() {
      _exportingImage = true;
      _pressed = false;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return null;
      return await _screenshotController.capture(pixelRatio: 3);
    } finally {
      if (mounted) setState(() => _exportingImage = false);
    }
  }

  void _setPressed(bool value) {
    if (_exportingImage) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  Iterable<Todo> _visibleTodos(Note note, NoteCardSize cardSize) {
    final todos = note.todo.where((todo) =>
        todo.title?.trim().isNotEmpty == true &&
        (!widget.unfinishedOnly || !todo.completed));
    final pattern = searchPattern(widget.searchQuery);
    return [
      if (pattern != null)
        ...todos.where((todo) => pattern.hasMatch(todo.title!)),
      ...todos.where((todo) =>
          !todo.completed && !(pattern?.hasMatch(todo.title!) ?? false)),
      ...todos.where((todo) =>
          todo.completed && !(pattern?.hasMatch(todo.title!) ?? false)),
    ].take(switch (cardSize) {
      NoteCardSize.small => 2,
      NoteCardSize.medium => 3,
      NoteCardSize.large => 5,
    });
  }

  @override
  Widget build(BuildContext context) {
    final Reminder? currentReminder =
        ReminderData.shared.getCurrentReminder(widget.note);
    final Note note = widget.note;
    final style = resolveNoteCardStyle(widget.cardStyle ?? note.cardStyle);
    final typography = NoteCardTypography(style);
    final cardSize = style.cardSize!;
    final strings = S.of(context);
    final title = note.title?.trim() ?? '';
    final body = note.description?.trim() ?? '';
    final hasTitle = title.isNotEmpty;
    final todos = note.todo
        .where((todo) => todo.title?.trim().isNotEmpty == true)
        .toList();
    final scanPaths = note.imageLayouts
        .where((layout) =>
            layout.isDocumentPage && note.imagePaths.contains(layout.path))
        .map((layout) => layout.path)
        .toSet();
    final photoCount = note.imagePaths.length - scanPaths.length;
    final imageLabel = [
      if (photoCount > 0) strings.History_Photos(photoCount),
      if (scanPaths.isNotEmpty)
        strings.Card_Scanned_Pages_Count(scanPaths.length),
    ].join(', ');
    final linkedCount = note.linkedNoteIds
        .where((id) => id.trim().isNotEmpty && id != note.id)
        .toSet()
        .length;
    final date = noteCardDateLabel(
      locale: Localizations.localeOf(context).toString(),
      showDate: style.showDate != false,
      movedToTrashLabel: strings.Card_Moved_To_Trash_On,
      dateTime: note.dateTime,
      deletedAt: note.deletedAt,
    );
    final transcripts = note.voiceMemos
        .map((memo) => memo.transcript?.trim() ?? '')
        .where((text) => text.isNotEmpty)
        .toList();
    final pattern = searchPattern(widget.searchQuery);
    final rawPhotoSearchText = widget.photoSearchText?.trim();
    final compactPhotoSearchText =
        rawPhotoSearchText?.replaceAll(RegExp(r'\s+'), ' ');
    final photoSearchText =
        pattern?.hasMatch(compactPhotoSearchText ?? '') == true
            ? compactPhotoSearchText
            : rawPhotoSearchText;
    final hasPhotoMatch = !_exportingImage &&
        pattern != null &&
        photoSearchText != null &&
        pattern.hasMatch(photoSearchText);
    final transcriptMatch = pattern == null
        ? null
        : transcripts.where(pattern.hasMatch).firstOrNull;
    final excerpt =
        transcriptMatch ?? (body.isNotEmpty ? body : transcripts.join('\n'));
    final fromTranscript =
        transcriptMatch != null || (body.isEmpty && transcripts.isNotEmpty);
    final hasDescription = excerpt.isNotEmpty;
    final displayTags = [
      if (pattern != null) ...note.tags.where(pattern.hasMatch),
      ...note.tags.where((tag) => !(pattern?.hasMatch(tag) ?? false)),
    ].take(2);
    // Always a light paper: everything drawn on it is ink-coloured.
    final paperColor = note.color ?? AppColors.parchment;
    final seed = note.id?.hashCode ?? note.date.hashCode;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      container: true,
      button: widget.onTap != null,
      selected: widget.selectionMode ? widget.selected : null,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: reduceMotion || _exportingImage
            ? Duration.zero
            : const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTapDown: _exportingImage ? null : (_) => _setPressed(true),
          onTapUp: _exportingImage ? null : (_) => _setPressed(false),
          onTapCancel: _exportingImage ? null : () => _setPressed(false),
          onLongPress: _exportingImage || widget.onLongPress == null
              ? null
              : () {
                  if (_exportingImage) return;
                  HapticFeedback.mediumImpact();
                  widget.onLongPress!();
                },
          onTap: _exportingImage || widget.onTap == null
              ? null
              : () {
                  if (_exportingImage) return;
                  _setPressed(false);
                  widget.onTap!();
                },
          child: Stack(
            children: [
              Screenshot(
                controller: _screenshotController,
                child: PaperNote(
                  color: paperColor,
                  seed: seed,
                  plainPaper: style.paperStyle == NoteCardPaperStyle.plain,
                  pinned: note.isPinned,
                  selected: widget.selected,
                  pressed: _pressed,
                  exportMode: _exportingImage,
                  padding: EdgeInsets.fromLTRB(
                      14, 14, 14, widget.selectionMode ? 56 : 14),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 88),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasTitle)
                          SearchHighlight(
                            searchExcerpt(title, widget.searchQuery),
                            query: widget.searchQuery,
                            style: typography.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: cardSize == NoteCardSize.small
                                ? 2
                                : cardSize == NoteCardSize.large
                                    ? 5
                                    : hasDescription
                                        ? 3
                                        : 5,
                          ),
                        if (hasTitle && hasDescription)
                          const SizedBox(height: AppSpacings.m),
                        if (hasDescription && fromTranscript)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacings.s),
                            child: Text(
                              strings.Voice_Memo,
                              key: const ValueKey('card-transcript-source'),
                              style: typography.description.copyWith(
                                  color: AppColors.ink.withValues(alpha: .65)),
                            ),
                          ),
                        if (hasDescription)
                          SearchHighlight(
                            searchExcerpt(excerpt, widget.searchQuery),
                            query: widget.searchQuery,
                            style:
                                hasTitle ? typography.body : typography.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: cardSize == NoteCardSize.small
                                ? 2
                                : cardSize == NoteCardSize.large
                                    ? 8
                                    : hasTitle
                                        ? 4
                                        : 6,
                          ),
                        if (hasPhotoMatch) ...[
                          if (hasTitle || hasDescription)
                            const SizedBox(height: AppSpacings.m),
                          Column(
                            key: const ValueKey('photo-search-match'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.image_search_rounded,
                                      size: 14,
                                      color: AppColors.ink
                                          .withValues(alpha: 0.65)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      S.of(context).Photo_Search_Text_In_Photo,
                                      style: typography.description.copyWith(
                                        color: AppColors.ink
                                            .withValues(alpha: 0.65),
                                        fontSize: 12 * typography.scale,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacings.s),
                              SearchHighlight(
                                _photoSearchExcerpt(
                                    photoSearchText, widget.searchQuery),
                                key: const ValueKey('photo-search-excerpt'),
                                query: widget.searchQuery,
                                style: typography.body,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ],
                        if (todos.isNotEmpty) ...[
                          const SizedBox(height: AppSpacings.l),
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacings.s),
                            child: Text(
                              strings.Checklist_Progress(
                                  todos.where((todo) => todo.completed).length,
                                  todos.length),
                              key: const ValueKey('card-checklist-progress'),
                              style: typography.description.copyWith(
                                color: AppColors.ink.withValues(alpha: .65),
                                fontSize: 12 * typography.scale,
                              ),
                            ),
                          ),
                          for (final todo in _visibleTodos(note, cardSize))
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacings.s),
                              child: PaperChecklistRow(
                                key: ValueKey('card-todo-${todo.id}'),
                                exportMode: _exportingImage,
                                onChanged: widget.selectionMode ||
                                        note.isDeleted ||
                                        widget.onTodoToggle == null ||
                                        todo.id == null
                                    ? null
                                    : (_) {
                                        if (_exportingImage) return;
                                        HapticFeedback.selectionClick();
                                        widget.onTodoToggle!(todo.id!);
                                      },
                                label: searchExcerpt(
                                    todo.title ?? '', widget.searchQuery),
                                searchQuery: widget.searchQuery,
                                completed: todo.completed,
                                dense: true,
                                textStyle: typography.body,
                                maxLines: 2,
                              ),
                            ),
                        ],
                        if (note.hasImages) ...[
                          const SizedBox(height: AppSpacings.m),
                          _PolaroidThumb(
                            path: hasPhotoMatch &&
                                    note.imagePaths
                                        .contains(widget.photoSearchImagePath)
                                ? widget.photoSearchImagePath!
                                : note.imagePaths.first,
                            extraCount: note.imagePaths.length - 1,
                            semanticLabel: imageLabel,
                            documentPages: scanPaths,
                            builder: widget.thumbnailBuilder,
                          ),
                        ],
                        if (date != null ||
                            note.isArchived ||
                            currentReminder != null) ...[
                          const SizedBox(height: AppSpacings.l),
                          if (date != null)
                            Text(
                              date,
                              key: const ValueKey('card-date'),
                              style: typography.description.copyWith(
                                color: AppColors.ink.withValues(alpha: .6),
                                fontSize: 12 * typography.scale,
                              ),
                            ),
                          if (note.isArchived)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacings.s),
                              child: Text(strings.Archive,
                                  style: typography.description.copyWith(
                                      color: AppColors.ink
                                          .withValues(alpha: .65))),
                            ),
                          if (currentReminder != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacings.s),
                              child: Row(children: [
                                Icon(Icons.alarm_rounded,
                                    size: 14,
                                    color:
                                        AppColors.ink.withValues(alpha: .65)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(currentReminder.timeString,
                                      style: typography.description.copyWith(
                                        color: AppColors.ink
                                            .withValues(alpha: .65),
                                      )),
                                ),
                              ]),
                            ),
                        ],
                        if (note.hasVoiceMemos) ...[
                          const SizedBox(height: AppSpacings.m),
                          Row(children: [
                            const Icon(Icons.mic_none_rounded,
                                size: 16, color: AppColors.ink),
                            const SizedBox(width: 6),
                            Flexible(
                                child: Text(
                                    S.of(context).History_Recordings(
                                        note.voiceMemos.length),
                                    style: typography.description.copyWith(
                                        color: AppColors.ink
                                            .withValues(alpha: 0.7)))),
                          ]),
                        ],
                        if (scanPaths.isNotEmpty) ...[
                          const SizedBox(height: AppSpacings.m),
                          Text(
                              strings.Card_Scanned_Pages_Count(
                                  scanPaths.length),
                              key: const ValueKey('card-scan-count'),
                              style: typography.description.copyWith(
                                  color: AppColors.ink.withValues(alpha: .7))),
                        ],
                        if (linkedCount > 0) ...[
                          const SizedBox(height: AppSpacings.m),
                          Text(strings.Card_Linked_Notes_Count(linkedCount),
                              key: const ValueKey('card-linked-count'),
                              style: typography.description.copyWith(
                                  color: AppColors.ink.withValues(alpha: .7))),
                        ],
                        if (note.tags.isNotEmpty) ...[
                          const SizedBox(height: AppSpacings.m),
                          Semantics(
                            label:
                                '${S.of(context).Tags}: ${note.tags.join(', ')}',
                            excludeSemantics: true,
                            child: SearchHighlight(
                              '${displayTags.map((tag) => '#$tag').join('  ')}'
                              '${note.tags.length > 2 ? '  +${note.tags.length - 2}' : ''}',
                              query: widget.searchQuery,
                              style: typography.description.copyWith(
                                  color: AppColors.ink.withValues(alpha: 0.65)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.selectionMode)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Tooltip(
                    message: S.of(context).Select,
                    child: IconButton(
                      style: AppButtonStyles.paper(selected: widget.selected),
                      onPressed: _exportingImage ? null : widget.onTap,
                      icon: ExcludeSemantics(
                        child: AnimatedSwitcher(
                          duration: reduceMotion || _exportingImage
                              ? Duration.zero
                              : const Duration(milliseconds: 160),
                          child: Icon(
                            widget.selected
                                ? Icons.check_rounded
                                : Icons.check_circle_outline_rounded,
                            key: ValueKey(
                                widget.selected ? 'selected' : 'unselected'),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keep the match near the start so a narrow card's three lines reveal it.
String _photoSearchExcerpt(String text, String query) {
  return searchExcerpt(text, query, leadingContext: 0);
}

class _PolaroidThumb extends StatelessWidget {
  const _PolaroidThumb({
    required this.path,
    required this.extraCount,
    required this.semanticLabel,
    required this.documentPages,
    this.builder,
  });

  final String path;
  final int extraCount;
  final String semanticLabel;
  final Set<String> documentPages;
  final Widget Function(BuildContext context, String path)? builder;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = math.min(64.0, math.max(0.0, constraints.maxWidth - 8));
        final isDocument = documentPages.contains(path);
        final height = width * (isDocument ? 1.3 : 52 / 64);
        return Semantics(
          container: true,
          image: true,
          label: semanticLabel,
          excludeSemantics: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0.5, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
              child: Stack(
                children: [
                  SizedBox(
                    width: width,
                    height: height,
                    child: builder?.call(context, path) ??
                        NoteImage(
                          path: path,
                          width: width,
                          height: height,
                          fit: isDocument ? BoxFit.contain : BoxFit.cover,
                        ),
                  ),
                  if (extraCount > 0)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          child: Text(
                            '+$extraCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      });
}
