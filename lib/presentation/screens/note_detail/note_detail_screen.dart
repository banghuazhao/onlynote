import 'dart:io';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/common/extension/random.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:screenshot/screenshot.dart';

import 'bloc/action/note_action_bloc.dart';
import 'bloc/detail/note_detail_bloc.dart';

@RoutePage(name: 'NoteDetailRoute')
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({Key? key, @PathParam('noteId') required this.noteId})
      : super(key: key);
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

  Future<void> _shareNoteAsImage(Note note) async {
    try {
      await ShareHelper.shareWidgetAsImage(
        _screenshotController,
        fileName: '${note.title?.isNotEmpty == true ? note.title : 'note'}.png',
        sharePositionOrigin: ShareHelper.shareOriginFromKey(_shareButtonKey),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).Share_Note_Failed)),
        );
      }
    }
  }

  Future<void> _showReminderPicker(BuildContext context, Note note) async {
    final currentReminder = ReminderData.shared.getCurrentReminder(note);

    if (currentReminder == null) {
      bool? permissionResult =
          await NotificationService().checkAndAskForPermission(context);
      if (permissionResult != null && permissionResult == true) {
        if (!context.mounted) return;
        DatePicker.showDateTimePicker(context, minTime: DateTime.now(),
            onConfirm: (date) {
          Reminder reminder = Reminder(
              reminderId:
                  DateTime.now().difference(DateTime(2020, 1, 1)).inSeconds,
              reminderDate: DateTime(
                  date.year, date.month, date.day, date.hour, date.minute),
              noteId: note.id!);

          ReminderData.shared.addReminder(reminder);

          NotificationService()
              .askForPermissionAndSchedule(context, note, reminder);

          if (mounted) setState(() {});
        });
      }
    } else {
      showAdaptiveActionSheet(
        context: context,
        androidBorderRadius: 30,
        actions: <BottomSheetAction>[
          BottomSheetAction(
              title: Text(S.of(context).Edit),
              onPressed: (BuildContext context) async {
                bool? permissionResult = await NotificationService()
                    .checkAndAskForPermission(context);
                if (permissionResult != null && permissionResult == true) {
                  if (!context.mounted) return;
                  DatePicker.showDateTimePicker(context,
                      minTime: DateTime.now(), onConfirm: (date) {
                    Reminder newReminder = Reminder(
                        reminderId: currentReminder.reminderId,
                        reminderDate: DateTime(date.year, date.month, date.day,
                            date.hour, date.minute),
                        noteId: note.id!);

                    ReminderData.shared
                        .modifyReminder(currentReminder, newReminder);

                    NotificationService().askForPermissionAndSchedule(
                        context, note, newReminder);

                    if (mounted) setState(() {});
                    Navigator.pop(context);
                  });
                }
              }),
          BottomSheetAction(
              title: Text(
                S.of(context).Delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: (BuildContext context) {
                ReminderData.shared.deleteReminder(currentReminder);
                NotificationService().removeNotification(currentReminder);
                if (mounted) setState(() {});
                Navigator.pop(context);
              }),
        ],
        cancelAction: CancelAction(
            title: Text(S
                .of(context)
                .Cancel)), // onPressed parameter is optional by default will dismiss the ActionSheet
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteDetailBloc, NoteDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: state.whenOrNull(
            success: (note) => note.color ?? colors.randomElement,
          ),
          appBar: NoteAppBar(
            actions: state.whenOrNull(
              success: (note) {
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
                    onPressed: () {
                      context.router.push(AddUpdateNoteRoute(note: note));
                    },
                  ),
                  AppButton(
                    tooltip: S.of(context).Delete,
                    child: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: S.of(context).Delete_Note_Confirm_Title,
                        message: S.of(context).Delete_Note_Confirm_Message,
                      );
                      if (!confirmed) return;

                      Reminder? currentReminder =
                          ReminderData.shared.getCurrentReminder(note);
                      if (currentReminder != null) {
                        ReminderData.shared.deleteReminder(currentReminder);
                        NotificationService()
                            .removeNotification(currentReminder);
                      }
                      context
                          .read<NoteActionBloc>()
                          .add(NoteActionEvent.deleteNote(note.id!));
                    },
                  ),
                ];
              },
            ),
          ),
          body: state.maybeMap(
            error: (error) => ErrorText(error.message ?? ''),
            success: (data) => LoadedView(
              note: data.note,
              screenshotController: _screenshotController,
              onReminderTap: () => _showReminderPicker(context, data.note),
            ),
            orElse: () => const _DetailSkeleton(),
          ),
        );
      },
    );
  }
}

