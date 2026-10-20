import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/confirm_dialog.dart';
import 'package:onlynote/presentation/components/template_name_dialog.dart';
import 'package:onlynote/presentation/components/template_name_search.dart';
import 'package:onlynote/presentation/components/template_content_snippet.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/note_templates.dart';
import 'package:onlynote/services/template_content_search.dart';

Future<NoteTemplateSelection?> showNoteTemplatePickerSheet(BuildContext context,
    {CustomNoteTemplateStore? store}) async {
  ModalRoute<NoteTemplateSelection>? pickerRoute;
  final selection = await showAppSheet<NoteTemplateSelection>(
    context: context,
    builder: (sheetContext) {
      pickerRoute ??= ModalRoute.of<NoteTemplateSelection>(sheetContext);
      return NoteTemplatePickerSheet(store: store);
    },
  );
  // A pop result arrives before the reverse animation removes the overlay.
  // Finish removing the picker before its caller pushes the note editor.
  await pickerRoute?.completed;
  return selection;
}

class NoteTemplatePickerSheet extends StatefulWidget {
  const NoteTemplatePickerSheet({super.key, this.store});
  final CustomNoteTemplateStore? store;

  @override
  State<NoteTemplatePickerSheet> createState() =>
      _NoteTemplatePickerSheetState();
}

class _NoteTemplatePickerSheetState extends State<NoteTemplatePickerSheet> {
  late final _store = widget.store ?? CustomNoteTemplateStore.instance;
  final _searchController = TextEditingController();
  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;
  bool _closing = false;
  bool _changeFailed = false;

  void _select(NoteTemplateSelection selection) {
    if (!mounted ||
        _busy ||
        _closing ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    setState(() => _closing = true);
    Navigator.pop(context, selection);
  }

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    unawaited(_load());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      await _store.load();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _change(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _changeFailed = false;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _changeFailed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(CustomNoteTemplate template) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TemplateNameDialog(
        title: S.of(context).Rename_Template,
        initial: template.name,
      ),
    );
    if (!mounted || name == null) return;
    await _change(() => _store.rename(template.id, name));
  }

  Future<void> _delete(CustomNoteTemplate template) async {
    final confirmed = await showConfirmDialog(
      context,
      title: S.of(context).Template_Delete_Confirm_Title,
      message: S.of(context).Template_Delete_Confirm_Message,
    );
    if (!mounted || !confirmed) return;
    await _change(() => _store.delete(template.id));
  }

  void _manage(CustomNoteTemplate template) {
    if (!mounted ||
        _busy ||
        _closing ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    showAppActionSheet(
      context: context,
      title: template.name,
      actions: [
        AppSheetAction(
          leading: const Icon(Icons.edit_outlined),
          title: Text(S.of(context).Rename_Template),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _rename(template);
          },
        ),
        AppSheetAction(
          destructive: true,
          leading: const Icon(Icons.delete_outline),
          title: Text(S.of(context).Delete_Template),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _delete(template);
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    final templates = _store.templates;
    final search = TemplateContentSearch(_searchController.text);
    final customMatches = search.filterCustom(templates);
    final starterMatches = search.filterBuiltIn(NoteTemplate.values, strings);
    final noMatches = !_loading &&
        !_loadFailed &&
        _searchController.text.trim().isNotEmpty &&
        customMatches.isEmpty &&
        starterMatches.isEmpty;
    return AppSheet(
      title: strings.Templates,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Text(strings.Templates_Description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TemplateNameSearchField(
              controller: _searchController,
              enabled: !_busy && !_closing,
              onChanged: (_) {
                if (mounted && !_busy && !_closing) setState(() {});
              },
            ),
          ),
          if (noMatches) const TemplateNameSearchEmpty(),
          _heading(strings.My_Templates),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(),
            )
          else if (_loadFailed)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.Template_Load_Failed,
                      style: TextStyle(color: theme.colorScheme.error)),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(strings.Retry),
                  ),
                ],
              ),
            )
          else if (templates.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Text(strings.Templates_Create_Hint,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            )
          else ...[
            for (final template in customMatches)
              _card(
                ListTile(
                  key: ValueKey('custom-template-${template.id}'),
                  minVerticalPadding: 16,
                  leading: _icon(Icons.notes_outlined),
                  title: Text(template.name),
                  subtitle: TemplateContentSubtitle(
                      template: template, query: _searchController.text),
                  trailing: IconButton(
                    key: ValueKey('manage-template-${template.id}'),
                    tooltip: strings.Template_Manage,
                    onPressed:
                        _busy || _closing ? null : () => _manage(template),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                  onTap: _busy || _closing
                      ? null
                      : () => _select(NoteTemplateSelection.custom(template)),
                ),
              ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (_changeFailed)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(strings.Template_Change_Failed,
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          _heading(strings.Starter_Templates),
          for (final template in starterMatches)
            _card(
              ListTile(
                key: ValueKey('template-${template.name}'),
                minVerticalPadding: 16,
                leading: _icon(switch (template) {
                  NoteTemplate.shopping => Icons.shopping_basket_outlined,
                  NoteTemplate.packing => Icons.luggage_outlined,
                  NoteTemplate.dailyPlan => Icons.today_outlined,
                  NoteTemplate.meeting => Icons.groups_outlined,
                }),
                title: Text(template.content(strings).title),
                subtitle: Text(
                  starterTemplateContentSnippet(template.content(strings),
                      query: _searchController.text),
                  key: ValueKey('template-starter-snippet-${template.name}'),
                  maxLines: _searchController.text.trim().isEmpty ? null : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _busy || _closing
                    ? null
                    : () => _select(NoteTemplateSelection.builtIn(template)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heading(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      );

  Widget _card(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: child,
        ),
      );

  Widget _icon(IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: colors.onPrimaryContainer, size: 22),
      ),
    );
  }
}
