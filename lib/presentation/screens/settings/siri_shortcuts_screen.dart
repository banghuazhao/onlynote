import 'package:onlynote/Tools/shortcuts_append_launch.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/shortcut_append_review_sheet.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/section_card.dart';
import 'package:onlynote/presentation/components/toast.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:url_launcher/url_launcher.dart';

class SiriShortcutsScreen extends StatefulWidget {
  const SiriShortcutsScreen({super.key, this.openShortcuts});
  final Future<bool> Function()? openShortcuts;

  @override
  State<SiriShortcutsScreen> createState() => _SiriShortcutsScreenState();
}

class _SiriShortcutsScreenState extends State<SiriShortcutsScreen> {
  bool _opening = false;
  bool _reviewing = false;

  Future<void> _open() async {
    if (!mounted || _opening || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    setState(() => _opening = true);
    var opened = false;
    try {
      opened = await (widget.openShortcuts?.call() ??
          launchUrl(Uri.parse('shortcuts://'),
              mode: LaunchMode.externalApplication));
    } catch (_) {
      // The guide remains usable when the Shortcuts app cannot be opened.
    } finally {
      if (mounted) setState(() => _opening = false);
    }
    if (!opened && mounted && ModalRoute.of(context)?.isCurrent == true) {
      showTransientSnackBar(context,
          SnackBar(content: Text(S.of(context).Siri_Shortcuts_Open_Failed)));
    }
  }

  Future<void> _review() async {
    if (!mounted || _reviewing || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _reviewing = true;
    final launch = ShortcutsAppendLaunch.instance;
    try {
      await showAppSheet<void>(
          context: context,
          builder: (_) => ShortcutAppendReviewSheet(
              pending: launch.pending,
              onDiscard: launch.discard,
              onRetry: launch.retry,
              noteTitle: (id) {
                if (!getIt.isRegistered<NoteRepository>()) return null;
                return getIt<NoteRepository>()
                    .getAllNotes()
                    .where((note) => note.id == id && !note.isDeleted)
                    .map((note) => note.title)
                    .firstOrNull;
              }));
    } finally {
      if (mounted) _reviewing = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DeskSurface.colorOf(context),
        appBar: AppBar(
          title: Text(S.of(context).Siri_Shortcuts_Title,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: DeskSurface(
          child: SafeArea(
            top: false,
            child: ValueListenableBuilder(
              valueListenable: ShortcutsAppendLaunch.instance.pending,
              builder: (context, requests, _) => SiriShortcutsContent(
                  onOpen: _open,
                  opening: _opening,
                  onReview: requests.isEmpty ? null : _review),
            ),
          ),
        ),
      );
}

/// Instructions are also renderable in previews without native app launches.
class SiriShortcutsContent extends StatelessWidget {
  const SiriShortcutsContent(
      {super.key, this.onOpen, this.onReview, this.opening = false});
  final VoidCallback? onOpen;
  final VoidCallback? onReview;
  final bool opening;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final tokens = context.tokens;
    return ListView(
      key: const ValueKey('siri-shortcuts-guide'),
      padding: EdgeInsets.all(tokens.space4),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: tokens.contentMaxWidth),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onReview != null) ...[
                    OutlinedButton.icon(
                        key: const ValueKey('review-pending-shortcuts'),
                        onPressed: onReview,
                        icon: const Icon(Icons.pending_actions_outlined),
                        label: Text(strings.Shortcuts_Requests)),
                    SizedBox(height: tokens.space4),
                  ],
                  Text(strings.Siri_Shortcuts_Description,
                      style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: tokens.space2),
                  Text(strings.Siri_Shortcuts_Setup),
                  SizedBox(height: tokens.space4),
                  if (onOpen != null) ...[
                    FilledButton.icon(
                      key: const ValueKey('open-siri-shortcuts'),
                      onPressed: opening ? null : onOpen,
                      icon: opening
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.open_in_new_rounded),
                      label: Text(strings.Siri_Shortcuts_Open),
                    ),
                    SizedBox(height: tokens.space4),
                  ],
                  SectionCard(
                    title: strings.Siri_Shortcuts_Today,
                    icon: Icons.today_outlined,
                    children: [Text(strings.Siri_Shortcuts_Today_Description)],
                  ),
                  SizedBox(height: tokens.space3),
                  SectionCard(
                    title: strings.Siri_Shortcuts_Note,
                    icon: Icons.note_add_outlined,
                    children: [Text(strings.Siri_Shortcuts_Note_Description)],
                  ),
                  SizedBox(height: tokens.space3),
                  SectionCard(
                    title: strings.Siri_Shortcuts_Inbox,
                    icon: Icons.move_to_inbox_outlined,
                    children: [Text(strings.Siri_Shortcuts_Inbox_Description)],
                  ),
                  SizedBox(height: tokens.space4),
                  Text(strings.Siri_Shortcuts_Save),
                  SizedBox(height: tokens.space2),
                  Text(strings.Siri_Shortcuts_Requirements,
                      style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: tokens.space4),
                ]),
          ),
        ),
      ],
    );
  }
}
