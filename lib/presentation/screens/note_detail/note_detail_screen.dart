import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/services/reminder_shortcuts.dart';

import 'bloc/action/note_action_bloc.dart';
import 'bloc/detail/note_detail_bloc.dart';

@RoutePage(name: 'NoteDetailRoute')
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen(
      {super.key, @PathParam('noteId') required this.noteId});
  final String noteId;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (mounted) {
      BlocProvider.of<NoteDetailBloc>(context)
          .add(NoteDetailEvent.showNote(widget.noteId));
    }
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
      );

  Future<void> _showReminderPicker(BuildContext context, Note note) async {
    final current = ReminderData.shared.getCurrentReminder(note);
    await showAppActionSheet(
      context: context,
      title: S.of(context).Reminder,
      actions: [
        for (final shortcut in ReminderShortcut.values)
          AppSheetAction(
            leading: Icon(switch (shortcut) {
              ReminderShortcut.inOneHour => Icons.schedule_outlined,
              ReminderShortcut.tomorrowMorning => Icons.wb_sunny_outlined,
              ReminderShortcut.nextWeek => Icons.event_outlined,
            }),
            title: Text(switch (shortcut) {
              ReminderShortcut.inOneHour => S.of(context).Reminder_In_One_Hour,
              ReminderShortcut.tomorrowMorning =>
                S.of(context).Reminder_Tomorrow,
              ReminderShortcut.nextWeek => S.of(context).Reminder_Next_Week,
            }),
            subtitle: Text(
                _formatReminderTime(context, shortcut.resolve(DateTime.now()))),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              _saveReminder(note, shortcut.resolve(DateTime.now()),
                  current: current);
            },
          ),
        AppSheetAction(
          leading: const Icon(Icons.edit_calendar_outlined),
          title: Text(S.of(context).Reminder_Custom),
          subtitle: current == null
              ? null
              : Text(_formatReminderTime(context, current.reminderDate)),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _editReminder(note, current: current);
          },
        ),
        if (current != null)
          AppSheetAction(
            destructive: true,
            leading: const Icon(Icons.notifications_off_outlined),
            title: Text(S.of(context).Delete),
            onPressed: (sheetContext) async {
              Navigator.pop(sheetContext);
              try {
                await NotificationService().removeNotification(current);
                await ReminderData.shared.deleteReminder(current);
                if (context.mounted) setState(() {});
              } catch (_) {
                if (context.mounted) {
                  showTransientSnackBar(
                      context,
                      SnackBar(
                          content: Text(S.of(context).Reminder_Save_Failed)));
                }
              }
            },
          ),
      ],
    );
  }

  String _formatReminderTime(BuildContext context, DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(date)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
  }

  Future<void> _editReminder(Note note, {Reminder? current}) async {
    final now = DateTime.now();
    final initial = current != null && current.reminderDate.isAfter(now)
        ? current.reminderDate
        : now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      helpText: S.of(context).Reminder,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      helpText: S.of(context).Reminder,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final reminderDate =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!reminderDate.isAfter(DateTime.now())) {
      showTransientSnackBar(
          context, SnackBar(content: Text(S.of(context).Reminder_Future_Time)));
      return;
    }
    await _saveReminder(note, reminderDate, current: current);
  }

  Future<void> _saveReminder(Note note, DateTime date,
      {Reminder? current}) async {
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
      final reminder =
          Reminder(reminderId: id, reminderDate: date, noteId: note.id!);
      if (!date.isAfter(DateTime.now())) {
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
    return BlocBuilder<NoteDetailBloc, NoteDetailState>(
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
                    onPressed: () => _showReminderPicker(context, note),
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
                    destructive: true,
                    tooltip: S.of(context).Delete,
                    child: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      context
                          .read<NoteActionBloc>()
                          .add(NoteActionEvent.deleteNote(note.id!));
                    },
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
                onReminderTap: data.note.isDeleted
                    ? null
                    : () => _showReminderPicker(context, data.note),
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
  });

  final Note note;
  final ScreenshotController screenshotController;
  final VoidCallback? onReminderTap;

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
                                Text(
                                  currentReminder.timeString,
                                  style: AppTypography.description.copyWith(
                                    color: AppColors.ink.withValues(alpha: 0.7),
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
                      _BuildTodoList(
                          todoList: note.todo, readOnly: note.isDeleted),
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

class _BuildTodoList extends StatelessWidget {
  const _BuildTodoList({required this.todoList, this.readOnly = false});
  final bool readOnly;
  final List<Todo> todoList;

  @override
  Widget build(BuildContext context) {
    final sortedTodos = [...todoList]..sort((left, right) {
        if (left.completed == right.completed) return 0;
        return left.completed ? 1 : -1;
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).Todo_list,
          style: AppTypography.headline6.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: AppColors.ink.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: AppSpacings.m),
        AnimatedSwitcher(
          duration: context.tokens.motionStandard,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.06),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(sortedTodos
                .map((todo) => '${todo.id}:${todo.completed}')
                .join('|')),
            children: [
              for (final todo in sortedTodos)
                PaperChecklistRow(
                  key: ValueKey(todo.id),
                  label: todo.title ?? '',
                  completed: todo.completed,
                  onChanged: readOnly
                      ? null
                      : (_) {
                          HapticFeedback.lightImpact();
                          context.read<NoteDetailBloc>().add(
                              NoteDetailEvent.toggleTodoCheckbox(todo.id!));
                        },
                ),
            ],
          ),
        ),
      ],
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
