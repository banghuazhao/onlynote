import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:screenshot/screenshot.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    Key? key,
    required this.note,
    this.selected = false,
    this.onLongPress,
    this.onTap,
    this.screenshotController,
  }) : super(key: key);

  final Note note;
  final bool selected;
  final Function()? onLongPress;
  final Function()? onTap;

  /// Lets a parent capture the same rendered content for its own actions
  /// (e.g. a long-press context menu's "Share" item). Falls back to an
  /// internally-owned controller when not provided.
  final ScreenshotController? screenshotController;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  late final ScreenshotController _screenshotController =
      widget.screenshotController ?? ScreenshotController();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  Future<void> _shareNoteAsImage() async {
    try {
      await ShareHelper.shareWidgetAsImage(
        _screenshotController,
        fileName:
            '${widget.note.title?.isNotEmpty == true ? widget.note.title : 'note'}.png',
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

  @override
  Widget build(BuildContext context) {
    Reminder? currentReminder =
        ReminderData.shared.getCurrentReminder(widget.note);
    final Note note = widget.note;
    // Title is optional — fall back to the description so the card still
    // shows something meaningful for title-less notes.
    final String headlineText =
        note.title?.isNotEmpty == true ? note.title! : (note.description ?? '');

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        type: MaterialType.card,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(AppSpacings.xl),
        color: note.color,
        shadowColor: Colors.black,
        elevation: 4,
        child: InkWell(
          splashColor: Colors.black12,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onLongPress: widget.onLongPress == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  widget.onLongPress!();
                },
          onTap: widget.onTap == null
              ? null
              : () {
                  _setPressed(false);
                  widget.onTap!();
                },
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
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    color: note.color ?? Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          headlineText,
                          style: AppTypography.cardTitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 4,
                        ),
                        const SizedBox(height: AppSpacings.m),
                        Text(
                          note.date,
                          style: AppTypography.description
                              .copyWith(color: Colors.black87),
                        ),
                        if (currentReminder != null)
                          const SizedBox(height: AppSpacings.m),
                        if (currentReminder != null)
                          Text(
                            "⏰ " + currentReminder.timeString,
                            style: AppTypography.description
                                .copyWith(color: Colors.black87),
                          ),
                        const SizedBox(height: AppSpacings.m),
                        if (note.hasTodo) ...{
                          _BuildTodoList(todoList: note.todo.take(2).toList()),
                        },
                        if (note.hasImages) ...{
                          const SizedBox(height: AppSpacings.m),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacings.m),
                            child: Image.file(
                              File(ImageStorage.resolvePath(note.imagePaths.first)),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                        },
                      ],
                    ),
                  ),
                ),
                if (widget.selected)
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
                  )
                else
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Material(
                      key: _shareButtonKey,
                      color: Colors.black.withOpacity(0.08),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _shareNoteAsImage,
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ),
                      ),
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
