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
import 'package:onlynote/domain/database/database.dart';
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
          // Releases an ad resource when it fails to load
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

  @override
  void dispose() {
    PurchaseService.instance.removeListener(_entitlementChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        actions: _isReorderMode
            ? [
                AppButton(
                  tooltip: S.of(context).Done,
                  child: Text(S.of(context).Done),
                  onPressed: () => _setReorderMode(false),
                ),
              ]
            : context.watch<MultipleDeleteBloc>().state.mapOrNull(
                  initial: (selectedNotes) => [
                    AppButton(
                      tooltip: S.of(context).notes,
                      child: const Icon(Icons.add),
                      onPressed: () {
                        context.router.push(AddUpdateNoteRoute());
                      },
                    ),
                  ],
                  selected: (selectedNotes) => [
                    AppButton(
                      tooltip: S.of(context).Delete,
                      child: Row(
                        children: [
                          Text(
                            '${S.of(context).Delete} - ${selectedNotes.selectedIds.length}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(width: AppSpacings.xl),
                          const Icon(Icons.delete_outline),
                        ],
                      ),
                      onPressed: () {
                        context
                            .read<MultipleDeleteBloc>()
                            .add(const MultipleDeleteEvent.delete());
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
                  ],
                  success: (selectedNotes) => [
                    AppButton(
                      tooltip: S.of(context).notes,
                      child: const Icon(Icons.add),
                      onPressed: () {
                        context.router.push(AddUpdateNoteRoute());
                      },
                    ),
                  ],
                  failed: (selectedNotes) => [
                    AppButton(
                      tooltip: S.of(context).notes,
                      child: const Icon(Icons.add),
                      onPressed: () {
                        context.router.push(AddUpdateNoteRoute());
                      },
                    ),
                  ],
                ),
      ),

      //* Show available notes list
      body: SafeArea(
        child: Column(children: [
          Expanded(
              child: ValueListenableBuilder(
            valueListenable: getIt<Database>().box.listenable(),
            builder: (context, _, child) {
              context.read<HomeBloc>().add(const HomeEvent.getAllNotes());
              return child!;
            },
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (_, state) {
                return state.maybeMap(
                  orElse: () => const _LoadingSkeleton(),
                  error: (error) => _HomeError(message: error.message ?? ''),
                  loaded: (data) => data.notes.isEmpty
                      ? _EmptyNotes(
                          onAdd: () =>
                              context.router.push(AddUpdateNoteRoute()))
                      : _BuildNotesList(
                          notes: data.notes,
                          isReorderMode: _isReorderMode,
                          onEnterReorderMode: () => _setReorderMode(true),
                        ),
                );
              },
            ),
          )),
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
        ]),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
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
            Text(S.of(context).No_notes_found,
                textAlign: TextAlign.center,
                style: context.textStyles.titleLarge),
            SizedBox(height: context.tokens.space4),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(S.of(context).notes),
            ),
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
    required this.isReorderMode,
    required this.onEnterReorderMode,
  });

  final List<Note> notes;
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

  void viewWillAppear() {
    debugPrint("onResume / viewWillAppear / onFocusGained");
    if (mounted) {
      setState(() {});
    }
  }

  void viewWillDisappear() {
    debugPrint("onPause / viewWillDisappear / onFocusLost");
  }

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

  void _showNoteContextMenu(
    BuildContext context,
    Note note,
    MultipleDeleteBloc multipleDeleteBloc,
    String noteId,
  ) {
    final screenshotController = _screenshotControllerFor(noteId);
    final cardKey = _cardKeyFor(noteId);

    showAdaptiveActionSheet(
      context: context,
      androidBorderRadius: 30,
      actions: <BottomSheetAction>[
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
          onFocusGained: viewWillAppear,
          onFocusLost: viewWillDisappear,
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
                '${widget.isReorderMode}:${widget.notes.map((note) => note.id).join(',')}',
              ),
              child: widget.isReorderMode
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

/// A stripped-down note preview used only while dragging to reorder.
///
/// Unlike [NoteCard], this has a small, fixed amount of content (title/
/// description headline + date) so it can safely sit in a uniform-height
/// grid cell without risking a RenderFlex overflow — full note content
/// (todos, images, reminders) can vary a lot in height, which is exactly
/// what the normal masonry layout is built to absorb.
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

/// A shimmering placeholder grid shown while the first page of notes loads,
/// so the app never flashes a bare "Loading.." label.
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
