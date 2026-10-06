import 'package:onlynote/presentation/theme/button_styles.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:animate_do/animate_do.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_text_format.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/components/note_body_editor.dart';
import 'package:onlynote/presentation/components/note_photo_editor.dart';
import 'package:onlynote/presentation/components/note_find_bar.dart';
import 'package:onlynote/presentation/components/note_find_preview.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/services/note_photo_edit.dart';
import 'package:onlynote/services/note_photo_transform.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
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
import 'package:onlynote/services/note_reminder_scheduler.dart';
import 'package:onlynote/services/reminder_date_suggestion.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';

import 'bloc/add_update_bloc.dart';
import 'bloc/add_update_form/add_update_form_bloc.dart';

part 'widgets/colors_bar.dart';
part 'widgets/image_section.dart';
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
      this.photoEditService,
      this.photoTextExtraction,
      this.voiceMemoService,
      this.voiceMemoDrafts,
      this.reminderScheduler,
      this.widgetCommands,
      this.start = NoteEditorStart.standard});
  final Note? note;
  final String? folderId;
  final NoteTemplate? template;

  /// A newly instantiated custom template, already owning its photo copies.
  final Note? customTemplateNote;
  final NoteAutosaveStore? autosaveStore;
  final NotePhotoCapture? photoCapture;
  final NotePhotoEditService? photoEditService;
  final PhotoTextExtraction? photoTextExtraction;
  final VoiceMemoService? voiceMemoService;
  final VoiceMemoDrafts? voiceMemoDrafts;
  final NoteReminderScheduler? reminderScheduler;
  final WidgetCommands? widgetCommands;
  final NoteEditorStart start;

  @override
  State<AddUpdateNoteScreen> createState() => _AddUpdateNoteScreenState();
}

