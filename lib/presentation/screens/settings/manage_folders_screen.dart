import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

class ManageFoldersScreen extends StatelessWidget {
  const ManageFoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foldersListenable = Hive.box(folderDatabaseBox).listenable();
    final notesListenable = Hive.box(databaseBox).listenable();

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Manage_Folders),
        actions: [
          IconButton(
            tooltip: S.of(context).New_Folder,
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showFolderNameDialog(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([foldersListenable, notesListenable]),
        builder: (context, _) {
          final folders = foldersListenable.value.values
              .whereType<FolderDto>()
              .map((folder) => folder.toDomain())
              .toList()
            ..sort(_compareFolders);
          final noteCounts = _noteCountsByFolder(notesListenable.value);

          if (folders.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(context.tokens.space5),
                child: Text(
                  S.of(context).No_Folders,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyLarge,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              context.tokens.space4,
              context.tokens.space2,
              context.tokens.space4,
              context.tokens.space6,
            ),
            itemCount: folders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final folder = folders[index];
              final noteCount = noteCounts[folder.id] ?? 0;
              return ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
                subtitle: Text(S.of(context).Folder_Notes_Count(noteCount)),
                trailing: PopupMenuButton<_FolderAction>(
                  onSelected: (action) {
                    switch (action) {
                      case _FolderAction.rename:
                        _showFolderNameDialog(context, folder: folder);
                      case _FolderAction.delete:
                        _deleteFolder(context, folder);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _FolderAction.rename,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.drive_file_rename_outline),
                        title: Text(S.of(context).Rename_Folder),
                      ),
                    ),
                    PopupMenuItem(
                      value: _FolderAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        title: Text(
                          S.of(context).Delete_Folder,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFolderNameDialog(context),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: Text(S.of(context).New_Folder),
      ),
    );
  }

  static Map<String, int> _noteCountsByFolder(Box notesBox) {
    final counts = <String, int>{};
    for (final note in notesBox.values.whereType<NoteDto>()) {
      if (note.isDeleted) continue;
      final folderId = note.folderId;
      if (folderId == null || folderId.isEmpty) continue;
      counts[folderId] = (counts[folderId] ?? 0) + 1;
    }
    return counts;
  }

  static int _compareFolders(Folder a, Folder b) {
    if (a.sortOrder != null && b.sortOrder != null) {
      return a.sortOrder!.compareTo(b.sortOrder!);
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  static Future<void> _showFolderNameDialog(
    BuildContext context, {
    Folder? folder,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _FolderNameDialog(
        title: folder == null
            ? S.of(context).New_Folder
            : S.of(context).Rename_Folder,
        initial: folder?.name,
      ),
    );
    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty || !context.mounted) return;

    final bloc = context.read<HomeBloc>();
    bloc.add(
      folder == null
          ? HomeEvent.createFolder(trimmedName)
          : HomeEvent.renameFolder(folder.id, trimmedName),
    );
  }

  static Future<void> _deleteFolder(
    BuildContext context,
    Folder folder,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: S.of(context).Delete_Folder,
      message: S.of(context).Delete_Folder_Confirm_Message,
    );
    if (confirmed && context.mounted) {
      context.read<HomeBloc>().add(HomeEvent.deleteFolder(folder.id));
    }
  }
}

enum _FolderAction { rename, delete }

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: S.of(context).Folder_Name),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).Cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(S.of(context).OK),
        ),
      ],
    );
  }
}