class LoadedView extends StatelessWidget {
  const LoadedView({
    Key? key,
    required this.note,
    required this.screenshotController,
    required this.onReminderTap,
  }) : super(key: key);

  final Note note;
  final ScreenshotController screenshotController;
  final VoidCallback onReminderTap;

  @override
  Widget build(BuildContext context) {
    Reminder? currentReminder = ReminderData.shared.getCurrentReminder(note);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.tokens.contentMaxWidth),
        child: ListView(
          padding: EdgeInsets.all(context.tokens.space4),
          children: [
            //* Everything inside here is captured when sharing the note as an image.
            Screenshot(
              controller: screenshotController,
              child: Container(
                color: note.color ?? Colors.white,
                padding: const EdgeInsets.all(AppSpacings.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //* Show Note Title
                    if (note.title?.isNotEmpty == true) ...[
                      SelectableText(note.title!,
                          style: AppTypography.headline3),
                      const SizedBox(height: AppSpacings.l),
                    ],

                    //* Show Note Update/Add time
                    SelectableText(
                      note.dateWithTime,
                      style: AppTypography.description
                          .copyWith(color: Colors.black87),
                    ),

                    //* Show reminder time, only if one is actually set.
                    if (currentReminder != null) ...{
                      const SizedBox(height: AppSpacings.m),
                      InkWell(
                        borderRadius:
                            BorderRadius.circular(context.tokens.radiusSmall),
                        onTap: onReminderTap,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: context.tokens.space2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alarm,
                                  size: 16, color: Colors.black87),
                              const SizedBox(width: AppSpacings.s),
                              Text(
                                currentReminder.timeString,
                                style: AppTypography.description
                                    .copyWith(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    },
                    const SizedBox(height: AppSpacings.xxl),

                    //* Show todo's list if any
                    if (note.hasTodo) ...{
                      _BuildTodoList(todoList: note.todo),
                      const SizedBox(height: AppSpacings.xxl),
                    },

                    //* Note Description
                    SelectableText(
                      note.description ?? '',
                      style: AppTypography.headline6,
                    ),

                    //* Attached photos, if any
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
  const _BuildTodoList({Key? key, required this.todoList}) : super(key: key);
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
          style: AppTypography.headline6
              .copyWith(decoration: TextDecoration.underline),
        ),
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
                AnimatedOpacity(
                  key: ValueKey(todo.id),
                  opacity: todo.completed ? 0.6 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    value: todo.completed,
                    contentPadding: EdgeInsets.zero,
                    enableFeedback: true,
                    title: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: AppTypography.title.copyWith(
                        decoration:
                            todo.completed ? TextDecoration.lineThrough : null,
                      ),
                      child: Text(todo.title ?? ''),
                    ),
                    onChanged: (bool? value) {
                      HapticFeedback.lightImpact();
                      context
                          .read<NoteDetailBloc>()
                          .add(NoteDetailEvent.toggleTodoCheckbox(todo.id!));
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuildImageGallery extends StatelessWidget {
  const _BuildImageGallery({Key? key, required this.imagePaths})
      : super(key: key);
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
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagePaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacings.m),
        itemBuilder: (context, index) {
          return Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(context.tokens.radiusSmall),
            child: InkWell(
              onTap: () => _openFullScreen(context, index),
              child: Hero(
                tag: 'note-image-${imagePaths[index]}',
                child: Image.file(
                  File(ImageStorage.resolvePath(imagePaths[index])),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  semanticLabel: S.of(context).Choose_From_Gallery,
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

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({
    Key? key,
    required this.imagePaths,
    required this.initialIndex,
  }) : super(key: key);

  final List<String> imagePaths;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child:
                  Image.file(File(ImageStorage.resolvePath(imagePaths[index]))),
            ),
          );
        },
      ),
    );
  }
}
