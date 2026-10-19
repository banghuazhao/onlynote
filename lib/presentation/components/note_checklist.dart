import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/Tools/app_checklist_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/services/unfinished_checklist.dart';

/// The interactive reader for a saved checklist. Filtering completed items is
/// only a presentation choice: the note retains the order chosen in the editor.
class NoteChecklist extends StatefulWidget {
  const NoteChecklist({
    super.key,
    required this.todos,
    this.readOnly = false,
    this.exportMode = false,
    this.onToggle,
    this.onReset,
    this.titleBuilder,
    this.expandCompleted = false,
    this.clipboardWriter,
    this.settings,
  });

  final List<Todo> todos;
  final bool readOnly;

  /// Expands every item and hides actions while the parent captures an image.
  final bool exportMode;
  final ValueChanged<String>? onToggle;
  final VoidCallback? onReset;
  final Widget Function(Todo todo, TextStyle style)? titleBuilder;
  final bool expandCompleted;

  /// A shared display preference; injection keeps previews and tests isolated.
  final AppChecklistSettings? settings;

  /// An optional clipboard adapter for isolated previews and tests. Copying
  /// shares a snapshot of the unfinished titles and never changes the note.
  /// The reader uses [Clipboard.setData] when no adapter is provided.
  final Future<void> Function(String text)? clipboardWriter;

  @override
  State<NoteChecklist> createState() => _NoteChecklistState();
}

class _NoteChecklistState extends State<NoteChecklist> {
  late AppChecklistSettings _settings;
  bool _copying = false;
  bool _copyFailed = false;
  int? _copiedCount;

  @override
  void initState() {
    super.initState();
    _bindSettings();
  }

  void _bindSettings() {
    _settings = widget.settings ?? AppChecklistSettings.instance;
    _settings.addListener(_settingsChanged);
    unawaited(_settings.load());
  }

