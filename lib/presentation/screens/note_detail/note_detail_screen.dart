import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/common/extension/random.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';

import 'bloc/action/note_action_bloc.dart';
import 'bloc/detail/note_detail_bloc.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({Key? key, required this.noteId}) : super(key: key);
  final String noteId;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  @override
  void initState() {
    super.initState();

    if (mounted) {
      BlocProvider.of<NoteDetailBloc>(context).add(NoteDetailEvent.showNote(widget.noteId));
    }
  }

  @override
  void deactivate() {
    super.deactivate();
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
              success: (note) => [
                AppButton(
                  child: const Icon(FeatherIcons.edit),
                  onPressed: () {
                    context.router.push(AddUpdateNoteRoute(note: note));
                  },
                ),
                AppButton(
                  child: const Icon(FeatherIcons.trash2),
                  onPressed: () {
                    Reminder? currentReminder = ReminderData.shared.getCurrentReminder(note);
                    if (currentReminder != null) {
                      ReminderData.shared.deleteReminder(currentReminder);
                      NotificationService().removeNotification(currentReminder);
                    }
                    context.read<NoteActionBloc>().add(NoteActionEvent.deleteNote(note.id!));
                  },
                ),
              ],
            ),
          ),
          body: state.maybeMap(
            error: (error) => ErrorText(error.message ?? ''),
            success: (data) => LoadedView(note: data.note),
            orElse: () => const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class LoadedView extends StatefulWidget {
  const LoadedView({
    Key? key,
    required this.note,
  }) : super(key: key);

  final Note note;

  @override
  _LoadedViewState createState() => _LoadedViewState();
}

class _LoadedViewState extends State<LoadedView> {
  @override
  Widget build(BuildContext context) {
    Reminder? currentReminder = ReminderData.shared.getCurrentReminder(widget.note);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacings.xl,
        vertical: AppSpacings.xl,
      ),
      children: [
        //* Show Note Title
        SelectableText(
          widget.note.title ?? '',
          style: AppTypography.headline3,
        ),
        const SizedBox(height: AppSpacings.l),

        //* Show Note Update/Add time
        SelectableText(
          widget.note.dateWithTime,
          style: AppTypography.description.copyWith(color: Colors.black87),
        ),
        const SizedBox(height: AppSpacings.xxl),

        //* Show todo's list if any
        if (widget.note.hasTodo) ...{
          _BuildTodoList(todoList: widget.note.todo),
          const SizedBox(height: AppSpacings.xxl),
        },

        //* Note Description
        SelectableText(
          widget.note.description ?? '',
          style: AppTypography.headline6,
        ),

        const SizedBox(height: AppSpacings.xxl),

        ElevatedButton.icon(
            onPressed: () async {
              if (currentReminder == null) {
                bool? permissionResult =
                    await NotificationService().checkAndAskForPermission(context);
                if (permissionResult != null && permissionResult == true) {
                  DatePicker.showDateTimePicker(context, minTime: DateTime.now(),
                      onConfirm: (date) {
                    print('confirm $date');

                    Reminder reminder = Reminder(
                        reminderId: DateTime.now().difference(DateTime(2020, 1, 1)).inSeconds,
                        reminderDate:
                            DateTime(date.year, date.month, date.day, date.hour, date.minute),
                        noteId: widget.note.id!);

                    ReminderData.shared.addReminder(reminder);

                    NotificationService()
                        .askForPermissionAndSchedule(context, widget.note, reminder);

                    setState(() {});
                  });
                }
              } else {
                showAdaptiveActionSheet(
                  context: context,
                  androidBorderRadius: 30,
                  actions: <BottomSheetAction>[
                    BottomSheetAction(
                        title: Text(S.of(context).Edit),
                        onPressed: () async {
                          bool? permissionResult =
                              await NotificationService().checkAndAskForPermission(context);
                          if (permissionResult != null && permissionResult == true) {
                            DatePicker.showDateTimePicker(context, minTime: DateTime.now(),
                                onConfirm: (date) {
                              Reminder newReminder = Reminder(
                                  reminderId: currentReminder.reminderId,
                                  reminderDate: DateTime(
                                      date.year, date.month, date.day, date.hour, date.minute),
                                  noteId: widget.note.id!);

                              ReminderData.shared.modifyReminder(currentReminder, newReminder);

                              NotificationService()
                                  .askForPermissionAndSchedule(context, widget.note, newReminder);

                              setState(() {});
                              Navigator.pop(context);
                            });
                          }
                        }),
                    BottomSheetAction(
                        title: Text(
                          S.of(context).Delete,
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          ReminderData.shared.deleteReminder(currentReminder);
                          NotificationService().removeNotification(currentReminder);
                          setState(() {});
                          Navigator.pop(context);
                        }),
                  ],
                  cancelAction: CancelAction(
                      title: Text(S
                          .of(context)
                          .Cancel)), // onPressed parameter is optional by default will dismiss the ActionSheet
                );
              }
            },
            icon: const Icon(
              Icons.alarm_rounded,
            ),
            label: buildText(context, currentReminder))
      ],
    );
  }

  Text buildText(BuildContext context, Reminder? currentReminder) {
    if (currentReminder == null) {
      return Text(S.of(context).Add_Reminder);
    } else {
      return Text(currentReminder.timeString);
    }
  }
}

class _BuildTodoList extends StatelessWidget {
  const _BuildTodoList({Key? key, required this.todoList}) : super(key: key);
  final List<Todo> todoList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).Todo_list,
          style: AppTypography.headline6.copyWith(decoration: TextDecoration.underline),
        ),
        ListView.builder(
          key: const PageStorageKey('note-todos'),
          shrinkWrap: true,
          itemCount: todoList.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, index) {
            final Todo todo = todoList[index];

            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              value: todo.completed,
              contentPadding: EdgeInsets.zero,
              enableFeedback: true,
              title: Text(
                todo.title ?? '',
                style: AppTypography.title.copyWith(
                  decoration: todo.completed ? TextDecoration.lineThrough : null,
                ),
              ),
              onChanged: (bool? value) {
                context.read<NoteDetailBloc>().add(NoteDetailEvent.toggleTodoCheckbox(todo.id!));
              },
            );
          },
        ),
      ],
    );
  }
}
