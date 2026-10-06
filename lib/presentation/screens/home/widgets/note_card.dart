import 'package:onlynote/presentation/theme/button_styles.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_image.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:screenshot/screenshot.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.selected = false,
    this.searchQuery = '',
    this.photoSearchText,
    this.photoSearchImagePath,
    this.selectionMode = false,
    this.unfinishedOnly = false,
    this.onTodoToggle,
    this.onLongPress,
    this.onTap,
    this.screenshotController,
  });

  final Note note;
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
  final GlobalKey _shareButtonKey = GlobalKey();
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

  Future<void> _shareNoteAsImage() => ShareHelper.shareNote(
        context,
        widget.note,
        _screenshotController,
        sharePositionOrigin: ShareHelper.shareOriginFromKey(_shareButtonKey),
        captureImage: captureImage,
      );

  Iterable<Todo> _visibleTodos(Note note) {
    final todos = widget.unfinishedOnly
        ? note.todo.where(
            (todo) => !todo.completed && todo.title?.trim().isNotEmpty == true)
        : note.todo;
    final pattern = searchPattern(widget.searchQuery);
    if (pattern == null) return todos.take(3);
    return [
      ...todos.where((t) => pattern.hasMatch(t.title ?? '')),
      ...todos.where((t) => !pattern.hasMatch(t.title ?? '')),
    ].take(3);
  }

  @override
  Widget build(BuildContext context) {
    final Reminder? currentReminder =
        ReminderData.shared.getCurrentReminder(widget.note);
    final Note note = widget.note;
    final hasTitle = note.title?.isNotEmpty == true;
    final transcripts = note.voiceMemos
        .map((memo) => memo.transcript ?? '')
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
    final excerpt = transcriptMatch ??
        (note.description?.isNotEmpty == true
            ? note.description!
            : transcripts.join('\n'));
    final hasDescription = excerpt.isNotEmpty;
    // Always a light paper: everything drawn on it is ink-coloured.
    final paperColor = note.color ?? AppColors.parchment;
    final seed = note.id?.hashCode ?? note.date.hashCode;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      selected: widget.selected,
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
                  pinned: note.isPinned,
                  selected: widget.selected,
                  pressed: _pressed,
                  exportMode: _exportingImage,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 56),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 88),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasTitle)
                          SearchHighlight(
                            searchExcerpt(note.title!, widget.searchQuery),
                            query: widget.searchQuery,
                            style: AppTypography.cardTitle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: hasDescription ? 3 : 5,
                          ),
                        if (hasTitle && hasDescription)
                          const SizedBox(height: AppSpacings.m),
                        if (hasDescription)
                          SearchHighlight(
                            searchExcerpt(excerpt, widget.searchQuery),
                            query: widget.searchQuery,
                            style: hasTitle
                                ? AppTypography.cardBody
                                : AppTypography.cardTitle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: hasTitle ? 4 : 6,
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
                                      style: AppTypography.description.copyWith(
                                        color: AppColors.ink
                                            .withValues(alpha: 0.65),
                                        fontSize: 12 *
                                            AppTypographySettings
                                                .instance.scale,
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
                                style: AppTypography.cardBody,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacings.l),
                        if (note.isArchived) ...[
                          Text.rich(
                            TextSpan(children: [
                              const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(Icons.archive_outlined,
                                      size: 14, color: AppColors.ink)),
                              TextSpan(text: ' ${S.of(context).Archive}'),
                            ]),
                            style: AppTypography.description.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.65)),
                          ),
                          const SizedBox(height: AppSpacings.s),
                        ],
                        Text(
                          note.date,
                          style: AppTypography.description.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.55),
                            fontSize: 12 * AppTypographySettings.instance.scale,
                          ),
                        ),
                        if (currentReminder != null) ...[
                          const SizedBox(height: AppSpacings.m),
                          Row(
                            children: [
                              Icon(
                                Icons.alarm_rounded,
                                size: 14,
                                color: AppColors.ink.withValues(alpha: 0.62),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  currentReminder.timeString,
                                  style: AppTypography.description.copyWith(
                                    color:
                                        AppColors.ink.withValues(alpha: 0.62),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (note.hasTodo) ...[
                          const SizedBox(height: AppSpacings.l),
                          for (final todo in _visibleTodos(note))
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
                                maxLines: 1,
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
                                    style: AppTypography.description.copyWith(
                                        color: AppColors.ink
                                            .withValues(alpha: 0.7)))),
                          ]),
                        ],
                        if (note.tags.isNotEmpty) ...[
                          const SizedBox(height: AppSpacings.m),
                          Semantics(
                            label:
                                '${S.of(context).Tags}: ${note.tags.join(', ')}',
                            excludeSemantics: true,
                            child: SearchHighlight(
                              '${note.tags.take(2).map((tag) => '#$tag').join('  ')}'
                              '${note.tags.length > 2 ? '  +${note.tags.length - 2}' : ''}',
                              query: widget.searchQuery,
                              style: AppTypography.description.copyWith(
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
              Positioned(
                right: 2,
                bottom: 2,
                child: Tooltip(
                  message: widget.selectionMode
                      ? S.of(context).Select
                      : S.of(context).Share,
                  child: IconButton(
                    key: widget.selectionMode ? null : _shareButtonKey,
                    style: AppButtonStyles.paper(selected: widget.selected),
                    onPressed: _exportingImage
                        ? null
                        : widget.selectionMode
                            ? widget.onTap
                            : _shareNoteAsImage,
                    icon: Icon(
                      widget.selectionMode
                          ? widget.selected
                              ? Icons.check_rounded
                              : Icons.check_circle_outline_rounded
                          : Icons.ios_share_rounded,
                      size: 18,
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
  final match = searchPattern(query)?.firstMatch(text);
  if (match == null || match.start == 0) return text;
  return '…${text.substring(match.start)}';
}

class _PolaroidThumb extends StatelessWidget {
  const _PolaroidThumb({required this.path, required this.extraCount});

  final String path;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
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
              NoteImage(path: path, width: 64, height: 52),
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
  }
}
