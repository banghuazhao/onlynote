import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:onlynote/services/document_scan_capture.dart';
import 'package:onlynote/services/note_autosave.dart';

class _UnusedRepository extends Fake implements NoteRepository {}

class _Store implements NoteAutosaveStore {
  final saved = <Note>[];
  bool fail = false;
  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async {
    if (fail) throw StateError('Storage unavailable');
    saved.add(note);
  }
}

class _Capture extends DocumentScanCapture {
  _Capture(this.store);
  final _Store store;
  Future<DocumentScanCaptureResult> Function()? action;
  DocumentScanCaptureResult next =
      const DocumentScanCaptureResult(status: DocumentScanStatus.cancelled);
  DocumentScanCaptureResult retried =
      const DocumentScanCaptureResult(status: DocumentScanStatus.pages);
  final paths = <String>[];
  final discarded = <String>[];
  int launched = 0;
  int retries = 0;
  int acknowledged = 0;
  bool retryPending = false;
  bool journaled = false;
  bool released = false;
  @override
  bool get canRetry => retryPending;
  @override
  bool get isJournaled => journaled;
  @override
  Future<DocumentScanCaptureResult> scan(Note note) async {
    launched++;
    final result = action == null ? next : await action!();
    paths.addAll(result.savedPaths);
    journaled = paths.isNotEmpty || retryPending;
    return result;
  }

  @override
  Future<DocumentScanCaptureResult> retry() async {
    retries++;
    retryPending = false;
    paths.addAll(retried.savedPaths);
    return retried;
  }

  @override
  Future<void> discardPage(String path) async => discarded.add(path);
  @override
  Future<void> complete() async {
    if (!journaled) return;
    expect(retryPending, isFalse);
    expect(store.saved.last.imagePaths,
        containsAll(paths.where((path) => !discarded.contains(path))));
    expect(
        store.saved.last.imageLayouts
            .where((layout) => paths.contains(layout.path))
            .every((layout) => layout.isDocumentPage),
        isTrue);
    acknowledged++;
    journaled = false;
  }

  @override
  void release() {
    released = true;
  }
}

