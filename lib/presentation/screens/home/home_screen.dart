import 'dart:async';

import 'package:onlynote/presentation/components/note_search_filters.dart';
import 'package:onlynote/presentation/components/note_search_feedback.dart';
import 'package:onlynote/presentation/components/photo_search_status.dart';
import 'package:onlynote/services/photo_search_index.dart';
import 'package:onlynote/presentation/components/daily_note_calendar_sheet.dart';
import 'package:onlynote/presentation/components/note_template_picker_sheet.dart';
import 'package:onlynote/presentation/components/library_filters_sheet.dart';
import 'package:onlynote/presentation/components/note_card_entrance.dart';
import 'package:onlynote/presentation/components/sliver_note_card_layout.dart';
import 'package:onlynote/presentation/components/note_tags_sheet.dart';
import 'package:onlynote/services/note_archive.dart';
import 'package:onlynote/services/saved_note_views.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/ads_manager.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/consent_gate.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/in_app_reviewer_helper.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/components/review_moment.dart';
import 'package:onlynote/presentation/components/premium_feature_gate.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/button_styles.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/presentation/theme/note_grid_layout.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/note_creation_limit.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:screenshot/screenshot.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/services/daily_note.dart';

import '../settings/manage_folders_screen.dart';
import '../settings/settings_screen.dart';
import '../card_appearance/card_appearance_screen.dart';
import 'bloc/home_bloc.dart';
import 'bloc/multiple_delete/multiple_delete_bloc.dart';
import 'widgets/note_card.dart';
import 'widgets/note_reorder_card.dart';
import 'widgets/widget_discovery_prompt.dart';
import 'widgets/home_menu_item_label.dart';

