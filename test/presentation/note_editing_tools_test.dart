import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_body_editor.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/document_scan_capture.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_edit_history.dart';

class _Notes implements NoteRepository {
  final values = <String, NoteDto>{};
  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => values[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async => values[note.id!] = note;
  @override
  Future<void> deleteNote(String id) async => values.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      values.remove(id);
    }
  }
}

class _Store implements NoteAutosaveStore {
  _Store(this.notes);
  final _Notes notes;
  final saved = <Note>[];
  final drafts = <String, NoteDto>{};
  @override
  Future<void> writeDraft(Note note) async =>
      drafts[note.id!] = NoteDto.fromNote(note);
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) async {
    saved.add(note);
    await notes.addUpdateNote(NoteDto.fromNote(note));
  }
}

/// Actual scan-journal durability is covered in document_scan_capture_test.
/// This facade verifies that editor undo/redo updates page-removal intent.
class _Capture extends DocumentScanCapture {
  _Capture(Iterable<String> pages) : copiedPages = pages.toSet();
  final Set<String> copiedPages;
  final discarded = <String>{};
  final reconciled = <List<String>>[];
  bool failReconcile = false;
  @override
  bool get canRetry => false;
  @override
  bool get isJournaled => copiedPages.isNotEmpty;
  @override
  Future<void> discardPage(String path) async {
    if (copiedPages.contains(path)) discarded.add(path);
  }

  @override
  Future<void> reconcilePages(Iterable<String> presentPaths) async {
    if (failReconcile) throw StateError('Journal storage unavailable');
    final present = presentPaths.toList();
    reconciled.add(present);
    discarded
      ..clear()
      ..addAll(copiedPages.where((path) => !present.contains(path)));
  }

  @override
  Future<void> complete() async {}
  @override
  void release() {}
}

class _Router extends RootStackRouter {
  _Router(this.store);
  final _Store store;
  final captures = <_Capture>[];
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo(HomeRoute.name,
                builder: (_) => const Scaffold(body: Text('Library')))),
        AutoRoute(
            page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
          final args = data.argsAs<AddUpdateNoteRouteArgs>();
          final capture = _Capture([
            for (final layout
                in args.note?.imageLayouts ?? const <NoteImageLayout>[])
              if (layout.isDocumentPage) layout.path,
          ]);
          captures.add(capture);
          return AddUpdateNoteScreen(
              note: args.note,
              autosaveStore: store,
              documentScanCapture: capture);
        })),
      ];
}

class _Editor {
  _Editor(this.store, this.router, this.boundary);
  final _Store store;
  final _Router router;
  final GlobalKey boundary;
  Note latest(String id) => store.notes.values[id]!.toDomain();
  _Capture get capture => router.captures.last;
}

