import 'package:onlynote/domain/model/note_section_link.dart';
import 'package:onlynote/services/note_section_links.dart';
import 'package:onlynote/services/note_section_link_capture.dart';
import 'package:onlynote/presentation/components/note_section_link_picker_sheet.dart';
import 'package:onlynote/presentation/components/note_section_links_section.dart';
import 'package:onlynote/presentation/theme/button_styles.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_creation_limit.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/services/note_text_format.dart';
import 'package:onlynote/services/note_edit_history.dart';
import 'package:onlynote/services/note_outline.dart';
import 'package:onlynote/presentation/components/note_editing_actions.dart';
import 'package:onlynote/presentation/components/note_outline_navigation_controller.dart';
import 'package:onlynote/presentation/components/note_outline_sheet.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/components/note_body_editor.dart';
import 'package:onlynote/presentation/components/note_body_formatting_controller.dart';
import 'package:onlynote/presentation/components/note_writing_toolbar.dart';
import 'package:onlynote/presentation/components/note_insert_sheet.dart';
import 'package:onlynote/presentation/components/note_save_status.dart';
import 'package:onlynote/presentation/components/note_editor_tip.dart';
import 'package:onlynote/services/note_editor_tips.dart';
import 'package:onlynote/presentation/components/note_photo_editor.dart';
import 'package:onlynote/presentation/components/note_find_bar.dart';
import 'package:onlynote/presentation/components/note_find_preview.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/services/note_replace.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_transfer.dart';
import 'package:onlynote/services/note_selection_checklist.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/note_statistics.dart';
import 'package:onlynote/services/note_folder_info.dart';
import 'package:onlynote/presentation/components/note_info_sheet.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';
import 'package:onlynote/presentation/components/note_selection_menu.dart';
import 'package:onlynote/presentation/components/note_copy_destination_sheet.dart';
import 'package:onlynote/services/note_photo_edit.dart';
import 'package:onlynote/services/note_photo_transform.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_links.dart';
import 'package:onlynote/presentation/components/note_links_section.dart';
import 'package:onlynote/presentation/components/note_link_picker_sheet.dart';
import 'package:onlynote/presentation/components/note_tags_sheet.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/photo_text_extraction.dart';
import 'package:onlynote/services/voice_memo_drafts.dart';
import 'package:onlynote/services/voice_memo_service.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/presentation/components/photo_text_review_sheet.dart';
import 'package:onlynote/presentation/components/voice_memo_composer.dart';
import 'package:onlynote/presentation/components/voice_memo_player.dart';
import 'package:onlynote/services/note_templates.dart';
import 'package:onlynote/services/note_photo_capture.dart';
import 'package:onlynote/services/document_scan_capture.dart';
import 'package:onlynote/services/scanned_note.dart';
import 'package:onlynote/services/note_reminder_scheduler.dart';
import 'package:onlynote/services/reminder_date_suggestion.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/note_cleanup.dart';
import 'package:onlynote/Tools/in_app_reviewer_helper.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/common/extension/random.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/components/review_moment.dart';
import 'package:onlynote/presentation/components/reminder_suggestion_chip.dart';
import 'package:onlynote/presentation/components/reminder_picker_sheet.dart';
import 'package:onlynote/presentation/components/premium_feature_gate.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/note_theme_access.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/presentation/theme/note_card_typography.dart';

import 'bloc/add_update_bloc.dart';
import 'bloc/add_update_form/add_update_form_bloc.dart';

part 'widgets/text_forms.dart';
part 'widgets/todo_tile.dart';

/// Determines which field is ready to type when a new note is opened.
enum NoteEditorStart { standard, quickNote, checklist, photo, voice }

@RoutePage(name: 'AddUpdateNoteRoute')
class AddUpdateNoteScreen extends StatefulWidget {
  const AddUpdateNoteScreen(
      {super.key,
      this.note,
      this.folderId,
      this.template,
      this.customTemplateNote,
      this.autosaveStore,
      this.photoCapture,
      this.documentScanCapture,
      this.photoEditService,
      this.photoTextExtraction,
      this.voiceMemoService,
      this.voiceMemoDrafts,
      this.reminderScheduler,
      this.widgetCommands,
      this.positionStore,
      this.editorTips,
      this.premiumAccess,
      this.start = NoteEditorStart.standard});
  final Note? note;
  final String? folderId;
  final NoteTemplate? template;

  /// A newly instantiated custom template, already owning its photo copies.
  final Note? customTemplateNote;
  final NoteAutosaveStore? autosaveStore;
  final NotePhotoCapture? photoCapture;
  final DocumentScanCapture? documentScanCapture;
  final NotePhotoEditService? photoEditService;
  final PhotoTextExtraction? photoTextExtraction;
  final VoiceMemoService? voiceMemoService;
  final VoiceMemoDrafts? voiceMemoDrafts;
  final NoteReminderScheduler? reminderScheduler;
  final WidgetCommands? widgetCommands;
  final NotePositionStore? positionStore;
  final NoteEditorTips? editorTips;
  final PremiumAccess? premiumAccess;
  final NoteEditorStart start;

  @override
  State<AddUpdateNoteScreen> createState() => _AddUpdateNoteScreenState();
}