@RoutePage(name: 'HomeRoute')
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _savedViews = SavedNoteViewStore.instance;
  bool _viewsUnavailable = false;
  bool _openingDailyNote = false;
  bool _openingTemplate = false;
  bool _presentingDailyCalendar = false;
  bool _presentingLibraryFilters = false;
  int _checklistReviewGeneration = 0;
  void _cancelChecklistReview() => _checklistReviewGeneration++;

  void _handleChecklistResult(HomeChecklistResult result) {
    if (!mounted) return;
    if (result.error != null) {
      _cancelChecklistReview();
      context.showToast(result.error!, isError: true);
      return;
    }
    final change = result.change;
    if (change == null) return;
    _considerChecklistReview(change);
    final bloc = context.read<HomeBloc>();
    showTransientSnackBar(
        context,
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(change.completed
              ? S.of(context).Checklist_Item_Completed
              : S.of(context).Checklist_Item_Reopened),
          action: SnackBarAction(
              label: S.of(context).Undo,
              onPressed: () async {
                _cancelChecklistReview();
                final undone = await bloc.setTodoCompleted(
                    noteId: change.noteId,
                    todoId: change.todoId,
                    completed: change.previousCompleted);
                if (mounted && undone.error != null) {
                  context.showToast(undone.error!, isError: true);
                }
              }),
        ));
  }

  Future<void> _considerChecklistReview(HomeChecklistChange change) async {
    final generation = ++_checklistReviewGeneration;
    if (!InAppReviewHelper.instance.promptsEnabled) return;
    if (!change.newlyCompleted || !change.checklistNowComplete) return;
    // Wait for Undo to expire. Any subsequent checkbox action cancels this.
    await Future<void>.delayed(const Duration(seconds: 6));
    if (!mounted ||
        generation != _checklistReviewGeneration ||
        !isReviewMomentIdle ||
        _isSearchVisible ||
        ModalRoute.of(context)?.isCurrent != true ||
        !getIt.isRegistered<NoteRepository>()) {
      return;
    }
    try {
      final note =
          (await getIt<NoteRepository>().getNote(change.noteId)).toDomain();
      final items = note.todo
          .where((todo) => todo.title?.trim().isNotEmpty == true)
          .toList();
      if (note.isDeleted ||
          items.isEmpty ||
          items.any((todo) => !todo.completed)) {
        return;
      }
      await InAppReviewHelper.instance
          .recordChecklistCompleted(noteId: change.noteId);
      if (mounted &&
          generation == _checklistReviewGeneration &&
          ModalRoute.of(context)?.isCurrent == true &&
          isReviewMomentIdle &&
          !_isSearchVisible) {
        await InAppReviewHelper.instance
            .requestReviewIfEligible(afterChecklistCompletion: true);
      }
    } catch (_) {
      // Review opportunities never interfere with a saved checklist.
    }
  }

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
    _savedViews.addListener(_savedViewsChanged);
    _loadSavedViews();
  }

  void _savedViewsChanged() {
    if (mounted) {
      context
          .read<HomeBloc>()
          .add(HomeEvent.savedViewsChanged(_savedViews.views));
    }
  }

  Future<void> _loadSavedViews() async {
    try {
      await _savedViews.load();
      if (mounted) {
        setState(() => _viewsUnavailable = false);
        _savedViewsChanged();
      }
    } catch (_) {
      if (mounted) setState(() => _viewsUnavailable = true);
    }
  }

  Future<void> _archiveNotes(List<String> ids, bool archived) async {
    final bloc = context.read<HomeBloc>();
    final changes = <NoteArchiveChange>[];
    for (final id in ids) {
      final result = await bloc.setArchived(id, archived);
      if (!mounted) return;
      if (result.error != null) {
        context.showToast(result.error!, isError: true);
      } else if (result.change != null) {
        changes.add(result.change!);
      }
    }
    if (!mounted || changes.isEmpty) return;
    showTransientSnackBar(
      context,
      SnackBar(
        content: Text(archived
            ? S.of(context).Note_Archived
            : S.of(context).Note_Unarchived),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: S.of(context).Undo,
          onPressed: () async {
            for (final change in changes) {
              final result = await bloc.setArchived(
                  change.noteId, change.previousArchived);
              if (mounted && result.error != null) {
                context.showToast(result.error!, isError: true);
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _editTags(Note note) async {
    try {
      final fresh =
          (await getIt<NoteRepository>().getNote(note.id!)).toDomain();
      if (!mounted || fresh.isDeleted) return;
      final suggestions = context.read<HomeBloc>().state.mapOrNull(
                loaded: (state) => state.availableTags,
              ) ??
          const <String>[];
      final tags = await showNoteTagsSheet(context,
          tags: fresh.tags, suggestions: suggestions);
      if (!mounted || tags == null) return;
      final error = await context.read<HomeBloc>().setTags(note.id!, tags);
      if (mounted && error != null) context.showToast(error, isError: true);
    } catch (_) {
      if (mounted) {
        context.showToast(S.of(context).Failed_to_Update_note_please_try_again,
            isError: true);
      }
    }
  }

  Future<void> _openLibraryFilters() async {
    if (_presentingLibraryFilters ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _presentingLibraryFilters = true;
    try {
      await _presentLibraryFilters();
    } finally {
      _presentingLibraryFilters = false;
    }
  }

  Future<void> _presentLibraryFilters() async {
    await _loadSavedViews();
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    final bloc = context.read<HomeBloc>();
    final data = bloc.state.mapOrNull(
        loaded: (state) => (
              query: state.searchQuery,
              filters: state.filters,
              tags: state.selectedTags,
              availableTags: state.availableTags,
              folderId: state.selectedFolderId,
              showTrash: state.showTrash,
              scope: state.showArchive
                  ? NoteArchiveScope.archived
                  : state.includeArchived
                      ? NoteArchiveScope.all
                      : NoteArchiveScope.active,
              views: state.savedViews,
              selectedViewId: state.selectedViewId,
              folderNames: {
                for (final folder in state.folders) folder.id: folder.name,
              },
            ));
    if (data == null) return;
    ModalRoute<LibraryFilterResult>? filtersRoute;
    final result = await showAppSheet<LibraryFilterResult>(
      context: context,
      builder: (sheetContext) {
        filtersRoute ??= ModalRoute.of<LibraryFilterResult>(sheetContext);
        return LibraryFiltersSheet(
          filters: data.filters,
          selectedTags: data.tags,
          availableTags: data.availableTags,
          scope: data.scope,
          showTrash: data.showTrash,
          savedViews: data.views,
          selectedViewId: data.selectedViewId,
          folderNames: data.folderNames,
          viewsUnavailable: _viewsUnavailable,
        );
      },
    );
    // Popping returns before the modal barrier finishes its exit animation.
    // Remove it before changing the grid and revealing its semantics tree.
    await filtersRoute?.completed;
    if (!mounted ||
        result == null ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _setReorderMode(false);
    context
        .read<MultipleDeleteBloc>()
        .add(const MultipleDeleteEvent.clearAll());
    try {
      switch (result) {
        case CreateSavedNoteView():
          final name = await showDialog<String>(
              context: context,
              builder: (_) => FolderNameDialog(
                    title: S.of(context).Save_Current_View,
                    labelText: S.of(context).Saved_View_Name,
                    icon: Icons.bookmark_border_rounded,
                    maxLength: 80,
                  ));
          if (!mounted || name == null) return;
          final view = await _savedViews.create(
            name: name,
            query: data.query,
            filters: result.filters,
            tags: result.tags.toList(),
            folderId: data.folderId,
            archiveScope: result.scope,
          );
          if (!mounted) return;
          _applyView(view);
          context.showToast(S.of(context).View_Saved);
        case ApplyLibraryFilters():
          bloc.add(HomeEvent.filtersChanged(result.filters));
          bloc.add(HomeEvent.tagsChanged(result.tags));
          if (!data.showTrash && result.scope != data.scope) {
            if (result.scope == NoteArchiveScope.archived) {
              bloc.add(const HomeEvent.showArchive(true));
            } else {
              bloc.add(HomeEvent.includeArchived(
                  result.scope == NoteArchiveScope.all));
            }
          }
        case ApplySavedNoteView():
          _applyView(result.view);
        case RenameSavedNoteView():
          final name = await showDialog<String>(
              context: context,
              builder: (_) => FolderNameDialog(
                  title: S.of(context).Rename_View,
                  labelText: S.of(context).Saved_View_Name,
                  icon: Icons.bookmark_border_rounded,
                  maxLength: 80,
                  initial: result.view.name));
          if (name != null) await _savedViews.rename(result.view.id, name);
        case DeleteSavedNoteView():
          final confirmed = await showConfirmDialog(context,
              title: S.of(context).Delete_View,
              message: S.of(context).Saved_View_Delete_Confirm);
          if (confirmed) await _savedViews.delete(result.view.id);
      }
    } catch (_) {
      if (mounted) {
        context.showToast(S.of(context).Saved_View_Failed, isError: true);
      }
    }
  }

  void _applyView(SavedNoteView view) {
    _searchController.text = view.query;
    setState(() => _isSearchVisible = view.query.trim().isNotEmpty);
    context.read<HomeBloc>().add(HomeEvent.applySavedView(view));
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
    required FutureOr<void> Function(String) onSubmit,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => FolderNameDialog(title: title, initial: initial),
    );
    if (mounted && name != null && name.trim().isNotEmpty) {
      await onSubmit(name.trim());
    }
  }

  Future<void> _createFolder(HomeBloc bloc, String name) async {
    try {
      final error = await bloc.createFolder(name);
      if (mounted) {
        context.showToast(error ?? S.of(context).Folder_Created,
            isError: error != null);
      }
    } on PremiumRequired {
      if (!mounted ||
          !await ensurePremiumAccess(context, PremiumFeature.folders,
              currentCount: getIt<FolderRepository>().getAllFolders().length,
              access: bloc.premiumAccess)) {
        return;
      }
      if (mounted) await _createFolder(bloc, name);
    }
  }

  Future<void> _openTemplates({String? folderId}) async {
    if (_openingTemplate) return;
    _openingTemplate = true;
    try {
      final selection = await showNoteTemplatePickerSheet(context);
      if (!mounted || selection == null) return;
      final access = context.read<HomeBloc>().premiumAccess;
      if (!await _ensureNoteCreation(access) || !mounted) return;
      if (selection.builtIn != null) {
        await context.router.push(
          AddUpdateNoteRoute(
              folderId: folderId,
              template: selection.builtIn,
              premiumAccess: access),
        );
        return;
      }
      final note = await CustomNoteTemplateStore.instance
          .createNote(selection.custom!.id, folderId: folderId);
      if (!mounted) {
        await ImageStorage.deleteImages(note.imagePaths);
        return;
      }
      await context.router.push(
          AddUpdateNoteRoute(customTemplateNote: note, premiumAccess: access));
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Template_Copy_Failed)));
      }
    } finally {
      _openingTemplate = false;
    }
  }

  Future<void> _openDailyNote() async {
    if (_openingDailyNote || _presentingDailyCalendar) return;
    _cancelChecklistReview();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _openingDailyNote = true);
    try {
      final locale = Localizations.localeOf(context).toString();
      final access = context.read<HomeBloc>().premiumAccess;
      final service =
          DailyNoteService(getIt<NoteRepository>(), premiumAccess: access);
      Future<Note> openToday() => service.openToday(
          titleForDay: (date) => DateFormat.yMMMMd(locale).format(date));
      Note note;
      try {
        note = await openToday();
      } on PremiumRequired {
        if (!mounted || !await _ensureNoteCreation(access) || !mounted) return;
        note = await openToday();
      }
      if (!mounted) return;
      await context.router
          .push(AddUpdateNoteRoute(note: note, premiumAccess: access));
    } catch (_) {
      if (mounted) {
        context.showToast(S.of(context).Today_Note_Open_Failed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _openingDailyNote = false);
    }
  }

  Future<void> _openDailyNoteCalendar() async {
    if (_openingDailyNote || _presentingDailyCalendar) return;
    _cancelChecklistReview();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _presentingDailyCalendar = true);
    ({DateTime? day, bool openToday})? selection;
    try {
      final repository = getIt<NoteRepository>();
      selection = await showAppSheet<({DateTime? day, bool openToday})>(
        context: context,
        builder: (sheetContext) => ValueListenableBuilder(
          valueListenable: getIt<Database>().box.listenable(),
          builder: (_, __, ___) => DailyNoteCalendarSheet(
            notes:
                repository.getAllNotes().map((dto) => dto.toDomain()).toList(),
            onOpenDay: (day) =>
                Navigator.of(sheetContext).pop((day: day, openToday: false)),
            onOpenToday: () =>
                Navigator.of(sheetContext).pop((day: null, openToday: true)),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        context.showToast(S.of(context).Daily_Note_Calendar_Open_Failed,
            isError: true);
      }
      return;
    } finally {
      if (mounted) setState(() => _presentingDailyCalendar = false);
    }
    if (!mounted || selection == null) return;
    if (selection.openToday) {
      await _openDailyNote();
      return;
    }
    await _openExistingDailyNote(selection.day!);
  }

  Future<void> _openExistingDailyNote(DateTime day) async {
    if (_openingDailyNote || _presentingDailyCalendar) return;
    setState(() => _openingDailyNote = true);
    try {
      final note =
          DailyNoteService(getIt<NoteRepository>()).existingForDay(day);
      if (note == null) {
        context.showToast(S.of(context).Daily_Note_Calendar_Note_Unavailable,
            isError: true);
        return;
      }
      await context.router.push(AddUpdateNoteRoute(note: note));
    } catch (_) {
      if (mounted) {
        context.showToast(S.of(context).Daily_Note_Calendar_Open_Failed,
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _openingDailyNote = false);
    }
  }

  /// What the app bar title reads: the scope the note list is currently
  /// showing.
  String _scopeLabel(BuildContext context, _FolderScope scope) {
    if (scope.showTrash) return S.of(context).Trash;
    if (scope.selectedViewName != null) return scope.selectedViewName!;
    if (scope.showArchive) return S.of(context).Archive;
    return scope.selectedFolder?.name ?? S.of(context).All_Notes;
  }

  IconData _scopeIcon(_FolderScope scope) {
    if (scope.showTrash) return Icons.delete_outline_rounded;
    if (scope.showArchive) return Icons.archive_outlined;
    if (scope.selectedViewName != null) return Icons.bookmark_border_rounded;
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
    if (result is _SelectAll ||
        result is _SelectFolder ||
        result is _SelectTrash ||
        result is _SelectArchive) {
      _setReorderMode(false);
      context
          .read<MultipleDeleteBloc>()
          .add(const MultipleDeleteEvent.clearAll());
    }

    switch (result) {
      case _SelectAll():
        bloc.add(const HomeEvent.selectFolder(null));
      case _SelectFolder(:final id):
        bloc.add(HomeEvent.selectFolder(id));
      case _SelectTrash():
        bloc.add(const HomeEvent.showTrash(true));
      case _SelectArchive():
        bloc.add(const HomeEvent.showArchive(true));
      case _CreateFolder():
        if (!await ensurePremiumAccess(context, PremiumFeature.folders,
                currentCount: getIt<FolderRepository>().getAllFolders().length,
                access: bloc.premiumAccess) ||
            !mounted) {
          return;
        }
        await _promptFolderName(
          title: S.of(context).New_Folder,
          onSubmit: (name) => _createFolder(bloc, name),
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
    _savedViews.removeListener(_savedViewsChanged);
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
          leading: _buildHomeLeading(context),
          titleWidget: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) => state.maybeMap(
              orElse: () => Text(S.of(context).notes),
              loaded: (data) {
                final scope = _FolderScope(
                  folders: data.folders,
                  selectedFolderId: data.selectedFolderId,
                  showTrash: data.showTrash,
                  showArchive: data.showArchive,
                  archiveCount: data.archiveCount,
                  selectedViewName: data.savedViews
                      .where((view) => view.id == data.selectedViewId)
                      .firstOrNull
                      ?.name,
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
                            onChanged: _changeSearchFilters,
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
                            error: (error) => _HomeError(
                              message: error.message ?? '',
                              onRetry: () => context
                                  .read<HomeBloc>()
                                  .add(const HomeEvent.getAllNotes()),
                            ),
                            loaded: (data) => _watchPhotoSearch(
                                data.searchQuery,
                                () => Column(
                                      children: [
                                        PhotoSearchStatus(
                                          indexing: data.searchQuery
                                                  .trim()
                                                  .isNotEmpty &&
                                              (PhotoSearchIndex
                                                      .initializedInstance
                                                      ?.isIndexing ??
                                                  false),
                                        ),
                                        if (data.searchQuery
                                                .trim()
                                                .isNotEmpty ||
                                            data.filters.isNotEmpty ||
                                            data.selectedTags.isNotEmpty)
                                          NoteSearchResultCount(
                                              count: data.notes.length),
                                        Expanded(
                                          child: data.notes.isEmpty
                                              ? _EmptyNotes(
                                                  showTrash: data.showTrash,
                                                  showArchive: data.showArchive,
                                                  hasSearch: data.searchQuery
                                                          .trim()
                                                          .isNotEmpty ||
                                                      data.filters.isNotEmpty,
                                                  hasTags: data
                                                      .selectedTags.isNotEmpty,
                                                  hasFolder:
                                                      data.selectedFolderId !=
                                                          null,
                                                  onClearSearch: data
                                                          .searchQuery
                                                          .trim()
                                                          .isNotEmpty
                                                      ? _clearSearch
                                                      : null,
                                                  onClearFilters:
                                                      data.filters.isNotEmpty ||
                                                              data.selectedTags
                                                                  .isNotEmpty
                                                          ? _clearLibraryFilters
                                                          : null,
                                                  onAdd: () {
                                                    context.router.push(
                                                      AddUpdateNoteRoute(
                                                        folderId: data
                                                            .selectedFolderId,
                                                      ),
                                                    );
                                                  },
                                                  onTemplates: () =>
                                                      _openTemplates(
                                                    folderId:
                                                        data.selectedFolderId,
                                                  ),
                                                )
                                              : _BuildNotesList(
                                                  onChecklistActionStart:
                                                      _cancelChecklistReview,
                                                  onChecklistResult:
                                                      _handleChecklistResult,
                                                  onArchive: _archiveNotes,
                                                  onEditTags: _editTags,
                                                  notes: data.notes,
                                                  searchQuery: data.searchQuery,
                                                  unfinishedOnly: data.filters
                                                      .contains(NoteSearchFilter
                                                          .unfinished),
                                                  folders: data.folders,
                                                  showTrash: data.showTrash,
                                                  showWidgetDiscovery:
                                                      !_isSearchVisible &&
                                                          data.searchQuery
                                                              .trim()
                                                              .isEmpty &&
                                                          data.filters
                                                              .isEmpty &&
                                                          !data.showTrash &&
                                                          !data.showArchive &&
                                                          data.notes.any((note) =>
                                                              note.isPinned &&
                                                              !note.isDeleted),
                                                  allowReorder: !data
                                                          .showArchive &&
                                                      !data.includeArchived &&
                                                      data.selectedTags.isEmpty,
                                                  isReorderMode:
                                                      _isReorderMode &&
                                                          !data.showArchive &&
                                                          !data
                                                              .includeArchived &&
                                                          data.selectedTags
                                                              .isEmpty &&
                                                          data.searchQuery
                                                              .trim()
                                                              .isEmpty &&
                                                          data.filters.isEmpty,
                                                  onEnterReorderMode: () {
                                                    _searchController.clear();
                                                    context
                                                        .read<HomeBloc>()
                                                        .add(const HomeEvent
                                                            .searchChanged(''));
                                                    context
                                                        .read<HomeBloc>()
                                                        .add(const HomeEvent
                                                            .filtersChanged(
                                                            {}));
                                                    setState(() {
                                                      _isSearchVisible = false;
                                                      _isReorderMode = true;
                                                    });
                                                  },
                                                ),
                                        ),
                                      ],
                                    )),
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

  Widget _watchPhotoSearch(String query, Widget Function() builder) {
    final index = PhotoSearchIndex.initializedInstance;
    if (index == null || query.trim().isEmpty) return builder();
    return ListenableBuilder(
      listenable: index,
      builder: (context, _) => builder(),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        context.read<HomeBloc>().add(const HomeEvent.searchChanged(''));
      }
    });
  }

  String? _creationFolder() => context.read<HomeBloc>().state.mapOrNull(
      loaded: (state) => state.showTrash ? null : state.selectedFolderId);

  void _showTemplates() => _openTemplates(folderId: _creationFolder());

  Future<bool> _ensureNoteCreation(PremiumAccess access) =>
      ensurePremiumAccess(context, PremiumFeature.notes,
          currentCount: NoteCreationLimit.count(getIt<NoteRepository>()),
          access: access);

  Future<void> _addNote() async {
    final access = context.read<HomeBloc>().premiumAccess;
    if (!await _ensureNoteCreation(access) || !mounted) return;
    await context.router.push(
        AddUpdateNoteRoute(folderId: _creationFolder(), premiumAccess: access));
  }

  void _openCurrentFolderPicker() {
    context.read<HomeBloc>().state.mapOrNull(loaded: (data) {
      _openFolderPicker(_FolderScope(
        folders: data.folders,
        selectedFolderId: data.selectedFolderId,
        showTrash: data.showTrash,
        showArchive: data.showArchive,
        archiveCount: data.archiveCount,
        selectedViewName: data.savedViews
            .where((view) => view.id == data.selectedViewId)
            .firstOrNull
            ?.name,
        trashCount: data.trashCount,
        folderCounts: data.folderCounts,
        allNotesCount: data.allNotesCount,
      ));
    });
  }

  Future<void> _deleteSelected(List<String> ids,
      {required bool forever}) async {
    final selection = context.read<MultipleDeleteBloc>();
    if (!forever) {
      selection.add(const MultipleDeleteEvent.delete());
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: S.of(context).Permanent_Delete_Confirm_Title,
      message: S.of(context).Permanent_Delete_Confirm_Message,
    );
    if (!confirmed || !mounted) return;
    context.read<HomeBloc>().add(HomeEvent.permanentDelete(List.of(ids)));
    selection.add(const MultipleDeleteEvent.clearAll());
  }

  void _archiveSelected(List<String> ids, bool archived) {
    _archiveNotes(List.of(ids), archived);
    context
        .read<MultipleDeleteBloc>()
        .add(const MultipleDeleteEvent.clearAll());
  }

  void _restoreSelected(List<String> ids) {
    context.read<HomeBloc>().add(HomeEvent.restoreNotes(List.of(ids)));
    context
        .read<MultipleDeleteBloc>()
        .add(const MultipleDeleteEvent.clearAll());
  }

  void _openSettings() => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );

  Widget _libraryFiltersButton() => BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) => LibraryFiltersButton(
          key: const ValueKey('home-library-filters'),
          count: state.mapOrNull(
                loaded: (data) =>
                    data.filters.length +
                    data.selectedTags.length +
                    (data.includeArchived ? 1 : 0),
              ) ??
              0,
          onPressed: _openLibraryFilters,
        ),
      );

  Widget _buildHomeLeading(BuildContext context) {
    final browsing = !_isReorderMode &&
        context.watch<MultipleDeleteBloc>().state.maybeMap(
              initial: (_) => true,
              orElse: () => false,
            );
    if (MediaQuery.sizeOf(context).width < 240 && browsing) {
      return _libraryFiltersButton();
    }
    return IconButton(
      tooltip: S.of(context).Settings,
      icon: const Icon(Icons.settings_outlined),
      onPressed: _openSettings,
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
            if (MediaQuery.sizeOf(context).width >= 240)
              _libraryFiltersButton(),
            if (MediaQuery.sizeOf(context).width >= 440)
              AppButton(
                tooltip: _isSearchVisible
                    ? S.of(context).Cancel_Searching
                    : S.of(context).Search_Notes,
                onPressed: _toggleSearch,
                child: HomeSearchStatusIcon(
                  icon: _isSearchVisible ? Icons.search_off : Icons.search,
                  active: _isSearchVisible,
                  badgeKey: const ValueKey('home-direct-search-active-dot'),
                ),
              ),
            PopupMenuButton<String>(
              key: const ValueKey('home-more'),
              tooltip: _isSearchVisible &&
                      MediaQuery.sizeOf(context).width < 440
                  ? '${S.of(context).More_Options}, ${S.of(context).Search_Active}'
                  : S.of(context).More_Options,
              style: AppButtonStyles.icon(Theme.of(context).colorScheme),
              onSelected: (action) {
                switch (action) {
                  case 'search':
                    _toggleSearch();
                  case 'templates':
                    _showTemplates();
                  case 'folders':
                    _openCurrentFolderPicker();
                  case 'daily-calendar':
                    _openDailyNoteCalendar();
                  case 'reminders':
                    _cancelChecklistReview();
                    context.router.push(RemindersRoute());
                  case 'settings':
                    _openSettings();
                }
              },
              itemBuilder: (context) => [
                if (MediaQuery.sizeOf(context).width < 280)
                  PopupMenuItem(
                      value: 'folders',
                      child: HomeMenuItemLabel(S.of(context).Folders,
                          icon: Icons.folder_outlined)),
                if (MediaQuery.sizeOf(context).width < 440)
                  PopupMenuItem(
                    key: const ValueKey('home-search-menu'),
                    value: 'search',
                    child: HomeMenuItemLabel(
                      _isSearchVisible
                          ? S.of(context).Cancel_Searching
                          : S.of(context).Search_Notes,
                      icon: _isSearchVisible ? Icons.search_off : Icons.search,
                      activeSearch: _isSearchVisible,
                      searchDotKey: const ValueKey('home-search-menu-dot'),
                    ),
                  ),
                PopupMenuItem(
                  key: const ValueKey('home-reminders-menu'),
                  value: 'reminders',
                  child: HomeMenuItemLabel(S.of(context).Reminders_Title,
                      icon: Icons.alarm_outlined),
                ),
                PopupMenuItem(
                    value: 'templates',
                    child: HomeMenuItemLabel(S.of(context).Templates,
                        icon: Icons.dashboard_customize_outlined)),
                PopupMenuItem(
                  key: const ValueKey('daily-note-calendar-menu'),
                  value: 'daily-calendar',
                  enabled: !_openingDailyNote && !_presentingDailyCalendar,
                  child: HomeMenuItemLabel(S.of(context).Daily_Note_Calendar,
                      icon: Icons.calendar_month_outlined),
                ),
                if (MediaQuery.sizeOf(context).width < 240)
                  PopupMenuItem(
                      value: 'settings',
                      child: HomeMenuItemLabel(S.of(context).Settings,
                          icon: Icons.settings_outlined)),
              ],
              icon: HomeSearchStatusIcon(
                icon: Icons.more_horiz_rounded,
                active:
                    _isSearchVisible && MediaQuery.sizeOf(context).width < 440,
                badgeKey: const ValueKey('home-search-active-dot'),
              ),
            ),
            AppButton(
              primary: true,
              tooltip: S.of(context).Add_Note,
              onPressed: _addNote,
              child: const Icon(Icons.add),
            ),
          ],
          selected: (selectedNotes) {
            final showTrash = context.read<HomeBloc>().state.mapOrNull(
                      loaded: (s) => s.showTrash,
                    ) ??
                false;
            final showArchive = context.read<HomeBloc>().state.mapOrNull(
                      loaded: (s) => s.showArchive,
                    ) ??
                false;
            final ids = selectedNotes.selectedIds;
            final archiveLabel = showArchive
                ? S.of(context).Unarchive_Note
                : S.of(context).Archive_Note;
            final deleteLabel =
                showTrash ? S.of(context).Delete_Forever : S.of(context).Delete;
            return [
              if (MediaQuery.sizeOf(context).width < 360)
                PopupMenuButton<String>(
                  key: const ValueKey('home-selection-more'),
                  tooltip: S.of(context).More_Options,
                  style: AppButtonStyles.icon(Theme.of(context).colorScheme),
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (action) {
                    switch (action) {
                      case 'archive':
                        _archiveSelected(ids, !showArchive);
                      case 'delete':
                        _deleteSelected(ids, forever: showTrash);
                      case 'restore':
                        _restoreSelected(ids);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!showTrash)
                      PopupMenuItem(
                          value: 'archive',
                          child: HomeMenuItemLabel(archiveLabel,
                              icon: showArchive
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined)),
                    PopupMenuItem(
                        value: 'delete',
                        child: HomeMenuItemLabel('$deleteLabel (${ids.length})',
                            icon: showTrash
                                ? Icons.delete_forever_outlined
                                : Icons.delete_outline)),
                    if (showTrash)
                      PopupMenuItem(
                          value: 'restore',
                          child: HomeMenuItemLabel(S.of(context).Restore,
                              icon: Icons.restore_outlined)),
                  ],
                )
              else ...[
                if (!showTrash)
                  AppButton(
                    tooltip: archiveLabel,
                    child: Icon(showArchive
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined),
                    onPressed: () => _archiveSelected(ids, !showArchive),
                  ),
                AppButton(
                  destructive: true,
                  tooltip: deleteLabel,
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
                  onPressed: () => _deleteSelected(ids, forever: showTrash),
                ),
                if (showTrash)
                  AppButton(
                    tooltip: S.of(context).Restore,
                    child: const Icon(Icons.restore_outlined),
                    onPressed: () => _restoreSelected(ids),
                  ),
              ],
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
              onPressed: _addNote,
              child: const Icon(Icons.add),
            ),
          ],
          failed: (_) => [
            AppButton(
              primary: true,
              tooltip: S.of(context).Add_Note,
              onPressed: _addNote,
              child: const Icon(Icons.add),
            ),
          ],
        );
  }

  void _changeSearchQuery(String query) {
    context
        .read<MultipleDeleteBloc>()
        .add(const MultipleDeleteEvent.clearAll());
    context.read<HomeBloc>().add(HomeEvent.searchChanged(query));
  }

  void _changeSearchFilters(Set<NoteSearchFilter> filters) {
    context
        .read<MultipleDeleteBloc>()
        .add(const MultipleDeleteEvent.clearAll());
    context.read<HomeBloc>().add(HomeEvent.filtersChanged(filters));
  }

  void _clearSearch() {
    _searchController.clear();
    _changeSearchQuery('');
    setState(() {});
  }

  void _clearLibraryFilters() {
    context
        .read<MultipleDeleteBloc>()
        .add(const MultipleDeleteEvent.clearAll());
    final bloc = context.read<HomeBloc>();
    bloc.add(const HomeEvent.filtersChanged({}));
    bloc.add(const HomeEvent.tagsChanged({}));
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
                    tooltip: S.of(context).Clear_Search,
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
          ),
          onChanged: (value) {
            _changeSearchQuery(value);
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
    required this.onTemplates,
    required this.showTrash,
    required this.showArchive,
    required this.hasTags,
    required this.hasSearch,
    required this.hasFolder,
    this.onClearSearch,
    this.onClearFilters,
  });

  final VoidCallback onAdd;
  final VoidCallback onTemplates;
  final bool showTrash;
  final bool showArchive;
  final bool hasTags;
  final bool hasSearch;
  final bool hasFolder;
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final message = hasSearch || hasTags
        ? l10n.No_Search_Results
        : showTrash
            ? l10n.Trash_Empty
            : showArchive
                ? l10n.Archive_Empty
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
            if (onClearSearch != null || onClearFilters != null) ...[
              SizedBox(height: context.tokens.space4),
              NoteSearchRecovery(
                onClearSearch: onClearSearch,
                onClearFilters: onClearFilters,
              ),
            ],
            if (!showTrash && !showArchive && !hasSearch && !hasTags) ...[
              SizedBox(height: context.tokens.space4),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.Add_Note),
              ),
              SizedBox(height: context.tokens.space2),
              TextButton.icon(
                onPressed: onTemplates,
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: Text(l10n.Use_Template),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
            SizedBox(height: context.tokens.space4),
            FilledButton.icon(
              key: const ValueKey('home-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(S.of(context).Retry),
            ),
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
    required this.unfinishedOnly,
    required this.folders,
    required this.showTrash,
    required this.showWidgetDiscovery,
    required this.isReorderMode,
    required this.allowReorder,
    required this.onEnterReorderMode,
    required this.onChecklistActionStart,
    required this.onChecklistResult,
    required this.onArchive,
    required this.onEditTags,
  });

  final List<Note> notes;
  final String searchQuery;
  final bool unfinishedOnly;
  final List<Folder> folders;
  final bool showTrash;
  final Future<void> Function(List<String>, bool) onArchive;
  final Future<void> Function(Note) onEditTags;
  final bool showWidgetDiscovery;
  final bool isReorderMode;
  final bool allowReorder;
  final VoidCallback onChecklistActionStart;
  final ValueChanged<HomeChecklistResult> onChecklistResult;
  final VoidCallback onEnterReorderMode;

  @override
  State<_BuildNotesList> createState() => __BuildNotesListState();
}

class __BuildNotesListState extends State<_BuildNotesList> {
  final Map<String, ScreenshotController> _screenshotControllers = {};
  final Map<String, GlobalKey<NoteCardState>> _cardKeys = {};
  bool _openingCardAppearance = false;

  ScreenshotController _screenshotControllerFor(String noteId) =>
      _screenshotControllers.putIfAbsent(noteId, () => ScreenshotController());

  GlobalKey<NoteCardState> _cardKeyFor(String noteId) =>
      _cardKeys.putIfAbsent(noteId, () => GlobalKey<NoteCardState>());

  @override
  void didUpdateWidget(covariant _BuildNotesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.notes.map((note) => note.id).toSet();
    _cardKeys.removeWhere((id, _) => !ids.contains(id));
    _screenshotControllers.removeWhere((id, _) => !ids.contains(id));
  }

  Future<void> _shareNote(
    BuildContext context,
    Note note,
    ScreenshotController controller,
    GlobalKey<NoteCardState> cardKey,
  ) async {
    await ShareHelper.shareNote(context, note, controller,
        sharePositionOrigin: ShareHelper.shareOriginFromKey(cardKey),
        captureImage: () async => cardKey.currentState?.captureImage());
  }

  Future<void> _toggleTodo(String noteId, String todoId) async {
    widget.onChecklistActionStart();
    final bloc = context.read<HomeBloc>();
    final onResult = widget.onChecklistResult;
    final result = await bloc.toggleTodo(noteId: noteId, todoId: todoId);
    // The Home screen owns feedback, even if Unfinished removes this list.
    onResult(result);
  }

  Future<void> _openCardAppearance(String noteId) async {
    if (_openingCardAppearance || !mounted) return;
    _openingCardAppearance = true;
    final bloc = context.read<HomeBloc>();
    try {
      final note = (await getIt<NoteRepository>().getNote(noteId)).toDomain();
      if (!mounted || note.isDeleted) return;
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => CardAppearanceScreen(
          note: note,
          premiumAccess: bloc.premiumAccess,
          onSaveAppearance: (style, color) async {
            final error = await bloc.setCardAppearance(noteId, style, color);
            if (error != null) throw StateError(error);
          },
        ),
      ));
    } catch (_) {
      if (mounted) {
        context.showToast(S.of(context).Card_Style_Save_Failed, isError: true);
      }
    } finally {
      _openingCardAppearance = false;
    }
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
          leading: const Icon(Icons.palette_outlined),
          title: Text(S.of(context).Card_Style),
          onPressed: (sheetContext) async {
            final route = ModalRoute.of(sheetContext);
            Navigator.pop(sheetContext);
            if (route != null) await route.completed;
            if (mounted) await _openCardAppearance(noteId);
          },
        ),
        AppSheetAction(
          leading: Icon(note.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined),
          title: Text(note.isArchived
              ? S.of(context).Unarchive_Note
              : S.of(context).Archive_Note),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            widget.onArchive([noteId], !note.isArchived);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.sell_outlined),
          title: Text(S.of(context).Edit_Tags),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            widget.onEditTags(note);
          },
        ),
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
          onPressed: (sheetContext) async {
            final route = ModalRoute.of(sheetContext);
            final bloc = context.read<HomeBloc>();
            Navigator.pop(sheetContext);
            if (route != null) await route.completed;
            if (!mounted ||
                !context.mounted ||
                !await ensurePremiumAccess(context, PremiumFeature.notes,
                    currentCount: getIt<NoteRepository>()
                        .getAllNotes()
                        .where((note) => !note.isDeleted)
                        .length,
                    access: bloc.premiumAccess) ||
                !mounted) {
              return;
            }
            bloc.add(HomeEvent.duplicateNote(note));
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
        if (widget.allowReorder)
          AppSheetAction(
            leading: const Icon(Icons.swap_vert),
            title: Text(S.of(context).Reorder),
            onPressed: (sheetContext) async {
              final route = ModalRoute.of(sheetContext);
              Navigator.pop(sheetContext);
              if (route != null) await route.completed;
              if (mounted) widget.onEnterReorderMode();
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
        final crossAxisCount = noteGridColumns(
          width: constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
          preferredColumns: AppLayoutSettings.instance.cardSize.columns,
          appFontScale: AppTypographySettings.instance.scale,
        );
        final cardColumns = [
          for (final note in widget.notes)
            noteGridColumns(
              width: constraints.maxWidth,
              textScaler: MediaQuery.textScalerOf(context),
              preferredColumns: (note.cardStyle.cardSize ??
                      AppCardStyleSettings.instance.defaults.cardSize!)
                  .columns,
              appFontScale: (note.cardStyle.fontSize ??
                      AppCardStyleSettings.instance.defaults.fontSize!)
                  .scale,
            ),
        ];
        return FocusDetector(
          onFocusGained: () {
            if (mounted) setState(() {});
          },
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 280),
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
                  ? _buildReorderableGrid(
                      context, crossAxisCount, constraints.maxWidth)
                  : _buildMasonryGrid(
                      context,
                      multipleDeleteBloc,
                      cardColumns,
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
    List<int> cardColumns,
  ) {
    final isSelectionMode = multipleDeleteBloc.state.maybeMap(
      selected: (_) => true,
      orElse: () => false,
    );

    return CustomScrollView(
      semanticChildCount: widget.notes.length,
      slivers: [
        SliverToBoxAdapter(
          child: WidgetDiscoveryPrompt(
            eligible: widget.showWidgetDiscovery && !isSelectionMode,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacings.xl,
            vertical: AppSpacings.xl,
          ),
          sliver: SliverNoteCardLayout(
            columns: cardColumns,
            itemBuilder: (BuildContext context, int index) {
              final note = widget.notes[index];
              final noteId = note.id!;
              final card = NoteCard(
                key: _cardKeyFor(noteId),
                note: note,
                searchQuery: widget.searchQuery,
                photoSearchText: PhotoSearchIndex.initializedInstance
                    ?.matchingText(note, widget.searchQuery),
                photoSearchImagePath: PhotoSearchIndex.initializedInstance
                    ?.matchingPhotoPath(note, widget.searchQuery),
                selected: multipleDeleteBloc.isSelected(noteId),
                selectionMode: isSelectionMode,
                unfinishedOnly: widget.unfinishedOnly,
                onTodoToggle: isSelectionMode || widget.showTrash
                    ? null
                    : (todoId) => _toggleTodo(noteId, todoId),
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
              );
              return MediaQuery.disableAnimationsOf(context)
                  ? card
                  : NoteCardEntrance(child: card);
            },
            mainAxisSpacing: AppSpacings.xl,
            crossAxisSpacing: AppSpacings.l,
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableGrid(
      BuildContext context, int crossAxisCount, double width) {
    final notes = List<Note>.from(widget.notes);
    final pinnedCount = notes.where((note) => note.isPinned).length;
    final strings = S.of(context);
    final cardWidth =
        (width - 2 * AppSpacings.xl - (crossAxisCount - 1) * AppSpacings.l) /
            crossAxisCount;
    final baseAspectRatio = noteReorderAspectRatio(
      width: width,
      columns: crossAxisCount,
      textScaler: MediaQuery.textScalerOf(context),
      appFontScale: AppTypographySettings.instance.scale,
    );

    Future<void> move(int oldIndex, int newIndex) async {
      final pinned = notes[oldIndex].isPinned;
      final first = pinned ? 0 : pinnedCount;
      final last = pinned ? pinnedCount - 1 : notes.length - 1;
      final target = newIndex.clamp(first, last);
      if (target == oldIndex) return;
      final reordered = List<Note>.from(notes);
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(target, moved);
      final error = await context.read<HomeBloc>().reorderNotes(reordered);
      if (context.mounted && error != null) {
        context.showToast(error, isError: true);
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        key: const ValueKey('home-reorder-instructions'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.drag_indicator_rounded, size: 20)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  pinnedCount > 0
                      ? '${strings.Reorder_Hint}\n${strings.Reorder_Pinned_Hint}'
                      : strings.Reorder_Hint,
                  style: context.textStyles.bodyMedium)),
        ]),
      ),
      Expanded(
        child: ReorderableGridView.count(
          key: const ValueKey('home-reorder-grid'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacings.xl,
            vertical: AppSpacings.xl,
          ),
          crossAxisCount: crossAxisCount,
          // Preserve the headline/date space while adding a 48px move control.
          childAspectRatio: cardWidth / (cardWidth / baseAspectRatio + 52),
          mainAxisSpacing: AppSpacings.xl,
          crossAxisSpacing: AppSpacings.l,
          onReorder: (oldIndex, newIndex) {
            move(oldIndex, newIndex);
          },
          children: [
            for (final (index, note) in notes.indexed)
              NoteReorderCard(
                  key: ValueKey(note.id),
                  note: note,
                  showReorderControls: true,
                  onMoveEarlier: index > (note.isPinned ? 0 : pinnedCount)
                      ? () => move(index, index - 1)
                      : null,
                  onMoveLater: index <
                          (note.isPinned ? pinnedCount - 1 : notes.length - 1)
                      ? () => move(index, index + 1)
                      : null),
          ],
        ),
      ),
    ]);
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = noteGridColumns(
        width: constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
        preferredColumns: AppLayoutSettings.instance.cardSize.columns,
        appFontScale: AppTypographySettings.instance.scale,
      );
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
    });
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
    required this.showArchive,
    required this.archiveCount,
    this.selectedViewName,
    required this.trashCount,
    required this.folderCounts,
    required this.allNotesCount,
  });

  final List<Folder> folders;
  final String? selectedFolderId;
  final bool showTrash;
  final bool showArchive;
  final int archiveCount;
  final String? selectedViewName;
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

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 56) return const SizedBox.shrink();
      final compact = constraints.maxWidth < 120;
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
                horizontal: compact ? tokens.space1 : tokens.space2,
                vertical: tokens.space1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!compact) ...[
                    Icon(icon,
                        size: 20, color: context.colors.onSurfaceVariant),
                    SizedBox(width: tokens.space2),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleLarge,
                    ),
                  ),
                  if (!compact)
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
    });
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

class _SelectArchive extends _FolderPickerResult {
  const _SelectArchive();
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
            selected: !scope.showTrash &&
                !scope.showArchive &&
                scope.selectedFolderId == null,
            onTap: () => Navigator.pop(context, const _SelectAll()),
          ),
          for (final folder in scope.folders)
            _PickerTile(
              icon: Icons.folder_rounded,
              label: folder.name,
              count: scope.folderCounts[folder.id] ?? 0,
              selected: !scope.showTrash &&
                  !scope.showArchive &&
                  scope.selectedFolderId == folder.id,
              onTap: () => Navigator.pop(context, _SelectFolder(folder.id)),
              onRename: () => Navigator.pop(context, _RenameFolder(folder)),
              onDelete: () => Navigator.pop(context, _DeleteFolder(folder)),
            ),
          _PickerTile(
            icon: Icons.archive_outlined,
            label: l10n.Archive,
            count: scope.archiveCount,
            selected: scope.showArchive,
            onTap: () => Navigator.pop(context, const _SelectArchive()),
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