class _AddUpdateNoteScreenState extends State<AddUpdateNoteScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final SimpleFormattingController _descriptionController;
  final FocusNode _bodyFocus = FocusNode();
  List<NoteImageLayout> _currentImageLayouts = const [];
  late final AddUpdateFormBloc _form;
  late final NoteAutosave _autosave;
  late final StreamSubscription<AddUpdateFormState> _changes;
  late final NotePhotoCapture _photoCapture;
  late final NoteReminderScheduler _reminderScheduler;
  VoidCallback? _unregisterWidgetEditor;
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
  NoteSearchController? _findController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _photoCapture = widget.photoCapture ?? NotePhotoCapture();
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
          color: colors.randomElement,
          dateTime: now,
          sortOrder: -now.millisecondsSinceEpoch,
          folderId: widget.folderId,
          todo: widget.start == NoteEditorStart.checklist
              ? [Todo.empty()]
              : const [],
        );
    final initial = seed.copyWith(
        dailyNoteDateKey: widget.note != null
            ? widget.note!.dailyNoteDateKey
            : seed.dailyNoteDateKey,
        imageLayouts: normalizeNoteImageLayouts(
            seed.imageLayouts, seed.imagePaths, seed.description ?? ''));
    _currentImageLayouts = initial.imageLayouts;
    _titleController = TextEditingController(text: initial.title);
    _descriptionController = SimpleFormattingController(
        text: initial.description, styles: initial.textStyles);
    _autosave = NoteAutosave(
      store: widget.autosaveStore ??
          HiveNoteAutosaveStore(
              getIt<NoteRepository>(), Hive.box(draftDatabaseBox)),
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
          dailyNoteDateKey: initial.dailyNoteDateKey,
        ));
    _changes = _form.stream.listen((state) {
      if (_refreshingFromLibrary) return;
      _currentImageLayouts = normalizeNoteImageLayouts(
          state.imageLayouts, state.imagePaths, _descriptionController.text);
      _hadUserChange = true;
      _capture(state);
      _queueReminderSuggestion();
    });
    _descriptionController.addListener(_bodyChanged);
    _editorWidgetCommands =
        widget.widgetCommands ?? WidgetCommands.initializedInstance;
    _registerWidgetEditor();
    ReminderData.shared.addListener(_reminderChanged);
    _queueReminderSuggestion();
    if (recovered != null) _autosave.update(initial.copyWith(dateTime: now));
    if (widget.note == null &&
        (widget.template != null || widget.customTemplateNote != null)) {
      _autosave.saveInitial();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  void _bodyChanged() {
    if (_refreshingFromLibrary || !mounted || _form.isClosed) return;
    final text = _descriptionController.text;
    final styles = _descriptionController.styles;
    if ((_form.state.description ?? '') == text &&
        listEquals(_form.state.textStyles, styles) &&
        listEquals(_form.state.imageLayouts, _currentImageLayouts)) {
      return;
    }
    _form.add(
        AddUpdateFormEvent.bodyChanged(text, styles, _currentImageLayouts));
  }

  void _imageLayoutsChanged(List<NoteImageLayout> layouts) {
    if (_refreshingFromLibrary ||
        !mounted ||
        _form.isClosed ||
        listEquals(_currentImageLayouts, layouts)) {
      return;
    }
    _currentImageLayouts = layouts;
    _form.add(AddUpdateFormEvent.imageLayoutsChanged(layouts));
  }

  void _removeInlineImage(String path) {
    _currentImageLayouts =
        _currentImageLayouts.where((layout) => layout.path != path).toList();
    _form.add(AddUpdateFormEvent.removeImage(path));
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
    if (_mediaBlocked || _findController != null) return;
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
    setState(() => _findController = controller);
  }

  void _closeFind() {
    final controller = _findController;
    if (controller == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _findController = null);
    controller.dispose();
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
      );

  void _capture(AddUpdateFormState state) {
    final next = _currentDraft(state);
    if (next != _autosave.note) {
      _autosave.update(next.copyWith(dateTime: DateTime.now()));
    }
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
      _presentingMedia ||
      _voiceMutations > 0 ||
      _addingPhoto ||
      _savingReminder ||
      _presentingReminder ||
      _leaving;

  Future<void> _extractPhotoText() async {
    if (_mediaBlocked || _form.state.imagePaths.isEmpty) return;
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
      _autosave.note
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

  Future<void> _openLinkedNote(Note note) async {
    if (_mediaBlocked || note.id == null) return;
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
      await context.router.push(NoteDetailRoute(noteId: target.id!));
      await _editorWidgetCommands?.importPending();
      if (!mounted || !getIt.isRegistered<NoteRepository>()) return;
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
        _titleController.text = refreshed.title ?? '';
        _currentImageLayouts = refreshed.imageLayouts;
        _descriptionController.setDocument(
            refreshed.description ?? '', refreshed.textStyles);
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
            dailyNoteDateKey: refreshed.dailyNoteDateKey);
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
              dailyNoteDateKey: refreshed.dailyNoteDateKey));
          await applied;
        }
      } finally {
        _refreshingFromLibrary = false;
      }
      _queueReminderSuggestion();
    } finally {
      _suspendedForLinkedNote = false;
      if (mounted) {
        _registerWidgetEditor();
        setState(() => _presentingMedia = false);
      }
    }
  }

  Future<bool> _applyWidgetCompletion(WidgetTodoCommand command) async {
    if (!mounted ||
        _leaving ||
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
    return _autosave.flush();
  }

  void _refreshStatus() {
    if (mounted) setState(() {});
  }

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
      _capture(_form.state);
      unawaited(_autosave.flush());
    }
  }

  Future<void> _finish() async {
    if (_leaving ||
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
    _leaving = true;
    await _voiceWrites;
    // Allow queued form events to apply before flushing the final snapshot.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    _capture(_form.state);
    final saved = await _autosave.flush();
    if (!mounted) return;
    _leaving = false;
    if (!saved) {
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
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.router.maybePop();
    });
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    ReminderData.shared.removeListener(_reminderChanged);
    _unregisterWidgetEditor?.call();
    _entryAnimation?.removeStatusListener(_onCaptureEntryStatus);
    WidgetsBinding.instance.removeObserver(this);
    _changes.cancel();
    _form.close();
    _autosave.removeListener(_refreshStatus);
    unawaited(_autosave.flush().whenComplete(_autosave.dispose));
    _titleController.dispose();
    _descriptionController.removeListener(_bodyChanged);
    _descriptionController.dispose();
    _bodyFocus.dispose();
    _findController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _form,
        child: PopScope(
          canPop: _allowPop ||
              (!_autosave.dirty &&
                  !_photoCapture.canRetry &&
                  !_addingPhoto &&
                  !_presentingMedia &&
                  _voiceMutations == 0 &&
                  !_savingReminder &&
                  !_presentingReminder),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _finish();
            } else {
              unawaited(_recordReviewOnExit());
            }
          },
          child: BlocBuilder<AddUpdateFormBloc, AddUpdateFormState>(
            builder: (context, state) => _BuildForm(
              widget: widget,
              state: state,
              titleController: _titleController,
              descriptionController: _descriptionController,
              bodyFocus: _bodyFocus,
              onImageLayoutsChanged: _imageLayoutsChanged,
              onRemoveImage: _removeInlineImage,
              onEditImage: _editPhoto,
              onFind: _openFind,
              onCloseFind: _closeFind,
              findController: _findController,
              findNote: _findController == null ? null : _currentDraft(state),
              status: _autosave.status,
              onDone: _finish,
              onAddPhoto: _addPhoto,
              addingPhoto: _addingPhoto,
              mediaBusy: _presentingMedia,
              extractingText: _extractingPhotoText,
              onExtractText: _extractPhotoText,
              onRecordVoice: _recordVoiceMemo,
              onRemoveVoice: _removeVoiceMemo,
              onTranscriptChanged: _editVoiceTranscript,
              resolveAudioPath: _audio.resolvePath,
              libraryNotes: _libraryNotes,
              onEditTags: _editTags,
              onEditLinks: _editLinks,
              onOpenLinkedNote: _openLinkedNote,
              reminderSuggestion: _reminderSuggestion,
              savingReminder: _savingReminder,
              onReminderSuggestion: _confirmReminderSuggestion,
              onDismissReminderSuggestion: _dismissReminderSuggestion,
            ),
          ),
        ),
      );
}

