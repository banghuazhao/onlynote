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
  });
  final NoteSearchController controller;
  final String hintText;
  final String noMatchesText;
  final String previousTooltip;
  final String nextTooltip;
  final String closeTooltip;
  final VoidCallback onClose;

  @override
  State<NoteFindBar> createState() => _NoteFindBarState();
}

class _NoteFindBarState extends State<NoteFindBar> {
  late final TextEditingController _text;
  late final FocusNode _focus;
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.controller.query);
    _focus = FocusNode(debugLabel: 'Find query');
    // A route that already has a focused child may ignore a newly inserted
    // field's autofocus. Opening Find should always focus its query.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
          const SingleActivator(LogicalKeyboardKey.enter):
              widget.controller.next,
          const SingleActivator(LogicalKeyboardKey.enter, shift: true):
              widget.controller.previous,
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
                    textInputAction: TextInputAction.search,
                    onChanged: widget.controller.setQuery,
                    onSubmitted: (_) => widget.controller.next(),
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
                    onPressed: widget.controller.matches.isEmpty
                        ? null
                        : widget.controller.previous,
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  );
                  final next = IconButton(
                    key: const ValueKey('note-find-next'),
                    tooltip: widget.nextTooltip,
                    onPressed: widget.controller.matches.isEmpty
                        ? null
                        : widget.controller.next,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  );
                  final close = IconButton(
                    key: const ValueKey('note-find-close'),
                    tooltip: widget.closeTooltip,
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  );
                  if (constraints.maxWidth < 360) {
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [Expanded(child: field), close]),
                      Row(children: [Expanded(child: count), previous, next]),
                    ]);
                  }
                  return Row(children: [
                    Expanded(child: field),
                    ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 88),
                        child: count),
                    previous,
                    next,
                    close,
                  ]);
                },
              ),
            ),
          ),
        ),
      );
}
