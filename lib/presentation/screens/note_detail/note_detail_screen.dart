import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:flutter/material.dart';
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
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/presentation/components/reminder_picker_sheet.dart';

import 'bloc/action/note_action_bloc.dart';
import 'bloc/detail/note_detail_bloc.dart';

@RoutePage(name: 'NoteDetailRoute')
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen(
      {super.key,
      @PathParam('noteId') required this.noteId,
      this.templateStore});
  final String noteId;
  final CustomNoteTemplateStore? templateStore;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _savingReminder = false;
  bool _exportingImage = false;
  bool _savingTemplate = false;
  Note? _lastSavedNote;
  int _reviewGeneration = 0;
  WidgetCommands? _widgetCommands;

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

  @override
  void initState() {
    super.initState();
    _widgetCommands = WidgetCommands.initializedInstance;
    _widgetCommands?.updates.addListener(_refreshWidgetCompletion);

    if (mounted) {
      BlocProvider.of<NoteDetailBloc>(context)
          .add(NoteDetailEvent.showNote(widget.noteId));
    }
  }

  @override
  void dispose() {
    _widgetCommands?.updates.removeListener(_refreshWidgetCompletion);
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
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
    setState(() => _exportingImage = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      return await _screenshotController.capture(pixelRatio: 3);
    } finally {
      if (mounted) setState(() => _exportingImage = false);
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

  List<Widget> _trashActions(Note note) => [
        AppButton(
            key: _shareButtonKey,
            tooltip: S.of(context).Share,
            child: const Icon(Icons.share_outlined),
            onPressed: () => _shareNoteAsImage(note)),
        AppButton(
            tooltip: S.of(context).Restore,
            child: const Icon(Icons.restore_outlined),
            onPressed: () async {
              final result = await getIt<RestoreNotesUsecase>()([note.id!]);
              if (!mounted) return;
              result.fold(
                  (error) =>
                      context.showToast('${error.message}', isError: true),
                  (remindersRestored) {
                context
                    .read<NoteDetailBloc>()
                    .add(NoteDetailEvent.showNote(note.id!));
                context.showToast(remindersRestored
                    ? S.of(context).Notes_Restored
                    : S.of(context).Restore_Reminder_Warning);
              });
            }),
        AppButton(
            destructive: true,
            tooltip: S.of(context).Delete_Forever,
            child: const Icon(Icons.delete_forever_outlined),
            onPressed: () async {
              final confirmed = await showConfirmDialog(context,
                  title: S.of(context).Permanent_Delete_Confirm_Title,
                  message: S.of(context).Permanent_Delete_Confirm_Message);
              if (!confirmed || !mounted) return;
              final result =
                  await getIt<PermanentDeleteNotesUsecase>()([note.id!]);
              if (!mounted) return;
              result.fold(
                  (error) =>
                      context.showToast('${error.message}', isError: true),
                  (_) => context.router.popUntilRoot());
            }),
      ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NoteDetailBloc, NoteDetailState>(
      listener: (_, state) => _observeSavedChecklist(state),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: DeskSurface.colorOf(context),
          appBar: NoteAppBar(
            actions: state.whenOrNull(
              success: (note) {
                if (note.isDeleted) return _trashActions(note);
                final hasReminder =
                    ReminderData.shared.getCurrentReminder(note) != null;
                return [
                  AppButton(
                    tooltip: S.of(context).Reminder,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
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
                    onPressed: () async {
                      await context.router.push(AddUpdateNoteRoute(note: note));
                      if (!context.mounted) return;
                      //* Reload the note so edits made on the form screen show up.
                      context
                          .read<NoteDetailBloc>()
                          .add(NoteDetailEvent.showNote(widget.noteId));
                    },
                  ),
                  AppButton(
                    tooltip: S.of(context).More_Options,
                    isLoading: _savingTemplate,
                    child: const Icon(Icons.more_horiz_rounded),
                    onPressed: () => _showMoreOptions(note),
                  ),
                ];
              },
            ),
          ),
          body: DeskSurface(
            child: state.maybeMap(
              error: (error) => ErrorText(error.message ?? ''),
              success: (data) => LoadedView(
                note: data.note,
                screenshotController: _screenshotController,
                exportMode: _exportingImage,
                onChecklistActionStart: () => _reviewGeneration++,
                onReminderTap: data.note.isDeleted
                    ? null
                    : () => _showReminderPicker(data.note),
              ),
              orElse: () => const _DetailSkeleton(),
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
  });

  final Note note;
  final ScreenshotController screenshotController;
  final VoidCallback? onReminderTap;
  final VoidCallback? onChecklistActionStart;
  final bool exportMode;

  @override
  Widget build(BuildContext context) {
    Reminder? currentReminder = ReminderData.shared.getCurrentReminder(note);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.tokens.contentMaxWidth),
        child: ListView(
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
                      SelectableText(
                        note.title!,
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
                        readOnly: note.isDeleted,
                        exportMode: exportMode,
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
                    SelectableText(
                      note.description ?? '',
                      style: AppTypography.headline6.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.ink.withValues(alpha: 0.88),
                      ),
                    ),
                    if (note.hasImages) ...{
                      const SizedBox(height: AppSpacings.xxl),
                      _BuildImageGallery(imagePaths: note.imagePaths),
                    },
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

class _BuildImageGallery extends StatelessWidget {
  const _BuildImageGallery({required this.imagePaths});
  final List<String> imagePaths;

  void _openFullScreen(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImageViewer(
          imagePaths: imagePaths,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagePaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacings.l),
        itemBuilder: (context, index) {
          return Material(
            color: Colors.white.withValues(alpha: 0.86),
            elevation: 1,
            shadowColor: Colors.black26,
            child: InkWell(
              onTap: () => _openFullScreen(context, index),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 14),
                child: Hero(
                  tag: 'note-image-${imagePaths[index]}',
                  child: NoteImage(
                    path: imagePaths[index],
                    width: 100,
                    height: 88,
                    semanticLabel: S.of(context).Choose_From_Gallery,
                  ),
                ),
              ),
            ),
          );
        },
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