Finder _body() => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.maxLines == 100);
Finder _undo() => find.byKey(const ValueKey('note-undo'));
Finder _redo() => find.byKey(const ValueKey('note-redo'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> _shortcut(WidgetTester tester,
    {bool meta = false, bool redo = false}) async {
  final modifier =
      meta ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft;
  await tester.sendKeyDownEvent(modifier);
  if (redo) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  try {
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
  } finally {
    if (redo) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(modifier);
  }
  await tester.pumpAndSettle();
}

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    final text = FontLoader('Roboto')
      ..addFont(File('assets/fonts/Roboto-Regular.ttf')
          .readAsBytes()
          .then(ByteData.sublistView))
      ..addFont(File('assets/fonts/Roboto-Bold.ttf')
          .readAsBytes()
          .then(ByteData.sublistView));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await text.load();
    await icons.load();
  });
  setUp(() {
    for (final family in originalFonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              fontFamily:
                  const bool.fromEnvironment('CAPTURE_UI') ? 'Roboto' : null,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  Future<_Editor> open(WidgetTester tester,
      {required Note note,
      Locale locale = const Locale('en'),
      double textScale = 1}) async {
    final notes = _Notes();
    notes.values[note.id!] = NoteDto.fromNote(note);
    getIt.pushNewScope();
    getIt.registerSingleton<NoteRepository>(notes);
    final store = _Store(notes);
    final bloc = AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
    final router = _Router(store);
    final boundary = GlobalKey();
    addTearDown(() async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      router.dispose();
      await bloc.close();
      await getIt.popScope();
    });
    await tester.pumpWidget(RepaintBoundary(
        key: boundary,
        child: BlocProvider.value(
          value: bloc,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router.config(),
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: S.delegate.supportedLocales,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(textScale)),
                child: child!),
          ),
        )));
    await tester.pumpAndSettle();
    router.push(AddUpdateNoteRoute(note: note));
    await tester.pumpAndSettle();
    return _Editor(store, router, boundary);
  }

  testWidgets('selected highlight autosaves undo redo and reopened note styles',
      (tester) async {
    final editor = await open(tester,
        note: Note(id: 'mark', title: 'Tea', description: 'Remember tea'));
    await _tap(tester, _body());
    final field = tester.widget<TextField>(_body());
    const selection = TextSelection(baseOffset: 9, extentOffset: 12);
    field.controller!.selection = selection;
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('format-highlight')));
    await _save(tester);
    const marker = NoteTextStyleRange(
        start: 9, end: 12, kind: NoteTextStyleKind.highlight);
    expect(editor.latest('mark').textStyles, [marker]);
    expect(field.controller!.selection, selection);
    expect(field.focusNode!.hasFocus, isTrue);

    await _tap(tester, _undo());
    expect(editor.latest('mark').textStyles, isEmpty);
    expect(editor.latest('mark').description, 'Remember tea');
    await _tap(tester, _redo());
    expect(editor.latest('mark').textStyles, [marker]);
    expect(editor.latest('mark').description, 'Remember tea');

    await _tap(tester, find.text(S.current.Done));
    expect(editor.router.current.name, HomeRoute.name);
    editor.router.push(AddUpdateNoteRoute(note: editor.latest('mark')));
    await tester.pumpAndSettle();
    final reopened = tester.widget<NoteBodyEditor>(find.byType(NoteBodyEditor));
    expect(reopened.controller.styles, [marker]);
    expect(reopened.controller.text, 'Remember tea');
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'continuous body typing is one undo step and preserves formatting',
      (tester) async {
    const mark =
        NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.highlight);
    final editor = await open(tester,
        note: Note(
            id: 'body',
            title: 'Thoughts',
            description: 'Keep',
            textStyles: const [mark]));
    await _tap(tester, _body());
    final field = tester.widget<TextField>(_body());
    field.controller!.selection = const TextSelection.collapsed(offset: 4);
    await tester.pump();
    for (final value in ['Keep ', 'Keep i', 'Keep it']) {
      tester.testTextInput.updateEditingValue(TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length)));
      await tester.pump();
    }
    await _save(tester);
    expect(editor.latest('body').description, 'Keep it');
    expect(editor.latest('body').textStyles, [mark]);
    await _tap(tester, _undo());
    expect(editor.latest('body').description, 'Keep');
    expect(editor.latest('body').textStyles, [mark]);
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    await _tap(tester, _redo());
    expect(editor.latest('body').description, 'Keep it');
    expect(editor.latest('body').textStyles, [mark]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('title undo and redo preserve body and library metadata',
      (tester) async {
    const marker =
        NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.highlight);
    final editor = await open(tester,
        note: Note(
            id: 'title',
            title: 'Old title',
            description: 'Body',
            textStyles: const [marker],
            tags: const ['Work'],
            isPinned: true,
            dailyNoteDateKey: '2026-10-07'));
    final title = find.byKey(const ValueKey('note-title-input'));
    await tester.enterText(title, 'New title');
    await _save(tester);
    expect(editor.latest('title').title, 'New title');
    await _tap(tester, _undo());
    expect(editor.latest('title').title, 'Old title');
    expect(editor.latest('title').description, 'Body');
    expect(editor.latest('title').textStyles, [marker]);
    expect(editor.latest('title').tags, ['Work']);
    expect(editor.latest('title').isPinned, isTrue);
    expect(editor.latest('title').dailyNoteDateKey, '2026-10-07');
    await _tap(tester, _redo());
    expect(editor.latest('title').title, 'New title');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor outline sheet jumps to a later heading without saving',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final body = 'Opening\n${'A paragraph of notes.\n' * 35}Final section\nEnd';
    final offset = body.indexOf('Final section');
    final styles = [
      const NoteTextStyleRange(
          start: 0, end: 7, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(
          start: offset, end: offset + 13, kind: NoteTextStyleKind.heading),
    ];
    final editor = await open(tester,
        note: Note(
            id: 'outline',
            title: 'Long note',
            description: body,
            textStyles: styles));
    await _tap(tester, find.byKey(const ValueKey('note-outline')));
    final entry = find.byKey(ValueKey('note-outline-entry-$offset'));
    expect(entry, findsOneWidget);
    await _tap(tester, entry);
    final field = tester.widget<TextField>(_body());
    expect(
        field.controller!.selection, TextSelection.collapsed(offset: offset));
    expect(field.focusNode!.hasFocus, isTrue);
    final editable = tester.state<EditableTextState>(
        find.descendant(of: _body(), matching: find.byType(EditableText)));
    final render = editable.renderEditable;
    final local = render.getLocalRectForCaret(TextPosition(offset: offset));
    final rect = Rect.fromPoints(render.localToGlobal(local.topLeft),
        render.localToGlobal(local.bottomRight));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(800));
    expect(editor.store.saved, isEmpty);
    expect(editor.latest('outline').description, body);
    expect(editor.latest('outline').textStyles, styles);
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checklist completion addition and deletion each undo and redo',
      (tester) async {
    final editor = await open(tester,
        note: Note(
            id: 'tasks',
            title: 'Shopping',
            todo: [Todo(id: 'tea', title: 'Tea')]));
    await _tap(tester, find.byKey(const ValueKey('todo-check-tea')));
    await _save(tester);
    expect(editor.latest('tasks').todo.single.completed, isTrue);
    await _tap(tester, _undo());
    expect(editor.latest('tasks').todo.single.completed, isFalse);
    await _tap(tester, _redo());
    expect(editor.latest('tasks').todo.single.completed, isTrue);

    await _tap(tester, find.text(S.current.Add_todo));
    await _save(tester);
    final added = editor.latest('tasks').todo.last;
    expect(editor.latest('tasks').todo.length, 2);
    await _tap(tester, _undo());
    expect(editor.latest('tasks').todo.map((todo) => todo.id), ['tea']);
    await _tap(tester, _redo());
    expect(
        editor.latest('tasks').todo.map((todo) => todo.id), ['tea', added.id]);

    final row = find.byKey(ValueKey(added.id));
    await _tap(tester,
        find.descendant(of: row, matching: find.byIcon(Icons.close_rounded)));
    await _tap(tester, find.widgetWithText(FilledButton, S.current.Delete));
    await _save(tester);
    expect(editor.latest('tasks').todo.map((todo) => todo.id), ['tea']);
    await _tap(tester, _undo());
    expect(
        editor.latest('tasks').todo.map((todo) => todo.id), ['tea', added.id]);
    expect(editor.latest('tasks').todo.first.completed, isTrue);
    await _tap(tester, _redo());
    expect(editor.latest('tasks').todo.map((todo) => todo.id), ['tea']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removed scan page undo redo retains file layout and page intent',
      (tester) async {
    final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('onlynote-edit-history-'));
    final photo = File('${directory!.path}/scan.png');
    await tester.runAsync(() => photo.writeAsBytes(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=')));
    addTearDown(() => directory.delete(recursive: true));
    final layout = NoteImageLayout(
        path: photo.path,
        textOffset: 7,
        widthFactor: .45,
        xFactor: 1,
        aspectRatio: 1,
        isDocumentPage: true);
    final editor = await open(tester,
        note: Note(
            id: 'scan',
            title: 'Receipt',
            description: 'Caption',
            imagePaths: [photo.path],
            imageLayouts: [layout]));
    await _tap(tester, find.byKey(ValueKey('image-select-${photo.path}')));
    await _tap(tester, find.byKey(ValueKey('image-remove-${photo.path}')));
    await _save(tester);
    expect(editor.latest('scan').imagePaths, isEmpty);
    expect(editor.latest('scan').imageLayouts, isEmpty);
    expect(editor.capture.discarded, {photo.path});
    expect(NoteEditHistory.heldImages, contains(photo.path));
    expect(await tester.runAsync(photo.exists), isTrue);

    await _tap(tester, _undo());
    expect(editor.latest('scan').imagePaths, [photo.path]);
    expect(editor.latest('scan').imageLayouts, [layout]);
    expect(editor.capture.reconciled.last, [photo.path]);
    expect(editor.capture.discarded, isEmpty);
    await _tap(tester, _redo());
    expect(editor.latest('scan').imagePaths, isEmpty);
    expect(editor.capture.reconciled.last, isEmpty);
    expect(editor.capture.discarded, {photo.path});
    expect(NoteEditHistory.heldImages, contains(photo.path));
    expect(await tester.runAsync(photo.exists), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one undo restores inline photo text and its rebased anchor',
      (tester) async {
    final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('onlynote-inline-history-'));
    final photo = File('${directory!.path}/inline.png');
    await tester.runAsync(() => photo.writeAsBytes(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=')));
    addTearDown(() => directory.delete(recursive: true));
    final layout = NoteImageLayout(
        path: photo.path,
        textOffset: 6,
        widthFactor: .4,
        xFactor: 0,
        aspectRatio: 1);
    final editor = await open(tester,
        note: Note(
            id: 'inline',
            title: 'Photo note',
            description: 'Intro\nAfter',
            imagePaths: [photo.path],
            imageLayouts: [layout]));
    final before = find.byKey(ValueKey('note-body-before:${photo.path}'));
    await _tap(tester, before);
    await tester.enterText(before, 'Intro edited');
    await tester.pumpAndSettle();
    await _save(tester);
    expect(editor.latest('inline').description, 'Intro edited\nAfter');
    expect(editor.latest('inline').imageLayouts,
        [layout.copyWith(textOffset: 13)]);
    await _tap(tester, _undo());
    expect(editor.latest('inline').description, 'Intro\nAfter');
    expect(editor.latest('inline').imagePaths, [photo.path]);
    expect(editor.latest('inline').imageLayouts, [layout]);
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    await _tap(tester, _redo());
    expect(editor.latest('inline').description, 'Intro edited\nAfter');
    expect(editor.latest('inline').imageLayouts,
        [layout.copyWith(textOffset: 13)]);
    expect(tester.takeException(), isNull);
  });

  for (final meta in [false, true]) {
    testWidgets(
        '${meta ? 'Cmd' : 'Ctrl'} Z reverses formatting through global history',
        (tester) async {
      final editor = await open(tester,
          note: Note(id: 'key', title: 'Keyboard', description: 'Mark me'));
      await _tap(tester, _body());
      final field = tester.widget<TextField>(_body());
      field.controller!.selection =
          const TextSelection(baseOffset: 0, extentOffset: 4);
      await tester.pump();
      await _tap(tester, find.byKey(const ValueKey('format-highlight')));
      await _save(tester);
      expect(editor.latest('key').textStyles, isNotEmpty);
      expect(field.focusNode!.hasFocus, isTrue);
      await _shortcut(tester, meta: meta);
      expect(editor.latest('key').textStyles, isEmpty);
      expect(editor.latest('key').description, 'Mark me');
      await _shortcut(tester, meta: meta, redo: true);
      expect(editor.latest('key').textStyles, [
        const NoteTextStyleRange(
            start: 0, end: 4, kind: NoteTextStyleKind.highlight),
      ]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('iOS platform undo gestures use whole note formatting history',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final states = <Map<Object?, Object?>>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.undoManager,
          (call) async {
        if (call.method == 'UndoManager.setUndoState') {
          states.add(Map<Object?, Object?>.from(call.arguments as Map));
        }
        return null;
      });
      addTearDown(() =>
          messenger.setMockMethodCallHandler(SystemChannels.undoManager, null));
      final editor = await open(tester,
          note: Note(
              id: 'ios', title: 'Platform gestures', description: 'Mark me'));
      await _tap(tester, _body());
      tester.widget<TextField>(_body()).controller!.selection =
          const TextSelection(baseOffset: 0, extentOffset: 4);
      await tester.pump();
      await _tap(tester, find.byKey(const ValueKey('format-highlight')));
      await _save(tester);
      final client = UndoManager.client;
      expect(client, isNotNull);
      expect(client!.canUndo, isTrue);
      expect(client.canRedo, isFalse);
      expect(editor.latest('ios').textStyles, isNotEmpty);
      client.handlePlatformUndo(UndoDirection.undo);
      await tester.pumpAndSettle();
      expect(editor.latest('ios').textStyles, isEmpty);
      expect(editor.latest('ios').description, 'Mark me');
      expect(client.canRedo, isTrue);
      expect(UndoManager.client, same(client));
      expect(states.any((state) => state['canRedo'] == true), isTrue);
      client.handlePlatformUndo(UndoDirection.redo);
      await tester.pumpAndSettle();
      expect(editor.latest('ios').textStyles, [
        const NoteTextStyleRange(
            start: 0, end: 4, kind: NoteTextStyleKind.highlight),
      ]);
      expect(client.canUndo, isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('failed page reconciliation keeps undo pointer and can retry',
      (tester) async {
    final editor = await open(tester,
        note: Note(
            id: 'retry', title: 'Journal failure', description: 'Mark me'));
    await _tap(tester, _body());
    tester.widget<TextField>(_body()).controller!.selection =
        const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('format-highlight')));
    await _save(tester);
    final before = editor.latest('retry');
    editor.capture.failReconcile = true;
    await _tap(tester, _undo());
    expect(editor.latest('retry'), before);
    expect(tester.widget<IconButton>(_undo()).onPressed, isNotNull);
    expect(tester.widget<IconButton>(_redo()).onPressed, isNull);
    expect(find.text(S.current.Autosave_Failed), findsOneWidget);
    editor.capture.failReconcile = false;
    await _tap(tester, _undo());
    expect(editor.latest('retry').textStyles, isEmpty);
    expect(editor.latest('retry').description, 'Mark me');
    expect(tester.widget<IconButton>(_redo()).onPressed, isNotNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing actions fit narrow Chinese notes with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester,
        locale: const Locale('zh', 'HK'),
        textScale: 2,
        note: Note(
            id: 'large',
            title: '重點',
            description: '第一節\n記住帶茶。\n第二節\n步行筆記。',
            textStyles: const [
              NoteTextStyleRange(
                  start: 0, end: 3, kind: NoteTextStyleKind.heading),
              NoteTextStyleRange(
                  start: 10, end: 13, kind: NoteTextStyleKind.heading),
            ]));
    expect(_undo(), findsOneWidget);
    expect(_redo(), findsOneWidget);
    expect(tester.getSize(_undo()).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(_redo()).width, greaterThanOrEqualTo(48));
    await _tap(tester, _body());
    final field = tester.widget<TextField>(_body());
    field.controller!.selection =
        const TextSelection(baseOffset: 4, extentOffset: 9);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('format-highlight')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor tools visual preview', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 920);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const body =
        'Summary\nA quiet walk by the water.\nPacking\nBring tea and a warm layer.';
    final packing = body.indexOf('Packing');
    final editor = await open(tester,
        note: Note(
            id: 'visual',
            title: 'Weekend notes',
            description: body,
            textStyles: [
              const NoteTextStyleRange(
                  start: 0, end: 7, kind: NoteTextStyleKind.heading),
              NoteTextStyleRange(
                  start: packing,
                  end: packing + 7,
                  kind: NoteTextStyleKind.heading),
            ]));
    await _tap(tester, _body());
    tester.widget<TextField>(_body()).controller!.selection =
        const TextSelection(baseOffset: 8, extentOffset: 32);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('format-highlight')));
    await _save(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final list = tester.state<ScrollableState>(find
        .descendant(
            of: find.byType(ListView).first, matching: find.byType(Scrollable))
        .first);
    list.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await tester.runAsync(() async {
        final image = await (editor.boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('/tmp/onlynote-note-tools-editor.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  testWidgets('undo stays disabled during native composition and resumes after',
      (tester) async {
    final editor = await open(tester,
        note: Note(id: 'ime', title: '中文', description: '茶'));
    await _tap(tester, _body());
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '茶葉',
      selection: TextSelection.collapsed(offset: 2),
      composing: TextRange(start: 1, end: 2),
    ));
    await tester.pump();
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    expect(tester.widget<IconButton>(_redo()).onPressed, isNull);
    final field = tester.widget<TextField>(_body());
    expect(
        field.controller!.value.composing, const TextRange(start: 1, end: 2));
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '茶葉', selection: TextSelection.collapsed(offset: 2)));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(_undo()).onPressed, isNotNull);
    await _tap(tester, _undo());
    expect(editor.latest('ime').description, '茶');
    expect(tester.takeException(), isNull);
  });
}
