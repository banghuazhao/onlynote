import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/toast.dart';
import 'package:onlynote/services/shortcuts_append.dart';

/// Failed requests stay readable until the user explicitly discards them.
/// Copying text never acknowledges or removes a pending native request.
class ShortcutAppendReviewSheet extends StatefulWidget {
  const ShortcutAppendReviewSheet(
      {super.key,
      required this.pending,
      required this.onDiscard,
      required this.onRetry,
      this.noteTitle,
      this.copyText});
  final ValueListenable<List<ShortcutAppendRequest>> pending;
  final Future<void> Function(String id) onDiscard;
  final VoidCallback onRetry;
  final String? Function(String id)? noteTitle;
  final Future<void> Function(String text)? copyText;

  @override
  State<ShortcutAppendReviewSheet> createState() =>
      _ShortcutAppendReviewSheetState();
}

class _ShortcutAppendReviewSheetState extends State<ShortcutAppendReviewSheet> {
  String? _busyId;
  bool _closing = false;

  bool _canAct(ShortcutAppendRequest request) =>
      mounted &&
      !_closing &&
      _busyId == null &&
      ModalRoute.of(context)?.isCurrent == true &&
      widget.pending.value.any((value) => value.id == request.id);

  Future<void> _copy(ShortcutAppendRequest request) async {
    if (!_canAct(request)) return;
    setState(() => _busyId = request.id);
    var copied = false;
    try {
      await (widget.copyText?.call(request.text) ??
          Clipboard.setData(ClipboardData(text: request.text)));
      copied = true;
    } catch (_) {
      // Leave the durable request available for another copy or save attempt.
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    showTransientSnackBar(
        context,
        SnackBar(
            content: Text(copied
                ? S.of(context).Share_Text_Copied
                : S.of(context).Share_Text_Copy_Failed)));
  }

  Future<void> _discard(ShortcutAppendRequest request) async {
    if (!_canAct(request)) return;
    setState(() => _busyId = request.id);
    var failed = false;
    try {
      await widget.onDiscard(request.id);
    } catch (_) {
      failed = true;
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
    if (failed && mounted && ModalRoute.of(context)?.isCurrent == true) {
      showTransientSnackBar(
          context,
          SnackBar(
              content: Text(S.of(context).Shortcuts_Request_Discard_Failed)));
    }
  }

  String _title(ShortcutAppendRequest request, S strings) =>
      switch (request.destination) {
        ShortcutAppendDestination.today => strings.Siri_Shortcuts_Today,
        ShortcutAppendDestination.inbox => strings.Shortcuts_Inbox_Title,
        ShortcutAppendDestination.note => request.noteId == null
            ? strings.Shortcuts_Append_Unavailable
            : widget.noteTitle?.call(request.noteId!) ??
                strings.Siri_Shortcuts_Note,
      };

  void _retry() {
    if (!mounted ||
        _closing ||
        _busyId != null ||
        widget.pending.value.isEmpty ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _closing = true;
    final retry = widget.onRetry;
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => retry());
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
      valueListenable: widget.pending,
      builder: (context, requests, _) {
        final strings = S.of(context);
        return AppSheet(
          title: strings.Shortcuts_Requests,
          footer: requests.isEmpty
              ? null
              : FilledButton(
                  key: const ValueKey('retry-shortcut-requests'),
                  onPressed: _busyId != null ? null : _retry,
                  child: Text(strings.Retry),
                ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(strings.Shortcuts_Request_Hint),
            const SizedBox(height: 12),
            if (requests.isEmpty) Text(strings.Shortcuts_Request_Empty),
            for (final request in requests)
              Card(
                key: ValueKey('shortcut-request-${request.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                            header: true,
                            child: Text(_title(request, strings),
                                style: Theme.of(context).textTheme.titleSmall)),
                        const SizedBox(height: 8),
                        SelectableText(request.text),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          OutlinedButton.icon(
                              key: ValueKey('copy-shortcut-${request.id}'),
                              onPressed:
                                  _busyId == null ? () => _copy(request) : null,
                              icon: const Icon(Icons.copy_outlined),
                              label: Text(MaterialLocalizations.of(context)
                                  .copyButtonLabel)),
                          TextButton.icon(
                              key: ValueKey('discard-shortcut-${request.id}'),
                              onPressed: _busyId == null
                                  ? () => _discard(request)
                                  : null,
                              style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(strings.Shortcuts_Request_Discard)),
                        ]),
                      ]),
                ),
              ),
          ]),
        );
      });
}
