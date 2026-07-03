import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    Key? key,
    required this.note,
    this.selected = false,
    this.onSelect,
    this.onTap,
  }) : super(key: key);

  final Note note;
  final bool selected;
  final Function()? onSelect;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    Reminder? currentReminder = ReminderData.shared.getCurrentReminder(note);

    return Material(
      type: MaterialType.card,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppSpacings.xl),
      color: note.color,
      shadowColor: Colors.black,
      elevation: 4,
      child: InkWell(
        splashColor: Colors.black12,
        onLongPress: onSelect,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            // maxHeight: 300,
            minHeight: 100,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacings.l,
            vertical: AppSpacings.l,
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    note.title ?? '',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 30,
                      color: AppColors.title,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacings.m),
                  Text(
                    note.date,
                    style: AppTypography.description.copyWith(color: Colors.black87),
                  ),
                  if (currentReminder != null) const SizedBox(height: AppSpacings.m),
                  if (currentReminder != null)
                    Text(
                      "⏰ " + currentReminder.timeString,
                      style: AppTypography.description.copyWith(color: Colors.black87),
                    ),
                  const SizedBox(height: AppSpacings.m),
                  if (note.hasTodo) ...{
                    _BuildTodoList(todoList: note.todo.take(2).toList()),
                  },
                ],
              ),
              if (selected)
                Align(
                  alignment: Alignment.topRight,
                  heightFactor: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          spreadRadius: 20,
                          color: note.color ?? AppColors.primary,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.check,
                        color: note.color,
                        size: 20,
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

class _BuildTodoList extends StatelessWidget {
  const _BuildTodoList({Key? key, required this.todoList}) : super(key: key);
  final List<Todo> todoList;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: todoList.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) {
        final Todo todo = todoList[index];

        return AbsorbPointer(
          absorbing: true,
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            value: todo.completed,
            contentPadding: EdgeInsets.zero,
            title: Text(
              todo.title ?? '',
              style: AppTypography.title.copyWith(
                decoration: todo.completed ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onChanged: (bool? value) {
              // context.read<NoteDetailBloc>().add(NoteDetailEvent.toggleTodoCheckbox(todo.id!));
            },
          ),
        );
      },
    );
  }
}
