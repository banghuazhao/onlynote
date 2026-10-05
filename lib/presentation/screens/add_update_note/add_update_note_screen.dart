import 'package:onlynote/presentation/theme/button_styles.dart';
import 'dart:io';
import 'dart:async';
import 'package:animate_do/animate_do.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_templates.dart';
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
enum NoteEditorStart { standard, quickNote, checklist }

@RoutePage(name: 'AddUpdateNoteRoute')
class AddUpdateNoteScreen extends StatefulWidget {
  const AddUpdateNoteScreen(
      {super.key,
      this.note,
      this.folderId,
      this.template,
      this.customTemplateNote,
      this.autosaveStore,
      this.start = NoteEditorStart.standard});
  final Note? note;
  final String? folderId;
  final NoteTemplate? template;

  /// A newly instantiated custom template, already owning its photo copies.
  final Note? customTemplateNote;
  final NoteAutosaveStore? autosaveStore;
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
  bool _leaving = false;
  bool _allowPop = false;
  bool _hadUserChange = false;
  bool _recordedReviewSave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    });
    if (recovered != null) _autosave.update(initial.copyWith(dateTime: now));
    if (widget.note == null &&
        (widget.template != null || widget.customTemplateNote != null)) {
      _autosave.saveInitial();
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
    if (_leaving) return;
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
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.router.maybePop();
    });
  }

  @override
  void dispose() {
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
          canPop: _allowPop || !_autosave.dirty,
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
  })  : _titleController = titleController,
        _descriptionController = descriptionController;

  final AddUpdateNoteScreen widget;
  final TextEditingController _titleController;
  final TextEditingController _descriptionController;
  final AddUpdateFormState state;
  final AutosaveStatus status;
  final VoidCallback onDone;

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
                      _BuildImageSection(state: state),
                      const SizedBox(height: AppSpacings.xml),
                      _BuildDescriptionField(
                        state: state,
                        descriptionController: _descriptionController,
                        autofocus: widget.note == null &&
                            widget.start == NoteEditorStart.quickNote,
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
