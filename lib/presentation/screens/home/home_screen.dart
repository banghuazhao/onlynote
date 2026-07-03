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

import 'bloc/home_bloc.dart';
import 'bloc/multiple_delete/multiple_delete_bloc.dart';
import 'more_apps_page.dart';
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
                  child: const Icon(Icons.more_horiz),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => MoreAppsPage(),
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
  void viewWillAppear() {
    print("onResume / viewWillAppear / onFocusGained");
    if (mounted) {
      setState(() {});
    }
  }

  void viewWillDisappear() {
    print("onPause / viewWillDisappear / onFocusLost");
  }

  @override
  Widget build(BuildContext context) {
    final multipleDeleteBloc = context.read<MultipleDeleteBloc>();

    double width = MediaQuery.of(context).size.width;

    return FocusDetector(
      onFocusGained: viewWillAppear,
      onFocusLost: viewWillDisappear,
      child: MasonryGridView.count(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacings.xl,
          vertical: AppSpacings.xl,
        ),
        crossAxisCount: width > 600 ? 3 : 2,
        itemCount: widget.notes.length,
        itemBuilder: (BuildContext context, int index) {
          final noteId = widget.notes[index].id!;
          return FadeInUp(
            duration: Duration(milliseconds: 100 * index),
            child: NoteCard(
              note: widget.notes[index],
              selected: multipleDeleteBloc.isSelected(noteId),
              onTap: () {
                multipleDeleteBloc.state.maybeMap(
                  orElse: () {
                    // var route = NoteDetailRoute(noteId: noteId);
                    // context.router.push(route);
                    // context.router.pop(route);
                    context.router.push(NoteDetailRoute(noteId: noteId));
                  },
                  selected: (_) {
                    multipleDeleteBloc.add(MultipleDeleteEvent.toggleSelect(noteId));
                  },
                );
              },
              onSelect: () {
                multipleDeleteBloc.add(MultipleDeleteEvent.toggleSelect(noteId));
              },
            ),
          );
        },
        mainAxisSpacing: AppSpacings.xl,
        crossAxisSpacing: AppSpacings.l,
      ),
    );
  }
}
