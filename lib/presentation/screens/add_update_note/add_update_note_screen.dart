import 'package:onlynote/presentation/theme/button_styles.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_templates.dart';
import 'package:onlynote/services/note_photo_capture.dart';
import 'package:onlynote/services/note_reminder_scheduler.dart';
import 'package:onlynote/services/reminder_date_suggestion.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onlynote/Tools/image_storage.dart';
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
enum NoteEditorStart { standard, quickNote, checklist, photo }

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
  final NoteReminderScheduler? reminderScheduler;
  final WidgetCommands? widgetCommands;
  final NoteEditorStart start;

  @override
  State<AddUpdateNoteScreen> createState() => _AddUpdateNoteScreenState();
}

class _AddUpdateNoteScreenState extends State<AddUpdateNoteScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final AddUpdateFormBloc _form;
  late final NoteAutosave _autosave;
  late final StreamSubscription<AddUpdateFormState> _changes;
  late final NotePhotoCapture _photoCapture;
  late final NoteReminderScheduler _reminderScheduler;
  VoidCallback? _unregisterWidgetEditor;
  Timer? _suggestionDebounce;
  ReminderDateSuggestion? _reminderSuggestion;
  final Set<String> _dismissedSuggestions = {};
  String? _lastSuggestionText;
  bool _savingReminder = false;
  bool _presentingReminder = false;
  Animation<double>? _entryAnimation;
  bool _photoStarted = false;
  bool _addingPhoto = false;
  bool _leaving = false;
  bool _allowPop = false;
  bool _hadUserChange = false;
  bool _recordedReviewSave = false;

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
    final initial = recovered?.toDomain() ??
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
    _titleController = TextEditingController(text: initial.title);
    _descriptionController = TextEditingController(text: initial.description);
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
          selectedColor: initial.color,
          todos: initial.todo,
          imagePaths: initial.imagePaths,
        ));
    _changes = _form.stream.listen((state) {
      _hadUserChange = true;
      _capture(state);
      _queueReminderSuggestion();
    });
    final widgetCommands =
        widget.widgetCommands ?? WidgetCommands.initializedInstance;
    if (initial.id != null) {
      _unregisterWidgetEditor =
          widgetCommands?.registerEditor(initial.id!, _applyWidgetCompletion);
    }
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
    if (widget.start != NoteEditorStart.photo ||
        widget.note != null ||
        _photoStarted) {
      return;
    }
    _photoStarted = true;
    // UIKit needs the editor's presentation transition to finish before it
    // can present the camera. Rebuilds and resumes must not launch it twice.
    _entryAnimation = ModalRoute.of(context)?.animation;
    if (_entryAnimation != null &&
        _entryAnimation!.status != AnimationStatus.completed) {
      _entryAnimation!.addStatusListener(_onPhotoEntryStatus);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_addPhoto(ImageSource.camera));
      });
    }
  }

  void _onPhotoEntryStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _entryAnimation?.removeStatusListener(_onPhotoEntryStatus);
    if (mounted) unawaited(_addPhoto(ImageSource.camera));
  }

  Future<void> _addPhoto(ImageSource source, {bool retry = false}) async {
    if (_addingPhoto || _savingReminder || _presentingReminder || _leaving) {
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
      final path =
          await (retry ? _photoCapture.retry() : _photoCapture.capture(source));
      if (path == null) return;
      if (!mounted) {
        if (!_photoCapture.isJournaled) {
          await ImageStorage.deleteImages([path]);
        }
        return;
      }
      _form.add(AddUpdateFormEvent.addImage(path));
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      _capture(_form.state);
      if (await _autosave.flush()) {
        await _photoCapture.complete();
      } else if (mounted) {
        showTransientSnackBar(
            context, SnackBar(content: Text(S.of(context).Autosave_Failed)));
      }
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

  void _capture(AddUpdateFormState state) {
    final next = _autosave.note.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      color: state.selectedColor,
      todo: state.todos,
      imagePaths: state.imagePaths,
    );
    if (next != _autosave.note) {
      _autosave.update(next.copyWith(dateTime: DateTime.now()));
    }
  }

  String get _reminderText => [
        _titleController.text,
        _descriptionController.text,
        ..._form.state.todos.map((todo) => todo.title ?? ''),
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
    if (_savingReminder || _presentingReminder || _addingPhoto || _leaving) {
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

  Future<bool> _applyWidgetCompletion(WidgetTodoCommand command) async {
    if (!mounted || _leaving || command.noteId != _autosave.note.id) {
      return false;
    }
    // Drain queued typing/reorder events, then change only completion in the
    // current form. Draft text, task labels, images, and ordering stay intact.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return false;
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
      if (!mounted) return false;
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
    if (state != AppLifecycleState.resumed) {
      _capture(_form.state);
      unawaited(_autosave.flush());
    }
  }

  Future<void> _finish() async {
    if (_leaving || _addingPhoto || _savingReminder || _presentingReminder) {
      return;
    }
    if (_photoCapture.canRetry) {
      await _addPhoto(ImageSource.camera, retry: true);
      if (!mounted || _photoCapture.canRetry) return;
    }
    _leaving = true;
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
    _entryAnimation?.removeStatusListener(_onPhotoEntryStatus);
    WidgetsBinding.instance.removeObserver(this);
    _changes.cancel();
    _form.close();
    _autosave.removeListener(_refreshStatus);
    unawaited(_autosave.flush().whenComplete(_autosave.dispose));
    _titleController.dispose();
    _descriptionController.dispose();
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
              status: _autosave.status,
              onDone: _finish,
              onAddPhoto: _addPhoto,
              addingPhoto: _addingPhoto,
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
    required TextEditingController descriptionController,
    required this.state,
    required this.status,
    required this.onDone,
    required this.onAddPhoto,
    required this.addingPhoto,
    required this.reminderSuggestion,
    required this.savingReminder,
    required this.onReminderSuggestion,
    required this.onDismissReminderSuggestion,
  })  : _titleController = titleController,
        _descriptionController = descriptionController;

  final AddUpdateNoteScreen widget;
  final TextEditingController _titleController;
  final TextEditingController _descriptionController;
  final AddUpdateFormState state;
  final AutosaveStatus status;
  final VoidCallback onDone;
  final ValueChanged<ImageSource> onAddPhoto;
  final bool addingPhoto;
  final ReminderDateSuggestion? reminderSuggestion;
  final bool savingReminder;
  final VoidCallback onReminderSuggestion;
  final VoidCallback onDismissReminderSuggestion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      bottomNavigationBar: ColorsBar(
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
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onDone,
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
          AppButton(
              primary: true,
              tooltip: S.of(context).Done,
              onPressed: onDone,
              child: Text(S.of(context).Done))
        ],
      ),
      body: DeskSurface(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.tokens.contentMaxWidth),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  padding: const EdgeInsetsDirectional.fromSTEB(32, 20, 16, 24),
                  child: Column(
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
                            (widget.start == NoteEditorStart.checklist ||
                                widget.template == NoteTemplate.shopping ||
                                widget.template == NoteTemplate.packing),
                      ),
                      SizedBox(
                          height: state.imagePaths.isEmpty
                              ? AppSpacings.m
                              : AppSpacings.xl),
                      _BuildImageSection(
                        state: state,
                        onAddPhoto: onAddPhoto,
                        addingPhoto: addingPhoto,
                      ),
                      const SizedBox(height: AppSpacings.xml),
                      _BuildDescriptionField(
                        state: state,
                        descriptionController: _descriptionController,
                        autofocus: widget.note == null &&
                            widget.start == NoteEditorStart.quickNote,
                      ),
                      AnimatedSize(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        alignment: Alignment.topCenter,
                        child: reminderSuggestion == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: ReminderSuggestionChip(
                                  date: reminderSuggestion!.date,
                                  busy: savingReminder,
                                  onPressed: onReminderSuggestion,
                                  onDismiss: onDismissReminderSuggestion,
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
    );
  }
}
