import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/ads_manager.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:screenshot/screenshot.dart';

import '../settings/settings_screen.dart';
import 'bloc/home_bloc.dart';
import 'bloc/multiple_delete/multiple_delete_bloc.dart';
import 'widgets/note_card.dart';

@RoutePage(name: 'HomeRoute')
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _ad;
  AdSize? _adSize;
  bool _adLoadStarted = false;

  bool _isAdLoaded = false;
  bool _isReorderMode = false;
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();

  void _setReorderMode(bool value) => setState(() => _isReorderMode = value);

  @override
  void initState() {
    super.initState();
    PurchaseService.instance.addListener(_entitlementChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adLoadStarted && PurchaseService.instance.shouldShowAds) {
      _adLoadStarted = true;
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null || !PurchaseService.instance.shouldShowAds) {
      return;
    }
    _adSize = size;
    _ad = BannerAd(
      adUnitId: AdsManager.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted && PurchaseService.instance.shouldShowAds) {
            setState(() => _isAdLoaded = true);
          } else {
            _disposeAd();
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _adSize = null);
          debugPrint(
              'Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );

    _ad?.load();
  }

  void _entitlementChanged() {
    if (!PurchaseService.instance.shouldShowAds) _disposeAd();
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
    if (mounted && _isAdLoaded) setState(() => _isAdLoaded = false);
  }

  void _showMovedToTrashSnackBar(List<String> ids) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(S.of(context).Notes_Moved_To_Trash),
        action: SnackBarAction(
          label: S.of(context).Undo,
          onPressed: () {
            context.read<HomeBloc>().add(HomeEvent.restoreNotes(ids));
          },
        ),
      ),
    );
  }

  Future<void> _promptFolderName({
    required String title,
    String? initial,
    required ValueChanged<String> onSubmit,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: S.of(context).Folder_Name),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.pop(dialogContext, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(S.of(context).Cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(S.of(context).OK),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      onSubmit(name.trim());
    }
  }

  @override
  void dispose() {
    PurchaseService.instance.removeListener(_entitlementChanged);
    _searchController.dispose();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MultipleDeleteBloc, MultipleDeleteState>(
          listener: (context, state) {
            state.mapOrNull(
              success: (success) {
                _showMovedToTrashSnackBar(success.deletedIds);
                context
                    .read<MultipleDeleteBloc>()
                    .add(const MultipleDeleteEvent.clearAll());
              },
            );
          },
        ),
      ],
      child: Scaffold(
        appBar: NoteAppBar(
          autoImplementLeading: false,
          leading: IconButton(
            tooltip: S.of(context).Settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          title: S.of(context).notes,
          actions: _buildAppBarActions(context),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_isSearchVisible) _buildSearchField(context),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: getIt<Database>().box.listenable(),
                  builder: (context, _, child) {
                    context
                        .read<HomeBloc>()
                        .add(const HomeEvent.getAllNotes());
                    return child!;
                  },
                  child: ValueListenableBuilder(
                    valueListenable:
                        Hive.box(folderDatabaseBox).listenable(),
                    builder: (context, _, child) {
                      context
                          .read<HomeBloc>()
                          .add(const HomeEvent.getAllNotes());
                      return child!;
                    },
                    child: BlocBuilder<HomeBloc, HomeState>(
                      builder: (_, state) {
                        return state.maybeMap(
                          orElse: () => const _LoadingSkeleton(),
                          error: (error) =>
                              _HomeError(message: error.message ?? ''),
                          loaded: (data) => Column(
                            children: [
                              _FolderFilterBar(
                                folders: data.folders,
                                selectedFolderId: data.selectedFolderId,
                                showTrash: data.showTrash,
                                trashCount: data.trashCount,
                                onSelectAll: () => context
                                    .read<HomeBloc>()
                                    .add(const HomeEvent.selectFolder(null)),
                                onSelectFolder: (id) => context
                                    .read<HomeBloc>()
                                    .add(HomeEvent.selectFolder(id)),
                                onShowTrash: () => context
                                    .read<HomeBloc>()
                                    .add(const HomeEvent.showTrash(true)),
                                onCreateFolder: () => _promptFolderName(
                                  title: S.of(context).New_Folder,
                                  onSubmit: (name) => context
                                      .read<HomeBloc>()
                                      .add(HomeEvent.createFolder(name)),
                                ),
                                onRenameFolder: (folder) => _promptFolderName(
                                  title: S.of(context).Rename_Folder,
                                  initial: folder.name,
                                  onSubmit: (name) =>
                                      context.read<HomeBloc>().add(
                                            HomeEvent.renameFolder(
                                              folder.id,
                                              name,
                                            ),
                                          ),
                                ),
                                onDeleteFolder: (folder) async {
                                  final confirmed = await showConfirmDialog(
                                    context,
                                    title: S.of(context).Delete_Folder,
                                    message: S
                                        .of(context)
                                        .Delete_Folder_Confirm_Message,
                                  );
                                  if (confirmed && context.mounted) {
                                    context.read<HomeBloc>().add(
                                          HomeEvent.deleteFolder(folder.id),
                                        );
                                  }
                                },
                              ),
                              Expanded(
                                child: data.notes.isEmpty
                                    ? _EmptyNotes(
                                        showTrash: data.showTrash,
                                        hasSearch:
                                            data.searchQuery.trim().isNotEmpty,
                                        hasFolder:
                                            data.selectedFolderId != null,
                                        onAdd: () {
                                          context.router.push(
                                            AddUpdateNoteRoute(
                                              folderId: data.selectedFolderId,
                                            ),
                                          );
                                        },
                                      )
                                    : _BuildNotesList(
                                        notes: data.notes,
                                        folders: data.folders,
                                        showTrash: data.showTrash,
                                        isReorderMode: _isReorderMode,
                                        onEnterReorderMode: () =>
                                            _setReorderMode(true),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_adSize != null && PurchaseService.instance.shouldShowAds)
                Semantics(
                  label: 'Advertisement',
                  container: true,
                  child: Padding(
                    padding: EdgeInsets.only(top: context.tokens.space2),
                    child: SizedBox(
                      width: _adSize!.width.toDouble(),
                      height: _adSize!.height.toDouble(),
                      child: _isAdLoaded
                          ? AdWidget(ad: _ad!)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget>? _buildAppBarActions(BuildContext context) {
    if (_isReorderMode) {
      return [
        AppButton(
          tooltip: S.of(context).Done,
          child: Text(S.of(context).Done),
          onPressed: () => _setReorderMode(false),
        ),
      ];
    }

    return context.watch<MultipleDeleteBloc>().state.mapOrNull(
          initial: (_) => [
            AppButton(
              tooltip: S.of(context).Search_Notes,
              child: Icon(
                _isSearchVisible ? Icons.search_off : Icons.search,
              ),
              onPressed: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) {
                    _searchController.clear();
                    context
                        .read<HomeBloc>()
                        .add(const HomeEvent.searchChanged(''));
                  }
                });
              },
            ),
            AppButton(
              tooltip: S.of(context).Add_Note,
              child: const Icon(Icons.add),
              onPressed: () {
                final folderId = context.read<HomeBloc>().state.mapOrNull(
                      loaded: (s) => s.showTrash ? null : s.selectedFolderId,
                    );
                context.router.push(AddUpdateNoteRoute(folderId: folderId));
              },
            ),
          ],
          selected: (selectedNotes) {
            final showTrash = context.read<HomeBloc>().state.mapOrNull(
                  loaded: (s) => s.showTrash,
                ) ??
                false;
            return [
              AppButton(
                tooltip: showTrash
                    ? S.of(context).Delete_Forever
                    : S.of(context).Delete,
                child: Row(
                  children: [
                    Text(
                      '${showTrash ? S.of(context).Delete_Forever : S.of(context).Delete} - ${selectedNotes.selectedIds.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: AppSpacings.xl),
                    Icon(
                      showTrash
                          ? Icons.delete_forever_outlined
                          : Icons.delete_outline,
                    ),
                  ],
                ),
                onPressed: () async {
                  if (showTrash) {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: S.of(context).Permanent_Delete_Confirm_Title,
                      message: S.of(context).Permanent_Delete_Confirm_Message,
                    );
                    if (!confirmed || !context.mounted) return;
                    context.read<HomeBloc>().add(
                          HomeEvent.permanentDelete(selectedNotes.selectedIds),
                        );
                    context
                        .read<MultipleDeleteBloc>()
                        .add(const MultipleDeleteEvent.clearAll());
                  } else {
                    context
                        .read<MultipleDeleteBloc>()
                        .add(const MultipleDeleteEvent.delete());
                  }
                },
              ),
              if (showTrash)
                AppButton(
                  tooltip: S.of(context).Restore,
                  child: const Icon(Icons.restore_outlined),
                  onPressed: () {
                    context.read<HomeBloc>().add(
                          HomeEvent.restoreNotes(selectedNotes.selectedIds),
                        );
                    context
                        .read<MultipleDeleteBloc>()
                        .add(const MultipleDeleteEvent.clearAll());
                  },
                ),
              AppButton(
                tooltip: S.of(context).Cancel,
                child: const Icon(Icons.close),
                onPressed: () {
                  context
                      .read<MultipleDeleteBloc>()
                      .add(const MultipleDeleteEvent.clearAll());
                },
              ),
            ];
          },
          success: (_) => [
            AppButton(
              tooltip: S.of(context).Add_Note,
              child: const Icon(Icons.add),
              onPressed: () {
                context.router.push(AddUpdateNoteRoute());
              },
            ),
          ],
          failed: (_) => [
            AppButton(
              tooltip: S.of(context).Add_Note,
              child: const Icon(Icons.add),
              onPressed: () {
                context.router.push(AddUpdateNoteRoute());
              },
            ),
          ],
        );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacings.xl,
        AppSpacings.s,
        AppSpacings.xl,
        AppSpacings.s,
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: S.of(context).Search_Notes,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<HomeBloc>()
                        .add(const HomeEvent.searchChanged(''));
                    setState(() {});
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacings.l),
          ),
          isDense: true,
        ),
        onChanged: (value) {
          context.read<HomeBloc>().add(HomeEvent.searchChanged(value));
          setState(() {});
        },
      ),
    );
  }
}

class _FolderFilterBar extends StatelessWidget {
  const _FolderFilterBar({
    required this.folders,
    required this.selectedFolderId,
    required this.showTrash,
    required this.trashCount,
    required this.onSelectAll,
    required this.onSelectFolder,
    required this.onShowTrash,
    required this.onCreateFolder,
    required this.onRenameFolder,
    required this.onDeleteFolder,
  });

  final List<Folder> folders;
  final String? selectedFolderId;
  final bool showTrash;
  final int trashCount;
  final VoidCallback onSelectAll;
  final ValueChanged<String> onSelectFolder;
  final VoidCallback onShowTrash;
  final VoidCallback onCreateFolder;
  final ValueChanged<Folder> onRenameFolder;
  final ValueChanged<Folder> onDeleteFolder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacings.xl),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacings.s),
            child: FilterChip(
              label: Text(S.of(context).All_Notes),
              selected: !showTrash && selectedFolderId == null,
              onSelected: (_) => onSelectAll(),
            ),
          ),
          ...folders.map(
            (folder) => Padding(
              padding: const EdgeInsets.only(right: AppSpacings.s),
              child: GestureDetector(
                onLongPress: () => _showFolderMenu(context, folder),
                child: FilterChip(
                  avatar: const Icon(Icons.folder_outlined, size: 18),
                  label: Text(folder.name),
                  selected: !showTrash && selectedFolderId == folder.id,
                  onSelected: (_) => onSelectFolder(folder.id),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacings.s),
            child: ActionChip(
              avatar: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: Text(S.of(context).New_Folder),
              onPressed: onCreateFolder,
            ),
          ),
          FilterChip(
            avatar: const Icon(Icons.delete_outline, size: 18),
            label: Text(
              trashCount > 0
                  ? '${S.of(context).Trash} ($trashCount)'
                  : S.of(context).Trash,
            ),
            selected: showTrash,
            onSelected: (_) => onShowTrash(),
          ),
        ],
      ),
    );
  }

  void _showFolderMenu(BuildContext context, Folder folder) {
    showAdaptiveActionSheet(
      context: context,
      androidBorderRadius: 30,
      actions: <BottomSheetAction>[
        BottomSheetAction(
          leading: const Icon(Icons.drive_file_rename_outline),
          title: Text(S.of(context).Rename_Folder),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            onRenameFolder(folder);
          },
        ),
        BottomSheetAction(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: Text(
            S.of(context).Delete_Folder,
            style: const TextStyle(color: Colors.red),
          ),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            onDeleteFolder(folder);
          },
        ),
      ],
      cancelAction: CancelAction(title: Text(S.of(context).Cancel)),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({
    required this.onAdd,
    required this.showTrash,
    required this.hasSearch,
    required this.hasFolder,
  });

  final VoidCallback onAdd;
  final bool showTrash;
  final bool hasSearch;
  final bool hasFolder;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final message = hasSearch
        ? l10n.No_Search_Results
        : showTrash
            ? l10n.Trash_Empty
            : hasFolder
                ? l10n.No_Notes_In_Folder
                : l10n.No_notes_found;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.tokens.space5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/empty_notes.png',
              width: 190,
              height: 190,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            SizedBox(height: context.tokens.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textStyles.titleLarge,
            ),
            if (!showTrash && !hasSearch) ...[
              SizedBox(height: context.tokens.space4),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.Add_Note),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.tokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/empty_notes.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            SizedBox(height: context.tokens.space4),
            ErrorText(message),
          ],
        ),
      ),
    );
  }
}

