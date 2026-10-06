import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/services/note_find.dart';

class NoteFindBar extends StatefulWidget {
  const NoteFindBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.noMatchesText,
    required this.previousTooltip,
    required this.nextTooltip,
    required this.closeTooltip,
    required this.onClose,
    this.onEditMatch,
    this.onReplace,
    this.onReplaceAll,
    this.editMatchTooltip = 'Edit match',
    this.replaceToggleLabel = 'Replace',
    this.replaceHintText = 'Replace with',
    this.replaceLabel = 'Replace',
    this.replaceAllLabel = 'Replace all',
    this.actionsEnabled = true,
    this.initialReplaceVisible = false,
    this.onComposingChanged,
  });
  final NoteSearchController controller;
  final String hintText;
  final String noMatchesText;
  final String previousTooltip;
  final String nextTooltip;
  final String closeTooltip;
  final VoidCallback onClose;
  final FutureOr<void> Function(NoteSearchMatch)? onEditMatch;
  final FutureOr<void> Function(NoteSearchMatch, String)? onReplace;
  final FutureOr<void> Function(String)? onReplaceAll;
  final String editMatchTooltip;
  final String replaceToggleLabel;
  final String replaceHintText;
  final String replaceLabel;
  final String replaceAllLabel;
  final bool actionsEnabled;
  final bool initialReplaceVisible;
  final ValueChanged<bool>? onComposingChanged;

  @override
  State<NoteFindBar> createState() => _NoteFindBarState();
}

class _NoteFindBarState extends State<NoteFindBar> {
  late final TextEditingController _text;
  late final FocusNode _focus;
  final _replacement = TextEditingController();
  bool _replaceOpen = false;
  bool _busy = false;
  bool _reportedComposing = false;

  bool get _composing => [_text, _replacement].any((controller) =>
      controller.value.composing.isValid &&
      !controller.value.composing.isCollapsed);

  bool get _canAct => !_busy && widget.actionsEnabled && !_composing;

  void _inputChanged() {
    final composing = _composing;
    if (composing != _reportedComposing) {
      _reportedComposing = composing;
      widget.onComposingChanged?.call(composing);
    }
    if (mounted) setState(() {});
  }

  Future<void> _runAction(FutureOr<void> Function() action) async {
    if (!_canAct) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _replaceOpen = widget.initialReplaceVisible;
    _text = TextEditingController(text: widget.controller.query);
    _text.addListener(_inputChanged);
    _replacement.addListener(_inputChanged);
    _focus = FocusNode(debugLabel: 'Find query');
    // A route that already has a focused child may ignore a newly inserted
    // field's autofocus. Opening Find should always focus its query.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _text.removeListener(_inputChanged);
    _replacement.removeListener(_inputChanged);
    _text.dispose();
    _replacement.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (!_busy && !_composing) widget.onClose();
          },
          const SingleActivator(LogicalKeyboardKey.enter): () {
            if (!_busy && !_composing) widget.controller.next();
          },
          const SingleActivator(LogicalKeyboardKey.enter, shift: true): () {
            if (!_busy && !_composing) widget.controller.previous();
          },
        },
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => LayoutBuilder(
                builder: (context, constraints) {
                  final field = TextField(
                    key: const ValueKey('note-find-query'),
                    controller: _text,
                    focusNode: _focus,
                    autofocus: true,
                    readOnly: _busy,
                    textInputAction: TextInputAction.search,
                    onChanged: widget.controller.setQuery,
                    onSubmitted: (_) {
                      if (!_busy && !_composing) widget.controller.next();
                    },
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  );
                  final count = Semantics(
                    liveRegion: true,
                    child: Text(
                      widget.controller.query.trim().isEmpty
                          ? ''
                          : widget.controller.matches.isEmpty
                              ? widget.noMatchesText
                              : '${widget.controller.currentIndex + 1} / ${widget.controller.matches.length}',
                      key: const ValueKey('note-find-count'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                  final previous = IconButton(
                    key: const ValueKey('note-find-previous'),
                    tooltip: widget.previousTooltip,
                    onPressed: _busy || widget.controller.matches.isEmpty
                        ? null
                        : widget.controller.previous,
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  );
                  final next = IconButton(
                    key: const ValueKey('note-find-next'),
                    tooltip: widget.nextTooltip,
                    onPressed: _busy || widget.controller.matches.isEmpty
                        ? null
                        : widget.controller.next,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  );
                  final close = IconButton(
                    key: const ValueKey('note-find-close'),
                    tooltip: widget.closeTooltip,
                    onPressed: _busy ? null : widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  );
                  final queryRow = constraints.maxWidth < 360
                      ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Row(children: [Expanded(child: field), close]),
                          Row(children: [
                            Expanded(child: count),
                            previous,
                            next
                          ]),
                        ])
                      : Row(children: [
                          Expanded(child: field),
                          ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 88),
                              child: count),
                          previous,
                          next,
                          close,
                        ]);
                  final match = widget.controller.currentMatch;
                  final canReplace =
                      widget.onReplace != null || widget.onReplaceAll != null;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      queryRow,
                      if (widget.onEditMatch != null || canReplace)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (widget.onEditMatch != null)
                              TextButton.icon(
                                key: const ValueKey('note-find-edit-match'),
                                onPressed: _canAct && match != null
                                    ? () => _runAction(() {
                                          final current =
                                              widget.controller.currentMatch;
                                          if (current != null) {
                                            return widget.onEditMatch!(current);
                                          }
                                        })
                                    : null,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(widget.editMatchTooltip),
                              ),
                            if (canReplace)
                              TextButton.icon(
                                key: const ValueKey('note-find-replace-toggle'),
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => _replaceOpen = !_replaceOpen),
                                icon: Icon(
                                    _replaceOpen
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    size: 20),
                                label: Text(widget.replaceToggleLabel),
                              ),
                          ],
                        ),
                      if (canReplace && _replaceOpen) ...[
                        TextField(
                          key: const ValueKey('note-find-replacement'),
                          controller: _replacement,
                          readOnly: _busy,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: widget.replaceHintText,
                            prefixIcon: const Icon(Icons.find_replace_rounded,
                                size: 20),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (_busy)
                              const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            if (widget.onReplace != null)
                              TextButton(
                                key: const ValueKey('note-find-replace'),
                                onPressed: _canAct && match != null
                                    ? () => _runAction(() {
                                          final current =
                                              widget.controller.currentMatch;
                                          if (current != null) {
                                            return widget.onReplace!(
                                                current, _replacement.text);
                                          }
                                        })
                                    : null,
                                child: Text(widget.replaceLabel),
                              ),
                            if (widget.onReplaceAll != null)
                              FilledButton.tonal(
                                key: const ValueKey('note-find-replace-all'),
                                onPressed: _canAct && match != null
                                    ? () => _runAction(() =>
                                        widget.onReplaceAll!(_replacement.text))
                                    : null,
                                child: Text(widget.replaceAllLabel),
                              ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
}