class _Router extends RootStackRouter {
  _Router(this.store, this.capture);
  final _Store store;
  final _Capture capture;
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo(HomeRoute.name,
                builder: (_) => const Scaffold(body: Text('Library')))),
        AutoRoute(
            page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
          final args = data.argsAs<AddUpdateNoteRouteArgs>();
          return AddUpdateNoteScreen(
              note: args.note,
              autosaveStore: store,
              documentScanCapture: capture);
        })),
      ];
}

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
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  Future<(_Store, _Capture, _Router)> open(WidgetTester tester,
      {Note? note,
      Locale locale = const Locale('en'),
      double textScale = 1}) async {
    final store = _Store();
    final capture = _Capture(store);
    final repository = _UnusedRepository();
    final bloc = AddUpdateBloc(
        AddNoteUsecase(repository), UpdateNoteUsecase(repository));
    final router = _Router(store, capture);
    addTearDown(() async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await bloc.close();
    });
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp.router(
        routerConfig: router.config(),
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(textScale)),
            child: child!),
      ),
    ));
    await tester.pumpAndSettle();
    router.push(AddUpdateNoteRoute(note: note));
    await tester.pumpAndSettle();
    return (store, capture, router);
  }

  Future<void> scan(WidgetTester tester, {bool settle = true}) async {
    final add = find.byKey(const ValueKey('editor-add-photo'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Document_Scan));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('reviewed pages are saved in order before acknowledgement',
      (tester) async {
    final (store, capture, _) = await open(tester,
        note: Note(
            id: 'note',
            title: 'Receipts',
            description: 'Keep this text',
            tags: const ['Work'],
            todo: [Todo(id: 'task', title: 'Keep task')]));
    capture.next = const DocumentScanCaptureResult(
        status: DocumentScanStatus.pages,
        savedPaths: ['note_images/page2.jpg', 'note_images/page1.jpg']);
    await scan(tester);
    expect(capture.launched, 1);
    expect(capture.acknowledged, 1);
    expect(store.saved.last.imagePaths,
        ['note_images/page2.jpg', 'note_images/page1.jpg']);
    expect(store.saved.last.description, 'Keep this text');
    expect(store.saved.last.todo.single.title, 'Keep task');
    expect(store.saved.last.tags, ['Work']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling a scan leaves a new note empty and usable',
      (tester) async {
    final (store, capture, _) = await open(tester);
    await scan(tester);
    expect(capture.launched, 1);
    expect(capture.acknowledged, 0);
    expect(store.saved, isEmpty);
    expect(find.text(S.current.Document_Scan_Failed), findsNothing);
    final add = tester
        .widget<TextButton>(find.byKey(const ValueKey('editor-add-photo')));
    expect(add.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'partial saving retries remaining pages without opening another scan',
      (tester) async {
    final (store, capture, _) = await open(tester);
    capture.retryPending = true;
    capture.next = DocumentScanCaptureResult(
        status: DocumentScanStatus.failed,
        savedPaths: const ['note_images/page0.jpg'],
        error: StateError('Copy failed'));
    capture.retried = const DocumentScanCaptureResult(
        status: DocumentScanStatus.pages,
        savedPaths: ['note_images/page1.jpg']);
    await scan(tester);
    expect(store.saved.last.imagePaths, ['note_images/page0.jpg']);
    expect(capture.acknowledged, 0);
    await tester.tap(find.text(S.current.Retry));
    await tester.pumpAndSettle();
    expect(capture.launched, 1);
    expect(capture.retries, 1);
    expect(capture.acknowledged, 1);
    expect(store.saved.last.imagePaths,
        ['note_images/page0.jpg', 'note_images/page1.jpg']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing a partial scan page records the choice before retry',
      (tester) async {
    final (store, capture, _) =
        await open(tester, note: Note(id: 'scan', title: 'Receipts'));
    capture.retryPending = true;
    capture.next = DocumentScanCaptureResult(
        status: DocumentScanStatus.failed,
        savedPaths: const ['note_images/page0.jpg'],
        error: StateError('Copy failed'));
    capture.retried = const DocumentScanCaptureResult(
        status: DocumentScanStatus.pages,
        savedPaths: ['note_images/page1.jpg']);
    await scan(tester);
    final select =
        find.byKey(const ValueKey('image-select-note_images/page0.jpg'));
    await tester.ensureVisible(select);
    await tester.pumpAndSettle();
    // A full-width document page is taller than this test viewport. Tap its
    // visible portion instead of its offscreen geometric center.
    final visibleImage = tester.getRect(select).intersect(tester.getRect(
        find.ancestor(of: select, matching: find.byType(ListView)).first));
    await tester.tapAt(visibleImage.center);
    await tester.pumpAndSettle();
    final remove =
        find.byKey(const ValueKey('image-remove-note_images/page0.jpg'));
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(capture.discarded, ['note_images/page0.jpg']);
    await tester.tap(find.text(S.current.Done));
    await tester.pumpAndSettle();
    expect(capture.retries, 1);
    expect(capture.acknowledged, 1);
    expect(store.saved.last.imagePaths, ['note_images/page1.jpg']);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('failed autosave retains pages until Done retries saving',
      (tester) async {
    final (store, capture, router) = await open(tester);
    store.fail = true;
    capture.next = const DocumentScanCaptureResult(
        status: DocumentScanStatus.pages,
        savedPaths: ['note_images/page0.jpg']);
    await scan(tester);
    expect(capture.acknowledged, 0);
    expect(capture.journaled, isTrue);
    expect(find.text(S.current.Autosave_Failed), findsOneWidget);
    store.fail = false;
    await tester.tap(find.text(S.current.Done));
    await tester.pumpAndSettle();
    expect(capture.acknowledged, 1);
    expect(store.saved.last.imagePaths, ['note_images/page0.jpg']);
    expect(router.current.name, HomeRoute.name);
    expect(capture.released, isTrue);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('native scanning disables other capture actions and leaving',
      (tester) async {
    final (_, capture, router) = await open(tester);
    final native = Completer<DocumentScanCaptureResult>();
    capture.action = () => native.future;
    await scan(tester, settle: false);
    expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('editor-add-photo')))
            .onPressed,
        isNull);
    await tester.tap(find.text(S.current.Done));
    await tester.pump();
    expect(router.current.name, AddUpdateNoteRoute.name);
    native.complete(
        const DocumentScanCaptureResult(status: DocumentScanStatus.cancelled));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('editor-add-photo')))
            .onPressed,
        isNotNull);
  });

  testWidgets('Chinese scanner discovery fits narrow screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, locale: const Locale('zh'), textScale: 1.5);
    final add = find.byKey(const ValueKey('editor-add-photo'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text(S.current.Document_Scan), findsOneWidget);
    expect(find.text(S.current.Choose_From_Gallery), findsOneWidget);
    expect(find.text(S.current.Take_Photo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