class _BuildNotesList extends StatefulWidget {
  const _BuildNotesList({
    required this.notes,
    required this.folders,
    required this.showTrash,
    required this.isReorderMode,
    required this.onEnterReorderMode,
  });

  final List<Note> notes;
  final List<Folder> folders;
  final bool showTrash;
  final bool isReorderMode;
  final VoidCallback onEnterReorderMode;

  @override
  State<_BuildNotesList> createState() => __BuildNotesListState();
}

class __BuildNotesListState extends State<_BuildNotesList> {
  final Map<String, ScreenshotController> _screenshotControllers = {};
  final Map<String, GlobalKey> _cardKeys = {};

  ScreenshotController _screenshotControllerFor(String noteId) =>
      _screenshotControllers.putIfAbsent(noteId, () => ScreenshotController());

  GlobalKey _cardKeyFor(String noteId) =>
      _cardKeys.putIfAbsent(noteId, () => GlobalKey());

  Future<void> _shareNote(
    BuildContext context,
    Note note,
    ScreenshotController controller,
    GlobalKey cardKey,
  ) async {
    try {
      await ShareHelper.shareWidgetAsImage(
        controller,
        fileName: '${note.title?.isNotEmpty == true ? note.title : 'note'}.png',
        sharePositionOrigin: ShareHelper.shareOriginFromKey(cardKey),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).Share_Note_Failed)),
        );
      }
    }
  }

  void _showMoveToFolderSheet(BuildContext context, Note note) {
    showAdaptiveActionSheet(
      context: context,
      androidBorderRadius: 30,
      actions: <BottomSheetAction>[
        BottomSheetAction(
          leading: const Icon(Icons.notes_outlined),
          title: Text(S.of(context).No_Folder),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            context.read<HomeBloc>().add(
                  HomeEvent.moveNoteToFolder(noteId: note.id!, folderId: null),
                );
          },
        ),
        ...widget.folders.map(
          (folder) => BottomSheetAction(
            leading: const Icon(Icons.folder_outlined),
            title: Text(folder.name),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              context.read<HomeBloc>().add(
                    HomeEvent.moveNoteToFolder(
                      noteId: note.id!,
                      folderId: folder.id,
                    ),
                  );
            },
          ),
        ),
      ],
      cancelAction: CancelAction(title: Text(S.of(context).Cancel)),
    );
  }

  void _showNoteContextMenu(
    BuildContext context,
    Note note,
    MultipleDeleteBloc multipleDeleteBloc,
    String noteId,
  ) {
    final screenshotController = _screenshotControllerFor(noteId);
    final cardKey = _cardKeyFor(noteId);

    if (widget.showTrash) {
      showAdaptiveActionSheet(
        context: context,
        androidBorderRadius: 30,
        actions: <BottomSheetAction>[
          BottomSheetAction(
            leading: const Icon(Icons.restore_outlined),
            title: Text(S.of(context).Restore),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              context
                  .read<HomeBloc>()
                  .add(HomeEvent.restoreNotes([noteId]));
            },
          ),
          BottomSheetAction(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: Text(
              S.of(context).Delete_Forever,
              style: const TextStyle(color: Colors.red),
            ),
            onPressed: (sheetContext) async {
              Navigator.pop(sheetContext);
              final confirmed = await showConfirmDialog(
                context,
                title: S.of(context).Permanent_Delete_Confirm_Title,
                message: S.of(context).Permanent_Delete_Confirm_Message,
              );
              if (confirmed && context.mounted) {
                context
                    .read<HomeBloc>()
                    .add(HomeEvent.permanentDelete([noteId]));
              }
            },
          ),
        ],
        cancelAction: CancelAction(title: Text(S.of(context).Cancel)),
      );
      return;
    }

    showAdaptiveActionSheet(
      context: context,
      androidBorderRadius: 30,
      actions: <BottomSheetAction>[
        BottomSheetAction(
          leading: Icon(
            note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          ),
          title: Text(note.isPinned ? S.of(context).Unpin : S.of(context).Pin),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            context.read<HomeBloc>().add(HomeEvent.togglePin(noteId));
          },
        ),
        BottomSheetAction(
          leading: const Icon(Icons.drive_file_move_outline),
          title: Text(S.of(context).Move_To_Folder),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _showMoveToFolderSheet(context, note);
          },
        ),
        BottomSheetAction(
          leading: const Icon(Icons.share_outlined),
          title: Text(S.of(context).Share),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _shareNote(context, note, screenshotController, cardKey);
          },
        ),
        BottomSheetAction(
          leading: const Icon(Icons.copy_outlined),
          title: Text(S.of(context).Duplicate),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            context.read<HomeBloc>().add(HomeEvent.duplicateNote(note));
          },
        ),
        BottomSheetAction(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(S.of(context).Select),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            multipleDeleteBloc.add(MultipleDeleteEvent.toggleSelect(noteId));
          },
        ),
        BottomSheetAction(
          leading: const Icon(Icons.swap_vert),
          title: Text(S.of(context).Reorder),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            widget.onEnterReorderMode();
          },
        ),
        BottomSheetAction(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: Text(S.of(context).Delete,
              style: const TextStyle(color: Colors.red)),
          onPressed: (sheetContext) async {
            Navigator.pop(sheetContext);
            final confirmed = await showConfirmDialog(
              context,
              title: S.of(context).Delete_Note_Confirm_Title,
              message: S.of(context).Delete_Note_Confirm_Message,
            );
            if (confirmed) {
              multipleDeleteBloc.add(MultipleDeleteEvent.toggleSelect(noteId));
              multipleDeleteBloc.add(const MultipleDeleteEvent.delete());
            }
          },
        ),
      ],
      cancelAction: CancelAction(title: Text(S.of(context).Cancel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final multipleDeleteBloc = context.read<MultipleDeleteBloc>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseColumns = AppLayoutSettings.instance.cardSize.columns;
        final crossAxisCount =
            constraints.maxWidth >= 600 ? baseColumns + 1 : baseColumns;
        return FocusDetector(
          onFocusGained: () {
            if (mounted) setState(() {});
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(
                '${widget.isReorderMode}:${widget.showTrash}:${widget.notes.map((note) => '${note.id}:${note.isPinned}').join(',')}',
              ),
              child: widget.isReorderMode && !widget.showTrash
                  ? _buildReorderableGrid(context, crossAxisCount)
                  : _buildMasonryGrid(
                      context,
                      multipleDeleteBloc,
                      crossAxisCount,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMasonryGrid(
    BuildContext context,
    MultipleDeleteBloc multipleDeleteBloc,
    int crossAxisCount,
  ) {
    final isSelectionMode = multipleDeleteBloc.state.maybeMap(
      selected: (_) => true,
      orElse: () => false,
    );

    return MasonryGridView.count(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacings.xl,
        vertical: AppSpacings.xl,
      ),
      crossAxisCount: crossAxisCount,
      itemCount: widget.notes.length,
      itemBuilder: (BuildContext context, int index) {
        final note = widget.notes[index];
        final noteId = note.id!;
        return FadeInUp(
          duration: Duration(milliseconds: 100 * index),
          child: KeyedSubtree(
            key: _cardKeyFor(noteId),
            child: NoteCard(
              note: note,
              selected: multipleDeleteBloc.isSelected(noteId),
              selectionMode: isSelectionMode,
              screenshotController: _screenshotControllerFor(noteId),
              onTap: () {
                multipleDeleteBloc.state.maybeMap(
                  orElse: () {
                    context.router.push(NoteDetailRoute(noteId: noteId));
                  },
                  selected: (_) {
                    multipleDeleteBloc
                        .add(MultipleDeleteEvent.toggleSelect(noteId));
                  },
                );
              },
              onLongPress: () {
                multipleDeleteBloc.state.maybeMap(
                  orElse: () => _showNoteContextMenu(
                      context, note, multipleDeleteBloc, noteId),
                  selected: (_) {
                    multipleDeleteBloc
                        .add(MultipleDeleteEvent.toggleSelect(noteId));
                  },
                );
              },
            ),
          ),
        );
      },
      mainAxisSpacing: AppSpacings.xl,
      crossAxisSpacing: AppSpacings.l,
    );
  }

  Widget _buildReorderableGrid(BuildContext context, int crossAxisCount) {
    final notes = List<Note>.from(widget.notes);

    return ReorderableGridView.count(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacings.xl,
        vertical: AppSpacings.xl,
      ),
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.3,
      mainAxisSpacing: AppSpacings.xl,
      crossAxisSpacing: AppSpacings.l,
      onReorder: (oldIndex, newIndex) {
        final reordered = List<Note>.from(notes);
        final moved = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, moved);
        context.read<HomeBloc>().add(HomeEvent.reorderNotes(reordered));
      },
      children: [
        for (final note in notes)
          _ReorderableNoteTile(key: ValueKey(note.id), note: note),
      ],
    );
  }
}

class _ReorderableNoteTile extends StatelessWidget {
  const _ReorderableNoteTile({super.key, required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final headlineText =
        note.title?.isNotEmpty == true ? note.title! : (note.description ?? '');

    return Material(
      type: MaterialType.card,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppSpacings.xl),
      color: note.color,
      shadowColor: Colors.black,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacings.l,
          vertical: AppSpacings.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note.isPinned)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacings.s),
                child: Icon(Icons.push_pin, size: 16),
              ),
            Text(
              headlineText,
              style: AppTypography.cardTitle,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacings.m),
            Text(
              note.date,
              style: AppTypography.description.copyWith(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final baseColumns = AppLayoutSettings.instance.cardSize.columns;
    final crossAxisCount =
        MediaQuery.of(context).size.width > 600 ? baseColumns + 1 : baseColumns;

    return ShimmerWrapper(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacings.xl,
          vertical: AppSpacings.xl,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacings.xl,
          crossAxisSpacing: AppSpacings.l,
          childAspectRatio: 1.1,
        ),
        itemCount: crossAxisCount * 3,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(AppSpacings.xl),
          ),
        ),
      ),
    );
  }
}