class _BuildForm extends StatelessWidget {
  const _BuildForm({
    required this.widget,
    required TextEditingController titleController,
    required SimpleFormattingController descriptionController,
    required this.bodyFocus,
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
    required this.onAddPhoto,
    required this.addingPhoto,
    required this.mediaBusy,
    required this.extractingText,
    required this.onExtractText,
    required this.onRecordVoice,
    required this.onRemoveVoice,
    required this.onTranscriptChanged,
    required this.resolveAudioPath,
    required this.libraryNotes,
    required this.onEditTags,
    required this.onEditLinks,
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
  final ValueChanged<ImageSource> onAddPhoto;
  final bool addingPhoto;
  final bool mediaBusy;
  final bool extractingText;
  final VoidCallback onExtractText;
  final VoidCallback onRecordVoice;
  final Future<void> Function(VoiceMemo) onRemoveVoice;
  final Future<void> Function(VoiceMemo, String?) onTranscriptChanged;
  final Future<String> Function(String) resolveAudioPath;
  final List<Note> libraryNotes;
  final VoidCallback onEditTags;
  final VoidCallback onEditLinks;
  final ValueChanged<Note> onOpenLinkedNote;
  final ReminderDateSuggestion? reminderSuggestion;
  final bool savingReminder;
  final VoidCallback onReminderSuggestion;
  final VoidCallback onDismissReminderSuggestion;

  @override
  Widget build(BuildContext context) {
    final finder = findController;
    if (finder != null && findNote != null) {
      finder.setFields(noteSearchFields(findNote!), notify: false);
    }
    final strings = S.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): onFind,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): onFind,
        if (finder != null)
          const SingleActivator(LogicalKeyboardKey.escape): onCloseFind,
      },
      child: Scaffold(
        backgroundColor: DeskSurface.colorOf(context),
        bottomNavigationBar: finder != null
            ? null
            : ColorsBar(
                selectedColor: state.selectedColor,
                onChanged: (Color color) {
                  context
                      .read<AddUpdateFormBloc>()
                      .add(AddUpdateFormEvent.colorChanged(color));
                },
              ),
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
            child: Text(
              switch (status) {
                AutosaveStatus.saved => S.of(context).Autosave_Saved,
                AutosaveStatus.failed => S.of(context).Autosave_Retry,
                _ => S.of(context).Autosave_Saving,
              },
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: status == AutosaveStatus.failed
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          actions: [
            IconButton(
              key: const ValueKey('editor-find-note'),
              tooltip: strings.Find_In_Note,
              onPressed: mediaBusy || addingPhoto ? null : onFind,
              icon: const Icon(Icons.search_rounded),
            ),
            AppButton(
                primary: true,
                tooltip: S.of(context).Done,
                onPressed: onDone,
                child: Text(S.of(context).Done))
          ],
        ),
        body: Column(
          children: [
            if (finder != null)
              NoteFindBar(
                controller: finder,
                hintText: strings.Find_In_Note,
                noMatchesText: strings.Find_No_Matches,
                previousTooltip: strings.Find_Previous,
                nextTooltip: strings.Find_Next,
                closeTooltip: strings.Find_Close,
                onClose: onCloseFind,
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
                          color: state.selectedColor ?? AppColors.parchment,
                          kind: PaperNoteKind.sheet,
                          seed: widget.note?.id?.hashCode ?? 5,
                          tilt: false,
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              32, 20, 16, 24),
                          child: finder != null && findNote != null
                              ? NoteFindPreview(
                                  note: findNote!, controller: finder)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _BuildTitleField(
                                      state: state,
                                      titleController: _titleController,
                                    ),
                                    const SizedBox(height: AppSpacings.l),
                                    _BuildTodoListField(
                                      state: state,
                                      autofocusFirstTodo: widget.note == null &&
                                          (widget.start ==
                                                  NoteEditorStart.checklist ||
                                              widget.template ==
                                                  NoteTemplate.shopping ||
                                              widget.template ==
                                                  NoteTemplate.packing),
                                    ),
                                    SizedBox(
                                        height: state.imagePaths.isEmpty
                                            ? AppSpacings.m
                                            : AppSpacings.xl),
                                    _BuildImageSection(
                                      state: state,
                                      onAddPhoto: onAddPhoto,
                                      addingPhoto: addingPhoto || mediaBusy,
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (state.imagePaths.isNotEmpty)
                                          TextButton.icon(
                                            key: const ValueKey(
                                                'editor-extract-text'),
                                            style:
                                                AppButtonStyles.paperAction(),
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
                                                ? S
                                                    .of(context)
                                                    .Photo_Text_Extracting
                                                : S
                                                    .of(context)
                                                    .Photo_Text_Extract),
                                          ),
                                        TextButton.icon(
                                          key: const ValueKey(
                                              'editor-record-voice'),
                                          style: AppButtonStyles.paperAction(),
                                          onPressed: mediaBusy || addingPhoto
                                              ? null
                                              : onRecordVoice,
                                          icon: const Icon(
                                              Icons.mic_none_rounded,
                                              size: 20),
                                          label: Text(S.of(context).Voice_Memo),
                                        ),
                                      ],
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
                                    const SizedBox(height: AppSpacings.xml),
                                    _BuildDescriptionField(
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
                                    const SizedBox(height: AppSpacings.l),
                                    Wrap(spacing: 8, runSpacing: 4, children: [
                                      for (final tag in state.tags)
                                        Chip(label: Text(tag)),
                                      TextButton.icon(
                                        key: const ValueKey('editor-edit-tags'),
                                        style: AppButtonStyles.paperAction(),
                                        onPressed: mediaBusy || addingPhoto
                                            ? null
                                            : onEditTags,
                                        icon: const Icon(Icons.sell_outlined,
                                            size: 20),
                                        label: Text(S.of(context).Edit_Tags),
                                      ),
                                    ]),
                                    NoteLinksSection(
                                      linkedNoteIds: state.linkedNoteIds,
                                      notes: libraryNotes,
                                      backlinks: noteBacklinks(
                                          widget.note ?? Note(), libraryNotes),
                                      onOpen: mediaBusy || addingPhoto
                                          ? null
                                          : onOpenLinkedNote,
                                      onEdit: mediaBusy || addingPhoto
                                          ? null
                                          : onEditLinks,
                                    ),
                                    AnimatedSize(
                                      duration: MediaQuery.disableAnimationsOf(
                                              context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 180),
                                      alignment: Alignment.topCenter,
                                      child: reminderSuggestion == null
                                          ? const SizedBox(
                                              width: double.infinity)
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12),
                                              child: ReminderSuggestionChip(
                                                date: reminderSuggestion!.date,
                                                busy: savingReminder,
                                                onPressed: onReminderSuggestion,
                                                onDismiss:
                                                    onDismissReminderSuggestion,
                                              ),
                                            ),
                                    ),
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
    );
  }
}
