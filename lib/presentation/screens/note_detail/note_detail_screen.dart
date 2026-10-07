import 'dart:async';

import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_find_bar.dart';
import 'package:onlynote/presentation/components/note_search_text.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_outline.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_transfer.dart';
import 'package:onlynote/services/note_selection_checklist.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/note_statistics.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/presentation/components/note_copy_destination_sheet.dart';
import 'package:onlynote/presentation/components/note_outline_navigation_controller.dart';
import 'package:onlynote/presentation/components/note_outline_sheet.dart';
import 'package:onlynote/presentation/components/note_info_sheet.dart';
import 'package:onlynote/presentation/components/note_reader_position_controller.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/Tools/in_app_reviewer_helper.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/components/review_moment.dart';
import 'package:onlynote/presentation/components/note_checklist.dart';
import 'package:onlynote/presentation/components/template_name_dialog.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/note_archive.dart';
import 'package:onlynote/services/note_tags.dart';
import 'package:onlynote/services/note_links.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/presentation/components/note_tags_sheet.dart';
import 'package:onlynote/presentation/components/note_links_section.dart';
import 'package:onlynote/presentation/components/note_link_picker_sheet.dart';
import 'package:onlynote/presentation/components/note_history_sheet.dart';
import 'package:onlynote/presentation/components/voice_memo_player.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/button_styles.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/presentation/components/reminder_picker_sheet.dart';

import 'bloc/action/note_action_bloc.dart';
import 'bloc/detail/note_detail_bloc.dart';

@RoutePage(name: 'NoteDetailRoute')
class NoteDetailScreen extends StatefulWidget implements AutoRouteWrapper {
  const NoteDetailScreen(
      {super.key,
      @PathParam('noteId') required this.noteId,
      this.templateStore,
      this.positionStore,
      this.selectionTransfer});
  final String noteId;
  final CustomNoteTemplateStore? templateStore;
  final NotePositionStore? positionStore;
  final NoteSelectionTransfer? selectionTransfer;