class _AddUpdateNoteScreenState extends State<AddUpdateNoteScreen>
    with WidgetsBindingObserver, UndoManagerClient {
  late final TextEditingController _titleController;
  late final SimpleFormattingController _descriptionController;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _bodyFocus = FocusNode();
  final _editorFocusScope = FocusScopeNode();
  final _outlineController = NoteOutlineNavigationController();
  final _formattingController = NoteBodyFormattingController();
  bool _retryingSave = false;
  bool _formattingTipAvailable = false;
  bool _imageTipAvailable = false;
  bool _imageTipRelevant = false;
  Set<String> _knownImagePaths = {};
  final Set<NoteEditorTipKind> _seenTips = {};
  NoteEditorTips get _tips => widget.editorTips ?? NoteEditorTips.instance;
  late final NoteEditHistory _editHistory;
  Timer? _captureTimer;
  bool _replayingHistory = false;
  NoteEditSnapshot? _restoredEdit;
  int _restoreRevision = 0;
  final Map<String, TextSelection> _todoSelections = {};
  final Set<String> _composingTodoIds = {};
  List<NoteImageLayout> _currentImageLayouts = const [];
  late final AddUpdateFormBloc _form;
  late final NoteAutosave _autosave;
  late final StreamSubscription<AddUpdateFormState> _changes;
  late final NotePhotoCapture _photoCapture;
  late final DocumentScanCapture _documentScanCapture;
  late final NoteReminderScheduler _reminderScheduler;
  VoidCallback? _unregisterWidgetEditor;
  VoidCallback? _unregisterSelectionEditor;
  VoidCallback? _unregisterChecklistEditor;
  VoidCallback? _unregisterDesktopEditor;
  VoidCallback? _unregisterDesktopRefresh;
  final _desktopCommands = <VoidCallback>[];
  WidgetCommands? _editorWidgetCommands;
  bool _suspendedForLinkedNote = false;
  Timer? _suggestionDebounce;
  ReminderDateSuggestion? _reminderSuggestion;
  final Set<String> _dismissedSuggestions = {};
  String? _lastSuggestionText;
  bool _savingReminder = false;
  bool _presentingReminder = false;
  Animation<double>? _entryAnimation;
  bool _captureStarted = false;
  bool _addingPhoto = false;
  bool _presentingMedia = false;
  bool _extractingPhotoText = false;
  VoiceMemoDrafts? _recordingDrafts;
  Future<void> _voiceWrites = Future.value();
  int _voiceMutations = 0;
  bool _leaving = false;
  bool _allowPop = false;
  bool _hadUserChange = false;
  bool _refreshingFromLibrary = false;
  bool _recordedReviewSave = false;
  bool _statusRefreshQueued = false;
  bool _seedSaveDeferred = false;
  NoteSearchController? _findController;
  bool _writingFocused = false;
  bool _findInputComposing = false;
  final _titleNavigationKey = GlobalKey();
  final _todoNavigationKey = GlobalKey<_BuildTodoListFieldState>();
  Timer? _writingPositionTimer;
  int _writingInteraction = 0;
  bool _restoringWritingPosition = false;
  NoteWritingField? _lastWritingField;
  String? _lastWritingTodo;
  NoteEditSnapshot? _lastChecklistAddition;
  int? _lastChecklistUndoCount;
  List<String> _lastChecklistIds = const [];
  NotePositionStore get _positions =>
      widget.positionStore ?? NotePositionStore.instance;

  PremiumAccess get _creationAccess =>
      widget.premiumAccess ?? PremiumAccess.instance;

  bool get _newNoteBlocked {
    if (widget.note != null ||
        !_creationAccess.limitsApply ||
        !getIt.isRegistered<NoteRepository>()) {
      return false;
    }
    return !NoteCreationLimit.canSave(
        getIt<NoteRepository>(), _autosave.note.id,
        access: _creationAccess);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _photoCapture = widget.photoCapture ?? NotePhotoCapture();
    _documentScanCapture = widget.documentScanCapture ?? DocumentScanCapture();
    _reminderScheduler = widget.reminderScheduler ?? NoteReminderScheduler();
    final now = DateTime.now();
    final recovered =
        widget.note?.id == null || !Hive.isBoxOpen(draftDatabaseBox)
            ? null
            : Hive.box(draftDatabaseBox).get(widget.note!.id) as NoteDto?;
    final seed = recovered?.toDomain() ??
        widget.note ??
        widget.customTemplateNote ??
        widget.template
            ?.createNote(S.current, folderId: widget.folderId, now: now) ??
        Note(
          id: const Uuid().v4(),
          color: AppCardStyleSettings.instance.noteTheme == NoteTheme.classic
              ? colors.randomElement
              : null,
          dateTime: now,
          sortOrder: -now.millisecondsSinceEpoch,
          folderId: widget.folderId,
          todo: widget.start == NoteEditorStart.checklist
              ? [Todo.empty()]
              : const [],
        );
    final initial = seed.copyWith(
        cardStyle: widget.note?.cardStyle ?? seed.cardStyle,
        dailyNoteDateKey: widget.note != null
            ? widget.note!.dailyNoteDateKey
            : seed.dailyNoteDateKey,
        imageLayouts: normalizeNoteImageLayouts(
            seed.imageLayouts, seed.imagePaths, seed.description ?? ''));
    _currentImageLayouts = initial.imageLayouts;
    _titleController = TextEditingController(text: initial.title);
    _descriptionController = SimpleFormattingController(
        text: initial.description, styles: initial.textStyles);
    _editHistory = NoteEditHistory(
        initial: NoteEditSnapshot(
            note: initial.copyWith(
                title: _titleController.text,
                description: _descriptionController.text)))
      ..addListener(_refreshStatus);
    _autosave = NoteAutosave(
      store: widget.autosaveStore ??
          HiveNoteAutosaveStore(
              getIt<NoteRepository>(), Hive.box(draftDatabaseBox),
              premiumAccess: _creationAccess),
      initial: initial,
      exists: widget.note != null,
    )..addListener(_refreshStatus);
    _form = AddUpdateFormBloc.withState(
        context.read<AddUpdateBloc>(),
        AddUpdateFormState(
          title: initial.title,
          description: initial.description,
          textStyles: initial.textStyles,
          selectedColor: initial.color,
          todos: initial.todo,
          imagePaths: initial.imagePaths,
          imageLayouts: initial.imageLayouts,
          voiceMemos: initial.voiceMemos,
          tags: initial.tags,
          linkedNoteIds: initial.linkedNoteIds,
          sectionLinks: initial.sectionLinks,
          dailyNoteDateKey: initial.dailyNoteDateKey,
          cardStyle: initial.cardStyle,
        ));
    _knownImagePaths = initial.imagePaths.toSet();
    _formattingController.addListener(_refreshStatus);
    _changes = _form.stream.listen((state) {
      if (_refreshingFromLibrary || _replayingHistory) return;
      _currentImageLayouts = normalizeNoteImageLayouts(
          state.imageLayouts, state.imagePaths, _descriptionController.text);
      final todoIds = state.todos.map((todo) => todo.id).toSet();
      _composingTodoIds.retainWhere(todoIds.contains);
      _todoSelections.removeWhere((id, _) => !todoIds.contains(id));
      if (state.imagePaths.any((path) => !_knownImagePaths.contains(path))) {
        _imageTipRelevant = true;
      }
      _knownImagePaths = state.imagePaths.toSet();
      _hadUserChange = true;
      // A body edit can emit text and rebased photo anchors separately. Capture
      // their settled form together so one keystroke has one undo step.
      _captureTimer?.cancel();
      _captureTimer = Timer(Duration.zero, () {
        if (!mounted || _refreshingFromLibrary || _replayingHistory) return;
        _capture(_form.state);
        _queueReminderSuggestion();
      });
      _refreshStatus();
    });
    _descriptionController.addListener(_bodyChanged);
    _titleController.addListener(_selectionChanged);
    FocusManager.instance.addListener(_syncPlatformUndo);
    FocusManager.instance.addListener(_writingFocusChanged);
    _editorWidgetCommands =
        widget.widgetCommands ?? WidgetCommands.initializedInstance;
    _registerWidgetEditor();
    _unregisterSelectionEditor = NoteSelectionTransfer.registerEditor(
        _autosave.note.id!, _appendCopiedSelection);
    _unregisterChecklistEditor = NoteSelectionTransfer.registerChecklistEditor(
        _autosave.note.id!,
        add: _appendChecklistSelection,
        undo: _undoAddedChecklist);
    ReminderData.shared.addListener(_reminderChanged);
    _unregisterDesktopEditor =
        DesktopCommands.instance.registerEditor(_flushForDesktopExit);
    _unregisterDesktopRefresh = DesktopCommands.instance
        .registerEditorRefresh(_resumeAfterDesktopRoute);
    bool currentRoute() => mounted && ModalRoute.of(context)?.isCurrent == true;
    bool editingNote() =>
        currentRoute() && _editorFocusScope.hasFocus && _findController == null;
    _desktopCommands.addAll([
      DesktopCommands.instance.registerCommand(DesktopCommand.settings,
          invoke: () => unawaited(_openDesktopSettings()),
          isActive: currentRoute,
          isEnabled: () => !_editBlocked),
      DesktopCommands.instance.registerCommand(DesktopCommand.findInNote,
          invoke: _openFind,
          isActive: currentRoute,
          isEnabled: () => !_editBlocked),
      DesktopCommands.instance.registerCommand(DesktopCommand.undo,
          invoke: undo, isActive: editingNote, isEnabled: () => canUndo),
      DesktopCommands.instance.registerCommand(DesktopCommand.redo,
          invoke: redo, isActive: editingNote, isEnabled: () => canRedo),
    ]);
    _queueReminderSuggestion();
    if (recovered != null) _autosave.update(initial.copyWith(dateTime: now));
    if (widget.note == null &&
        (widget.template != null || widget.customTemplateNote != null)) {
      if (_newNoteBlocked) {
        _seedSaveDeferred = true;
      } else {
        _autosave.saveInitial();
      }
    }
    if (widget.note != null) unawaited(_restoreWritingPosition());
    unawaited(_loadTips());
  }

  Future<void> _loadTips() async {
    final available = await Future.wait([
      _tips.shouldShow(NoteEditorTipKind.formatting),
      _tips.shouldShow(NoteEditorTipKind.imageLayout),
    ]);
    if (!mounted) return;
    setState(() {
      _formattingTipAvailable = available[0];
      _imageTipAvailable = available[1];
    });
  }

  // Record a tip only after its relevant UI has been displayed. It stays
  // dismissible in this editor and is not offered again on later visits.
  void _recordTipSeen(NoteEditorTipKind kind) {
    if (!_seenTips.add(kind)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_tips.dismiss(kind));
    });
  }

  void _dismissTip(NoteEditorTipKind kind) {
    setState(() {
      if (kind == NoteEditorTipKind.formatting) {
        _formattingTipAvailable = false;
      } else {
        _imageTipAvailable = false;
      }
    });
    unawaited(_tips.dismiss(kind));
  }

  Future<void> _insert() async {
    if (_mediaBlocked || _findController != null) return;
    final action = await showAppSheet<NoteInsertAction>(
      context: context,
      builder: (_) => const NoteInsertSheet(),
    );
    if (!mounted || _mediaBlocked || action == null) return;
    switch (action) {
      case NoteInsertAction.divider:
        _formattingController.prepareFormattingSelection();
        if (_descriptionController.insertDivider()) {
          await WidgetsBinding.instance.endOfFrame;
          if (mounted) {
            await _outlineController
                .jumpTo(_descriptionController.selection.extentOffset);
          }
        }
      case NoteInsertAction.checklist:
        _todoNavigationKey.currentState?.addItem();
      case NoteInsertAction.gallery:
        await _addPhoto(ImageSource.gallery);
      case NoteInsertAction.camera:
        await _addPhoto(ImageSource.camera);
      case NoteInsertAction.scan:
        await _scanDocument();
      case NoteInsertAction.voice:
        await _recordVoiceMemo();
    }
  }

  void _writingGesture(PointerDownEvent _) => _writingInteraction++;

  void _writingFocusChanged() {
    if (!mounted ||
        _restoringWritingPosition ||
        !_editorFocusScope.hasFocus ||
        _replayingHistory ||
        _refreshingFromLibrary ||
        _suspendedForLinkedNote) {
      return;
    }
    final label = FocusManager.instance.primaryFocus?.debugLabel;
    if (_titleFocus.hasFocus) {
      _lastWritingField = NoteWritingField.title;
    } else if (_bodyFocus.hasFocus || label == 'note-body') {
      _lastWritingField = NoteWritingField.body;
    } else if (label?.startsWith('note-todo:') == true) {
      _lastWritingField = NoteWritingField.todo;
      _lastWritingTodo = label!.substring(10);
    } else {
      return;
    }
    _writingInteraction++;
    _writingPositionTimer?.cancel();
    _writingPositionTimer = Timer(const Duration(milliseconds: 250),
        () => unawaited(_rememberWritingPosition()));
  }

  Future<void> _rememberWritingPosition() async {
    _writingPositionTimer?.cancel();
    final field = _lastWritingField;
    if (field == null ||
        _restoringWritingPosition ||
        _suspendedForLinkedNote ||
        !NoteAutosave.hasContent(_currentDraft(_form.state))) {
      return;
    }
    String text;
    TextSelection selection;
    if (field == NoteWritingField.title) {
      text = _titleController.text;
      selection = _titleController.selection;
    } else if (field == NoteWritingField.todo) {
      final todo = _form.state.todos
          .where((item) => item.id == _lastWritingTodo)
          .firstOrNull;
      if (todo == null) return;
      text = todo.title ?? '';
      selection = _todoSelections[_lastWritingTodo] ??
          const TextSelection.collapsed(offset: 0);
    } else {
      text = _descriptionController.text;
      selection = _descriptionController.selection;
    }
    if (!selection.isValid) return;
    await _positions.saveWriting(
        _autosave.note.id!,
        NoteWritingPosition.capture(
            field: field,
            text: text,
            selection: selection,
            todoId: _lastWritingTodo,
            bodyText: _descriptionController.text,
            bodySelection: _descriptionController.selection));
  }

  Future<void> _restoreWritingPosition() async {
    final generation = _writingInteraction;
    bool allowed() =>
        mounted &&
        generation == _writingInteraction &&
        !_editorFocusScope.hasFocus &&
        !_editBlocked &&
        _findController == null;
    final saved = (await _positions.read(_autosave.note.id!)).writing;
    if (saved == null || !allowed()) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!allowed()) return;
    final resolved = saved.resolve(
        title: _titleController.text,
        body: _descriptionController.text,
        todos: {
          for (final item in _form.state.todos)
            if (item.id != null) item.id!: item.title ?? ''
        });
    _restoringWritingPosition = true;
    try {
      _lastWritingField = resolved.field;
      _lastWritingTodo = resolved.todoId;
      switch (resolved.field) {
        case NoteWritingField.title:
          _titleController.selection = resolved.selection;
          final target = _titleNavigationKey.currentContext;
          if (target != null && target.mounted && allowed()) {
            revealNoteTextOffset(target, resolved.selection.extentOffset,
                animate: false);
          }
        case NoteWritingField.body:
          await _outlineController.restoreTo(resolved.selection.extentOffset,
              canRestore: allowed);
          if (allowed()) _descriptionController.selection = resolved.selection;
        case NoteWritingField.todo:
          _todoSelections[resolved.todoId!] = resolved.selection;
          await _todoNavigationKey.currentState?.selectMatch(
              resolved.todoId!, resolved.selection,
              requestFocus: false, canRestore: allowed);
      }
    } finally {
      _restoringWritingPosition = false;
    }
  }

  void _showEditorMore() {
    var openingStyle = false;
    final strings = S.of(context);
    showAppActionSheet(context: context, title: strings.More_Options, actions: [
      AppSheetAction(
          section: strings.Note_Menu_Editing,
          leading: const Icon(Icons.palette_outlined),
          title: Text(S.of(context).Card_Style),
          onPressed: (sheetContext) async {
            if (openingStyle) return;
            openingStyle = true;
            final route = ModalRoute.of(sheetContext);
            Navigator.pop(sheetContext);
            await route?.completed;
            if (mounted) await _openCardStyle();
          }),
      if (MediaQuery.sizeOf(context).width < 260)
        AppSheetAction(
            section: strings.Note_Menu_Editing,
            leading: const Icon(Icons.search_rounded),
            title: Text(S.of(context).Find_In_Note),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              _openFind();
            }),
      if (MediaQuery.sizeOf(context).width < 260)
        AppSheetAction(
            section: strings.Note_Menu_Editing,
            leading: const Icon(Icons.check_rounded),
            title: Text(S.of(context).Done),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              _finish();
            }),
      AppSheetAction(
          section: strings.Note_Menu_Details,
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(S.of(context).Note_Info),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            final draft = _currentDraft(_form.state);
            // A new blank editor seeds its clock on opening; only show
            // existing metadata, seeded content, or an actual draft edit.
            final hasModificationMetadata = widget.note != null ||
                widget.template != null ||
                widget.customTemplateNote != null ||
                _hadUserChange;
            showNoteInfoSheet(
                context: context,
                statistics: NoteStatistics.fromNote(draft),
                folderName: noteFolderInfoName(draft.folderId),
                dailyNoteDateKey: draft.dailyNoteDateKey,
                modifiedAt: hasModificationMetadata ? draft.dateTime : null);
          }),
    ]);
  }

  Future<void> _openCardStyle() async {
    if (_mediaBlocked) return;
    setState(() => _presentingMedia = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await _voiceWrites;
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      final pendingChanges =
          _captureTimer?.isActive == true || _hadUserChange || _autosave.dirty;
      _captureTimer?.cancel();
      if (pendingChanges) _capture(_form.state);
      final route = MaterialPageRoute<void>(
        builder: (_) => CardAppearanceScreen(
          note: _currentDraft(_form.state),
          premiumAccess: _creationAccess,
          onSaveAppearance: (style, color) async {
            if (!mounted) throw StateError('The editor is no longer available');
            final previousStyle = _form.state.cardStyle;
            final previousColor = _form.state.selectedColor;
            final feature = requiredNoteStyleFeature(previousStyle, style);
            if (feature != null) _creationAccess.require(feature);
            try {
              await _applyCardAppearance(style, color);
              if (!await _autosave.flush()) {
                throw StateError('Could not save the card appearance');
              }
              if (mounted) _capture(_form.state);
            } catch (_) {
              // Failed staged edits must not enter a later typing save or
              // recovery draft if the user discards the appearance screen.
              if (mounted) {
                await _applyCardAppearance(previousStyle, previousColor);
                await _autosave.flush();
              }
              rethrow;
            }
          },
        ),
      );
      await Navigator.of(context).push(route);
      await route.completed;
    } finally {
      if (mounted) setState(() => _presentingMedia = false);
    }
  }

  Future<void> _applyCardAppearance(NoteCardStyle style, Color? color) async {
    if (_form.state.cardStyle != style || _form.state.selectedColor != color) {
      final updated = _form.stream.firstWhere(
          (state) => state.cardStyle == style && state.selectedColor == color);
      _form.add(AddUpdateFormEvent.appearanceChanged(style, color));
      await updated;
    }
    if (!mounted) throw StateError('The editor is no longer available');
    _captureTimer?.cancel();
    // Record the undo step only once persistence succeeds. Discarding a failed
    // save must not leave the staged color in the editor's undo history.
    final next = _currentDraft(_form.state);
    if (next != _autosave.note) {
      _autosave.update(next.copyWith(dateTime: DateTime.now()));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prepareCapture();
  }

  void _prepareCapture() {
    if (_newNoteBlocked) return;
    if ((widget.start != NoteEditorStart.photo &&
            widget.start != NoteEditorStart.voice) ||
        widget.note != null ||
        _captureStarted) {
      return;
    }
    _captureStarted = true;
    // UIKit needs the editor's presentation transition to finish before it
    // can present the camera. Rebuilds and resumes must not launch it twice.
    _entryAnimation = ModalRoute.of(context)?.animation;
    if (_entryAnimation != null &&
        _entryAnimation!.status != AnimationStatus.completed) {
      _entryAnimation!.addStatusListener(_onCaptureEntryStatus);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startCapture();
      });
    }
  }

  void _onCaptureEntryStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _entryAnimation?.removeStatusListener(_onCaptureEntryStatus);
    if (mounted) _startCapture();
  }

  void _startCapture() {
    if (_newNoteBlocked) {
      _captureStarted = false;
      return;
    }
    if (widget.start == NoteEditorStart.voice) {
      unawaited(_recordVoiceMemo());
    } else {
      unawaited(_addPhoto(ImageSource.camera));
    }
  }

  Future<void> _addPhoto(ImageSource source, {bool retry = false}) async {
    if (_addingPhoto ||
        _presentingMedia ||
        _savingReminder ||
        _presentingReminder ||
        _leaving) {
      return;
    }
    setState(() => _addingPhoto = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      if (!await _autosave.flush()) {
        throw StateError(
            'Current draft could not be saved before photo capture');
      }
      await _photoCapture.prepare(_autosave.note);
      final result = await (retry
          ? _photoCapture.retryMany()
          : _photoCapture.captureMany(source));
      if (!mounted) {
        if (!_photoCapture.isJournaled) {
          await ImageStorage.deleteImages(result.savedPaths);
        }
        return;
      }
      if (result.savedPaths.isNotEmpty) {
        final offset = _descriptionController.selection.isValid
            ? _descriptionController.selection.extentOffset
            : null;
        for (final path in result.savedPaths) {
          if (!_form.state.imagePaths.contains(path)) {
            _form.add(AddUpdateFormEvent.addImage(path, textOffset: offset));
          }
        }
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return;
        _capture(_form.state);
        if (await _autosave.flush()) {
          await _photoCapture.complete();
        } else if (mounted) {
          showTransientSnackBar(
              context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
        }
      }
      if (result.error != null) throw result.error!;
    } catch (error) {
      if (!mounted) return;
      showTransientSnackBar(
        context,
        SnackBar(
          content: Text(S.of(context).Photo_Capture_Failed),
          action: _photoCapture.canRetry
              ? SnackBarAction(
                  label: S.of(context).Retry,
                  onPressed: () => _addPhoto(source, retry: true),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _addingPhoto = false);
    }
  }

  Future<void> _scanDocument({bool retry = false}) async {
    if (_mediaBlocked) return;
    setState(() => _addingPhoto = true);
    final selection = _descriptionController.selection;
    final offset = selection.isValid ? selection.extentOffset : null;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      // Save the latest form events before recording the scanner's origin.
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      _capture(_form.state);
      if (!await _autosave.flush()) {
        if (mounted) {
          showTransientSnackBar(
              context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
        }
        return;
      }
      final result = await (retry
          ? _documentScanCapture.retry()
          : _documentScanCapture.scan(_autosave.note));
      if (!mounted) return;
      if (result.savedPaths.isNotEmpty) {
        final updated = appendScannedPages(
            _currentDraft(_form.state), result.savedPaths,
            textOffset: offset);
        // Wait for adoption before flushing; a native callback can arrive
        // while the editor has queued another field event.
        final adopted = _form.stream.firstWhere((state) =>
            listEquals(state.imagePaths, updated.imagePaths) &&
            listEquals(state.imageLayouts, updated.imageLayouts));
        _currentImageLayouts = updated.imageLayouts;
        _form.add(AddUpdateFormEvent.initialize(
          title: updated.title,
          description: updated.description,
          textStyles: updated.textStyles,
          color: updated.color,
          todos: updated.todo,
          imagePaths: updated.imagePaths,
          imageLayouts: updated.imageLayouts,
          voiceMemos: updated.voiceMemos,
          tags: updated.tags,
          linkedNoteIds: updated.linkedNoteIds,
          sectionLinks: updated.sectionLinks,
          dailyNoteDateKey: updated.dailyNoteDateKey,
          cardStyle: updated.cardStyle,
        ));
        await adopted;
        if (!mounted) return;
        _capture(_form.state);
        if (!await _autosave.flush()) {
          if (mounted) {
            showTransientSnackBar(context,
                SnackBar(content: Text(S.of(context).Autosave_Failed)));
          }
          return;
        }
      }
      if (result.status == DocumentScanStatus.pages) {
        if (result.error != null) throw result.error!;
        await _documentScanCapture.complete();
      } else if (result.status != DocumentScanStatus.cancelled) {
        if (mounted) _showScanMessage(result.status);
      }
    } catch (_) {
      if (mounted) _showScanMessage(DocumentScanStatus.failed);
    } finally {
      if (mounted) setState(() => _addingPhoto = false);
    }
  }

  void _showScanMessage(DocumentScanStatus status) {
    final strings = S.of(context);
    final message = switch (status) {
      DocumentScanStatus.unsupported => strings.Document_Scan_Unsupported,
      DocumentScanStatus.permissionDenied => strings.Document_Scan_Permission,
      DocumentScanStatus.tooManyPages => strings.Document_Scan_Too_Many,
      DocumentScanStatus.pending => strings.Document_Scan_Pending,
      _ => strings.Document_Scan_Failed,
    };
    showTransientSnackBar(
        context,
        SnackBar(
          content: Text(message),
          action: _documentScanCapture.isJournaled
              ? SnackBarAction(
                  label: strings.Retry,
                  onPressed: () => _scanDocument(retry: true),
                )
              : null,
        ));
  }

  void _bodyChanged() {
    if (_refreshingFromLibrary ||
        _replayingHistory ||
        !mounted ||
        _form.isClosed) {
      return;
    }
    _writingFocusChanged();
    final text = _descriptionController.text;
    final styles = _descriptionController.styles;
    if ((_form.state.description ?? '') == text &&
        listEquals(_form.state.textStyles, styles) &&
        listEquals(_form.state.imageLayouts, _currentImageLayouts)) {
      _selectionChanged();
      return;
    }
    _form.add(
        AddUpdateFormEvent.bodyChanged(text, styles, _currentImageLayouts));
  }

  void _imageLayoutsChanged(List<NoteImageLayout> layouts) {
    if (_refreshingFromLibrary ||
        _replayingHistory ||
        !mounted ||
        _form.isClosed ||
        listEquals(_currentImageLayouts, layouts)) {
      return;
    }
    _currentImageLayouts = layouts;
    _form.add(AddUpdateFormEvent.imageLayoutsChanged(layouts));
  }

  Future<void> _removeInlineImage(String path) async {
    if (_mediaBlocked || !_form.state.imagePaths.contains(path)) return;
    setState(() => _presentingMedia = true);
    try {
      // A reviewed page may still be held by an interrupted scan. Record the
      // explicit removal before changing the form so recovery respects it.
      await _documentScanCapture.discardPage(path);
      if (!mounted || !_form.state.imagePaths.contains(path)) return;
      _currentImageLayouts =
          _currentImageLayouts.where((layout) => layout.path != path).toList();
      _form.add(AddUpdateFormEvent.removeImage(path));
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
      }
    } finally {
      if (mounted) setState(() => _presentingMedia = false);
    }
  }

  Future<void> _editPhoto(String path) async {
    if (_mediaBlocked || !_form.state.imagePaths.contains(path)) return;
    setState(() => _presentingMedia = true);
    FocusManager.instance.primaryFocus?.unfocus();
    ui.Image? image;
    NoteEditedPhoto? edited;
    var adopted = false;
    try {
      if (!await _autosave.flush()) {
        throw StateError('The current draft could not be saved');
      }
      final service = widget.photoEditService ?? const NotePhotoEditService();
      image = await service.load(path);
      if (!mounted) return;
      edited = await showDialog<NoteEditedPhoto>(
        context: context,
        barrierDismissible: false,
        builder: (_) => NotePhotoEditor(
          image: image!,
          save: service.save,
        ),
      );
      if (edited == null || !mounted) return;
      if (!_form.state.imagePaths.contains(path)) return;
      await _documentScanCapture.discardPage(path);
      if (!mounted || !_form.state.imagePaths.contains(path)) return;
      _currentImageLayouts = [
        for (final layout in _currentImageLayouts)
          layout.path == path
              ? layout.copyWith(
                  path: edited.path, aspectRatio: edited.aspectRatio)
              : layout,
      ];
      _form.add(AddUpdateFormEvent.replaceImage(
        oldPath: path,
        newPath: edited.path,
        aspectRatio: edited.aspectRatio,
      ));
      adopted = true;
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      _capture(_form.state);
      if (!await _autosave.flush() && mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
      }
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Photo_Edit_Failed)));
      }
    } finally {
      image?.dispose();
      if (edited != null && !adopted && edited.path != path) {
        await ImageStorage.deleteImages([edited.path]);
      }
      if (mounted) setState(() => _presentingMedia = false);
    }
  }

  void _openFind() {
    if (_editBlocked || _findController != null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = NoteSearchController();
    controller.setFields(noteSearchFields(_currentDraft(_form.state)),
        notify: false);
    final selection = _descriptionController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final selected =
          _descriptionController.text.substring(selection.start, selection.end);
      if (selected.length <= 80) controller.setQuery(selected);
    }
    _editHistory.breakCoalescing();
    setState(() => _findController = controller);
    _syncPlatformUndo();
  }

  void _closeFind() {
    final controller = _findController;
    if (controller == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _findController = null;
      _findInputComposing = false;
    });
    controller.dispose();
    _syncPlatformUndo();
  }

  void _findCompositionChanged(bool value) {
    _findInputComposing = value;
    _refreshStatus();
  }

  void _toggleWritingFocus() {
    if (_mediaBlocked) return;
    setState(() => _writingFocused = !_writingFocused);
  }

  Note _currentDraft(AddUpdateFormState state) => _autosave.note.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        textStyles: _descriptionController.styles,
        color: state.selectedColor,
        todo: state.todos,
        imagePaths: state.imagePaths,
        imageLayouts: _currentImageLayouts,
        voiceMemos: state.voiceMemos,
        tags: state.tags,
        linkedNoteIds: state.linkedNoteIds,
        sectionLinks: state.sectionLinks,
        cardStyle: state.cardStyle,
      );

  void _capture(AddUpdateFormState state) {
    if (_newNoteBlocked) return;
    if (_replayingHistory) return;
    final next = _currentDraft(state);
    final previous = _editHistory.current.note;
    final kind = _editKind(previous, next);
    final changedTodo = kind == NoteEditKind.todoTyping
        ? next.todo
            .firstWhere((todo) => previous.todo
                .any((old) => old.id == todo.id && old.title != todo.title))
            .id
        : null;
    _editHistory.record(_editSnapshot(next, focusedTodo: changedTodo),
        kind: kind, fieldId: changedTodo);
    if (next != _autosave.note) {
      _autosave.update(next.copyWith(dateTime: DateTime.now()));
    }
  }

  NoteEditSnapshot _editSnapshot(Note note, {String? focusedTodo}) =>
      NoteEditSnapshot(
        note: note,
        titleSelection: _titleController.selection,
        bodySelection: _descriptionController.selection,
        todoSelections: _todoSelections,
        focusedField: focusedTodo ??
            (_titleFocus.hasFocus
                ? 'title'
                : FocusManager.instance.primaryFocus?.debugLabel
                            ?.startsWith('note-todo:') ==
                        true
                    ? FocusManager.instance.primaryFocus!.debugLabel!
                        .substring(10)
                    : _bodyFocus.hasFocus ||
                            FocusManager.instance.primaryFocus?.debugLabel ==
                                'note-body'
                        ? 'body'
                        : null),
      );

  void _todoInputChanged(String id, TextEditingValue value) {
    _todoSelections[id] = value.selection;
    if (value.composing.isValid && !value.composing.isCollapsed) {
      _composingTodoIds.add(id);
    } else {
      _composingTodoIds.remove(id);
    }
    if (_replayingHistory || _refreshingFromLibrary || !mounted) return;
    _writingFocusChanged();
    if (_form.state.todos
        .any((todo) => todo.id == id && (todo.title ?? '') == value.text)) {
      _selectionChanged();
    } else {
      _refreshStatus();
    }
  }

  void _selectionChanged() {
    if (!mounted || _replayingHistory || _refreshingFromLibrary) return;
    _writingFocusChanged();
    // Cursor movement updates the live snapshot without adding a content step.
    // A pending text event still needs its preceding snapshot for undo.
    if ((_editHistory.current.note.title ?? '') == _titleController.text &&
        (_editHistory.current.note.description ?? '') ==
            _descriptionController.text &&
        listEquals(_editHistory.current.note.textStyles,
            _descriptionController.styles)) {
      _editHistory.record(_editSnapshot(_editHistory.current.note));
    }
    _refreshStatus();
  }

  NoteEditKind _editKind(Note previous, Note next) {
    if (previous.title != next.title) return NoteEditKind.titleTyping;
    if (previous.description != next.description) {
      return NoteEditKind.bodyTyping;
    }
    if (previous.todo.length == next.todo.length) {
      final changed = [
        for (var i = 0; i < next.todo.length; i++)
          if (previous.todo[i] != next.todo[i]) i,
      ];
      if (changed.length == 1) {
        final old = previous.todo[changed.single];
        final current = next.todo[changed.single];
        if (old.id == current.id &&
            old.completed == current.completed &&
            old.title != current.title) {
          return NoteEditKind.todoTyping;
        }
      }
    }
    return NoteEditKind.discrete;
  }

  bool get _editBlocked =>
      _mediaBlocked ||
      _replayingHistory ||
      _composingTodoIds.isNotEmpty ||
      _suspendedForLinkedNote ||
      (_titleController.value.composing.isValid &&
          !_titleController.value.composing.isCollapsed) ||
      (_descriptionController.value.composing.isValid &&
          !_descriptionController.value.composing.isCollapsed);

  bool get _historyBlocked => _editBlocked || _findController != null;

  Future<void> _restoreHistory(
      {required bool redo, bool allowFind = false}) async {
    if (allowFind ? _editBlocked : _historyBlocked) return;
    setState(() => _replayingHistory = true);
    // Drain input before moving the history pointer, keeping rapid taps atomic.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    _replayingHistory = false;
    _capture(_form.state);
    _replayingHistory = true;
    final before = _editSnapshot(_currentDraft(_form.state));
    final restored = redo ? _editHistory.redo() : _editHistory.undo();
    if (restored == null) {
      setState(() => _replayingHistory = false);
      return;
    }
    final next = restored.applyTo(_autosave.note);
    // Pointer blocking alone does not stop an attached hardware keyboard or
    // IME from sending input while a scan intent is being written.
    if (!allowFind) FocusManager.instance.primaryFocus?.unfocus();
    var appliedToForm = false;
    try {
      await _applyEditSnapshot(restored, next, restoreFocus: !allowFind);
      appliedToForm = true;
      if (!await _autosave.flush() && mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
      }
    } catch (_) {
      // Journal storage can fail before the form changes. Retain the previous
      // pointer so Retry/Undo still refers to the edit the user is seeing.
      if (!appliedToForm) {
        redo ? _editHistory.undo() : _editHistory.redo();
        try {
          await _documentScanCapture.reconcilePages(before.note.imagePaths);
        } catch (_) {
          // The retained journal will retry when storage becomes available.
        }
      }
      if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
      }
    } finally {
      if (mounted) {
        setState(() => _replayingHistory = false);
        _syncPlatformUndo();
      }
    }
  }

  /// Applies one complete note without recording intermediate field events.
  /// Callers retain the history snapshot before updating autosave ownership.
  Future<void> _applyEditSnapshot(NoteEditSnapshot restored, Note next,
      {bool restoreFocus = true, bool reconcilePages = true}) async {
    if (reconcilePages) {
      await _documentScanCapture.reconcilePages(next.imagePaths);
    }
    if (!mounted) return;
    _currentImageLayouts = next.imageLayouts;
    _titleController.value = TextEditingValue(
        text: next.title ?? '',
        selection: _safeSelection(restored.titleSelection, next.title ?? ''));
    _descriptionController.setDocument(next.description ?? '', next.textStyles);
    _descriptionController.selection =
        _safeSelection(restored.bodySelection, next.description ?? '');
    final state = AddUpdateFormState(
        title: next.title,
        description: next.description,
        textStyles: next.textStyles,
        selectedColor: next.color,
        todos: next.todo,
        imagePaths: next.imagePaths,
        imageLayouts: next.imageLayouts,
        voiceMemos: next.voiceMemos,
        tags: next.tags,
        linkedNoteIds: next.linkedNoteIds,
        sectionLinks: next.sectionLinks,
        dailyNoteDateKey: next.dailyNoteDateKey,
        cardStyle: next.cardStyle);
    if (_form.state != state) {
      final applied = _form.stream.firstWhere((value) => value == state);
      _form.add(AddUpdateFormEvent.initialize(
          title: next.title,
          description: next.description,
          textStyles: next.textStyles,
          color: next.color,
          todos: next.todo,
          imagePaths: next.imagePaths,
          imageLayouts: next.imageLayouts,
          voiceMemos: next.voiceMemos,
          tags: next.tags,
          linkedNoteIds: next.linkedNoteIds,
          sectionLinks: next.sectionLinks,
          dailyNoteDateKey: next.dailyNoteDateKey,
          cardStyle: next.cardStyle));
      await applied;
    }
    if (!mounted) return;
    _restoredEdit = restoreFocus ? restored : NoteEditSnapshot(note: next);
    _restoreRevision++;
    _hadUserChange = true;
    final todoIds = state.todos.map((todo) => todo.id).toSet();
    _composingTodoIds.retainWhere(todoIds.contains);
    _todoSelections.removeWhere((id, _) => !todoIds.contains(id));
    _autosave.update(next.copyWith(dateTime: DateTime.now()));
    _queueReminderSuggestion();
    setState(() {});
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (restoreFocus && restored.focusedField == 'title') {
      _titleFocus.requestFocus();
    } else if (restoreFocus && restored.focusedField == 'body') {
      final selection = _descriptionController.selection;
      await _outlineController.jumpTo(selection.extentOffset);
      if (mounted) _descriptionController.selection = selection;
    }
  }

  Future<void> _replaceFind(String replacement,
      {NoteSearchMatch? match}) async {
    final finder = _findController;
    if (_editBlocked || _findInputComposing || finder == null) return;
    final expected = finder.fields;
    final query = finder.query;
    setState(() => _replayingHistory = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    _replayingHistory = false;
    _capture(_form.state);
    _replayingHistory = true;
    try {
      if (!identical(finder, _findController)) return;
      final result = replaceNoteText(_currentDraft(_form.state),
          query: query,
          replacement: replacement,
          match: match,
          expectedFields: expected);
      if (result.failure != null) {
        showTransientSnackBar(
            context,
            SnackBar(
                content: Text(result.failure == NoteReplaceFailure.lengthLimit
                    ? S.of(context).Find_Replace_Limit
                    : S.of(context).Find_Replace_Changed)));
        return;
      }
      if (!result.changed) return;
      final snapshot = NoteEditSnapshot(note: result.note);
      _editHistory.record(snapshot);
      await _applyEditSnapshot(snapshot, result.note,
          restoreFocus: false, reconcilePages: false);
      if (!mounted) return;
      finder.setFields(noteSearchFields(result.note));
      final saved = await _autosave.flush();
      if (!mounted) return;
      showTransientSnackBar(
          context,
          SnackBar(
              content: Text(saved
                  ? S.of(context).Find_Replaced(result.replacedCount)
                  : S.of(context).Autosave_Failed),
              action: SnackBarAction(
                  label: S.of(context).Note_Undo,
                  onPressed: () {
                    if (_editHistory.current.sameContent(snapshot)) {
                      unawaited(_restoreHistory(redo: false, allowFind: true));
                    }
                  })));
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
      }
    } finally {
      if (mounted) {
        setState(() => _replayingHistory = false);
        _syncPlatformUndo();
      }
    }
  }

  Future<void> _editFindMatch(NoteSearchMatch match) async {
    final finder = _findController;
    if (_editBlocked || _findInputComposing || finder == null) return;
    // A search result must still refer to the displayed literal text.
    await Future<void>.delayed(Duration.zero);
    if (!mounted || !identical(finder, _findController)) return;
    final current = _currentDraft(_form.state);
    if (!findNoteMatches(noteSearchFields(current), finder.query)
        .contains(match)) {
      return;
    }
    final selection =
        TextSelection(baseOffset: match.start, extentOffset: match.end);
    _closeFind();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (match.fieldId == 'title') {
      _titleController.selection =
          _safeSelection(selection, _titleController.text);
      _titleFocus.requestFocus();
      final fieldContext = _titleNavigationKey.currentContext;
      if (fieldContext != null && fieldContext.mounted) {
        revealNoteTextOffset(fieldContext, match.start);
      }
    } else if (match.fieldId == 'body') {
      await _outlineController.jumpTo(match.start);
      if (mounted) _descriptionController.selection = selection;
    } else if (match.fieldId.startsWith('todo:')) {
      final id = match.fieldId.substring(5);
      await _todoNavigationKey.currentState?.selectMatch(id, selection);
    } else if (match.fieldId.startsWith('voice:')) {
      final id = match.fieldId.substring(6);
      final memo =
          current.voiceMemos.where((memo) => memo.id == id).firstOrNull;
      if (!mounted || memo == null) return;
      final changed = await showVoiceTranscriptEditor(context,
          initial: memo.transcript ?? '', selection: selection);
      if (!mounted || changed == null) return;
      try {
        await _editVoiceTranscript(memo, changed.isEmpty ? null : changed);
      } catch (_) {
        if (mounted) {
          showTransientSnackBar(context,
              SnackBar(content: Text(S.of(context).Voice_Save_Failed)));
        }
      }
    }
  }

  TextSelection _safeSelection(TextSelection? selection, String text) {
    if (selection == null || !selection.isValid) {
      return TextSelection.collapsed(offset: text.length);
    }
    return TextSelection(
      baseOffset: selection.baseOffset.clamp(0, text.length),
      extentOffset: selection.extentOffset.clamp(0, text.length),
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );
  }

  Future<void> _openOutline() async {
    if (_historyBlocked) return;
    _editHistory.breakCoalescing();
    final entries = buildNoteOutline(
        _descriptionController.text, _descriptionController.styles);
    final entry = await showNoteOutlineSheet(
        context: context,
        entries: entries,
        currentOffset: _descriptionController.selection.extentOffset);
    if (mounted && entry != null) await _outlineController.jumpTo(entry.start);
  }

  AudioStorage get _audio =>
      widget.voiceMemoDrafts?.audio ?? AudioStorage.instance;

  VoiceMemoDrafts get _voiceDrafts =>
      _recordingDrafts ??= widget.voiceMemoDrafts ??
          VoiceMemoDrafts(
            journal: Hive.box(draftDatabaseBox),
            notes: getIt<NoteRepository>(),
            audio: _audio,
            readDuration:
                (widget.voiceMemoService ?? VoiceMemoService.instance).duration,
          );

  bool get _mediaBlocked =>
      _replayingHistory ||
      _presentingMedia ||
      _voiceMutations > 0 ||
      _addingPhoto ||
      _savingReminder ||
      _presentingReminder ||
      _leaving ||
      _retryingSave;

  Future<void> _extractPhotoText() async {
    if (_mediaBlocked || _form.state.imagePaths.isEmpty) return;
    _editHistory.breakCoalescing();
    setState(() => _presentingMedia = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final paths = List<String>.of(_form.state.imagePaths);
      final path = paths.length == 1
          ? paths.single
          : await showAppSheet<String>(
              context: context,
              builder: (sheetContext) => AppSheet(
                title: S.of(sheetContext).Photo_Text_Choose,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (index, path) in paths.indexed)
                      ListTile(
                        leading: NoteImage(path: path, width: 48, height: 48),
                        title: Text(
                            S.of(sheetContext).Photo_Text_Photo(index + 1)),
                        onTap: () => Navigator.pop(sheetContext, path),
                      ),
                  ],
                ),
              ),
            );
      if (path == null || !mounted) return;
      setState(() => _extractingPhotoText = true);
      final result = await (widget.photoTextExtraction ?? PhotoTextExtraction())
          .extract(path);
      if (!mounted) return;
      setState(() => _extractingPhotoText = false);
      if (result.status != PhotoTextStatus.text) {
        final strings = S.of(context);
        final message = switch (result.status) {
          PhotoTextStatus.noText => strings.Photo_Text_No_Text,
          PhotoTextStatus.unsupported => strings.Photo_Text_Unsupported,
          _ => strings.Photo_Text_Failed,
        };
        showTransientSnackBar(context, SnackBar(content: Text(message)));
        return;
      }
      final text = await showAppSheet<String>(
          context: context,
          builder: (_) => PhotoTextReviewSheet(text: result.text));
      if (text == null || text.trim().isEmpty || !mounted) return;
      // Append to the latest editor text so recognition never replaces typing.
      _editHistory.breakCoalescing();
      final previous = _descriptionController.text;
      final retained = previous.trimRight();
      final styles =
          normalizeNoteTextStyles(_descriptionController.styles, retained);
      final updated =
          '$retained${previous.trim().isEmpty ? '' : '\n\n'}${text.trim()}';
      _imageLayoutsChanged(normalizeNoteImageLayouts(
          normalizeNoteImageLayouts(
              _currentImageLayouts, _form.state.imagePaths, retained),
          _form.state.imagePaths,
          updated));
      _descriptionController.setDocument(updated, styles);
      _descriptionController.selection =
          TextSelection.collapsed(offset: updated.length);
      await Future<void>.delayed(Duration.zero);
      _capture(_form.state);
      final saved = await _autosave.flush();
      if (mounted) {
        showTransientSnackBar(
            context,
            SnackBar(
                content: Text(saved
                    ? S.of(context).Photo_Text_Insert_Done
                    : S.of(context).Autosave_Failed)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _presentingMedia = false;
          _extractingPhotoText = false;
        });
      }
    }
  }

  Future<void> _setVoiceMemos(List<VoiceMemo> memos) async {
    if (listEquals(_form.state.voiceMemos, memos)) return;
    final applied =
        _form.stream.firstWhere((state) => listEquals(state.voiceMemos, memos));
    _form.add(AddUpdateFormEvent.voiceMemosChanged(memos));
    await applied;
    _capture(_form.state);
  }

  Future<T> _serializeVoiceChange<T>(Future<T> Function() change) {
    if (_leaving) return Future.error(StateError('Editor is closing'));
    _voiceMutations++;
    if (mounted) setState(() {});
    final result = _voiceWrites.then<T>((_) {
      if (!mounted) throw StateError('Editor is closed');
      return change();
    });
    _voiceWrites =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result.whenComplete(() {
      _voiceMutations--;
      if (mounted) setState(() {});
    });
  }

  Future<VoiceMemo> _saveVoiceDraft(VoiceMemo memo) =>
      _serializeVoiceChange(() async {
        await _voiceDrafts.retain(memo);
        await Future<void>.delayed(Duration.zero);
        await _setVoiceMemos([
          for (final existing in _form.state.voiceMemos)
            if (existing.id != memo.id) existing,
          memo,
        ]);
        if (!await _autosave.flush()) throw StateError('Recording save failed');
        try {
          await _voiceDrafts.complete(memo);
        } catch (error) {
          // The note already owns the recording; startup can clear its journal.
          debugPrint('Recording journal cleanup deferred: $error');
        }
        return memo;
      });

  Future<void> _discardVoiceDraft(VoiceMemo memo) =>
      _serializeVoiceChange(() async {
        if (_form.state.voiceMemos.any((existing) => existing.id == memo.id)) {
          await _setVoiceMemos(_form.state.voiceMemos
              .where((existing) => existing.id != memo.id)
              .toList());
          if (!await _autosave.flush()) {
            throw StateError('Recording discard failed');
          }
        }
        await _voiceDrafts.discard(memo);
      });

  Future<void> _recordVoiceMemo() async {
    if (_mediaBlocked) return;
    setState(() => _presentingMedia = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      if (!await ensurePremiumAccess(context, PremiumFeature.voiceMemos,
              access: widget.premiumAccess) ||
          !mounted) {
        return;
      }
      await Future<void>.delayed(Duration.zero);
      _capture(_form.state);
      if (!await _autosave.flush()) throw StateError('Draft save failed');
      if (!mounted) return;
      await showVoiceMemoComposer(
        context,
        service: widget.voiceMemoService,
        createDraft: () => _voiceDrafts.prepare(_autosave.note),
        resolvePath: _audio.resolvePath,
        retainDraft: (memo) => _voiceDrafts.retain(memo),
        saveDraft: _saveVoiceDraft,
        discardDraft: _discardVoiceDraft,
      );
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Voice_Save_Failed)));
      }
    } finally {
      if (mounted) setState(() => _presentingMedia = false);
    }
  }

  Future<void> _removeVoiceMemo(VoiceMemo memo) =>
      _serializeVoiceChange(() async {
        final before = List<VoiceMemo>.of(_form.state.voiceMemos);
        await _setVoiceMemos(
            before.where((existing) => existing.id != memo.id).toList());
        if (!await _autosave.flush()) {
          await _setVoiceMemos(before);
          throw StateError('Recording removal failed');
        }
        await NoteCleanup.deleteUnreferencedAudio([memo.path],
            repository:
                widget.voiceMemoDrafts?.notes ?? getIt<NoteRepository>(),
            audio: _audio);
      });

  Future<void> _editVoiceTranscript(VoiceMemo memo, String? text) =>
      _serializeVoiceChange(() async {
        await _setVoiceMemos([
          for (final existing in _form.state.voiceMemos)
            if (existing.id == memo.id)
              existing.copyWith(transcript: text, clearTranscript: text == null)
            else
              existing,
        ]);
        if (!await _autosave.flush()) {
          throw StateError('Transcript save failed');
        }
      });

  String get _reminderText => [
        _titleController.text,
        _descriptionController.text,
        ..._form.state.todos.map((todo) => todo.title ?? ''),
        ..._form.state.voiceMemos.map((memo) => memo.transcript ?? ''),
      ].join('\n');

  void _reminderChanged() => _queueReminderSuggestion(force: true);

  void _queueReminderSuggestion({bool force = false}) {
    final text = _reminderText;
    if (!force && text == _lastSuggestionText) return;
    _lastSuggestionText = text;
    _suggestionDebounce?.cancel();
    _suggestionDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final suggestion = _findReminderSuggestion();
      setState(() => _reminderSuggestion = suggestion);
    });
  }

  ReminderDateSuggestion? _findReminderSuggestion() {
    final suggestion = suggestReminderDate(_reminderText, now: DateTime.now());
    if (suggestion == null || _dismissedSuggestions.contains(suggestion.key)) {
      return null;
    }
    final current = _reminderScheduler.current(_autosave.note);
    if (current?.repeat == ReminderRepeat.none) {
      final date = current!.reminderDate.toLocal();
      final suggested = suggestion.date;
      if (date.year == suggested.year &&
          date.month == suggested.month &&
          date.day == suggested.day &&
          date.hour == suggested.hour &&
          date.minute == suggested.minute) {
        return null;
      }
    }
    return suggestion;
  }

  void _dismissReminderSuggestion() {
    final suggestion = _reminderSuggestion;
    if (suggestion == null || _savingReminder) return;
    _dismissedSuggestions.add(suggestion.key);
    setState(() => _reminderSuggestion = null);
  }

  Future<void> _confirmReminderSuggestion() async {
    if (_savingReminder ||
        _presentingReminder ||
        _addingPhoto ||
        _presentingMedia ||
        _leaving) {
      return;
    }
    // The last keystroke may precede the debounce. Never open a stale date.
    final suggestion = _findReminderSuggestion();
    if (suggestion == null || suggestion.key != _reminderSuggestion?.key) {
      setState(() => _reminderSuggestion = suggestion);
      return;
    }
    setState(() => _presentingReminder = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final result = await showAppSheet<ReminderPickerResult>(
        context: context,
        builder: (_) => ReminderPickerSheet(
          current: _reminderScheduler.current(_autosave.note),
          suggestedDate: suggestion.date,
          allowDelete: false,
        ),
      );
      if (result == null || result.delete || !mounted) return;
      setState(() {
        _presentingReminder = false;
        _savingReminder = true;
      });
      // Save the meaningful draft first. Scheduling cannot create a reminder
      // for content that failed to reach the notes database.
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      _capture(_form.state);
      if (!NoteAutosave.hasContent(_autosave.note) ||
          !await _autosave.flush()) {
        if (mounted) {
          showTransientSnackBar(
              context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
        }
        return;
      }
      if (!mounted) return;
      final outcome = await _reminderScheduler.save(
          context, _autosave.note, result.date!, result.repeat);
      if (!mounted) return;
      switch (outcome) {
        case NoteReminderSaveResult.saved:
          _dismissedSuggestions.add(suggestion.key);
          setState(() => _reminderSuggestion = null);
          showTransientSnackBar(
              context, SnackBar(content: Text(S.of(context).Reminder_Saved)));
        case NoteReminderSaveResult.failed:
          showTransientSnackBar(context,
              SnackBar(content: Text(S.of(context).Reminder_Save_Failed)));
        case NoteReminderSaveResult.past:
          showTransientSnackBar(context,
              SnackBar(content: Text(S.of(context).Reminder_Future_Time)));
        case NoteReminderSaveResult.denied:
          break;
      }
    } finally {
      _savingReminder = false;
      _presentingReminder = false;
      if (mounted) setState(() {});
    }
  }

  List<Note> get _libraryNotes {
    final notes = getIt.isRegistered<NoteRepository>()
        ? getIt<NoteRepository>()
            .getAllNotes()
            .map((note) => note.toDomain())
            .toList()
        : <Note>[];
    return [
      for (final note in notes)
        if (note.id != _autosave.note.id) note,
      _currentDraft(_form.state)
    ];
  }

  Future<void> _editTags() async {
    if (_mediaBlocked) return;
    setState(() => _presentingMedia = true);
    try {
      final tags = await showNoteTagsSheet(context,
          tags: _form.state.tags,
          suggestions: [
            for (final note in _libraryNotes)
              if (!note.isDeleted) ...note.tags
          ]);
      if (!mounted || tags == null || listEquals(tags, _form.state.tags)) {
        return;
      }
      final applied =
          _form.stream.firstWhere((state) => listEquals(state.tags, tags));
      _form.add(AddUpdateFormEvent.tagsChanged(tags));
      await applied;
    } finally {
      if (mounted) setState(() => _presentingMedia = false);
    }
  }

  Future<void> _editLinks() async {
    if (_mediaBlocked) return;
    setState(() => _presentingMedia = true);
    try {
      final ids = await showNoteLinkPickerSheet(context,
          currentNoteId: _autosave.note.id!,
          selectedIds: _form.state.linkedNoteIds,
          notes: _libraryNotes);
      if (!mounted ||
          ids == null ||
          listEquals(ids, _form.state.linkedNoteIds)) {
        return;
      }
      final applied = _form.stream
          .firstWhere((state) => listEquals(state.linkedNoteIds, ids));
      _form.add(AddUpdateFormEvent.linksChanged(ids));
      await applied;
    } finally {
      if (mounted) setState(() => _presentingMedia = false);
    }
  }

  void _registerWidgetEditor() {
    if (_unregisterWidgetEditor != null || _autosave.note.id == null) return;
    _unregisterWidgetEditor = _editorWidgetCommands?.registerEditor(
        _autosave.note.id!, _applyWidgetCompletion);
  }

  Future<void> _copySelection(NoteTextSelection selection) async {
    if (_editBlocked) return;
    setState(() => _presentingMedia = true);
    try {
      final destination = await showNoteCopyDestinationPicker(context,
          notes: _libraryNotes, sourceNoteId: _autosave.note.id);
      if (!mounted || destination == null) return;
      final transfer = NoteSelectionTransfer(
        repository: getIt<NoteRepository>(),
        store: _autosave.store,
        readDraft: (id) => Hive.isBoxOpen(draftDatabaseBox)
            ? (Hive.box(draftDatabaseBox).get(id) as NoteDto?)?.toDomain()
            : null,
      );
      final saved = destination.isNewNote
          ? await transfer.copyToNew(selection,
              color: _form.state.selectedColor)
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
      if (mounted) setState(() => _presentingMedia = false);
    }
  }

  bool get _selectionComposing =>
      _composingTodoIds.isNotEmpty ||
      (_titleController.value.composing.isValid &&
          !_titleController.value.composing.isCollapsed) ||
      (_descriptionController.value.composing.isValid &&
          !_descriptionController.value.composing.isCollapsed);

  void _beginSelectionMutation() {
    // Close this editor's input connection before awaiting repository or media
    // work; a hidden editor must leave its child reader's focus alone.
    if (_editorFocusScope.hasFocus) _editorFocusScope.unfocus();
    setState(() => _replayingHistory = true);
  }

  bool get _selectionMutationBusy =>
      !mounted ||
      _leaving ||
      _replayingHistory ||
      _refreshingFromLibrary ||
      (_mediaBlocked && !_suspendedForLinkedNote) ||
      _selectionComposing;

  Future<Note?> _selectionDestination({bool allowNew = false}) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return null;
    _captureTimer?.cancel();
    _replayingHistory = false;
    _capture(_form.state);
    _replayingHistory = true;
    Note latest;
    try {
      latest = (await getIt<NoteRepository>().getNote(_autosave.note.id!))
          .toDomain();
    } catch (_) {
      if (!allowNew || widget.note != null || _suspendedForLinkedNote) rethrow;
      latest = _currentDraft(_form.state);
    }
    if (!mounted || latest.isDeleted) return null;
    // A linked reader can edit this note while these fields are hidden.
    final current = (_suspendedForLinkedNote
            ? latest.copyWith(
                title: latest.title ?? '',
                description: latest.description ?? '')
            : _currentDraft(_form.state))
        .copyWith(
            isPinned: latest.isPinned,
            isArchived: latest.isArchived,
            folderId: latest.folderId,
            dailyNoteDateKey: latest.dailyNoteDateKey,
            cardStyle: latest.cardStyle,
            sortOrder: latest.sortOrder,
            deletedAt: latest.deletedAt);
    if (_suspendedForLinkedNote) {
      await _documentScanCapture.reconcilePages(current.imagePaths);
      if (!mounted) return null;
      final baseline = _editSnapshot(current);
      if (!_editHistory.current.sameContent(baseline)) {
        _editHistory.reset(baseline);
      } else {
        _editHistory.record(baseline);
      }
    }
    return current;
  }

  void _finishSelectionMutation() {
    _replayingHistory = false;
    if (mounted) {
      if (!_suspendedForLinkedNote) {
        _bodyChanged();
        _capture(_form.state);
      }
      _refreshStatus();
      _syncPlatformUndo();
    }
  }

  Future<bool> _appendCopiedSelection(NoteTextSelection selection) async {
    if (_selectionMutationBusy) return false;
    _beginSelectionMutation();
    try {
      final current = await _selectionDestination();
      if (current == null || current.isArchived || _selectionComposing) {
        return false;
      }
      final next = appendSelectionToNote(current, selection);
      final snapshot = _editSnapshot(next);
      _editHistory.record(snapshot);
      await _applyEditSnapshot(snapshot, next,
          restoreFocus: false, reconcilePages: false);
      return mounted && await _autosave.flush();
    } catch (_) {
      return false;
    } finally {
      _finishSelectionMutation();
    }
  }

  Future<NoteSelectionChecklistResult?> _appendChecklistSelection(
      NoteTextSelection selection) async {
    if (_selectionMutationBusy) return null;
    // Reject oversized rows before touching the current draft or history.
    final parsed = appendSelectionToChecklist(_autosave.note, selection);
    if (parsed.status != NoteSelectionChecklistStatus.ready) return parsed;
    _beginSelectionMutation();
    try {
      final current = await _selectionDestination(allowNew: true);
      if (current == null || _selectionComposing) return null;
      final result = appendSelectionToChecklist(current, selection);
      final next = result.note!;
      final snapshot = _editSnapshot(next);
      _editHistory.record(snapshot);
      await _applyEditSnapshot(snapshot, next,
          restoreFocus: false, reconcilePages: false);
      if (!mounted || !await _autosave.flush()) return null;
      _lastChecklistAddition = snapshot;
      _lastChecklistUndoCount = _editHistory.undoCount;
      _lastChecklistIds = result.addedTodoIds;
      return result;
    } catch (_) {
      return null;
    } finally {
      _finishSelectionMutation();
    }
  }

  Future<bool> _undoAddedChecklist(List<String> ids) async {
    if (_selectionMutationBusy) return false;
    _beginSelectionMutation();
    try {
      final current = await _selectionDestination(allowNew: true);
      if (current == null || _selectionComposing) return false;
      final next = undoSelectionChecklist(current, ids);
      if (identical(next, current)) return await _autosave.flush();
      NoteEditSnapshot? restored;
      if (listEquals(ids, _lastChecklistIds) &&
          _lastChecklistUndoCount == _editHistory.undoCount &&
          _lastChecklistAddition != null &&
          _lastChecklistAddition!.sameContent(_editSnapshot(current))) {
        restored = _editHistory.undo();
      }
      final snapshot = restored ?? _editSnapshot(next);
      if (restored == null) _editHistory.record(snapshot);
      await _applyEditSnapshot(snapshot, snapshot.applyTo(current),
          restoreFocus: false, reconcilePages: false);
      return mounted && await _autosave.flush();
    } catch (_) {
      return false;
    } finally {
      _finishSelectionMutation();
    }
  }

  Future<void> _addSelectionToChecklist(NoteTextSelection selection) async {
    final result = await _appendChecklistSelection(selection);
    if (!mounted) return;
    final strings = S.of(context);
    if (result?.status == NoteSelectionChecklistStatus.empty) return;
    if (result?.status != NoteSelectionChecklistStatus.ready) {
      showTransientSnackBar(
          context,
          SnackBar(
              content: Text(
                  result?.status == NoteSelectionChecklistStatus.tooLong
                      ? strings.Selection_Checklist_Too_Long
                      : strings.Selection_Checklist_Failed)));
      return;
    }
    showTransientSnackBar(
        context,
        SnackBar(
            content: Text(
                strings.Selection_Checklist_Added(result!.addedTodoIds.length)),
            action: SnackBarAction(
                label: strings.Undo,
                onPressed: () async {
                  final saved = await _undoAddedChecklist(result.addedTodoIds);
                  if (!saved && mounted) {
                    showTransientSnackBar(
                        context,
                        SnackBar(
                            content: Text(
                                S.of(context).Selection_Checklist_Failed)));
                  }
                })));
  }

  Future<void> _setSectionLinks(List<NoteSectionLink> links) async {
    final normalized = normalizeNoteSectionLinks(links);
    if (listEquals(normalized, _form.state.sectionLinks)) return;
    final applied = _form.stream
        .firstWhere((state) => listEquals(state.sectionLinks, normalized));
    _form.add(AddUpdateFormEvent.sectionLinksChanged(normalized));
    await applied;
  }

  Future<void> _addSectionLink() async {
    if (_mediaBlocked) return;
    setState(() => _presentingMedia = true);
    try {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      final selected = await showNoteSectionLinkPickerSheet(context,
          notes: _libraryNotes, currentNoteId: _autosave.note.id!);
      if (!mounted ||
          selected == null ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final self = selected.noteId == _autosave.note.id;
      final repository = getIt<NoteRepository>();
      final target = self
          ? _currentDraft(_form.state)
          : (await repository.getNote(selected.noteId)).toDomain();
      final captured = captureNoteSectionLink(target, selected.heading);
      if (captured == null) throw StateError('Heading changed');
      final links = normalizeNoteSectionLinks(
          [..._form.state.sectionLinks, captured.link]);
      if (self) {
        _descriptionController.setDocument(
            captured.target.description ?? '', captured.target.textStyles);
      } else {
        await repository.addUpdateNote(NoteDto.fromNote(captured.target));
      }
      if (!mounted) return;
      await _setSectionLinks(links);
      _capture(_form.state);
      if (!await _autosave.flush() && mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
      }
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Section_Link_Failed)));
      }
    } finally {
      if (mounted) setState(() => _presentingMedia = false);
    }
  }

  Future<void> _removeSectionLink(NoteSectionLink link) async {
    if (_mediaBlocked) return;
    await _setSectionLinks(
        _form.state.sectionLinks.where((value) => value != link).toList());
  }

  Future<void> _openSectionLink(NoteSectionLink link) async {
    if (_mediaBlocked) return;
    final target = resolveNoteSectionLink(link, _libraryNotes);
    if (target == null) {
      showTransientSnackBar(context,
          SnackBar(content: Text(S.of(context).Section_Link_Unavailable)));
      return;
    }
    if (target.note.id == _autosave.note.id) {
      await _outlineController.jumpTo(target.heading.start);
    } else {
      await _openLinkedNote(target.note, headingId: link.headingId);
    }
  }

  Future<void> _openLinkedNote(Note note, {String? headingId}) async {
    if (_mediaBlocked || note.id == null) return;
    await _rememberWritingPosition();
    if (!mounted) return;
    _suspendedForLinkedNote = true;
    setState(() => _presentingMedia = true);
    try {
      await _voiceWrites;
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      _capture(_form.state);
      if (!await _autosave.flush()) {
        if (mounted) {
          showTransientSnackBar(
              context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
        }
        return;
      }
      if (!mounted) return;
      final target = availableLinkedNote(note.id!, _libraryNotes);
      if (target == null) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Link_Unavailable)));
        return;
      }
      _unregisterWidgetEditor?.call();
      _unregisterWidgetEditor = null;
      await context.router.push(
          NoteDetailRoute(noteId: target.id!, initialHeadingId: headingId));
      await _editorWidgetCommands?.importPending();
      await _refreshSavedNoteFromLibrary();
    } finally {
      _suspendedForLinkedNote = false;
      if (mounted) {
        _registerWidgetEditor();
        setState(() => _presentingMedia = false);
      }
    }
  }

  Future<void> _openDesktopSettings() async {
    if (_editBlocked || ModalRoute.of(context)?.isCurrent != true) return;
    _suspendedForLinkedNote = true;
    setState(() => _presentingMedia = true);
    try {
      await _voiceWrites;
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      _captureTimer?.cancel();
      _capture(_form.state);
      if (!await _autosave.flush()) {
        if (mounted) {
          showTransientSnackBar(
              context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
        }
        return;
      }
      if (!mounted) return;
      _unregisterWidgetEditor?.call();
      _unregisterWidgetEditor = null;
      await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const SettingsScreen()));
      await _editorWidgetCommands?.importPending();
      await _refreshSavedNoteFromLibrary();
    } finally {
      _suspendedForLinkedNote = false;
      if (mounted) {
        _registerWidgetEditor();
        setState(() => _presentingMedia = false);
      }
    }
  }

  Future<void> _resumeAfterDesktopRoute() async {
    if (!mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        _mediaBlocked ||
        _autosave.dirty ||
        _captureTimer?.isActive == true) {
      return;
    }
    await _refreshSavedNoteFromLibrary();
  }

  Future<void> _refreshSavedNoteFromLibrary() async {
    if (!mounted || !getIt.isRegistered<NoteRepository>()) return;
    if (widget.note == null && !NoteAutosave.hasContent(_autosave.note)) {
      return;
    }
    // The child route can reach this note through a backlink and edit its
    // content or archive/tags. Adopt the latest saved note before more typing.
    NoteDto fresh;
    try {
      fresh = await getIt<NoteRepository>().getNote(_autosave.note.id!);
    } catch (_) {
      if (mounted) {
        setState(() => _allowPop = true);
        await context.router.maybePop();
      }
      return;
    }
    if (!mounted) return;
    if (fresh.isDeleted) {
      setState(() => _allowPop = true);
      await context.router.maybePop();
      return;
    }
    final refreshed = fresh.toDomain();
    _refreshingFromLibrary = true;
    try {
      if (!_autosave.adoptSavedNote(refreshed)) return;
      if (_titleController.text != (refreshed.title ?? '')) {
        _titleController.text = refreshed.title ?? '';
      }
      _currentImageLayouts = refreshed.imageLayouts;
      if (_descriptionController.text != (refreshed.description ?? '') ||
          !listEquals(_descriptionController.styles, refreshed.textStyles)) {
        _descriptionController.setDocument(
            refreshed.description ?? '', refreshed.textStyles);
      }
      final state = AddUpdateFormState(
          title: refreshed.title,
          description: refreshed.description,
          textStyles: refreshed.textStyles,
          selectedColor: refreshed.color,
          todos: refreshed.todo,
          imagePaths: refreshed.imagePaths,
          imageLayouts: refreshed.imageLayouts,
          voiceMemos: refreshed.voiceMemos,
          tags: refreshed.tags,
          linkedNoteIds: refreshed.linkedNoteIds,
          sectionLinks: refreshed.sectionLinks,
          dailyNoteDateKey: refreshed.dailyNoteDateKey,
          cardStyle: refreshed.cardStyle);
      if (_form.state != state) {
        final applied = _form.stream.firstWhere((value) => value == state);
        _form.add(AddUpdateFormEvent.initialize(
            title: refreshed.title,
            description: refreshed.description,
            textStyles: refreshed.textStyles,
            color: refreshed.color,
            todos: refreshed.todo,
            imagePaths: refreshed.imagePaths,
            imageLayouts: refreshed.imageLayouts,
            voiceMemos: refreshed.voiceMemos,
            tags: refreshed.tags,
            linkedNoteIds: refreshed.linkedNoteIds,
            sectionLinks: refreshed.sectionLinks,
            dailyNoteDateKey: refreshed.dailyNoteDateKey,
            cardStyle: refreshed.cardStyle));
        await applied;
      }
    } finally {
      _refreshingFromLibrary = false;
    }
    if (!mounted) return;
    final baseline = _editSnapshot(_currentDraft(_form.state));
    if (_editHistory.current.sameContent(baseline)) {
      _editHistory.record(baseline);
    } else {
      _editHistory.reset(baseline);
    }
    _queueReminderSuggestion();
  }

  Future<bool> _applyWidgetCompletion(WidgetTodoCommand command) async {
    if (!mounted ||
        _leaving ||
        _replayingHistory ||
        _suspendedForLinkedNote ||
        command.noteId != _autosave.note.id) {
      return false;
    }
    // Drain queued typing/reorder events, then change only completion in the
    // current form. Draft text, task labels, images, and ordering stay intact.
    await Future<void>.delayed(Duration.zero);
    if (!mounted || _suspendedForLinkedNote) return false;
    final matches =
        _form.state.todos.where((todo) => todo.id == command.todoId);
    if (matches.isEmpty) return true; // A deleted draft row stays deleted.
    if (matches.first.completed != command.completed) {
      final applied = _form.stream.firstWhere((state) => state.todos.any(
          (todo) =>
              todo.id == command.todoId &&
              todo.completed == command.completed));
      _form.add(AddUpdateFormEvent.setTodoCompleted(
          id: command.todoId, completed: command.completed));
      await applied;
      if (!mounted || _suspendedForLinkedNote) return false;
    }
    _capture(_form.state);
    // A widget command is an external edit; future undo starts at its result.
    _editHistory.reset(_editSnapshot(_currentDraft(_form.state)));
    return _autosave.flush();
  }

  void _refreshStatus() {
    if (!mounted) return;
    DesktopCommands.instance.refresh();
    _syncPlatformUndo();
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_statusRefreshQueued) return;
      _statusRefreshQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _statusRefreshQueued = false;
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  // iOS keyboard buttons and three-finger gestures share the same whole-note
  // history as the visible controls, including changes with unchanged text.
  void _syncPlatformUndo() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!mounted || !_editorFocusScope.hasFocus || _findController != null) {
      if (identical(UndoManager.client, this)) UndoManager.client = null;
      return;
    }
    UndoManager.client = this;
    UndoManager.setUndoState(canUndo: canUndo, canRedo: canRedo);
  }

  @override
  bool get canUndo => !_historyBlocked && _editHistory.canUndo;
  @override
  bool get canRedo => !_historyBlocked && _editHistory.canRedo;
  @override
  void undo() => unawaited(_restoreHistory(redo: false));
  @override
  void redo() => unawaited(_restoreHistory(redo: true));
  @override
  void handlePlatformUndo(UndoDirection direction) =>
      direction == UndoDirection.undo ? undo() : redo();

  Future<void> _recordReviewOnExit() async {
    if (!InAppReviewHelper.instance.promptsEnabled) return;
    final seeded = widget.note == null &&
        (widget.template != null || widget.customTemplateNote != null);
    if (_recordedReviewSave ||
        (!_hadUserChange && !seeded) ||
        _autosave.dirty ||
        _autosave.status != AutosaveStatus.saved ||
        !NoteAutosave.hasContent(_autosave.note)) {
      return;
    }
    _recordedReviewSave = true;
    RouteData? destination;
    if (getIt.isRegistered<AppRouter>()) {
      final router = getIt<AppRouter>().topMostRouter();
      final stack = router.stackData;
      final exitingRoute = RouteData.of(context);
      final index = stack.indexWhere((route) => identical(route, exitingRoute));
      destination = index > 0
          ? stack[index - 1]
          : index < 0
              ? router.current
              : null;
    }
    await InAppReviewHelper.instance.recordSavedNote(_autosave.note);
    // Let the page transition settle, then confirm the editor stayed closed.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (destination == null ||
        !getIt.isRegistered<AppRouter>() ||
        !isReviewMomentIdle) {
      return;
    }
    final router = getIt<AppRouter>();
    if (router.hasPagelessTopRoute) return;
    final route = router.topMostRouter().current;
    if (identical(route, destination) &&
        (route.name == HomeRoute.name || route.name == NoteDetailRoute.name)) {
      await InAppReviewHelper.instance.requestReviewIfEligible();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited((widget.voiceMemoService ?? VoiceMemoService.instance)
          .onBackground());
    }
    if (state != AppLifecycleState.resumed) {
      unawaited(_rememberWritingPosition());
      _capture(_form.state);
      unawaited(_autosave.flush());
    }
  }

  Future<void> _retrySave() async {
    if (_retryingSave || _mediaBlocked) return;
    setState(() => _retryingSave = true);
    try {
      await _voiceWrites;
      // Include any field events queued in the frame of the retry tap.
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      _captureTimer?.cancel();
      _capture(_form.state);
      final saved = await _autosave.flush();
      if (mounted && !saved) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
      }
    } finally {
      if (mounted) setState(() => _retryingSave = false);
    }
  }

  Future<bool> _flushForDesktopExit() async {
    await _voiceWrites;
    // Include field and checklist events queued in the same frame as Quit.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return true;
    if (_replayingHistory ||
        _refreshingFromLibrary ||
        _addingPhoto ||
        _presentingMedia ||
        _presentingReminder ||
        _voiceMutations > 0 ||
        _savingReminder) {
      return false;
    }
    _captureTimer?.cancel();
    // Linked-note navigation has already flushed the underlying editor. Its
    // stale snapshot must not overwrite the newer child editor's content.
    if (!_suspendedForLinkedNote) _capture(_form.state);
    final saved = await _autosave.flush();
    if (saved && mounted) await _rememberWritingPosition();
    return saved;
  }

  Future<void> _finish() async {
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true ||
        _allowPop ||
        _leaving ||
        _retryingSave ||
        _replayingHistory ||
        _addingPhoto ||
        _presentingMedia ||
        _savingReminder ||
        _presentingReminder) {
      return;
    }
    if (_photoCapture.canRetry) {
      await _addPhoto(ImageSource.camera, retry: true);
      if (!mounted || _photoCapture.canRetry) return;
    }
    if (_documentScanCapture.canRetry) {
      await _scanDocument(retry: true);
      if (!mounted || _documentScanCapture.canRetry) return;
    }
    setState(() => _leaving = true);
    await _voiceWrites;
    // Allow queued form events to apply before flushing the final snapshot.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    _capture(_form.state);
    await _rememberWritingPosition();
    final saved = await _autosave.flush();
    if (!mounted) return;
    if (!saved) {
      setState(() => _leaving = false);
      showTransientSnackBar(
          context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
      return;
    }
    try {
      await _photoCapture.complete();
    } catch (error) {
      // The photo and note are already saved. Recovery will harmlessly merge
      // the recorded path again if clearing its metadata must be retried.
      debugPrint('Photo capture journal cleanup deferred: $error');
    }
    try {
      await _documentScanCapture.complete();
    } catch (error) {
      debugPrint('Document scan cleanup deferred: $error');
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The state stays mounted during the exit animation. A later callback
      // must never pop the route underneath an editor that already closed.
      if (mounted && route?.isCurrent == true) context.router.maybePop();
    });
  }

  @override
  void dispose() {
    unawaited(_rememberWritingPosition());
    _writingPositionTimer?.cancel();
    final pendingInput = _captureTimer?.isActive == true ||
        _titleController.text != (_autosave.note.title ?? '') ||
        _descriptionController.text != (_autosave.note.description ?? '') ||
        !listEquals(_descriptionController.styles, _autosave.note.textStyles);
    _captureTimer?.cancel();
    FocusManager.instance.removeListener(_syncPlatformUndo);
    FocusManager.instance.removeListener(_writingFocusChanged);
    if (identical(UndoManager.client, this)) UndoManager.client = null;
    _suggestionDebounce?.cancel();
    ReminderData.shared.removeListener(_reminderChanged);
    _unregisterWidgetEditor?.call();
    _unregisterSelectionEditor?.call();
    _unregisterChecklistEditor?.call();
    for (final unregister in _desktopCommands) {
      unregister();
    }
    _entryAnimation?.removeStatusListener(_onCaptureEntryStatus);
    WidgetsBinding.instance.removeObserver(this);
    _autosave.removeListener(_refreshStatus);
    _editHistory.removeListener(_refreshStatus);
    // Preserve a final input value even if the route is removed before the
    // zero-delay form capture runs. Media ownership lives through this flush.
    if (pendingInput && !_replayingHistory && !_refreshingFromLibrary) {
      _capture(_form.state);
    }
    _changes.cancel();
    _documentScanCapture.release();
    _form.close();
    final finalSave = _autosave.flush().whenComplete(() {
      _autosave.dispose();
      _editHistory.dispose();
    });
    DesktopCommands.instance.trackSave(finalSave);
    _unregisterDesktopEditor?.call();
    _unregisterDesktopRefresh?.call();
    unawaited(finalSave);
    _titleController.removeListener(_selectionChanged);
    _titleController.dispose();
    _descriptionController.removeListener(_bodyChanged);
    _descriptionController.dispose();
    _bodyFocus.dispose();
    _titleFocus.dispose();
    _editorFocusScope.dispose();
    _outlineController.dispose();
    _formattingController.removeListener(_refreshStatus);
    _formattingController.dispose();
    _findController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _creationAccess.purchases,
      builder: (context, _) {
        if (_newNoteBlocked) {
          return PremiumScreen(
              purchases: _creationAccess.purchases,
              feature: PremiumFeature.notes);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _newNoteBlocked) return;
          if (_seedSaveDeferred) {
            _seedSaveDeferred = false;
            _autosave.saveInitial();
          }
          _prepareCapture();
        });
        return _buildEditor(context);
      },
    );
  }

  Widget _buildEditor(BuildContext context) {
    final selection = _descriptionController.selection;
    final formattingTip = _formattingTipAvailable &&
        _formattingController.hasFocus &&
        selection.isValid &&
        !selection.isCollapsed &&
        _findController == null &&
        !_mediaBlocked;
    final imageTip = _imageTipAvailable &&
        _imageTipRelevant &&
        _form.state.imagePaths.isNotEmpty &&
        !_writingFocused &&
        _findController == null &&
        !_mediaBlocked &&
        !formattingTip;
    if (formattingTip) _recordTipSeen(NoteEditorTipKind.formatting);
    if (imageTip) _recordTipSeen(NoteEditorTipKind.imageLayout);
    return Listener(
      onPointerDown: _writingGesture,
      onPointerSignal: (_) => _writingInteraction++,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (_) {
          _writingInteraction++;
          return false;
        },
        child: FocusScope(
          node: _editorFocusScope,
          child: BlocProvider.value(
            value: _form,
            child: PopScope(
              canPop: _allowPop ||
                  (!_leaving &&
                      !_autosave.dirty &&
                      _captureTimer?.isActive != true &&
                      !_replayingHistory &&
                      !_photoCapture.canRetry &&
                      !_documentScanCapture.canRetry &&
                      !_addingPhoto &&
                      !_presentingMedia &&
                      _voiceMutations == 0 &&
                      !_savingReminder &&
                      !_presentingReminder &&
                      !_retryingSave),
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) {
                  _finish();
                } else {
                  unawaited(_recordReviewOnExit());
                }
              },
              child: BlocBuilder<AddUpdateFormBloc, AddUpdateFormState>(
                builder: (context, state) => AbsorbPointer(
                  absorbing: _replayingHistory || _leaving,
                  child: _BuildForm(
                    widget: widget,
                    state: state,
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    bodyFocus: _bodyFocus,
                    titleFocus: _titleFocus,
                    outlineController: _outlineController,
                    formattingController: _formattingController,
                    showFormattingTip: formattingTip,
                    showImageTip: imageTip,
                    onDismissFormattingTip: () =>
                        _dismissTip(NoteEditorTipKind.formatting),
                    onDismissImageTip: () =>
                        _dismissTip(NoteEditorTipKind.imageLayout),
                    onInsert: _insert,
                    titleNavigationKey: _titleNavigationKey,
                    todoNavigationKey: _todoNavigationKey,
                    writingFocused: _writingFocused,
                    onToggleFocus: _mediaBlocked ? null : _toggleWritingFocus,
                    onEditFindMatch: _editFindMatch,
                    onReplaceFind: (match, replacement) =>
                        _replaceFind(replacement, match: match),
                    onReplaceAllFind: _replaceFind,
                    findActionsEnabled: !_editBlocked && !_findInputComposing,
                    onFindCompositionChanged: _findCompositionChanged,
                    onOutline: !_historyBlocked &&
                            shouldShowNoteOutline(
                                _descriptionController.text,
                                buildNoteOutline(_descriptionController.text,
                                    _descriptionController.styles))
                        ? _openOutline
                        : null,
                    onUndo: !_historyBlocked && _editHistory.canUndo
                        ? () => _restoreHistory(redo: false)
                        : null,
                    onRedo: !_historyBlocked && _editHistory.canRedo
                        ? () => _restoreHistory(redo: true)
                        : null,
                    restoredEdit: _restoredEdit,
                    restoreRevision: _restoreRevision,
                    onTodoInputChanged: _todoInputChanged,
                    onCopySelection: _copySelection,
                    onAddSelectionToChecklist: _addSelectionToChecklist,
                    onMore: _showEditorMore,
                    onImageLayoutsChanged: _imageLayoutsChanged,
                    onRemoveImage: _removeInlineImage,
                    onEditImage: _editPhoto,
                    onFind: _openFind,
                    onCloseFind: _closeFind,
                    findController: _findController,
                    findNote:
                        _findController == null ? null : _currentDraft(state),
                    status: _autosave.status,
                    onDone: _finish,
                    onRetrySave: _mediaBlocked ? null : _retrySave,
                    retryingSave: _retryingSave,
                    addingPhoto: _addingPhoto,
                    mediaBusy: _presentingMedia,
                    extractingText: _extractingPhotoText,
                    onExtractText: _extractPhotoText,
                    onRemoveVoice: _removeVoiceMemo,
                    onTranscriptChanged: _editVoiceTranscript,
                    resolveAudioPath: _audio.resolvePath,
                    libraryNotes: _libraryNotes,
                    onEditTags: _editTags,
                    onEditLinks: _editLinks,
                    onAddSectionLink: _addSectionLink,
                    onRemoveSectionLink: _removeSectionLink,
                    onOpenSectionLink: _openSectionLink,
                    onOpenLinkedNote: _openLinkedNote,
                    reminderSuggestion: _reminderSuggestion,
                    savingReminder: _savingReminder,
                    onReminderSuggestion: _confirmReminderSuggestion,
                    onDismissReminderSuggestion: _dismissReminderSuggestion,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildForm extends StatelessWidget {
  const _BuildForm({
    required this.widget,
    required TextEditingController titleController,
    required SimpleFormattingController descriptionController,
    required this.bodyFocus,
    required this.titleFocus,
    required this.outlineController,
    required this.formattingController,
    required this.showFormattingTip,
    required this.showImageTip,
    required this.onDismissFormattingTip,
    required this.onDismissImageTip,
    required this.onInsert,
    required this.titleNavigationKey,
    required this.todoNavigationKey,
    required this.writingFocused,
    required this.onToggleFocus,
    required this.onEditFindMatch,
    required this.onReplaceFind,
    required this.onReplaceAllFind,
    required this.findActionsEnabled,
    required this.onFindCompositionChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onOutline,
    required this.restoredEdit,
    required this.restoreRevision,
    required this.onTodoInputChanged,
    required this.onCopySelection,
    required this.onAddSelectionToChecklist,
    required this.onMore,
    required this.onImageLayoutsChanged,
    required this.onRemoveImage,
    required this.onEditImage,
    required this.onFind,
    required this.onCloseFind,
    required this.findController,
    required this.findNote,
    required this.state,
    required this.status,
    required this.onDone,
    required this.onRetrySave,
    required this.retryingSave,
    required this.addingPhoto,
    required this.mediaBusy,
    required this.extractingText,
    required this.onExtractText,
    required this.onRemoveVoice,
    required this.onTranscriptChanged,
    required this.resolveAudioPath,
    required this.libraryNotes,
    required this.onEditTags,
    required this.onEditLinks,
    required this.onAddSectionLink,
    required this.onRemoveSectionLink,
    required this.onOpenSectionLink,
    required this.onOpenLinkedNote,
    required this.reminderSuggestion,
    required this.savingReminder,
    required this.onReminderSuggestion,
    required this.onDismissReminderSuggestion,
  })  : _titleController = titleController,
        _descriptionController = descriptionController;

  final AddUpdateNoteScreen widget;
  final TextEditingController _titleController;
  final SimpleFormattingController _descriptionController;
  final FocusNode bodyFocus;
  final FocusNode titleFocus;
  final NoteOutlineNavigationController outlineController;
  final NoteBodyFormattingController formattingController;
  final bool showFormattingTip;
  final bool showImageTip;
  final VoidCallback onDismissFormattingTip;
  final VoidCallback onDismissImageTip;
  final VoidCallback onInsert;
  final GlobalKey titleNavigationKey;
  final GlobalKey<_BuildTodoListFieldState> todoNavigationKey;
  final bool writingFocused;
  final VoidCallback? onToggleFocus;
  final Future<void> Function(NoteSearchMatch) onEditFindMatch;
  final Future<void> Function(NoteSearchMatch, String) onReplaceFind;
  final Future<void> Function(String) onReplaceAllFind;
  final bool findActionsEnabled;
  final ValueChanged<bool> onFindCompositionChanged;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onOutline;
  final NoteEditSnapshot? restoredEdit;
  final int restoreRevision;
  final void Function(String, TextEditingValue) onTodoInputChanged;
  final ValueChanged<NoteTextSelection> onCopySelection;
  final ValueChanged<NoteTextSelection> onAddSelectionToChecklist;
  final VoidCallback onMore;
  final ValueChanged<List<NoteImageLayout>> onImageLayoutsChanged;
  final ValueChanged<String> onRemoveImage;
  final ValueChanged<String> onEditImage;
  final VoidCallback onFind;
  final VoidCallback onCloseFind;
  final NoteSearchController? findController;
  final Note? findNote;
  final AddUpdateFormState state;
  final AutosaveStatus status;
  final VoidCallback onDone;
  final VoidCallback? onRetrySave;
  final bool retryingSave;
  final bool addingPhoto;
  final bool mediaBusy;
  final bool extractingText;
  final VoidCallback onExtractText;
  final Future<void> Function(VoiceMemo) onRemoveVoice;
  final Future<void> Function(VoiceMemo, String?) onTranscriptChanged;
  final Future<String> Function(String) resolveAudioPath;
  final List<Note> libraryNotes;
  final VoidCallback onEditTags;
  final VoidCallback onEditLinks;
  final VoidCallback onAddSectionLink;
  final ValueChanged<NoteSectionLink> onRemoveSectionLink;
  final ValueChanged<NoteSectionLink> onOpenSectionLink;
  final ValueChanged<Note> onOpenLinkedNote;
  final ReminderDateSuggestion? reminderSuggestion;
  final bool savingReminder;
  final VoidCallback onReminderSuggestion;
  final VoidCallback onDismissReminderSuggestion;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppCardStyleSettings.instance,
        builder: (context, _) => _buildForm(context),
      );

  Widget _buildForm(BuildContext context) {
    final finder = findController;
    if (finder != null && findNote != null) {
      finder.setFields(noteSearchFields(findNote!), notify: false);
    }
    final strings = S.of(context);
    final compactAppBar = MediaQuery.sizeOf(context).width < 260;
    final noteTheme =
        resolveNoteCardStyle(state.cardStyle).noteTheme ?? NoteTheme.classic;
    final suggestion = reminderSuggestion == null
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ReminderSuggestionChip(
                date: reminderSuggestion!.date,
                busy: savingReminder,
                onPressed: onReminderSuggestion,
                onDismiss: onDismissReminderSuggestion));
    final suggestionSection = MediaQuery.disableAnimationsOf(context)
        ? suggestion
        : AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: suggestion);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): onFind,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): onFind,
        if (finder == null) ...{
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
              onUndo?.call(),
          const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () =>
              onUndo?.call(),
          const SingleActivator(LogicalKeyboardKey.keyZ,
              control: true, shift: true): () => onRedo?.call(),
          const SingleActivator(LogicalKeyboardKey.keyZ,
              meta: true, shift: true): () => onRedo?.call(),
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
              onRedo?.call(),
        },
        if (finder != null)
          const SingleActivator(LogicalKeyboardKey.escape): onCloseFind,
      },
      child: Scaffold(
        backgroundColor: DeskSurface.colorOf(context),
        bottomNavigationBar: finder != null
            ? null
            : formattingController.hasFocus
                ? NoteWritingToolbar(
                    controller: _descriptionController,
                    focusNode:
                        formattingController.activeFocusNode ?? bodyFocus,
                    beforeApply:
                        formattingController.prepareFormattingSelection,
                    enabled: !mediaBusy && !addingPhoto && !retryingSave,
                    tip: showFormattingTip
                        ? strings.Editor_Tip_Formatting
                        : null,
                    onDismissTip: onDismissFormattingTip,
                  )
                : null,
        appBar: NoteAppBar(
          leading: Center(
            child: IconButton(
              tooltip: finder == null
                  ? MaterialLocalizations.of(context).backButtonTooltip
                  : strings.Find_Close,
              onPressed: finder == null ? onDone : onCloseFind,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          titleWidget: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: NoteSaveStatus(
              status: status,
              onRetry: onRetrySave,
              retrying: retryingSave,
            ),
          ),
          actions: [
            if (!compactAppBar)
              IconButton(
                key: const ValueKey('editor-find-note'),
                tooltip: strings.Find_In_Note,
                onPressed: mediaBusy || addingPhoto ? null : onFind,
                icon: const Icon(Icons.search_rounded),
              ),
            IconButton(
              key: const ValueKey('editor-more-note'),
              tooltip: strings.More_Options,
              onPressed: mediaBusy || addingPhoto ? null : onMore,
              icon: const Icon(Icons.more_horiz_rounded),
            ),
            if (!compactAppBar)
              AppButton(
                  primary: true,
                  tooltip: S.of(context).Done,
                  onPressed: onDone,
                  child: Text(S.of(context).Done))
          ],
        ),
        body: LayoutBuilder(
          builder: (context, viewport) => Column(
            children: [
              if (finder == null)
                ConstrainedBox(
                  constraints:
                      BoxConstraints(maxHeight: viewport.maxHeight * .35),
                  child: SingleChildScrollView(
                    primary: false,
                    child: NoteEditingActions(
                        onUndo: onUndo,
                        onRedo: onRedo,
                        onOutline: onOutline,
                        onToggleFocus: onToggleFocus,
                        writingFocused: writingFocused,
                        onInsert: writingFocused ? null : onInsert,
                        insertEnabled:
                            !mediaBusy && !addingPhoto && !retryingSave),
                  ),
                ),
              if (showImageTip && finder == null)
                ConstrainedBox(
                  constraints:
                      BoxConstraints(maxHeight: viewport.maxHeight * .22),
                  child: SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: NoteEditorTip(
                      key: const ValueKey('editor-image-tip'),
                      message: strings.Editor_Tip_Image_Layout,
                      onDismiss: onDismissImageTip,
                    ),
                  ),
                ),
              if (finder != null)
                ConstrainedBox(
                  constraints:
                      BoxConstraints(maxHeight: viewport.maxHeight * .65),
                  child: SingleChildScrollView(
                    primary: false,
                    child: NoteFindBar(
                      controller: finder,
                      hintText: strings.Find_In_Note,
                      noMatchesText: strings.Find_No_Matches,
                      previousTooltip: strings.Find_Previous,
                      nextTooltip: strings.Find_Next,
                      closeTooltip: strings.Find_Close,
                      onClose: onCloseFind,
                      onEditMatch: onEditFindMatch,
                      onReplace: onReplaceFind,
                      onReplaceAll: onReplaceAllFind,
                      editMatchTooltip: strings.Find_Edit_Match,
                      replaceToggleLabel: strings.Find_Replace,
                      replaceHintText: strings.Find_Replace_With,
                      replaceLabel: strings.Find_Replace,
                      replaceAllLabel: strings.Find_Replace_All,
                      actionsEnabled: findActionsEnabled,
                      onComposingChanged: onFindCompositionChanged,
                    ),
                  ),
                ),
              Expanded(
                child: DeskSurface(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: context.tokens.contentMaxWidth),
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          context.tokens.space4,
                          context.tokens.space3,
                          context.tokens.space4,
                          context.tokens.space6,
                        ),
                        children: [
                          PaperNote(
                            color: noteThemePaperColor(noteTheme,
                                customColor: state.selectedColor),
                            theme: noteTheme,
                            kind: PaperNoteKind.sheet,
                            seed: widget.note?.id?.hashCode ?? 5,
                            tilt: false,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                32, 20, 16, 24),
                            child: finder != null && findNote != null
                                ? NoteFindPreview(
                                    note: findNote!,
                                    controller: finder,
                                    onEditMatch: findActionsEnabled
                                        ? (match) =>
                                            unawaited(onEditFindMatch(match))
                                        : null)
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _BuildTitleField(
                                        key: titleNavigationKey,
                                        state: state,
                                        titleController: _titleController,
                                        focusNode: titleFocus,
                                        onCopySelection: onCopySelection,
                                        onAddSelectionToChecklist:
                                            onAddSelectionToChecklist,
                                      ),
                                      const SizedBox(height: AppSpacings.l),
                                      _BuildTodoListField(
                                        key: todoNavigationKey,
                                        showAddButton: !writingFocused &&
                                            state.todos.isNotEmpty,
                                        state: state,
                                        restoredEdit: restoredEdit,
                                        restoreRevision: restoreRevision,
                                        onInputChanged: onTodoInputChanged,
                                        onCopySelection: onCopySelection,
                                        autofocusFirstTodo: widget.note ==
                                                null &&
                                            (widget.start ==
                                                    NoteEditorStart.checklist ||
                                                widget.template ==
                                                    NoteTemplate.shopping ||
                                                widget.template ==
                                                    NoteTemplate.packing),
                                      ),
                                      for (final memo in state.voiceMemos)
                                        VoiceMemoPlayer(
                                          key: ValueKey(memo.id),
                                          memo: memo,
                                          service: widget.voiceMemoService,
                                          resolvePath: resolveAudioPath,
                                          onRemove: () => onRemoveVoice(memo),
                                          onTranscriptChanged: (text) =>
                                              onTranscriptChanged(memo, text),
                                        ),
                                      if (state.todos.isNotEmpty ||
                                          state.voiceMemos.isNotEmpty)
                                        const SizedBox(height: AppSpacings.xml),
                                      _BuildDescriptionField(
                                        key: const ValueKey(
                                            'note-description-section'),
                                        outlineController: outlineController,
                                        formattingController:
                                            formattingController,
                                        onCopySelection: onCopySelection,
                                        onAddSelectionToChecklist:
                                            onAddSelectionToChecklist,
                                        focusNode: bodyFocus,
                                        onImageLayoutsChanged:
                                            onImageLayoutsChanged,
                                        onRemoveImage: onRemoveImage,
                                        onEditImage: onEditImage,
                                        state: state,
                                        descriptionController:
                                            _descriptionController,
                                        autofocus: widget.note == null &&
                                            widget.start ==
                                                NoteEditorStart.quickNote,
                                      ),
                                      if (!writingFocused &&
                                          state.imagePaths.isNotEmpty)
                                        TextButton.icon(
                                          key: const ValueKey(
                                              'editor-extract-text'),
                                          style: AppButtonStyles.paperAction(),
                                          onPressed: mediaBusy || addingPhoto
                                              ? null
                                              : onExtractText,
                                          icon: extractingText
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2))
                                              : const Icon(
                                                  Icons
                                                      .document_scanner_outlined,
                                                  size: 20),
                                          label: Text(extractingText
                                              ? strings.Photo_Text_Extracting
                                              : strings.Photo_Text_Extract),
                                        ),
                                      if (!writingFocused) ...[
                                        const SizedBox(height: AppSpacings.l),
                                        Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              for (final tag in state.tags)
                                                Chip(label: Text(tag)),
                                              TextButton.icon(
                                                key: const ValueKey(
                                                    'editor-edit-tags'),
                                                style: AppButtonStyles
                                                    .paperAction(),
                                                onPressed:
                                                    mediaBusy || addingPhoto
                                                        ? null
                                                        : onEditTags,
                                                icon: const Icon(
                                                    Icons.sell_outlined,
                                                    size: 20),
                                                label: Text(
                                                    S.of(context).Edit_Tags),
                                              ),
                                            ]),
                                        NoteLinksSection(
                                          linkedNoteIds: state.linkedNoteIds,
                                          notes: libraryNotes,
                                          backlinks: noteBacklinks(
                                              widget.note ?? Note(),
                                              libraryNotes),
                                          onOpen: mediaBusy || addingPhoto
                                              ? null
                                              : onOpenLinkedNote,
                                          onEdit: mediaBusy || addingPhoto
                                              ? null
                                              : onEditLinks,
                                        ),
                                        NoteSectionLinksSection(
                                          links: state.sectionLinks,
                                          notes: libraryNotes,
                                          onAdd: mediaBusy || addingPhoto
                                              ? null
                                              : onAddSectionLink,
                                          onRemove: mediaBusy || addingPhoto
                                              ? null
                                              : onRemoveSectionLink,
                                          onOpen: mediaBusy || addingPhoto
                                              ? null
                                              : onOpenSectionLink,
                                        ),
                                        suggestionSection,
                                      ],
                                    ],
                                  ),
                          ),
                        ],
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