  void _settingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant NoteChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings.removeListener(_settingsChanged);
      _bindSettings();
    }
    if (oldWidget.todos != widget.todos) {
      _copyFailed = false;
      _copiedCount = null;
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_settingsChanged);
    super.dispose();
  }

  Future<void> _copyUnfinished() async {
    if (_copying || widget.exportMode) return;
    final titles = unfinishedChecklistTitles(widget.todos);
    if (titles.isEmpty) return;
    final text = titles.join('\n');
    setState(() {
      _copying = true;
      _copyFailed = false;
      _copiedCount = null;
    });
    try {
      final writer = widget.clipboardWriter;
      if (writer == null) {
        await Clipboard.setData(ClipboardData(text: text));
      } else {
        await writer(text);
      }
      if (!mounted) return;
      setState(() {
        _copying = false;
        _copiedCount = titles.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _copying = false;
        _copyFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedExpanded = _settings.completedExpanded;
    final active = widget.todos.where((todo) => !todo.completed).toList();
    final completed = widget.todos.where((todo) => todo.completed).toList();
    final canCopy = !widget.exportMode &&
        unfinishedChecklistTitles(widget.todos).isNotEmpty;
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        widget.exportMode ||
        widget.expandCompleted;
    final duration = reduceMotion ? Duration.zero : context.tokens.motionFast;
    final allDone = widget.todos.isNotEmpty && active.isEmpty;
    final progress =
        widget.todos.isEmpty ? 0.0 : completed.length / widget.todos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: context.tokens.space2,
          runSpacing: context.tokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(S.of(context).Todo_list, style: AppTypography.headline6),
            Text(
              S
                  .of(context)
                  .Checklist_Progress(completed.length, widget.todos.length),
              style: AppTypography.description.copyWith(
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ),
            if (canCopy)
              TextButton.icon(
                key: const ValueKey('checklist-copy-unfinished'),
                onPressed: _copying ? null : _copyUnfinished,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: Text(S.of(context).Checklist_Copy_Unfinished),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink.withValues(alpha: 0.8),
                  minimumSize: const Size(48, 48),
                ),
              ),
            if (completed.isNotEmpty &&
                !widget.readOnly &&
                !widget.exportMode &&
                widget.onReset != null)
              TextButton.icon(
                key: const ValueKey('checklist-reset'),
                onPressed: widget.onReset,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(S.of(context).Checklist_Reset),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink.withValues(alpha: 0.8),
                  minimumSize: const Size(44, 44),
                ),
              ),
          ],
        ),
        if (canCopy && (_copyFailed || _copiedCount != null))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacings.m),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _copyFailed
                    ? S.of(context).Checklist_Copy_Failed
                    : S.of(context).Checklist_Copy_Success(_copiedCount!),
                key: const ValueKey('checklist-copy-feedback'),
                style: AppTypography.description.copyWith(
                  color: _copyFailed
                      ? Theme.of(context).colorScheme.error
                      : AppColors.ink.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacings.m),
        Semantics(
          label: S
              .of(context)
              .Checklist_Progress(completed.length, widget.todos.length),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: duration,
            curve: Curves.easeOut,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 3,
              color: AppColors.ink.withValues(alpha: 0.55),
              backgroundColor: AppColors.ink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: AppSpacings.l),
        _ChecklistSize(
          duration: duration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final todo in active) _row(todo, duration),
              if (allDone)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacings.m),
                  child: Row(
                    children: [
                      const Icon(Icons.done_all_rounded, size: 20),
                      const SizedBox(width: AppSpacings.m),
                      Expanded(
                        child: Text(S.of(context).Checklist_All_Done,
                            style: AppTypography.formText),
                      ),
                    ],
                  ),
                ),
              if (completed.isNotEmpty) ...[
                const SizedBox(height: AppSpacings.m),
                if (widget.exportMode)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacings.m),
                    child: Text(
                        S.of(context).Checklist_Completed(completed.length),
                        style: AppTypography.description.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.65))),
                  )
                else
                  Semantics(
                    expanded: completedExpanded || widget.expandCompleted,
                    child: TextButton.icon(
                      key: const ValueKey('checklist-completed-toggle'),
                      onPressed: widget.expandCompleted
                          ? null
                          : () => unawaited(_settings.setCompletedExpanded(
                              !_settings.completedExpanded)),
                      icon: AnimatedRotation(
                        turns: completedExpanded || widget.expandCompleted
                            ? 0.25
                            : 0,
                        duration: duration,
                        child:
                            const Icon(Icons.chevron_right_rounded, size: 20),
                      ),
                      label: Text(
                          S.of(context).Checklist_Completed(completed.length)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.ink.withValues(alpha: 0.65),
                        minimumSize: const Size(44, 44),
                        padding:
                            const EdgeInsetsDirectional.only(start: 0, end: 12),
                      ),
                    ),
                  ),
                if (completedExpanded ||
                    widget.exportMode ||
                    widget.expandCompleted)
                  for (final todo in completed) _row(todo, duration),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(Todo todo, Duration duration) {
    final onToggle = !widget.readOnly &&
            !widget.exportMode &&
            todo.id != null &&
            widget.onToggle != null
        ? () => widget.onToggle!(todo.id!)
        : null;
    final label = todo.title ?? '';
    return Semantics(
      key: ValueKey('checklist-item-${todo.id}'),
      checked: todo.completed,
      label: label,
      enabled: onToggle != null,
      onTap: onToggle,
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacings.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AnimatedSwitcher(
                    duration: duration,
                    child: InkCheckbox(
                      key: ValueKey(todo.completed),
                      checked: todo.completed,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    style: AppTypography.formText.copyWith(
                      color: AppColors.ink
                          .withValues(alpha: todo.completed ? 0.5 : 0.88),
                      decoration:
                          todo.completed ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.ink.withValues(alpha: 0.45),
                    ),
                    child: widget.titleBuilder?.call(
                          todo,
                          AppTypography.formText.copyWith(
                            color: AppColors.ink
                                .withValues(alpha: todo.completed ? 0.5 : 0.88),
                            decoration: todo.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ) ??
                        Text(label),
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

/// Removing the size animator also prevents intermediate clipping in exports.
class _ChecklistSize extends StatelessWidget {
  const _ChecklistSize({required this.duration, required this.child});
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) => duration == Duration.zero
      ? child
      : AnimatedSize(
          duration: duration,
          alignment: Alignment.topCenter,
          curve: Curves.easeOut,
          child: child,
        );
}
