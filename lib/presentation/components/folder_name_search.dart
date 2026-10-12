import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/generated/l10n.dart';

import 'app_sheet.dart';

/// Literal, case-insensitive name search that retains original folder objects
/// and their order. Search never changes a folder or the selected scope.
List<Folder> filterFoldersByName(Iterable<Folder> folders, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return folders.toList(growable: false);
  final pattern =
      RegExp(RegExp.escape(trimmed), caseSensitive: false, unicode: true);
  return folders
      .where((folder) => pattern.hasMatch(folder.name))
      .toList(growable: false);
}

class FolderNameSearchField extends StatelessWidget {
  const FolderNameSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.keyPrefix,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => TextField(
        key: ValueKey('$keyPrefix-search'),
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          labelText: S.of(context).Search_Folders,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  key: ValueKey('$keyPrefix-clear-search'),
                  tooltip: S.of(context).Clear_Search,
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      );
}

class FolderNameSearchEmpty extends StatelessWidget {
  const FolderNameSearchEmpty({super.key, required this.keyPrefix});

  final String keyPrefix;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Semantics(
          liveRegion: true,
          child: Text(
            S.of(context).Folder_Search_Empty,
            key: ValueKey('$keyPrefix-search-empty'),
          ),
        ),
      );
}

/// A pure Flutter leaf: choosing a row is delegated to its caller, while
/// filtering and cancellation do not invoke any note or folder repository.
class MoveToFolderSheet extends StatefulWidget {
  const MoveToFolderSheet({
    super.key,
    required this.folders,
    required this.onSelected,
    this.selectedFolderId,
    this.onCancel,
  });

  final List<Folder> folders;
  final String? selectedFolderId;
  final ValueChanged<String?> onSelected;
  final VoidCallback? onCancel;

  @override
  State<MoveToFolderSheet> createState() => _MoveToFolderSheetState();
}

class _MoveToFolderSheetState extends State<MoveToFolderSheet> {
  final _searchController = TextEditingController();
  bool _selecting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(String? folderId) {
    if (_selecting || !mounted || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _selecting = true;
    widget.onSelected(folderId);
  }

  void _cancel() {
    if (_selecting || !mounted || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _selecting = true;
    final cancel = widget.onCancel;
    if (cancel != null) {
      cancel();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folders = filterFoldersByName(widget.folders, _searchController.text);
    Widget row(String key, String label, String? folderId, IconData icon) {
      final selected = widget.selectedFolderId == folderId;
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          key: ValueKey(key),
          minVerticalPadding: 14,
          selected: selected,
          selectedTileColor: colors.primaryContainer,
          selectedColor: colors.onPrimaryContainer,
          leading: Icon(icon),
          title: Text(label),
          trailing: selected ? const Icon(Icons.check_rounded) : null,
          onTap: () => _select(folderId),
        ),
      );
    }

    return AppSheet(
      title: S.of(context).Move_To_Folder,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FolderNameSearchField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              keyPrefix: 'move-to-folder',
            ),
          ),
          row('move-to-folder-none', S.of(context).No_Folder, null,
              Icons.notes_outlined),
          if (folders.isEmpty && _searchController.text.trim().isNotEmpty)
            const FolderNameSearchEmpty(keyPrefix: 'move-to-folder'),
          for (final folder in folders)
            row('move-to-folder-folder-${folder.id}', folder.name, folder.id,
                Icons.folder_outlined),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('move-to-folder-cancel'),
            onPressed: _cancel,
            child: Text(S.of(context).Cancel),
          ),
        ],
      ),
    );
  }
}
