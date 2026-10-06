import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_photo_capture.dart';

class _UnusedRepository implements NoteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Editor should persist through its autosave store');
}

class _PhotoStore implements NoteAutosaveStore {
  final saved = <Note>[];
  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async => saved.add(note);
}

class _PhotoRouter extends RootStackRouter {
  _PhotoRouter(this.store, this.capture);
  final _PhotoStore store;
  final NotePhotoCapture capture;
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo(HomeRoute.name,
              builder: (_) => const Scaffold(body: Text('Library'))),
        ),
        AutoRoute(
          page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
            final args = data.argsAs<AddUpdateNoteRouteArgs>();
            return AddUpdateNoteScreen(
              start: args.start,
              autosaveStore: store,
              photoCapture: capture,
            );
          }),
        ),
      ];
}

Finder _bodyField() => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.maxLines == 100);

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUp(() {
    for (final family in originalFonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
          );
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  Future<_PhotoRouter> openPhoto(
      WidgetTester tester, _PhotoStore store, NotePhotoCapture capture) async {
    // The editor autosaves independently; AddUpdateBloc is only needed for
    // its form constructor and receives no explicit persistence events here.
    final repository = _UnusedRepository();
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
    final router = _PhotoRouter(store, capture);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await bloc.close();
    });
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp.router(
        routerConfig: router.config(),
        theme: AppTheme.light,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    router.push(AddUpdateNoteRoute(start: NoteEditorStart.photo));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('canceled camera keeps a usable editor and saves no blank note',
      (tester) async {
    final store = _PhotoStore();
    var picks = 0;
    final router = await openPhoto(
      tester,
      store,
      NotePhotoCapture(pick: (source) async {
        expect(source, ImageSource.camera);
        picks++;
        return null;
      }),
    );
    expect(picks, 1);
    expect(store.saved, isEmpty);
    expect(find.byKey(const ValueKey('editor-add-photo')), findsOneWidget);
    await tester.enterText(_bodyField(), 'Camera canceled; keep this note');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved.last.description, 'Camera canceled; keep this note');
    expect(picks, 1);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(router.current.name, HomeRoute.name);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'successful photo capture autosaves once without reopening camera',
      (tester) async {
    final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('onlynote-photo-test-'));
    final photo = File('${directory!.path}/photo.png');
    await tester.runAsync(() => photo.writeAsBytes(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=')));
    addTearDown(() => directory.delete(recursive: true));
    final store = _PhotoStore();
    var picks = 0;
    await openPhoto(
      tester,
      store,
      NotePhotoCapture(
        pick: (_) async {
          picks++;
          return XFile(photo.path);
        },
        save: (_) async => photo.path,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved.last.imagePaths, [photo.path]);
    await tester.enterText(_bodyField(), 'A caption');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved.last.description, 'A caption');
    expect(store.saved.last.imagePaths, [photo.path]);
    expect(picks, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo copy failure keeps draft and Retry uses the same capture',
      (tester) async {
    final store = _PhotoStore();
    var picks = 0;
    var writes = 0;
    await openPhoto(
      tester,
      store,
      NotePhotoCapture(
        pick: (_) async {
          picks++;
          return XFile('/tmp/camera-selected.png');
        },
        save: (_) async {
          if (++writes == 1) throw StateError('Disk temporarily unavailable');
          return 'note_images/retried.png';
        },
      ),
    );
    expect(store.saved, isEmpty);
    expect(find.text('Retry'), findsOneWidget);
    await tester.enterText(_bodyField(), 'Keep this draft while retrying');
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(picks, 1);
    expect(writes, 2);
    expect(store.saved.last.description, 'Keep this draft while retrying');
    expect(store.saved.last.imagePaths, ['note_images/retried.png']);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'partial gallery import saves completed photos and retries the rest',
      (tester) async {
    final store = _PhotoStore();
    var galleryPicks = 0;
    final copies = <String, int>{};
    await openPhoto(
      tester,
      store,
      NotePhotoCapture(
        pick: (_) async => null,
        pickMany: () async {
          galleryPicks++;
          return [XFile('/tmp/first.png'), XFile('/tmp/second.png')];
        },
        save: (source) async {
          copies.update(source.path, (count) => count + 1, ifAbsent: () => 1);
          if (source.path == '/tmp/second.png' && copies[source.path] == 1) {
            throw StateError('Disk temporarily unavailable');
          }
          return 'note_images/${source.uri.pathSegments.last}';
        },
      ),
    );
    await tester.tap(find.byKey(const ValueKey('editor-add-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Choose_From_Gallery));
    await tester.pumpAndSettle();
    expect(store.saved.last.imagePaths, ['note_images/first.png']);
    expect(find.text('Retry'), findsOneWidget);
    await tester.enterText(_bodyField(), 'Caption while importing');
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.saved.last.imagePaths,
        ['note_images/first.png', 'note_images/second.png']);
    expect(store.saved.last.description, 'Caption while importing');
    expect(galleryPicks, 1);
    expect(copies, {'/tmp/first.png': 1, '/tmp/second.png': 2});
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
