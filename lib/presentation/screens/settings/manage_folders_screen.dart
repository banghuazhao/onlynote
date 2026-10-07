import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/components/premium_feature_gate.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/premium_access.dart';

class ManageFoldersScreen extends StatelessWidget {
  const ManageFoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foldersListenable = Hive.box(folderDatabaseBox).listenable();
    final notesListenable = Hive.box(databaseBox).listenable();

    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      // "New folder" lives on the FAB alone — it was also in the app bar,
      // which read as two different actions.
      appBar: AppBar(title: Text(S.of(context).Manage_Folders)),
      body: DeskSurface(
          child: SafeArea(
              top: false,
              child: Center(
                  child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: context.tokens.contentMaxWidth),
                      child: AnimatedBuilder(
                        animation: Listenable.merge(
                            [foldersListenable, notesListenable]),
                        builder: (context, _) {
                          final folders = foldersListenable.value.values
                              .whereType<FolderDto>()
                              .map((folder) => folder.toDomain())
                              .toList()
                            ..sort(_compareFolders);
                          final noteCounts =
                              _noteCountsByFolder(notesListenable.value);

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
                              // Clears the extended FAB so it can't sit on the last folder.
                              context.tokens.space6 * 3,
                            ),
                            itemCount: folders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final folder = folders[index];
                              final noteCount = noteCounts[folder.id] ?? 0;
                              return Card(
                                  child: ListTile(
                                leading: const Icon(Icons.folder_outlined),
                                title: Text(folder.name),
                                subtitle: Text(S
                                    .of(context)
                                    .Folder_Notes_Count(noteCount)),
                                trailing: PopupMenuButton<_FolderAction>(
                                  tooltip: S.of(context).Edit,
                                  onSelected: (action) {
                                    switch (action) {
                                      case _FolderAction.rename:
                                        _showFolderNameDialog(context,
                                            folder: folder);
                                      case _FolderAction.delete:
                                        _deleteFolder(context, folder);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: _FolderAction.rename,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                            Icons.drive_file_rename_outline),
                                        title:
                                            Text(S.of(context).Rename_Folder),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _FolderAction.delete,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.delete_outline,
                                            color: context.colors.error),
                                        title: Text(
                                          S.of(context).Delete_Folder,
                                          style: TextStyle(
                                              color: context.colors.error),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ));
                            },
                          );
                        },
                      ))))),
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
    final bloc = context.read<HomeBloc>();
    int folderCount() =>
        Hive.box(folderDatabaseBox).values.whereType<FolderDto>().length;
    if (folder == null &&
        !await ensurePremiumAccess(context, PremiumFeature.folders,
            currentCount: folderCount(), access: bloc.premiumAccess)) {
      return;
    }
    if (!context.mounted) return;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => FolderNameDialog(
        title: folder == null
            ? S.of(context).New_Folder
            : S.of(context).Rename_Folder,
        initial: folder?.name,
      ),
    );
    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty || !context.mounted) return;

    if (folder != null) {
      bloc.add(HomeEvent.renameFolder(folder.id, trimmedName));
      return;
    }
    String? error;
    try {
      error = await bloc.createFolder(trimmedName);
    } on PremiumRequired {
      if (!context.mounted ||
          !await ensurePremiumAccess(context, PremiumFeature.folders,
              currentCount: folderCount(), access: bloc.premiumAccess)) {
        return;
      }
      error = await bloc.createFolder(trimmedName);
    }
    if (context.mounted) {
      context.showToast(error ?? S.of(context).Folder_Created,
          isError: error != null);
    }
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