  @override
  Widget wrappedRoute(BuildContext context) => BlocProvider<NoteDetailBloc>(
        create: (_) => context.read<NoteDetailBloc>().createSibling(),
        child: this,
      );

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen>
    with WidgetsBindingObserver {
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _savingReminder = false;
  bool _exportingImage = false;
  bool _savingTemplate = false;
  bool _changingLibrary = false;
  Note? _lastSavedNote;
  int _reviewGeneration = 0;
  WidgetCommands? _widgetCommands;
  final NoteSearchController _findController = NoteSearchController();
  bool _findOpen = false;
  final _outlineController = NoteOutlineNavigationController();
  final _readerPositionController = NoteReaderPositionController();
  final _readerScrollController = ScrollController();
  Timer? _positionSaveTimer;
  bool _positionCaptureScheduled = false;
  Note? _positionNote;
  NoteReadingPosition? _normalReadingPosition;
  bool _positionLoadStarted = false;
  bool _restoringReadingPosition = false;
  int _readingRestoreToken = 0;
  int _readingGeneration = 0;

  NotePositionStore get _positions =>
      widget.positionStore ?? NotePositionStore.instance;

  bool get _compactToolbar => MediaQuery.sizeOf(context).width < 280;

  NoteSelectionTransfer get _selectionTransfer {
    if (widget.selectionTransfer != null) return widget.selectionTransfer!;
    final repository = getIt<NoteRepository>();
    final drafts = Hive.box(draftDatabaseBox);
    return NoteSelectionTransfer(
        repository: repository,
        store: HiveNoteAutosaveStore(repository, drafts),
        readDraft: (id) => (drafts.get(id) as NoteDto?)?.toDomain());
  }

  void _cancelReadingRestore() {
    _readingGeneration++;
    _readerPositionController.cancelPendingRestore();
  }

  void _rememberReadingPosition() {
    if (_findOpen ||
        _exportingImage ||
        _restoringReadingPosition ||
        ModalRoute.of(context)?.isCurrent == false ||
        _positionNote?.isDeleted == true) {
      return;
    }
    final position = _readerPositionController.capture();
    if (position != null) _normalReadingPosition = position;
  }

  Future<void> _saveReadingPosition({bool capture = true}) async {
    _positionSaveTimer?.cancel();
    if (capture) _rememberReadingPosition();
    final note = _positionNote;
    final position = _normalReadingPosition;
    if (note?.id == null || note!.isDeleted || position == null) return;
    await _positions.saveReading(note.id!, position);
  }

  bool _readerScrollChanged(ScrollNotification notification) {
    if (notification.depth != 0 || _findOpen || _exportingImage) return false;
    if ((notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle)) {
      _cancelReadingRestore();
    }
    if (!_restoringReadingPosition &&
        (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification)) {
      _rememberReadingPosition();
      // Sliver positions are updated after scroll notifications. Record the
      // newly drawn glyph after layout as well, so a quick exit retains the
      // current viewport even before the preference debounce expires.
      if (!_positionCaptureScheduled) {
        _positionCaptureScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _positionCaptureScheduled = false;
          if (mounted) _rememberReadingPosition();
        });
      }
      _positionSaveTimer?.cancel();
      _positionSaveTimer = Timer(const Duration(milliseconds: 280),
          () => unawaited(_saveReadingPosition()));
    }
    return false;
  }

  void _observeReadingPosition(NoteDetailState state) {
    final note = state.whenOrNull(success: (note) => note);
    if (note == null) return;
    _positionNote = note;
    if (_positionLoadStarted || note.isDeleted || note.id != widget.noteId) {
      return;
    }
    _positionLoadStarted = true;
    final generation = _readingGeneration;
    unawaited(_loadReadingPosition(note.id!, generation));
  }

  Future<void> _loadReadingPosition(String noteId, int generation) async {
    final saved = await _positions.read(noteId);
    if (!mounted ||
        generation != _readingGeneration ||
        _findOpen ||
        _exportingImage ||
        _positionNote?.isDeleted == true) {
      return;
    }
    _normalReadingPosition = saved.reading;
    if (saved.reading != null) {
      await _restoreReadingPosition(saved.reading!, generation);
    } else {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted && generation == _readingGeneration) {
        _rememberReadingPosition();
      }
    }
  }

  Future<void> _restoreReadingPosition(
      NoteReadingPosition position, int generation) async {
    bool allowed() =>
        mounted &&
        generation == _readingGeneration &&
        !_findOpen &&
        !_exportingImage &&
        ModalRoute.of(context)?.isCurrent != false &&
        _positionNote?.isDeleted != true;
    if (!allowed()) return;
    final token = ++_readingRestoreToken;
    _restoringReadingPosition = true;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!allowed()) return;
      await _readerPositionController.restore(position, canRestore: allowed);
    } finally {
      if (token == _readingRestoreToken) {
        _restoringReadingPosition = false;
        if (allowed()) _rememberReadingPosition();
      }
    }
  }

  Future<void> _addSelectionToChecklist(
      Note source, NoteTextSelection selection) async {
    if (_changingLibrary ||
        _exportingImage ||
        _savingReminder ||
        source.isDeleted ||
        source.id != widget.noteId) {
      return;
    }
    _rememberReadingPosition();
    _cancelReadingRestore();
    _reviewGeneration++;
    setState(() => _changingLibrary = true);
    try {
      final result =
          await _selectionTransfer.addToChecklist(source.id!, selection);
      if (!mounted) return;
      if (result?.status == NoteSelectionChecklistStatus.empty) return;
      final saved = result?.status == NoteSelectionChecklistStatus.ready;
      if (saved) _reload();
      showTransientSnackBar(
          context,
          SnackBar(
            content: Text(saved
                ? S
                    .of(context)
                    .Selection_Checklist_Added(result!.addedTodoIds.length)
                : result?.status == NoteSelectionChecklistStatus.tooLong
                    ? S.of(context).Selection_Checklist_Too_Long
                    : S.of(context).Selection_Checklist_Failed),
            action: !saved
                ? null
                : SnackBarAction(
                    label: S.of(context).Undo,
                    onPressed: () => _undoSelectionChecklist(
                        source.id!, result!.addedTodoIds)),
          ));
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Selection_Checklist_Failed)));
      }
    } finally {
      if (mounted) setState(() => _changingLibrary = false);
    }
  }

  Future<void> _undoSelectionChecklist(String noteId, List<String> ids) async {
    if (_changingLibrary || _exportingImage || _savingReminder) return;
    _reviewGeneration++;
    setState(() => _changingLibrary = true);
    try {
      final saved = await _selectionTransfer.undoChecklist(noteId, ids);
      if (!mounted) return;
      if (saved) {
        _reload();
      } else {
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Selection_Checklist_Failed)));
      }
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Selection_Checklist_Failed)));
      }
    } finally {
      if (mounted) setState(() => _changingLibrary = false);
    }
  }

  Future<void> _copySelection(Note source, NoteTextSelection selection) async {
    if (_changingLibrary || _exportingImage || _savingReminder) return;
    setState(() => _changingLibrary = true);
    try {
      final destination = await showNoteCopyDestinationPicker(context,
          notes: _libraryNotes, sourceNoteId: source.id);
      if (!mounted || destination == null) return;
      final transfer = _selectionTransfer;
      final saved = destination.isNewNote
          ? await transfer.copyToNew(selection, color: source.color)
          : await transfer.copyToExisting(destination.noteId!, selection);
      if (!mounted) return;
      showTransientSnackBar(
          context,
          SnackBar(
              content: Text(saved
                  ? S.of(context).Copy_Selection_Saved
                  : S.of(context).Copy_Selection_Failed)));
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Copy_Selection_Failed)));
      }
    } finally {
      if (mounted) setState(() => _changingLibrary = false);
    }
  }

  Future<void> _openOutline(Note note) async {
    if (_exportingImage || _savingReminder || _changingLibrary) return;
    final entries = buildNoteOutline(note.description ?? '', note.textStyles);
    if (entries.isEmpty) return;
    _cancelReadingRestore();
    final entry =
        await showNoteOutlineSheet(context: context, entries: entries);
    if (!mounted || entry == null) return;
    await _outlineController.jumpTo(entry.start);
  }

  void _openFind() {
    if (_findOpen || _exportingImage || _positionNote?.isDeleted == true) {
      return;
    }
    _rememberReadingPosition();
    _positionSaveTimer?.cancel();
    _cancelReadingRestore();
    if (mounted) setState(() => _findOpen = true);
  }

  void _closeFind() {
    if (!_findOpen) return;
    _cancelReadingRestore();
    final generation = _readingGeneration;
    _findController.setQuery('');
    if (mounted) setState(() => _findOpen = false);
    final position = _normalReadingPosition;
    if (position != null) {
      unawaited(_restoreReadingPosition(position, generation));
    }
  }

  void _findChanged() {
    if (mounted) setState(() {});
  }

  void _refreshWidgetCompletion() {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (_widgetCommands?.updates.value?.noteId == widget.noteId) {
      context
          .read<NoteDetailBloc>()
          .add(NoteDetailEvent.showNote(widget.noteId));
    }
  }

  void _observeSavedChecklist(NoteDetailState state) {
    final generation = ++_reviewGeneration;
    final next = state.whenOrNull(success: (note) => note);
    final previous = _lastSavedNote;
    _lastSavedNote = next;
    if (next == null ||
        previous == null ||
        !context.read<NoteDetailBloc>().lastSaveWasTodoToggle ||
        previous.id != next.id ||
        next.isDeleted ||
        !previous.todo.any((item) =>
            item.title?.trim().isNotEmpty == true && !item.completed)) {
      return;
    }
    final items = next.todo
        .where((item) => item.title?.trim().isNotEmpty == true)
        .toList();
    if (items.isEmpty || items.any((item) => !item.completed)) return;
    _considerChecklistReview(next.id!, generation);
  }

  Future<void> _considerChecklistReview(String noteId, int generation) async {
    if (!InAppReviewHelper.instance.promptsEnabled) return;
    await Future<void>.delayed(const Duration(seconds: 6));
    if (!mounted ||
        generation != _reviewGeneration ||
        !isReviewMomentIdle ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    await InAppReviewHelper.instance.recordChecklistCompleted(noteId: noteId);
    if (mounted &&
        generation == _reviewGeneration &&
        ModalRoute.of(context)?.isCurrent == true &&
        isReviewMomentIdle) {
      await InAppReviewHelper.instance
          .requestReviewIfEligible(afterChecklistCompletion: true);
    }
  }

  Future<void> _saveAsTemplate(Note note) async {
    if (_savingTemplate) return;
    final strings = S.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TemplateNameDialog(
        title: strings.Save_As_Template,
        initial: note.title?.trim().isNotEmpty == true
            ? note.title
            : strings.Template_Default_Name,
      ),
    );
    if (!mounted || name == null) return;
    setState(() => _savingTemplate = true);
    try {
      await (widget.templateStore ?? CustomNoteTemplateStore.instance)
          .saveFromNote(note, name: name);
      if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(strings.Template_Saved)));
      }
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(strings.Template_Save_Failed)));
      }
    } finally {
      if (mounted) setState(() => _savingTemplate = false);
    }
  }

  void _showMoreOptions(Note note) {
    showAppActionSheet(
      context: context,
      title: S.of(context).More_Options,
      actions: [
        if (_compactToolbar) ...[
          AppSheetAction(
            leading: const Icon(Icons.alarm_add_outlined),
            title: Text(S.of(context).Reminder),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              _showReminderPicker(note);
            },
          ),
          AppSheetAction(
            leading: const Icon(Icons.share_outlined),
            title: Text(S.of(context).Share),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              _shareNoteAsImage(note);
            },
          ),
          AppSheetAction(
            leading: const Icon(Icons.edit_outlined),
            title: Text(S.of(context).Edit),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              _editNote(note);
            },
          ),
        ],
        if (shouldShowNoteOutline(note.description ?? '',
            buildNoteOutline(note.description ?? '', note.textStyles)))
          AppSheetAction(
            leading: const Icon(Icons.format_list_bulleted_rounded),
            title: Text(S.of(context).Note_Outline),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              _openOutline(note);
            },
          ),
        AppSheetAction(
          leading: const Icon(Icons.manage_search_rounded),
          title: Text(S.of(context).Find_In_Note),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _openFind();
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(S.of(context).Note_Info),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            showNoteInfoSheet(
                context: context, statistics: NoteStatistics.fromNote(note));
          },
        ),
        AppSheetAction(
          leading: Icon(note.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined),
          title: Text(note.isArchived
              ? S.of(context).Unarchive_Note
              : S.of(context).Archive_Note),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _setArchive(note);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.sell_outlined),
          title: Text(S.of(context).Edit_Tags),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _editTags(note);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.link_rounded),
          title: Text(S.of(context).Link_Note),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _editLinks(note);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.history_rounded),
          title: Text(S.of(context).History_Title),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _showHistory(note);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.bookmarks_outlined),
          title: Text(S.of(context).Save_As_Template),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _saveAsTemplate(note);
          },
        ),
        AppSheetAction(
          destructive: true,
          leading: const Icon(Icons.delete_outline),
          title: Text(S.of(context).Delete),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            context
                .read<NoteActionBloc>()
                .add(NoteActionEvent.deleteNote(note.id!));
          },
        ),
      ],
    );
  }

  List<Note> get _libraryNotes => getIt.isRegistered<NoteRepository>()
      ? getIt<NoteRepository>()
          .getAllNotes()
          .map((note) => note.toDomain())
          .toList()
      : const [];

  void _reload() {
    if (mounted) {
      context
          .read<NoteDetailBloc>()
          .add(NoteDetailEvent.showNote(widget.noteId));
    }
  }

  Future<void> _editNote(Note note) async {
    if (_changingLibrary || _exportingImage) return;
    await _saveReadingPosition();
    if (!mounted) return;
    await context.router.push(AddUpdateNoteRoute(note: note));
    _reload();
  }

  Future<void> _changeLibrary(
      Future<void> Function(NoteRepository) operation) async {
    if (_changingLibrary || !getIt.isRegistered<NoteRepository>()) return;
    setState(() => _changingLibrary = true);
    try {
      await operation(getIt<NoteRepository>());
      _reload();
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Link_Save_Failed)));
      }
    } finally {
      if (mounted) setState(() => _changingLibrary = false);
    }
  }

  Future<void> _setArchive(Note note) => _changeLibrary((repository) async {
        final change =
            await setNoteArchived(repository, note.id!, !note.isArchived);
        if (!mounted || change == null) return;
        showTransientSnackBar(
            context,
            SnackBar(
              content: Text(change.archived
                  ? S.of(context).Note_Archived
                  : S.of(context).Note_Unarchived),
              action: SnackBarAction(
                  label: S.of(context).Undo,
                  onPressed: () {
                    _changeLibrary((repository) async {
                      await setNoteArchived(
                          repository, change.noteId, change.previousArchived);
                    });
                  }),
            ));
      });

  Future<void> _editTags(Note note) async {
    if (_changingLibrary) return;
    final tags =
        await showNoteTagsSheet(context, tags: note.tags, suggestions: [
      for (final value in _libraryNotes)
        if (!value.isDeleted) ...value.tags
    ]);
    if (!mounted || tags == null) return;
    await _changeLibrary((repository) async {
      final current = await repository.getNote(note.id!);
      if (current.isDeleted) throw StateError('Note unavailable');
      await repository
          .addUpdateNote(current.copyWith(tags: normalizeNoteTags(tags)));
    });
  }

  Future<void> _editLinks(Note note) async {
    if (_changingLibrary) return;
    final links = await showNoteLinkPickerSheet(context,
        currentNoteId: note.id!,
        selectedIds: note.linkedNoteIds,
        notes: _libraryNotes);
    if (!mounted || links == null) return;
    await _changeLibrary((repository) async {
      final current = await repository.getNote(note.id!);
      if (current.isDeleted) throw StateError('Note unavailable');
      await repository.addUpdateNote(current.copyWith(
          linkedNoteIds: normalizeLinkedNoteIds(links, noteId: note.id)));
    });
  }

  Future<void> _openLinkedNote(Note note) async {
    if (_changingLibrary || note.id == null) return;
    final current = availableLinkedNote(note.id!, _libraryNotes);
    if (current == null) {
      showTransientSnackBar(
          context, SnackBar(content: Text(S.of(context).Link_Unavailable)));
      return;
    }
    await _saveReadingPosition();
    if (!mounted) return;
    await context.router.push(NoteDetailRoute(noteId: current.id!));
    _reload();
  }

  Future<void> _showHistory(Note note) async {
    final history = NoteHistory.initializedInstance;
    if (history == null || note.id == null) return;
    final restored =
        await showNoteHistorySheet(context, noteId: note.id!, history: history);
    if (restored == true && mounted) {
      context
          .read<NoteDetailBloc>()
          .add(NoteDetailEvent.showNote(widget.noteId));
      showTransientSnackBar(
          context, SnackBar(content: Text(S.of(context).History_Restored)));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetCommands = WidgetCommands.initializedInstance;
    _widgetCommands?.updates.addListener(_refreshWidgetCompletion);
    _findController.addListener(_findChanged);

    if (mounted) {
      BlocProvider.of<NoteDetailBloc>(context)
          .add(NoteDetailEvent.showNote(widget.noteId));
    }
  }

  @override
  void dispose() {
    _positionSaveTimer?.cancel();
    unawaited(_saveReadingPosition(capture: false));
    _cancelReadingRestore();
    WidgetsBinding.instance.removeObserver(this);
    _widgetCommands?.updates.removeListener(_refreshWidgetCompletion);
    _findController.removeListener(_findChanged);
    _findController.dispose();
    _outlineController.dispose();
    _readerPositionController.dispose();
    _readerScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_saveReadingPosition());
    }
  }

  @override
  void didUpdateWidget(NoteDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteId != widget.noteId) {
      unawaited(_saveReadingPosition());
      _cancelReadingRestore();
      _positionLoadStarted = false;
      _normalReadingPosition = null;
      _positionNote = null;
      _findOpen = false;
      _findController.setQuery('');
      context
          .read<NoteDetailBloc>()
          .add(NoteDetailEvent.showNote(widget.noteId));
    }
  }

  Future<void> _shareNoteAsImage(Note note) => ShareHelper.shareNote(
        context,
        note,
        _screenshotController,
        sharePositionOrigin: ShareHelper.shareOriginFromKey(_shareButtonKey),
        captureImage: _captureNoteImage,
      );

  Future<Uint8List?> _captureNoteImage() async {
    if (!mounted) return null;
    _rememberReadingPosition();
    _positionSaveTimer?.cancel();
    _cancelReadingRestore();
    final generation = _readingGeneration;
    setState(() => _exportingImage = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      return await _screenshotController.capture(pixelRatio: 3);
    } finally {
      if (mounted) {
        setState(() => _exportingImage = false);
        final position = _normalReadingPosition;
        if (position != null) {
          await _restoreReadingPosition(position, generation);
        }
      }
    }
  }

  Future<void> _showReminderPicker(Note note) async {
    if (_savingReminder) return;
    final current = ReminderData.shared.getCurrentReminder(note);
    final result = await showAppSheet<ReminderPickerResult>(
      context: context,
      builder: (_) => ReminderPickerSheet(current: current),
    );
    if (result == null || !mounted) return;
    if (!result.delete) {
      await _saveReminder(note, result.date!,
          current: current, repeat: result.repeat);
      return;
    }
    if (current == null) return;
    _savingReminder = true;
    final service = NotificationService();
    final l10n = S.of(context);
    try {
      await service.removeNotification(current);
      try {
        await ReminderData.shared.deleteReminder(current);
      } catch (_) {
        if (current.isSchedulable(DateTime.now())) {
          await service.scheduleNotifications(
            id: current.reminderId,
            title: l10n.Onlynote,
            body: '${l10n.Reminder}: ${note.title ?? ''}',
            time: current.reminderDate,
            noteId: current.noteId,
            repeat: current.repeat,
          );
        }
        rethrow;
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(l10n.Reminder_Save_Failed)));
      }
    } finally {
      _savingReminder = false;
    }
  }

  Future<void> _saveReminder(Note note, DateTime date,
      {Reminder? current, ReminderRepeat repeat = ReminderRepeat.none}) async {
    if (_savingReminder) return;
    _savingReminder = true;
    final l10n = S.of(context);
    try {
      final service = NotificationService();
      final allowed = await service.checkAndAskForPermission(context);
      if (allowed != true || !mounted) return;
      final usedIds =
          ReminderData.shared.reminders.map((r) => r.reminderId).toSet();
      var id = current?.reminderId ?? (const Uuid().v4().hashCode & 0x7fffffff);
      if (current == null) {
        while (usedIds.contains(id)) {
          id = (id + 1) & 0x7fffffff;
        }
      }
      final reminder = Reminder(
          reminderId: id, reminderDate: date, noteId: note.id!, repeat: repeat);
      if (!reminder.isSchedulable(DateTime.now())) {
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Reminder_Future_Time)));
        return;
      }
      final scheduled = await service.scheduleNotifications(
        id: id,
        title: S.of(context).Onlynote,
        body: '${S.of(context).Reminder}: ${note.title ?? ''}',
        time: date,
        noteId: reminder.noteId,
        repeat: repeat,
      );
      if (!scheduled) throw StateError('Scheduling failed');
      try {
        if (current == null) {
          await ReminderData.shared.addReminder(reminder);
        } else {
          await ReminderData.shared.modifyReminder(current, reminder);
        }
      } catch (_) {
        await service.removeNotification(reminder);
        if (current != null && current.isSchedulable(DateTime.now())) {
          await service.scheduleNotifications(
            id: current.reminderId,
            title: l10n.Onlynote,
            body: '${l10n.Reminder}: ${note.title ?? ''}',
            time: current.reminderDate,
            noteId: current.noteId,
            repeat: current.repeat,
          );
        }
        rethrow;
      }
      if (mounted) {
        setState(() {});
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Reminder_Saved)));
      }
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Reminder_Save_Failed)));
      }
    } finally {
      _savingReminder = false;
    }
  }

  Future<void> _restoreNote(Note note) async {
    final result = await getIt<RestoreNotesUsecase>()([note.id!]);
    if (!mounted) return;
    result.fold((error) => context.showToast('${error.message}', isError: true),
        (remindersRestored) {
      _reload();
      context.showToast(remindersRestored
          ? S.of(context).Notes_Restored
          : S.of(context).Restore_Reminder_Warning);
    });
  }

  Future<void> _deleteForever(Note note) async {
    final confirmed = await showConfirmDialog(context,
        title: S.of(context).Permanent_Delete_Confirm_Title,
        message: S.of(context).Permanent_Delete_Confirm_Message);
    if (!confirmed || !mounted) return;
    final result = await getIt<PermanentDeleteNotesUsecase>()([note.id!]);
    if (!mounted) return;
    result.fold((error) => context.showToast('${error.message}', isError: true),
        (_) => context.router.popUntilRoot());
  }

  void _showTrashOptions(Note note) {
    showAppActionSheet(
      context: context,
      title: S.of(context).More_Options,
      actions: [
        AppSheetAction(
          leading: const Icon(Icons.share_outlined),
          title: Text(S.of(context).Share),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _shareNoteAsImage(note);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.restore_outlined),
          title: Text(S.of(context).Restore),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _restoreNote(note);
          },
        ),
        AppSheetAction(
          destructive: true,
          leading: const Icon(Icons.delete_forever_outlined),
          title: Text(S.of(context).Delete_Forever),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _deleteForever(note);
          },
        ),
      ],
    );
  }

  List<Widget> _trashActions(Note note) => _compactToolbar
      ? [
          AppButton(
              key: _shareButtonKey,
              tooltip: S.of(context).More_Options,
              child: const Icon(Icons.more_horiz_rounded),
              onPressed: () => _showTrashOptions(note)),
        ]
      : [
          AppButton(
              key: _shareButtonKey,
              tooltip: S.of(context).Share,
              child: const Icon(Icons.share_outlined),
              onPressed: () => _shareNoteAsImage(note)),
          AppButton(
              tooltip: S.of(context).Restore,
              child: const Icon(Icons.restore_outlined),
              onPressed: () => _restoreNote(note)),
          AppButton(
              destructive: true,
              tooltip: S.of(context).Delete_Forever,
              child: const Icon(Icons.delete_forever_outlined),
              onPressed: () => _deleteForever(note)),
        ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NoteDetailBloc, NoteDetailState>(
      listener: (_, state) {
        _observeSavedChecklist(state);
        _observeReadingPosition(state);
      },
      builder: (context, state) {
        final note = state.whenOrNull(success: (note) => note);
        if (note != null) {
          _observeReadingPosition(state);
          _findController.setFields(noteSearchFields(note), notify: false);
        }
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) unawaited(_saveReadingPosition());
          },
          child: Listener(
            onPointerDown: (_) => _cancelReadingRestore(),
            onPointerSignal: (_) => _cancelReadingRestore(),
            child: CallbackShortcuts(
              bindings: {
                if (_findOpen)
                  const SingleActivator(LogicalKeyboardKey.escape): _closeFind,
                const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                    _openFind,
                const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                    _openFind,
              },
              child: Focus(
                autofocus: true,
                child: Scaffold(
                  backgroundColor: DeskSurface.colorOf(context),
                  appBar: NoteAppBar(
                    actions: state.whenOrNull(
                      success: (note) {
                        if (note.isDeleted) return _trashActions(note);
                        final hasReminder =
                            ReminderData.shared.getCurrentReminder(note) !=
                                null;
                        return [
                          if (!_compactToolbar) ...[
                            AppButton(
                              tooltip: S.of(context).Reminder,
                              child: AnimatedSwitcher(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                        scale: animation, child: child),
                                child: Icon(
                                  hasReminder
                                      ? Icons.alarm_on_outlined
                                      : Icons.alarm_add_outlined,
                                  key: ValueKey(hasReminder),
                                ),
                              ),
                              onPressed: () => _showReminderPicker(note),
                            ),
                            AppButton(
                              key: _shareButtonKey,
                              tooltip: S.of(context).Share,
                              child: const Icon(Icons.share_outlined),
                              onPressed: () => _shareNoteAsImage(note),
                            ),
                            AppButton(
                              tooltip: S.of(context).Edit,
                              child: const Icon(Icons.edit_outlined),
                              onPressed: () => _editNote(note),
                            ),
                          ],
                          AppButton(
                            key: _compactToolbar ? _shareButtonKey : null,
                            tooltip: S.of(context).More_Options,
                            isLoading: _savingTemplate || _changingLibrary,
                            child: const Icon(Icons.more_horiz_rounded),
                            onPressed: () => _showMoreOptions(note),
                          ),
                        ];
                      },
                    ),
                  ),
                  body: Column(children: [
                    if (_findOpen && note != null)
                      NoteFindBar(
                        controller: _findController,
                        hintText: S.of(context).Find_In_Note,
                        noMatchesText: S.of(context).Find_No_Matches,
                        previousTooltip: S.of(context).Find_Previous,
                        nextTooltip: S.of(context).Find_Next,
                        closeTooltip: S.of(context).Find_Close,
                        onClose: _closeFind,
                      ),
                    Expanded(
                        child: DeskSurface(
                      child: state.maybeMap(
                        error: (error) => ErrorText(error.message ?? ''),
                        success: (data) =>
                            NotificationListener<ScrollNotification>(
                          onNotification: _readerScrollChanged,
                          child: LoadedView(
                            note: data.note,
                            screenshotController: _screenshotController,
                            exportMode: _exportingImage,
                            searchController: _findOpen && !_exportingImage
                                ? _findController
                                : null,
                            outlineController:
                                _exportingImage ? null : _outlineController,
                            scrollController: _readerScrollController,
                            readerPositionController: data.note.isDeleted ||
                                    _exportingImage ||
                                    _findOpen
                                ? null
                                : _readerPositionController,
                            onCopySelection:
                                data.note.isDeleted || _exportingImage
                                    ? null
                                    : (selection) =>
                                        _copySelection(data.note, selection),
                            onAddSelectionToChecklist:
                                data.note.isDeleted || _exportingImage
                                    ? null
                                    : (selection) => _addSelectionToChecklist(
                                        data.note, selection),
                            libraryNotes: _libraryNotes,
                            onOpenLinkedNote: _openLinkedNote,
                            onEditLinks: data.note.isDeleted
                                ? null
                                : () => _editLinks(data.note),
                            onChecklistActionStart: () => _reviewGeneration++,
                            checklistReadOnly: _changingLibrary,
                            onReminderTap: data.note.isDeleted
                                ? null
                                : () => _showReminderPicker(data.note),
                          ),
                        ),
                        orElse: () => const _DetailSkeleton(),
                      ),
                    )),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoadedView extends StatelessWidget {
  const LoadedView({
    super.key,
    required this.note,
    required this.screenshotController,
    required this.onReminderTap,
    this.onChecklistActionStart,
    this.exportMode = false,
    this.libraryNotes = const [],
    this.onOpenLinkedNote,
    this.onEditLinks,
    this.searchController,
    this.outlineController,
    this.onCopySelection,
    this.onAddSelectionToChecklist,
    this.readerPositionController,
    this.scrollController,
    this.checklistReadOnly = false,
  });

  final Note note;
  final ScreenshotController screenshotController;
  final VoidCallback? onReminderTap;
  final VoidCallback? onChecklistActionStart;
  final bool exportMode;
  final List<Note> libraryNotes;
  final ValueChanged<Note>? onOpenLinkedNote;
  final VoidCallback? onEditLinks;
  final NoteSearchController? searchController;
  final NoteOutlineNavigationController? outlineController;
  final ValueChanged<NoteTextSelection>? onCopySelection;
  final ValueChanged<NoteTextSelection>? onAddSelectionToChecklist;
  final NoteReaderPositionController? readerPositionController;
  final ScrollController? scrollController;
  final bool checklistReadOnly;

  @override
  Widget build(BuildContext context) {
    Reminder? currentReminder = ReminderData.shared.getCurrentReminder(note);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.tokens.contentMaxWidth),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            context.tokens.space4,
            context.tokens.space3,
            context.tokens.space4,
            context.tokens.space6,
          ),
          children: [
            //* Everything inside here is captured when sharing the note as an image.
            Screenshot(
              controller: screenshotController,
              child: PaperNote(
                color: note.color ?? AppColors.parchment,
                kind: PaperNoteKind.sheet,
                seed: note.id?.hashCode ?? 0,
                pinned: note.isPinned,
                tilt: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (note.title?.isNotEmpty == true) ...[
                      if (searchController != null)
                        NoteSearchText(
                          controller: searchController!,
                          fieldId: 'title',
                          text: note.title!,
                          selectable: !exportMode,
                          onCopySelection: exportMode ? null : onCopySelection,
                          onAddSelectionToChecklist:
                              exportMode ? null : onAddSelectionToChecklist,
                          style: AppTypography.headline3.copyWith(height: 1.25),
                        )
                      else
                        FormattedNoteText(
                          text: note.title!,
                          selectable: !exportMode,
                          onCopySelection: exportMode ? null : onCopySelection,
                          onAddSelectionToChecklist:
                              exportMode ? null : onAddSelectionToChecklist,
                          style: AppTypography.headline3.copyWith(height: 1.25),
                        ),
                      const SizedBox(height: AppSpacings.l),
                    ],
                    SelectableText(
                      note.dateWithTime,
                      style: AppTypography.description.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                      ),
                    ),
                    if (note.isArchived || note.tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacings.m),
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        if (note.isArchived)
                          Chip(
                              avatar:
                                  const Icon(Icons.archive_outlined, size: 18),
                              label: Text(S.of(context).Archive)),
                        for (final tag in note.tags) Chip(label: Text(tag)),
                      ]),
                    ],
                    if (currentReminder != null) ...{
                      const SizedBox(height: AppSpacings.m),
                      InkWell(
                        borderRadius:
                            BorderRadius.circular(context.tokens.radiusSmall),
                        onTap: onReminderTap,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: context.tokens.space2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.alarm_rounded,
                                  size: 16,
                                  color: AppColors.ink.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: AppSpacings.s),
                                Flexible(
                                  child: Text(
                                    '${formatReminderTime(context, currentReminder.nextOccurrence(DateTime.now()))}${currentReminder.isRepeating ? ' · ${reminderRepeatLabel(context, currentReminder.repeat)}' : ''}',
                                    style: AppTypography.description.copyWith(
                                      color:
                                          AppColors.ink.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    },
                    const SizedBox(height: AppSpacings.xxl),
                    if (note.hasTodo) ...{
                      NoteChecklist(
                        key: ValueKey(note.id),
                        todos: note.todo,
                        readOnly: note.isDeleted || checklistReadOnly,
                        exportMode: exportMode,
                        expandCompleted:
                            searchController?.query.trim().isNotEmpty == true,
                        titleBuilder: searchController == null
                            ? null
                            : (todo, style) => NoteSearchText(
                                  controller: searchController!,
                                  fieldId:
                                      'todo:${todo.id ?? note.todo.indexWhere((item) => identical(item, todo))}',
                                  text: todo.title ?? '',
                                  style: style,
                                  selectable: false,
                                ),
                        onToggle: (id) {
                          onChecklistActionStart?.call();
                          HapticFeedback.selectionClick();
                          context
                              .read<NoteDetailBloc>()
                              .add(NoteDetailEvent.toggleTodoCheckbox(id));
                        },
                        onReset: () async {
                          onChecklistActionStart?.call();
                          final bloc = context.read<NoteDetailBloc>();
                          final ids = await bloc.resetChecklist(note.id!);
                          if (!context.mounted || ids == null) return;
                          showTransientSnackBar(
                              context,
                              SnackBar(
                                content:
                                    Text(S.of(context).Checklist_Reset_Done),
                                action: SnackBarAction(
                                    label: S.of(context).Undo,
                                    onPressed: () {
                                      onChecklistActionStart?.call();
                                      bloc.add(
                                          NoteDetailEvent.restoreCompletedTodos(
                                              noteId: note.id!, todoIds: ids));
                                    }),
                              ));
                        },
                      ),
                      const SizedBox(height: AppSpacings.xxl),
                    },
                    NoteDocumentView(
                      outlineController: outlineController,
                      readerPositionController:
                          exportMode || searchController != null
                              ? null
                              : readerPositionController,
                      collapsibleSections:
                          !exportMode && searchController == null,
                      sectionToggleLabel: (heading, expanded) => expanded
                          ? S.of(context).Collapse_Section(heading)
                          : S.of(context).Expand_Section(heading),
                      onCopySelection: exportMode ? null : onCopySelection,
                      onAddSelectionToChecklist:
                          exportMode ? null : onAddSelectionToChecklist,
                      text: note.description ?? '',
                      styles: note.textStyles,
                      imagePaths: note.imagePaths,
                      imageLayouts: note.imageLayouts,
                      selectable: !exportMode,
                      textBuilder: searchController == null
                          ? null
                          : (text, styles, start, _) => NoteSearchText(
                                controller: searchController!,
                                fieldId: 'body',
                                text: text,
                                textOffset: start,
                                styles: styles,
                                selectable: !exportMode,
                                onCopySelection:
                                    exportMode ? null : onCopySelection,
                                onAddSelectionToChecklist: exportMode
                                    ? null
                                    : onAddSelectionToChecklist,
                                style: AppTypography.headline6.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.ink.withValues(alpha: 0.88),
                                ),
                              ),
                      onImageTap: exportMode
                          ? null
                          : (path) {
                              final paths = noteDocumentParts(
                                      note.description ?? '',
                                      normalizeNoteImageLayouts(
                                          note.imageLayouts,
                                          note.imagePaths,
                                          note.description ?? ''))
                                  .whereType<NoteImagePart>()
                                  .map((part) => part.layout.path)
                                  .toList();
                              Navigator.of(context).push(MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) => _FullScreenImageViewer(
                                      imagePaths: paths,
                                      initialIndex: paths
                                          .indexOf(path)
                                          .clamp(0, paths.length - 1))));
                            },
                      style: AppTypography.headline6.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.ink.withValues(alpha: 0.88),
                      ),
                    ),
                    if (note.linkedNoteIds.isNotEmpty ||
                        (!exportMode &&
                            noteBacklinks(note, libraryNotes).isNotEmpty)) ...[
                      const SizedBox(height: AppSpacings.l),
                      NoteLinksSection(
                        linkedNoteIds: note.linkedNoteIds,
                        notes: libraryNotes,
                        backlinks: exportMode
                            ? const []
                            : noteBacklinks(note, libraryNotes),
                        onOpen: note.isDeleted ? null : onOpenLinkedNote,
                        onEdit: onEditLinks,
                        exportMode: exportMode,
                      ),
                    ],
                    if (note.hasVoiceMemos) ...[
                      const SizedBox(height: AppSpacings.xxl),
                      for (final memo in note.voiceMemos)
                        if (exportMode) ...[
                          Text(
                              '${S.of(context).Voice_Memo} · ${Duration(milliseconds: memo.durationMs).inMinutes}:${(Duration(milliseconds: memo.durationMs).inSeconds % 60).toString().padLeft(2, '0')}',
                              style: AppTypography.headline6),
                          if (memo.transcript?.isNotEmpty == true)
                            Text(memo.transcript!,
                                style: AppTypography.cardBody),
                          const SizedBox(height: AppSpacings.m),
                        ] else
                          VoiceMemoPlayer(
                              memo: memo,
                              key: ValueKey(memo.id),
                              transcriptBuilder: searchController == null
                                  ? (text) => FormattedNoteText(
                                        text: text,
                                        style: context.textStyles.bodyMedium,
                                        selectable: !exportMode,
                                        onCopySelection:
                                            exportMode ? null : onCopySelection,
                                        onAddSelectionToChecklist: exportMode
                                            ? null
                                            : onAddSelectionToChecklist,
                                      )
                                  : (text) => NoteSearchText(
                                        controller: searchController!,
                                        fieldId: 'voice:${memo.id}',
                                        text: text,
                                        style: context.textStyles.bodyMedium,
                                        selectable: !exportMode,
                                        onCopySelection:
                                            exportMode ? null : onCopySelection,
                                        onAddSelectionToChecklist: exportMode
                                            ? null
                                            : onAddSelectionToChecklist,
                                      ),
                              resolvePath: AudioStorage.instance.resolvePath),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        padding: EdgeInsets.all(context.tokens.space4),
        children: [
          Container(height: 42, decoration: _decoration(context)),
          SizedBox(height: context.tokens.space3),
          Container(height: 16, width: 160, decoration: _decoration(context)),
          SizedBox(height: context.tokens.space5),
          Container(height: 180, decoration: _decoration(context)),
        ],
      ),
    );
  }

  BoxDecoration _decoration(BuildContext context) => BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(context.tokens.radiusMedium),
      );
}

class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.imagePaths,
    required this.initialIndex,
  });

  final List<String> imagePaths;
  final int initialIndex;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.imagePaths.length > 1;
    const viewerColors = ColorScheme.dark(
      onSurface: Colors.white,
      surfaceContainerHigh: Color(0xFF242424),
      outlineVariant: Color(0xFF454545),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: CloseButton(style: AppButtonStyles.icon(viewerColors)),
        title: hasMultiple
            ? Text('${_index + 1} / ${widget.imagePaths.length}')
            : null,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imagePaths.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Hero(
                tag: 'note-image-${widget.imagePaths[index]}',
                child: NoteImage(
                  path: widget.imagePaths[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
