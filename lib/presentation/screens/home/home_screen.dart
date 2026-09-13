import 'package:onlynote/presentation/components/note_search_filters.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/ads_manager.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/consent_gate.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:screenshot/screenshot.dart';

import '../settings/manage_folders_screen.dart';
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
  /// Height of the home screen banner, in logical pixels.
  static const _bannerHeight = 50;

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
    ReminderData.shared.addListener(_remindersChanged);
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
    // The standard 320x50 banner. The adaptive helper used before returned up
    // to 100 high and ate a note row's worth of the grid; a custom
    // screen-width x 50 slot fixes the height but letterboxes standard
    // creatives in black, since nothing is served at that exact size.
    const size = AdSize.banner;
    assert(size.height == _bannerHeight);

    // No request may go out before consent has an answer — on every launch,
    // not just the one where the form was shown.
    final gate = ConsentGate.instance;
    await gate.resolve();
    if (!mounted || !gate.canRequestAds) return;

    if (!PurchaseService.instance.shouldShowAds) return;
    _adSize = size;
    _ad = BannerAd(
      adUnitId: AdsManager.bannerAdUnitId,
      size: size,
      request: AdRequest(nonPersonalizedAds: gate.nonPersonalizedAds),
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

  void _remindersChanged() {
    if (mounted) context.read<HomeBloc>().add(const HomeEvent.getAllNotes());
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
    showTransientSnackBar(
      context,
      SnackBar(
        content: Text(S.of(context).Notes_Moved_To_Trash),
        duration: const Duration(seconds: 6),
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
    final name = await showDialog<String>(
      context: context,
      builder: (_) => FolderNameDialog(title: title, initial: initial),
    );
    if (mounted && name != null && name.trim().isNotEmpty) {
      onSubmit(name.trim());
    }
  }

  /// What the app bar title reads: the scope the note list is currently
  /// showing.
  String _scopeLabel(BuildContext context, _FolderScope scope) {
    if (scope.showTrash) return S.of(context).Trash;
    return scope.selectedFolder?.name ?? S.of(context).All_Notes;
  }

  IconData _scopeIcon(_FolderScope scope) {
    if (scope.showTrash) return Icons.delete_outline_rounded;
    if (scope.selectedFolderId != null) return Icons.folder_rounded;
    return Icons.notes_rounded;
  }

  Future<void> _openFolderPicker(_FolderScope scope) async {
    final bloc = context.read<HomeBloc>();

    final result = await showAppSheet<_FolderPickerResult>(
      context: context,
      builder: (_) => _FolderPickerSheet(scope: scope),
    );
    if (result == null || !mounted) return;

    switch (result) {
      case _SelectAll():
        bloc.add(const HomeEvent.selectFolder(null));
      case _SelectFolder(:final id):
        bloc.add(HomeEvent.selectFolder(id));
      case _SelectTrash():
        bloc.add(const HomeEvent.showTrash(true));
      case _CreateFolder():
        await _promptFolderName(
          title: S.of(context).New_Folder,
          onSubmit: (name) => bloc.add(HomeEvent.createFolder(name)),
        );
      case _RenameFolder(:final folder):
        await _promptFolderName(
          title: S.of(context).Rename_Folder,
          initial: folder.name,
          onSubmit: (name) => bloc.add(HomeEvent.renameFolder(folder.id, name)),
        );
      case _DeleteFolder(:final folder):
        final confirmed = await showConfirmDialog(
          context,
          title: S.of(context).Delete_Folder,
          message: S.of(context).Delete_Folder_Confirm_Message,
        );
        if (confirmed) bloc.add(HomeEvent.deleteFolder(folder.id));
      case _ManageFolders():
        await Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const ManageFoldersScreen()),
        );
    }
  }

  @override
  void dispose() {
    PurchaseService.instance.removeListener(_entitlementChanged);
    ReminderData.shared.removeListener(_remindersChanged);
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
        backgroundColor: DeskSurface.colorOf(context),
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
          titleWidget: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) => state.maybeMap(
              orElse: () => Text(S.of(context).notes),
              loaded: (data) {
                final scope = _FolderScope(
                  folders: data.folders,
                  selectedFolderId: data.selectedFolderId,
                  showTrash: data.showTrash,
                  trashCount: data.trashCount,
                  folderCounts: data.folderCounts,
                  allNotesCount: data.allNotesCount,
                );
                return _FolderPickerTitle(
                  label: _scopeLabel(context, scope),
                  icon: _scopeIcon(scope),
                  onTap: () => _openFolderPicker(scope),
                );
              },
            ),
          ),
          actions: _buildAppBarActions(context),
        ),
        body: DeskSurface(
          child: SafeArea(
            child: Column(
              children: [
                if (_isSearchVisible) ...[
                  _buildSearchField(context),
                  BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, state) => NoteSearchFilters(
                            selected:
                                state.mapOrNull(loaded: (s) => s.filters) ?? {},
                            onChanged: (filters) => context
                                .read<HomeBloc>()
                                .add(HomeEvent.filtersChanged(filters)),
                          )),
                ],
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
                      valueListenable: Hive.box(folderDatabaseBox).listenable(),
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
                                Expanded(
                                  child: data.notes.isEmpty
                                      ? _EmptyNotes(
                                          showTrash: data.showTrash,
                                          hasSearch: data.searchQuery
                                                  .trim()
                                                  .isNotEmpty ||
                                              data.filters.isNotEmpty,
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
                                          searchQuery: data.searchQuery,
                                          folders: data.folders,
                                          showTrash: data.showTrash,
                                          isReorderMode: _isReorderMode &&
                                              data.searchQuery.trim().isEmpty &&
                                              data.filters.isEmpty,
                                          onEnterReorderMode: () {
                                            _searchController.clear();
                                            context.read<HomeBloc>().add(
                                                const HomeEvent.searchChanged(
                                                    ''));
                                            context.read<HomeBloc>().add(
                                                const HomeEvent.filtersChanged(
                                                    {}));
                                            setState(() {
                                              _isSearchVisible = false;
                                              _isReorderMode = true;
                                            });
                                          },
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
                if (_adSize != null &&
                    PurchaseService.instance.shouldShowAds &&
                    MediaQuery.viewInsetsOf(context).bottom == 0)
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
      ),
    );
  }

  List<Widget>? _buildAppBarActions(BuildContext context) {
    if (_isReorderMode) {
      return [
        AppButton(
          primary: true,
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
                        .add(const HomeEvent.filtersChanged({}));
                    context
                        .read<HomeBloc>()
                        .add(const HomeEvent.searchChanged(''));
                  }
                });
              },
            ),
            AppButton(
              primary: true,
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
                destructive: true,
                tooltip: showTrash
                    ? S.of(context).Delete_Forever
                    : S.of(context).Delete,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${selectedNotes.selectedIds.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: 6),
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
              primary: true,
              tooltip: S.of(context).Add_Note,
              child: const Icon(Icons.add),
              onPressed: () {
                context.router.push(AddUpdateNoteRoute());
              },
            ),
          ],
          failed: (_) => [
            AppButton(
              primary: true,
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
      child: PaperNote(
        color: AppColors.parchment,
        seed: 11,
        tilt: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: AppTypography.formText.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: S.of(context).Search_Notes,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context
                          .read<HomeBloc>()
                          .add(const HomeEvent.searchChanged(''));
                      setState(() {});
                    },
                  ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
          ),
          onChanged: (value) {
            context.read<HomeBloc>().add(HomeEvent.searchChanged(value));
            setState(() {});
          },
        ),
      ),
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
    required this.searchQuery,
    required this.folders,
    required this.showTrash,
    required this.isReorderMode,
    required this.onEnterReorderMode,
  });

  final List<Note> notes;
  final String searchQuery;
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
    await ShareHelper.shareNote(context, note, controller,
        sharePositionOrigin: ShareHelper.shareOriginFromKey(cardKey));
  }

  void _showMoveToFolderSheet(BuildContext context, Note note) {
    showAppActionSheet(
      context: context,
      title: S.of(context).Move_To_Folder,
      actions: <AppSheetAction>[
        AppSheetAction(
          leading: const Icon(Icons.notes_outlined),
          title: Text(S.of(context).No_Folder),
          selected: note.folderId == null,
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            context.read<HomeBloc>().add(
                  HomeEvent.moveNoteToFolder(noteId: note.id!, folderId: null),
                );
          },
        ),
        ...widget.folders.map(
          (folder) => AppSheetAction(
            leading: const Icon(Icons.folder_outlined),
            title: Text(folder.name),
            selected: note.folderId == folder.id,
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
      showAppActionSheet(
        context: context,
        title: S.of(context).Trash,
        actions: <AppSheetAction>[
          AppSheetAction(
            leading: const Icon(Icons.restore_outlined),
            title: Text(S.of(context).Restore),
            onPressed: (sheetContext) {
              Navigator.pop(sheetContext);
              context.read<HomeBloc>().add(HomeEvent.restoreNotes([noteId]));
            },
          ),
          AppSheetAction(
            destructive: true,
            leading: const Icon(Icons.delete_forever_outlined),
            title: Text(
              S.of(context).Delete_Forever,
              style: TextStyle(color: context.colors.error),
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
      );
      return;
    }

    showAppActionSheet(
      context: context,
      title: note.title?.trim().isNotEmpty == true
          ? note.title!
          : S.of(context).Onlynote,
      actions: <AppSheetAction>[
        AppSheetAction(
          leading: Icon(
            note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          ),
          title: Text(note.isPinned ? S.of(context).Unpin : S.of(context).Pin),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            context.read<HomeBloc>().add(HomeEvent.togglePin(noteId));
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.drive_file_move_outline),
          title: Text(S.of(context).Move_To_Folder),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _showMoveToFolderSheet(context, note);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.share_outlined),
          title: Text(S.of(context).Share),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _shareNote(context, note, screenshotController, cardKey);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.copy_outlined),
          title: Text(S.of(context).Duplicate),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            context.read<HomeBloc>().add(HomeEvent.duplicateNote(note));
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(S.of(context).Select),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            multipleDeleteBloc.add(MultipleDeleteEvent.toggleSelect(noteId));
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.swap_vert),
          title: Text(S.of(context).Reorder),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            widget.onEnterReorderMode();
          },
        ),
        AppSheetAction(
          destructive: true,
          leading: const Icon(Icons.delete_outline),
          title: Text(S.of(context).Delete,
              style: TextStyle(color: context.colors.error)),
          onPressed: (sheetContext) async {
            Navigator.pop(sheetContext);
            multipleDeleteBloc.add(MultipleDeleteEvent.deleteIds([noteId]));
          },
        ),
      ],
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
              // Keyed on the *mode* only. Including the notes themselves
              // swapped in a brand-new grid on every add/pin/delete, which
              // replayed the entrance animation and threw away the user's
              // scroll position.
              key: ValueKey('${widget.isReorderMode}:${widget.showTrash}'),
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
          duration: Duration(milliseconds: 80 + (index.clamp(0, 6) * 40)),
          child: KeyedSubtree(
            key: _cardKeyFor(noteId),
            child: NoteCard(
              note: note,
              searchQuery: widget.searchQuery,
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

    return PaperNote(
      color: note.color ?? AppColors.parchment,
      seed: note.id?.hashCode ?? 0,
      pinned: note.isPinned,
      tilt: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            headlineText,
            style: AppTypography.cardTitle,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacings.m),
          Text(
            note.date,
            style: AppTypography.description.copyWith(
              color: AppColors.ink.withValues(alpha: 0.55),
            ),
          ),
        ],
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
        itemBuilder: (context, index) => DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.parchment,
              AppColors.ink,
              0.04 + (index % 3) * 0.02,
            ),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(1, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The slice of [HomeState] the folder picker needs.
///
/// Freezed generates the loaded state as a library-private class, so it can't
/// be named outside the bloc's own file — this is the view-model that crosses
/// that boundary.
class _FolderScope {
  const _FolderScope({
    required this.folders,
    required this.selectedFolderId,
    required this.showTrash,
    required this.trashCount,
    required this.folderCounts,
    required this.allNotesCount,
  });

  final List<Folder> folders;
  final String? selectedFolderId;
  final bool showTrash;
  final int trashCount;
  final Map<String, int> folderCounts;
  final int allNotesCount;

  Folder? get selectedFolder {
    for (final folder in folders) {
      if (folder.id == selectedFolderId) return folder;
    }
    return null;
  }
}

/// The app bar title on the home screen: a button that reads as the current
/// scope and opens the folder picker. Replaces the horizontal chip bar that
/// used to sit under the app bar and cost a row of vertical space on every
/// screen, whether or not the user had folders.
class _FolderPickerTitle extends StatelessWidget {
  const _FolderPickerTitle({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        button: true,
        // The label alone reads as a heading; the hint is what tells a screen
        // reader user this is also how you switch folders.
        hint: S.of(context).Folders,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space2,
              vertical: tokens.space1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
                SizedBox(width: tokens.space2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleLarge,
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the picker sheet hands back. The sheet itself stays presentational —
/// it pops a result and lets the screen own the dialogs and bloc events, so a
/// confirmation dialog is never parented to a sheet that's closing.
sealed class _FolderPickerResult {
  const _FolderPickerResult();
}

class _SelectAll extends _FolderPickerResult {
  const _SelectAll();
}

class _SelectFolder extends _FolderPickerResult {
  const _SelectFolder(this.id);
  final String id;
}

class _SelectTrash extends _FolderPickerResult {
  const _SelectTrash();
}

class _CreateFolder extends _FolderPickerResult {
  const _CreateFolder();
}

class _RenameFolder extends _FolderPickerResult {
  const _RenameFolder(this.folder);
  final Folder folder;
}

class _DeleteFolder extends _FolderPickerResult {
  const _DeleteFolder(this.folder);
  final Folder folder;
}

class _ManageFolders extends _FolderPickerResult {
  const _ManageFolders();
}

class _FolderPickerSheet extends StatelessWidget {
  const _FolderPickerSheet({required this.scope});

  final _FolderScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AppSheet(
      title: l10n.Folders,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PickerTile(
            icon: Icons.notes_rounded,
            label: l10n.All_Notes,
            count: scope.allNotesCount,
            selected: !scope.showTrash && scope.selectedFolderId == null,
            onTap: () => Navigator.pop(context, const _SelectAll()),
          ),
          for (final folder in scope.folders)
            _PickerTile(
              icon: Icons.folder_rounded,
              label: folder.name,
              count: scope.folderCounts[folder.id] ?? 0,
              selected: !scope.showTrash && scope.selectedFolderId == folder.id,
              onTap: () => Navigator.pop(context, _SelectFolder(folder.id)),
              onRename: () => Navigator.pop(context, _RenameFolder(folder)),
              onDelete: () => Navigator.pop(context, _DeleteFolder(folder)),
            ),
          _PickerTile(
            icon: Icons.delete_outline_rounded,
            label: l10n.Trash,
            count: scope.trashCount,
            selected: scope.showTrash,
            onTap: () => Navigator.pop(context, const _SelectTrash()),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.create_new_folder_outlined,
              color: context.colors.primary,
            ),
            title: Text(
              l10n.New_Folder,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.pop(context, const _CreateFolder()),
          ),
          if (scope.folders.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: Text(l10n.Manage_Folders),
              onTap: () => Navigator.pop(context, const _ManageFolders()),
            ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isFolder = onRename != null;

    return ListTile(
      selected: selected,
      selectedTileColor: context.colors.primaryContainer,
      selectedColor: context.colors.onPrimaryContainer,
      leading: Icon(
        icon,
        color: selected ? context.colors.primary : null,
      ),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.bodyLarge?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            Icon(Icons.check_rounded, size: 20, color: context.colors.primary),
            const SizedBox(width: 8),
          ],
          Text(
            '$count',
            style: context.textStyles.labelLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (isFolder)
            // Rename/delete used to be long-press only, which nobody
            // discovers. An explicit overflow button is the trade for a
            // slightly busier row.
            Row(
              children: [
                const SizedBox(width: 10),
                PopupMenuButton<_FolderRowAction>(
                  tooltip: S.of(context).Edit,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: context.colors.onSurfaceVariant,
                  ),
                  iconSize: 20,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  onSelected: (action) => switch (action) {
                    _FolderRowAction.rename => onRename!(),
                    _FolderRowAction.delete => onDelete!(),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _FolderRowAction.rename,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.drive_file_rename_outline),
                        title: Text(S.of(context).Rename_Folder),
                      ),
                    ),
                    PopupMenuItem(
                      value: _FolderRowAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: context.colors.error,
                        ),
                        title: Text(
                          S.of(context).Delete_Folder,
                          style: TextStyle(color: context.colors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            SizedBox(width: tokens.space4),
        ],
      ),
      onTap: onTap,
    );
  }
}

enum _FolderRowAction { rename, delete }
