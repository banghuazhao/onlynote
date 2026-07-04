import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:animate_do/animate_do.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/ads_manager.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/share_helper.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:screenshot/screenshot.dart';

import '../settings/settings_screen.dart';
import 'bloc/home_bloc.dart';
import 'bloc/multiple_delete/multiple_delete_bloc.dart';
import 'widgets/note_card.dart';

@RoutePage(name: 'HomeRoute')
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _ad;

  bool _isAdLoaded = false;

  @override
  initState() {
    super.initState();

    _ad = BannerAd(
      adUnitId: AdsManager.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Releases an ad resource when it fails to load
          ad.dispose();

          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );

    _ad?.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NoteAppBar(
        systemUiOverlayStyle: SystemUiOverlayStyle.dark,
        autoImplementLeading: false,
        title: S.of(context).notes,
        actions: context.watch<MultipleDeleteBloc>().state.mapOrNull(
              initial: (selectedNotes) => [
                AppButton(
                  child: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                AppButton(
                  child: const Icon(Icons.add),
                  onPressed: () {
                    context.router.push(AddUpdateNoteRoute());
                  },
                ),
              ],
              selected: (selectedNotes) => [
                AppButton(
                  child: Row(
                    children: [
                      Text(
                        S.of(context).Delete + ' - ${selectedNotes.selectedIds.length}',
                        style: AppTypography.headline6.copyWith(color: AppColors.white),
                      ),
                      const SizedBox(width: AppSpacings.xl),
                      const Icon(Icons.delete_outline),
                    ],
                  ),
                  onPressed: () {
                    context.read<MultipleDeleteBloc>().add(const MultipleDeleteEvent.delete());
                  },
                ),
                AppButton(
                  child: const Icon(Icons.close),
                  onPressed: () {
                    context.read<MultipleDeleteBloc>().add(const MultipleDeleteEvent.clearAll());
                  },
                ),
              ],
              success: (selectedNotes) => [
                AppButton(
                  child: const Icon(Icons.add),
                  onPressed: () {
                    context.router.push(AddUpdateNoteRoute());
                  },
                ),
              ],
              failed: (selectedNotes) => [
                AppButton(
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
        child: Stack(children: [
          ValueListenableBuilder(
            valueListenable: getIt<Database>().box.listenable(),
            builder: (context, _, child) {
              context.read<HomeBloc>().add(const HomeEvent.getAllNotes());
              return child!;
            },
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (_, state) {
                return state.maybeMap(
                  orElse: () => const ErrorText('Loading..'),
                  error: (error) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          child: Image.asset("assets/empty.png"),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ErrorText(error.message ?? ''),
                        const SizedBox(
                          height: 80,
                        ),
                      ],
                    );
                  },
                  loaded: (data) => _BuildNotesList(notes: data.notes),
                );
              },
            ),
          ),
          if (_isAdLoaded)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: AdWidget(ad: _ad!),
                height: 50.0,
              ),
            ),
        ]),
      ),
    );
  }
}

class _BuildNotesList extends StatefulWidget {
  const _BuildNotesList({
    Key? key,
    required this.notes,
  }) : super(key: key);

  final List<Note> notes;

  @override
  __BuildNotesListState createState() => __BuildNotesListState();
}

class __BuildNotesListState extends State<_BuildNotesList> {
  final Map<String, ScreenshotController> _screenshotControllers = {};
  final Map<String, GlobalKey> _cardKeys = {};

  ScreenshotController _screenshotControllerFor(String noteId) =>
      _screenshotControllers.putIfAbsent(noteId, () => ScreenshotController());

  GlobalKey _cardKeyFor(String noteId) => _cardKeys.putIfAbsent(noteId, () => GlobalKey());

  void viewWillAppear() {
    print("onResume / viewWillAppear / onFocusGained");
    if (mounted) {
      setState(() {});
    }
  }

  void viewWillDisappear() {
    print("onPause / viewWillDisappear / onFocusLost");
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
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: Text(S.of(context).Delete, style: const TextStyle(color: Colors.red)),
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

    double width = MediaQuery.of(context).size.width;
    final baseColumns = AppLayoutSettings.instance.cardSize.columns;
    final crossAxisCount = width > 600 ? baseColumns + 1 : baseColumns;

    return FocusDetector(
      onFocusGained: viewWillAppear,
      onFocusLost: viewWillDisappear,
      child: MasonryGridView.count(
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
                screenshotController: _screenshotControllerFor(noteId),
                onTap: () {
                  multipleDeleteBloc.state.maybeMap(
                    orElse: () {
                      context.router.push(NoteDetailRoute(noteId: noteId));
                    },
                    selected: (_) {
                      multipleDeleteBloc.add(MultipleDeleteEvent.toggleSelect(noteId));
                    },
                  );
                },
                onLongPress: () {
                  multipleDeleteBloc.state.maybeMap(
                    orElse: () => _showNoteContextMenu(context, note, multipleDeleteBloc, noteId),
                    selected: (_) {
                      multipleDeleteBloc.add(MultipleDeleteEvent.toggleSelect(noteId));
                    },
                  );
                },
              ),
            ),
          );
        },
        mainAxisSpacing: AppSpacings.xl,
        crossAxisSpacing: AppSpacings.l,
      ),
    );
  }
}
