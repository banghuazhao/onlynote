import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
import 'package:onlynote/domain/model/voice_memo.dart';
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
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_transfer.dart';
import 'package:onlynote/services/note_selection_checklist.dart';
import 'package:onlynote/services/note_position_store.dart';

class _Notes implements NoteRepository {
  final values = <String, NoteDto>{};
  Completer<void>? readGate;
  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<NoteDto> getNote(String id) async {
    final gate = readGate;
    if (gate != null) await gate.future;
    return values[id]!;
  }

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
  bool failSave = false;
  @override
  Future<void> writeDraft(Note note) async =>
      drafts[note.id!] = NoteDto.fromNote(note);
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) async {
    if (failSave) throw StateError('Save unavailable');
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
  _Router(this.store, this.positions);
  final _Store store;
  final NotePositionStore positions;
  final captures = <_Capture>[];
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo(HomeRoute.name,
                builder: (_) => const Scaffold(body: Text('Library')))),
        AutoRoute(
            page: PageInfo(NoteDetailRoute.name,
                builder: (_) => const Scaffold(body: Text('Linked reader')))),
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
              positionStore: positions,
              documentScanCapture: capture);
        })),
      ];
}

class _DeferredPositionStorage implements NotePositionStorage {
  _DeferredPositionStorage(this.memory);
  final MemoryNotePositionStorage memory;
  final ready = Completer<void>();
  @override
  Future<String?> read(String key) async {
    await ready.future;
    return memory.read(key);
  }

  @override
  Future<void> write(String key, String value) => memory.write(key, value);
  @override
  Future<void> remove(String key) => memory.remove(key);
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

Future<void> _showChecklistSelectionToolbar(
    WidgetTester tester, Finder target) async {
  final editable = tester.state<EditableTextState>(
      find.descendant(of: target, matching: find.byType(EditableText)));
  // Rebuild the native menu after the fixture replaces the selection range.
  editable.hideToolbar(false);
  expect(editable.showToolbar(), isTrue);
  await tester.pumpAndSettle();
  final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
      find.byType(AdaptiveTextSelectionToolbar));
  expect(toolbar.buttonItems!.map((item) => item.label),
      contains(S.current.Add_Selection_To_Checklist));
  final action = find.text(S.current.Add_Selection_To_Checklist);
  if (action.evaluate().isEmpty) {
    final more = find.descendant(
        of: find.byType(AdaptiveTextSelectionToolbar),
        matching: find.byIcon(Icons.more_vert));
    expect(more, findsOneWidget);
    await _tap(tester, more);
  }
  expect(action, findsOneWidget);
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
    final fallback = FontLoader('DroidSansFallback')
      ..addFont(File('assets/fonts/DroidSansFallback.ttf')
          .readAsBytes()
          .then(ByteData.sublistView));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await text.load();
    await fallback.load();
    await icons.load();
  });
  setUp(() {
    for (final family in originalFonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              fontFamily:
                  const bool.fromEnvironment('CAPTURE_UI') ? 'Roboto' : null,
              fontFamilyFallback: const bool.fromEnvironment('CAPTURE_UI')
                  ? ['DroidSansFallback']
                  : null,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  Future<_Editor> open(WidgetTester tester,
      {required Note? note,
      NotePositionStore? positions,
      List<Note> existingNotes = const [],
      Locale locale = const Locale('en'),
      double textScale = 1,
      bool dark = false}) async {
    final notes = _Notes();
    if (note != null) notes.values[note.id!] = NoteDto.fromNote(note);
    for (final existing in existingNotes) {
      notes.values[existing.id!] = NoteDto.fromNote(existing);
    }
    getIt.pushNewScope();
    getIt.registerSingleton<NoteRepository>(notes);
    final store = _Store(notes);
    final bloc = AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
    final router = _Router(store, positions ?? NotePositionStore.memory());
    final boundary = GlobalKey();
    final appTheme = dark ? AppTheme.dark : AppTheme.light;
    final theme = const bool.fromEnvironment('CAPTURE_UI')
        ? appTheme.copyWith(
            textTheme: appTheme.textTheme.apply(
                fontFamily: 'Roboto',
                fontFamilyFallback: ['DroidSansFallback']),
            primaryTextTheme: appTheme.primaryTextTheme.apply(
                fontFamily: 'Roboto',
                fontFamilyFallback: ['DroidSansFallback']))
        : appTheme;
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
            theme: theme,
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
      await _tap(tester, find.byKey(const ValueKey('note-focus-writing')));
      Future<void> capture(String path) async {
        await tester.runAsync(() async {
          final image = await (editor.boundary.currentContext!
                  .findRenderObject() as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(path).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('/tmp/onlynote-focus-writing-editor.png');
      await _tap(tester, find.byKey(const ValueKey('editor-find-note')));
      await tester.enterText(
          find.byKey(const ValueKey('note-find-query')), 'walk');
      await tester.pumpAndSettle();
      await _tap(
          tester, find.byKey(const ValueKey('note-find-replace-toggle')));
      await tester.enterText(
          find.byKey(const ValueKey('note-find-replacement')), 'stroll');
      await tester.pumpAndSettle();
      await capture('/tmp/onlynote-replace-editor.png');
      expect(tester.takeException(), isNull);
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

  testWidgets('focus writing preserves real body IME and checklist selection',
      (tester) async {
    final editor = await open(tester,
        note: Note(
            id: 'focus',
            title: '中文',
            description: '茶',
            todo: [Todo(id: 'task', title: 'Bring tea')]));
    await _tap(tester, _body());
    final field = tester.widget<TextField>(_body());
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '茶葉',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 1, end: 2)));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('note-focus-writing')));
    expect(
        tester.widget<TextField>(_body()).controller, same(field.controller));
    expect(
        field.controller!.value.composing, const TextRange(start: 1, end: 2));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(find.byKey(const ValueKey('editor-record-voice')), findsNothing);
    expect(find.byKey(const ValueKey('editor-edit-tags')), findsNothing);
    expect(find.text(S.current.Add_todo), findsNothing);
    expect(find.byKey(const ValueKey('todo-field-task')), findsOneWidget);
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '茶葉', selection: TextSelection.collapsed(offset: 2)));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('todo-field-task')));
    final todo =
        tester.widget<TextField>(find.byKey(const ValueKey('todo-field-task')));
    todo.controller!.selection =
        const TextSelection(baseOffset: 6, extentOffset: 9);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('note-focus-writing')));
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('todo-field-task')))
            .controller,
        same(todo.controller));
    expect(todo.controller!.selection,
        const TextSelection(baseOffset: 6, extentOffset: 9));
    expect(todo.focusNode!.hasFocus, isTrue);
    expect(find.byKey(const ValueKey('editor-record-voice')), findsOneWidget);
    await _tap(tester, _undo());
    expect(editor.latest('focus').description, '茶');
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final target in ['title', 'body', 'todo']) {
    testWidgets(
        'Find opens the exact $target match for editing without a history step',
        (tester) async {
      final editor = await open(tester,
          note: Note(
              id: 'jump-$target',
              title: target == 'title' ? 'Tea notes' : 'Notes',
              description: target == 'body' ? 'Bring tea today' : 'Body text',
              todo: [
                Todo(id: 'task', title: target == 'todo' ? 'Bring tea' : 'Task')
              ]));
      await _tap(tester, find.byKey(const ValueKey('editor-find-note')));
      await tester.enterText(
          find.byKey(const ValueKey('note-find-query')), 'tea');
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('note-find-edit-match')));
      expect(find.byKey(const ValueKey('note-find-query')), findsNothing);
      final input = target == 'title'
          ? find.byKey(const ValueKey('note-title-input'))
          : target == 'todo'
              ? find.byKey(const ValueKey('todo-field-task'))
              : _body();
      final field = tester.widget<TextField>(input);
      expect(
          field.controller!.selection,
          target == 'title'
              ? const TextSelection(baseOffset: 0, extentOffset: 3)
              : const TextSelection(baseOffset: 6, extentOffset: 9));
      expect(field.focusNode!.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
      await _save(tester);
      expect(editor.latest('jump-$target').description,
          target == 'body' ? 'Bring tea today' : 'Body text');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Replace all autosaves one step with styles and inline photo positions',
      (tester) async {
    final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('onlynote-replace-photo-'));
    final photo = File('${directory!.path}/inline.png');
    await tester.runAsync(() => photo.writeAsBytes(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl2H7sAAAAASUVORK5CYII=')));
    addTearDown(() => directory.delete(recursive: true));
    final layout =
        NoteImageLayout(path: photo.path, textOffset: 4, widthFactor: .65);
    const styles = [
      NoteTextStyleRange(start: 0, end: 3, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 4, end: 7, kind: NoteTextStyleKind.highlight),
    ];
    final original = Note(
        id: 'replace',
        title: 'Tea notes',
        description: 'tea\ntea after',
        todo: [Todo(id: 'task', title: 'Bring tea')],
        tags: const ['weekend'],
        linkedNoteIds: const ['other'],
        dailyNoteDateKey: '2026-10-07',
        textStyles: styles,
        imagePaths: [photo.path],
        imageLayouts: [layout]);
    final editor = await open(tester, note: original);
    await _tap(tester, find.byKey(const ValueKey('editor-find-note')));
    await tester.enterText(
        find.byKey(const ValueKey('note-find-query')), 'tea');
    await tester.pumpAndSettle();
    expect(find.text('1 / 4'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('note-find-replace-toggle')));
    await tester.enterText(
        find.byKey(const ValueKey('note-find-replacement')), 'coffee');
    await _tap(tester, find.byKey(const ValueKey('note-find-replace-all')));
    final replaced = editor.latest('replace');
    expect(replaced.title, 'coffee notes');
    expect(replaced.description, 'coffee\ncoffee after');
    expect(replaced.todo.single.title, 'Bring coffee');
    expect(replaced.textStyles, const [
      NoteTextStyleRange(start: 0, end: 6, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 7, end: 13, kind: NoteTextStyleKind.highlight),
    ]);
    expect(replaced.imageLayouts, [layout.copyWith(textOffset: 7)]);
    expect(replaced.tags, original.tags);
    expect(replaced.linkedNoteIds, original.linkedNoteIds);
    expect(replaced.dailyNoteDateKey, original.dailyNoteDateKey);
    expect(find.text(S.current.Find_No_Matches), findsOneWidget);
    await _tap(
        tester, find.widgetWithText(SnackBarAction, S.current.Note_Undo));
    final restored = editor.latest('replace');
    expect(restored.title, original.title);
    expect(restored.description, original.description);
    expect(restored.todo, original.todo);
    expect(restored.textStyles, styles);
    expect(restored.imageLayouts, [layout]);
    expect(find.byKey(const ValueKey('note-find-query')), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('note-find-close')));
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    await _tap(tester, _redo());
    expect(editor.latest('replace').description, replaced.description);
    expect(editor.latest('replace').textStyles, replaced.textStyles);
    expect(editor.latest('replace').imageLayouts, replaced.imageLayouts);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Replace supports deletion and rejects oversized titles atomically',
      (tester) async {
    final editor = await open(tester,
        note: Note(id: 'single', title: 'Notes', description: 'Tea and tea'));
    await _tap(tester, find.byKey(const ValueKey('editor-find-note')));
    await tester.enterText(
        find.byKey(const ValueKey('note-find-query')), 'tea');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('note-find-replace-toggle')));
    await _tap(tester, find.byKey(const ValueKey('note-find-replace')));
    expect(editor.latest('single').description, ' and tea');
    expect(find.text('1 / 1'), findsOneWidget);
    await _tap(
        tester, find.widgetWithText(SnackBarAction, S.current.Note_Undo));
    expect(editor.latest('single').description, 'Tea and tea');
    await tester.enterText(
        find.byKey(const ValueKey('note-find-query')), 'Notes');
    await tester.enterText(
        find.byKey(const ValueKey('note-find-replacement')), 'x' * 141);
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('note-find-replace-all')));
    expect(editor.latest('single').title, 'Notes');
    expect(editor.latest('single').description, 'Tea and tea');
    expect(find.text(S.current.Find_Replace_Limit), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('note-find-close')));
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded replace fits real 320px Chinese editor with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester,
        locale: const Locale('zh', 'HK'),
        textScale: 2,
        note: Note(id: 'replace-large', title: '散步筆記', description: '今天散步。'));
    await _tap(tester, find.byKey(const ValueKey('editor-find-note')));
    await tester.enterText(find.byKey(const ValueKey('note-find-query')), '散步');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('note-find-replace-toggle')));
    expect(find.byKey(const ValueKey('note-find-replacement')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-find-replace-all')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Find edits an offscreen completed checklist item and reveals it',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester,
        note: Note(id: 'long-checklist', title: 'Packing', todo: [
          for (var i = 0; i < 35; i++)
            Todo(id: 'task-$i', title: 'Packing item $i'),
          Todo(id: 'last', title: 'Bring tea', completed: true),
        ]));
    await _tap(tester, find.byKey(const ValueKey('editor-find-note')));
    await tester.enterText(
        find.byKey(const ValueKey('note-find-query')), 'tea');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('note-find-edit-match')));
    final target = find.byKey(const ValueKey('todo-field-last'));
    final field = tester.widget<TextField>(target);
    expect(field.controller!.selection,
        const TextSelection(baseOffset: 6, extentOffset: 9));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(
        tester.getRect(target).overlaps(const Rect.fromLTWH(0, 100, 390, 650)),
        isTrue);
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Find query keeps local keyboard undo and guards preview edit during IME',
      (tester) async {
    final editor = await open(tester,
        note: Note(id: 'find-ime', title: 'Notes', description: 'tea'));
    await _tap(tester, _body());
    await tester.enterText(_body(), 'tea today');
    await _save(tester);
    await _tap(tester, find.byKey(const ValueKey('editor-find-note')));
    final query = find.byKey(const ValueKey('note-find-query'));
    await tester.enterText(query, 'tea');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await _shortcut(tester);
    expect(tester.widget<TextField>(query).controller!.text, '');
    expect(editor.latest('find-ime').description, 'tea today');
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'tea',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('note-find-edit-match')))
            .onPressed,
        isNull);
    expect(tester.widget<TextField>(query).controller!.value.composing,
        const TextRange(start: 0, end: 3));
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'tea', selection: TextSelection.collapsed(offset: 3)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextButton>(
                find.byKey(const ValueKey('note-find-edit-match')))
            .onPressed,
        isNotNull);
    expect(editor.latest('find-ime').description, 'tea today');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'expanded replace remains reachable on a small phone with keyboard',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await open(tester,
        locale: const Locale('zh', 'HK'),
        textScale: 2,
        note: Note(id: 'keyboard-small', title: '筆記', description: '散步'));
    await _tap(tester, find.byKey(const ValueKey('editor-find-note')));
    await tester.enterText(find.byKey(const ValueKey('note-find-query')), '散步');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('note-find-replace-toggle')));
    await _tap(tester, find.byKey(const ValueKey('note-find-replacement')));
    await tester.enterText(
        find.byKey(const ValueKey('note-find-replacement')), '喝茶');
    await _tap(tester, find.byKey(const ValueKey('note-find-replace-all')));
    expect(find.text(S.current.Find_Replaced(1)), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Find edits a selected voice transcript and saves an undoable correction',
      (tester) async {
    final memo = VoiceMemo(
        id: 'memo',
        path: 'note_audio/memo.m4a',
        durationMs: 5000,
        createdAt: DateTime(2026, 10, 7),
        transcript: 'Bring tea today');
    final editor = await open(tester,
        note: Note(
            id: 'find-voice',
            title: 'Notes',
            description: 'Keep body',
            voiceMemos: [memo]));
    await _tap(tester, find.byKey(const ValueKey('editor-find-note')));
    await tester.enterText(
        find.byKey(const ValueKey('note-find-query')), 'tea');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('note-find-edit-match')));
    final input = find.byKey(const ValueKey('voice-transcript-editor-input'));
    expect(input, findsOneWidget);
    final field = tester.widget<TextField>(input);
    expect(field.controller!.selection,
        const TextSelection(baseOffset: 6, extentOffset: 9));
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(input, 'Bring coffee today');
    await _tap(tester, find.text(S.current.Voice_Save));
    expect(editor.latest('find-voice').voiceMemos.single.transcript,
        'Bring coffee today');
    expect(editor.latest('find-voice').description, 'Keep body');
    await _tap(tester, _undo());
    expect(editor.latest('find-voice').voiceMemos.single, memo);
    expect(editor.latest('find-voice').description, 'Keep body');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'native selection copies formatting to a new note without changing source',
      (tester) async {
    const highlight =
        NoteTextStyleRange(start: 5, end: 8, kind: NoteTextStyleKind.highlight);
    final editor = await open(tester,
        note: Note(
            id: 'source-copy',
            title: 'Keep',
            description: 'Keep tea',
            textStyles: [highlight]));
    await _tap(tester, _body());
    final field = tester.widget<TextField>(_body());
    field.controller!.selection =
        const TextSelection(baseOffset: 5, extentOffset: 8);
    await tester.pump();
    final editable =
        find.descendant(of: _body(), matching: find.byType(EditableText));
    tester.state<EditableTextState>(editable).showToolbar();
    await tester.pumpAndSettle();
    await _tap(tester, find.text(S.current.Copy_Selection_To_Note));
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await tester.runAsync(() async {
        final render = editor.boundary.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/onlynote-copy-note-picker.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    }
    await _tap(tester, find.byKey(const ValueKey('note-copy-new')));
    await _save(tester);
    final copies = editor.store.notes
        .getAllNotes()
        .where((note) => note.id != 'source-copy');
    final copied = copies.single.toDomain();
    expect(copied.description, 'tea');
    expect(copied.textStyles, [
      const NoteTextStyleRange(
          start: 0, end: 3, kind: NoteTextStyleKind.highlight)
    ]);
    final source = editor.latest('source-copy');
    expect(source.description, 'Keep tea');
    expect(source.textStyles, [highlight]);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'copy picker appends to latest existing note and preserves its content',
      (tester) async {
    final editor = await open(tester,
        note: Note(id: 'copy-from', description: 'Selected tea'));
    editor.store.notes.values['copy-to'] = NoteDto.fromNote(Note(
        id: 'copy-to',
        title: 'Shopping',
        description: 'Original',
        tags: ['home'],
        todo: [Todo(id: 'todo', title: 'Milk', completed: true)]));
    await _tap(tester, _body());
    final field = tester.widget<TextField>(_body());
    field.controller!.selection =
        const TextSelection(baseOffset: 9, extentOffset: 12);
    await tester.pump();
    tester
        .state<EditableTextState>(
            find.descendant(of: _body(), matching: find.byType(EditableText)))
        .showToolbar();
    await tester.pumpAndSettle();
    await _tap(tester, find.text(S.current.Copy_Selection_To_Note));
    // An update while choosing a destination must be retained.
    editor.store.notes.values['copy-to'] =
        editor.store.notes.values['copy-to']!.copyWith(description: 'Newest');
    await _tap(
        tester, find.byKey(const ValueKey('note-copy-existing-copy-to')));
    await _save(tester);
    final destination = editor.latest('copy-to');
    expect(destination.description, 'Newest\n\ntea');
    expect(destination.title, 'Shopping');
    expect(destination.tags, ['home']);
    expect(destination.todo.single.completed, isTrue);
    expect(editor.latest('copy-from').description, 'Selected tea');
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'copy into open editor merges unsaved typing with one undoable step',
      (tester) async {
    final editor =
        await open(tester, note: Note(id: 'open-copy', description: 'Saved'));
    await _tap(tester, _body());
    await tester.enterText(_body(), 'Unsaved typing');
    final transfer = NoteSelectionTransfer(
        repository: editor.store.notes,
        store: editor.store,
        readDraft: (id) => editor.store.drafts[id]?.toDomain());
    bool? saved;
    transfer
        .copyToExisting('open-copy', NoteTextSelection(text: 'Copied'))
        .then((value) => saved = value);
    for (var frame = 0; frame < 20 && saved == null; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(saved, isTrue);
    expect(editor.latest('open-copy').description, 'Unsaved typing\n\nCopied');
    expect(tester.widget<TextField>(_body()).controller!.text,
        'Unsaved typing\n\nCopied');
    await _tap(tester, _undo());
    expect(editor.latest('open-copy').description, 'Unsaved typing');
    await _tap(tester, _redo());
    expect(editor.latest('open-copy').description, 'Unsaved typing\n\nCopied');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'numbered Return before a photo preserves anchors styles and note undo',
      (tester) async {
    final directory = await tester.runAsync(
        () => Directory.systemTemp.createTemp('onlynote-numbered-photo-'));
    final photo = File('${directory!.path}/inline.png');
    await tester.runAsync(() => photo.writeAsBytes(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=')));
    addTearDown(() => directory.delete(recursive: true));
    final layout = NoteImageLayout(
        path: photo.path,
        textOffset: 7,
        widthFactor: .4,
        xFactor: 0,
        aspectRatio: 1);
    const highlight =
        NoteTextStyleRange(start: 3, end: 6, kind: NoteTextStyleKind.highlight);
    final editor = await open(tester,
        note: Note(
            id: 'numbered-photo',
            title: 'Tea',
            description: '1. Tea\nAfter',
            imagePaths: [photo.path],
            imageLayouts: [layout],
            textStyles: [highlight]));
    final before = find.byKey(ValueKey('note-body-before:${photo.path}'));
    await _tap(tester, before);
    final field = tester.widget<TextField>(before);
    field.controller!.selection = const TextSelection.collapsed(offset: 6);
    await tester.pump();
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '1. Tea\n', selection: TextSelection.collapsed(offset: 7)));
    await tester.pumpAndSettle();
    await _save(tester);
    expect(editor.latest('numbered-photo').description, '1. Tea\n2. \nAfter');
    expect(editor.latest('numbered-photo').imageLayouts,
        [layout.copyWith(textOffset: 11)]);
    expect(editor.latest('numbered-photo').textStyles, [highlight]);
    await _tap(tester, _undo());
    expect(editor.latest('numbered-photo').description, '1. Tea\nAfter');
    expect(editor.latest('numbered-photo').imageLayouts, [layout]);
    await _tap(tester, _redo());
    expect(editor.latest('numbered-photo').description, '1. Tea\n2. \nAfter');
    expect(editor.latest('numbered-photo').imageLayouts,
        [layout.copyWith(textOffset: 11)]);
    // The native inline field clips formatting into the copied passage.
    await _tap(tester, before);
    tester.widget<TextField>(before).controller!.selection =
        const TextSelection(baseOffset: 3, extentOffset: 6);
    await tester.pump();
    tester
        .state<EditableTextState>(
            find.descendant(of: before, matching: find.byType(EditableText)))
        .showToolbar();
    await tester.pumpAndSettle();
    await _tap(tester, find.text(S.current.Copy_Selection_To_Note));
    await _tap(tester, find.byKey(const ValueKey('note-copy-new')));
    await _save(tester);
    final copy = editor.store.notes
        .getAllNotes()
        .where((note) => note.id != 'numbered-photo')
        .single
        .toDomain();
    expect(copy.description, 'Tea');
    expect(copy.textStyles, [
      const NoteTextStyleRange(
          start: 0, end: 3, kind: NoteTextStyleKind.highlight)
    ]);
    expect(copy.imagePaths, isEmpty);
    expect(editor.latest('numbered-photo').imageLayouts,
        [layout.copyWith(textOffset: 11)]);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'copy into a suspended editor retains changes saved through child routes',
      (tester) async {
    final original = Note(
        id: 'hidden-copy',
        title: 'Original',
        description: 'Old body',
        tags: ['old'],
        todo: [Todo(id: 'task', title: 'Old task')],
        linkedNoteIds: ['child']);
    final child = Note(id: 'child', title: 'Child', description: 'Selected');
    final editor = await open(tester, note: original, existingNotes: [child]);
    await _tap(tester, find.byKey(const ValueKey('linked-note-child')));
    expect(find.text('Linked reader'), findsOneWidget);
    final fresh = original.copyWith(
        title: 'Child edit',
        description: 'Newest body',
        tags: ['new'],
        todo: [Todo(id: 'task', title: 'New task', completed: true)]);
    editor.store.notes.values['hidden-copy'] = NoteDto.fromNote(fresh);
    final transfer = NoteSelectionTransfer(
        repository: editor.store.notes,
        store: editor.store,
        readDraft: (id) => editor.store.drafts[id]?.toDomain());
    bool? copied;
    transfer
        .copyToExisting('hidden-copy', NoteTextSelection(text: 'Selected'))
        .then((value) => copied = value);
    for (var frame = 0; frame < 20 && copied == null; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(copied, isTrue);
    final saved = editor.latest('hidden-copy');
    expect(saved.title, 'Child edit');
    expect(saved.description, 'Newest body\n\nSelected');
    expect(saved.todo, fresh.todo);
    expect(saved.tags, fresh.tags);
    editor.router.maybePop();
    await tester.pumpAndSettle();
    await _tap(tester, _undo());
    final restored = editor.latest('hidden-copy');
    expect(restored.description, 'Newest body');
    expect(restored.title, 'Child edit');
    expect(restored.todo, fresh.todo);
    expect(restored.tags, fresh.tags);
    expect(tester.takeException(), isNull);
  });
  Future<void> addSelectedLines(
      WidgetTester tester, Finder target, TextSelection selection) async {
    await _tap(tester, target);
    tester.widget<TextField>(target).controller!.selection = selection;
    await tester.pump();
    await _showChecklistSelectionToolbar(tester, target);
    await _tap(tester, find.text(S.current.Add_Selection_To_Checklist));
    await _save(tester);
  }

  testWidgets(
      'selected lines add tasks with one undo step and preserve prose and styles',
      (tester) async {
    const body = '1. Tea\n2. Milk\n☐ Bread';
    const mark =
        NoteTextStyleRange(start: 3, end: 6, kind: NoteTextStyleKind.bold);
    final original = Note(
        id: 'lines',
        title: 'Shopping',
        description: body,
        textStyles: [mark],
        tags: ['groceries'],
        todo: [Todo(id: 'old', title: 'Bag', completed: true)]);
    final editor = await open(tester, note: original);
    await addSelectedLines(tester, _body(),
        const TextSelection(baseOffset: 0, extentOffset: body.length));
    final added = editor.latest('lines');
    expect(
        added.todo.map((item) => item.title), ['Bag', 'Tea', 'Milk', 'Bread']);
    expect(added.todo.skip(1).every((item) => !item.completed), isTrue);
    expect(added.description, body);
    expect(added.textStyles, [mark]);
    expect(added.tags, original.tags);
    await _tap(tester, _undo());
    expect(editor.latest('lines').todo, original.todo);
    expect(editor.latest('lines').description, body);
    await _tap(tester, _redo());
    expect(editor.latest('lines').todo, added.todo);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('checklist snackbar Undo keeps newer typing and can be redone',
      (tester) async {
    final editor = await open(tester,
        note: Note(id: 'line-undo', description: 'Tea\nMilk'));
    await addSelectedLines(
        tester, _body(), const TextSelection(baseOffset: 0, extentOffset: 8));
    final ids = editor.latest('line-undo').todo.map((item) => item.id).toList();
    // Keep the snackbar alive while making a newer content change.
    await tester.enterText(_body(), 'Tea\nMilk\nNewest prose');
    await tester.pump();
    await _tap(tester, find.widgetWithText(SnackBarAction, S.current.Undo));
    expect(editor.latest('line-undo').todo, isEmpty);
    expect(editor.latest('line-undo').description, 'Tea\nMilk\nNewest prose');
    await _tap(tester, _undo());
    expect(editor.latest('line-undo').todo.map((item) => item.id), ids);
    expect(editor.latest('line-undo').description, 'Tea\nMilk\nNewest prose');
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected lines create checklist in an unsaved new note',
      (tester) async {
    final editor = await open(tester, note: null);
    await tester.enterText(_body(), 'Tea\nMilk');
    await tester.pump();
    await addSelectedLines(
        tester, _body(), const TextSelection(baseOffset: 0, extentOffset: 8));
    final note = editor.store.notes.getAllNotes().single.toDomain();
    expect(note.description, 'Tea\nMilk');
    expect(note.todo.map((item) => item.title), ['Tea', 'Milk']);
    await _tap(tester, _undo());
    expect(editor.latest(note.id!).description, 'Tea\nMilk');
    expect(editor.latest(note.id!).todo, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'oversized selected line rejects entire checklist without history or save',
      (tester) async {
    final body = 'Tea\n${'x' * 101}';
    final editor =
        await open(tester, note: Note(id: 'long-line', description: body));
    await addSelectedLines(tester, _body(),
        TextSelection(baseOffset: 0, extentOffset: body.length));
    expect(find.text(S.current.Selection_Checklist_Too_Long), findsOneWidget);
    expect(editor.latest('long-line').todo, isEmpty);
    expect(editor.store.saved, isEmpty);
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor Note info uses unsaved text and creates no history entry',
      (tester) async {
    final editor = await open(tester,
        note: Note(id: 'info-draft', title: 'Title', description: 'Old'));
    await tester.enterText(_body(), 'Two words');
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('editor-more-note')));
    await _tap(tester, find.text(S.current.Note_Info));
    expect(find.byKey(const ValueKey('note-info-words-value')), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('note-info-words-value')))
            .data,
        '3');
    expect(editor.latest('info-draft').description, anyOf('Old', 'Two words'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'writing selection resumes on reopen silently without content writes',
      (tester) async {
    final positions = NotePositionStore.memory();
    final editor = await open(tester,
        positions: positions,
        note: Note(
            id: 'resume-editor',
            title: 'Thoughts',
            description: 'Tea and milk'));
    await _tap(tester, _body());
    const selection = TextSelection(baseOffset: 4, extentOffset: 7);
    tester.widget<TextField>(_body()).controller!.selection = selection;
    await tester.pump(const Duration(milliseconds: 300));
    await _tap(tester, find.text(S.current.Done));
    expect(
        (await positions.read('resume-editor'))
            .writing!
            .resolve(title: 'Thoughts', body: 'Tea and milk')
            .selection,
        selection);
    final writes = editor.store.saved.length;
    editor.router
        .push(AddUpdateNoteRoute(note: editor.latest('resume-editor')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(_body());
    expect(field.controller!.selection, selection);
    expect(field.focusNode!.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(editor.store.saved.length, writes);
    expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late writing restore yields to user selection and IME',
      (tester) async {
    final memory = MemoryNotePositionStorage();
    final initial = NotePositionStore(storage: memory);
    await initial.saveWriting(
        'late-editor',
        NoteWritingPosition.capture(
            field: NoteWritingField.body,
            text: 'Tea and milk',
            selection: const TextSelection.collapsed(offset: 8)));
    final delayed = _DeferredPositionStorage(memory);
    await open(tester,
        positions: NotePositionStore(storage: delayed),
        note: Note(id: 'late-editor', description: 'Tea and milk'));
    await _tap(tester, _body());
    const composing = TextEditingValue(
        text: '茶葉',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2));
    tester.testTextInput.updateEditingValue(composing);
    await tester.pump();
    delayed.ready.complete();
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(_body());
    expect(field.controller!.value, composing);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reader checklist mutation uses suspended editor and latest saved child changes',
      (tester) async {
    final original = Note(
        id: 'hidden-lines',
        title: 'Original',
        description: 'Original body',
        todo: [Todo(id: 'old-task', title: 'Old')],
        linkedNoteIds: ['child']);
    final editor = await open(tester,
        note: original, existingNotes: [Note(id: 'child', title: 'Child')]);
    await _tap(tester, find.byKey(const ValueKey('linked-note-child')));
    final fresh = original.copyWith(
        title: 'New title',
        description: 'New prose',
        tags: ['new'],
        todo: [Todo(id: 'old-task', title: 'New task', completed: true)]);
    editor.store.notes.values['hidden-lines'] = NoteDto.fromNote(fresh);
    final transfer = NoteSelectionTransfer(
        repository: editor.store.notes,
        store: editor.store,
        readDraft: (id) => editor.store.drafts[id]?.toDomain());
    NoteSelectionChecklistResult? result;
    transfer
        .addToChecklist('hidden-lines', NoteTextSelection(text: 'Tea\nMilk'))
        .then((value) => result = value);
    for (var frame = 0; frame < 20 && result == null; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(result?.status, NoteSelectionChecklistStatus.ready);
    expect(editor.latest('hidden-lines').description, 'New prose');
    expect(editor.latest('hidden-lines').title, 'New title');
    expect(editor.latest('hidden-lines').tags, ['new']);
    editor.router.maybePop();
    await tester.pumpAndSettle();
    await _tap(tester, _undo());
    expect(editor.latest('hidden-lines').todo, fresh.todo);
    expect(editor.latest('hidden-lines').description, 'New prose');
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets('checklist and info phone visual preview dark=$dark',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const body =
          'Weekend errands\n• Coffee\n2. Fresh bread\n☐ Pick up flowers';
      final editor = await open(tester,
          dark: dark,
          note: Note(
              id: 'visual-checklist',
              title: 'Saturday notes',
              description: body));
      Future<void> capture(String kind) async {
        if (!const bool.fromEnvironment('CAPTURE_UI')) return;
        await tester.runAsync(() async {
          final image = await (editor.boundary.currentContext!
                  .findRenderObject() as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          try {
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await File('/tmp/onlynote-$kind-${dark ? 'dark' : 'light'}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }

      await _tap(tester, _body());
      tester.widget<TextField>(_body()).controller!.selection =
          const TextSelection(baseOffset: 16, extentOffset: body.length);
      await tester.pump();
      await _showChecklistSelectionToolbar(tester, _body());
      await capture('selection-checklist');
      await _tap(tester, find.text(S.current.Add_Selection_To_Checklist));
      await _save(tester);
      expect(editor.latest('visual-checklist').todo.length, 3);
      FocusManager.instance.primaryFocus?.unfocus();
      final scroll = tester.state<ScrollableState>(find
          .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable))
          .first);
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await capture('added-checklist');
      await _tap(tester, find.byKey(const ValueKey('editor-more-note')));
      await _tap(tester, find.text(S.current.Note_Info));
      expect(
          find.byKey(const ValueKey('note-info-reading-time')), findsOneWidget);
      await capture('note-info');
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'live checklist Undo retries a failed save without losing newer prose',
      (tester) async {
    final editor = await open(tester,
        note: Note(id: 'retry-lines', description: 'Tea\nMilk'));
    final transfer = NoteSelectionTransfer(
        repository: editor.store.notes,
        store: editor.store,
        readDraft: (id) => editor.store.drafts[id]?.toDomain());
    Future<T> pumpResult<T>(Future<T> future) async {
      var complete = false;
      late T result;
      future.then((value) {
        result = value;
        complete = true;
      });
      for (var frame = 0; frame < 40 && !complete; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(complete, isTrue);
      return result;
    }

    final addition = await pumpResult(transfer.addToChecklist(
        'retry-lines', NoteTextSelection(text: 'Tea\nMilk')));
    expect(addition?.status, NoteSelectionChecklistStatus.ready);
    editor.store.failSave = true;
    expect(
        await pumpResult(
            transfer.undoChecklist('retry-lines', addition!.addedTodoIds)),
        isFalse);
    expect(editor.latest('retry-lines').todo.length, 2);
    expect(editor.store.drafts['retry-lines']!.toDomain().todo, isEmpty);
    editor.store.failSave = false;
    expect(
        await pumpResult(
            transfer.undoChecklist('retry-lines', addition.addedTodoIds)),
        isTrue);
    expect(editor.latest('retry-lines').todo, isEmpty);
    expect(editor.store.drafts, isEmpty);
    expect(editor.latest('retry-lines').description, 'Tea\nMilk');
    expect(tester.takeException(), isNull);
  });
  for (final field in [NoteWritingField.title, NoteWritingField.todo]) {
    testWidgets('saved $field selection restores silently in editor',
        (tester) async {
      final positions = NotePositionStore.memory();
      const selection = TextSelection(baseOffset: 2, extentOffset: 6);
      await positions.saveWriting(
          'resume-field',
          NoteWritingPosition.capture(
              field: field,
              text: field == NoteWritingField.title
                  ? 'Weekend title'
                  : 'Later task',
              selection: selection,
              todoId: field == NoteWritingField.todo ? 'later' : null));
      final editor = await open(tester,
          positions: positions,
          note: Note(
              id: 'resume-field',
              title: 'Weekend title',
              description: 'Body',
              todo: [
                for (var row = 0; row < 15; row++)
                  Todo(id: 'task-$row', title: 'Earlier task $row'),
                Todo(id: 'later', title: 'Later task', completed: true),
              ]));
      final target = find.byKey(ValueKey(field == NoteWritingField.title
          ? 'note-title-input'
          : 'todo-field-later'));
      final input = tester.widget<TextField>(target);
      expect(input.controller!.selection, selection);
      expect(input.focusNode!.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(editor.store.saved, isEmpty);
      expect(tester.widget<IconButton>(_undo()).onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'late IME during checklist lookup preserves composing value and adds no tasks',
      (tester) async {
    final editor =
        await open(tester, note: Note(id: 'ime-lines', description: 'Tea'));
    await _tap(tester, _body());
    final body = tester.widget<NoteBodyEditor>(find.byType(NoteBodyEditor));
    final gate = Completer<void>();
    editor.store.notes.readGate = gate;
    body.onAddSelectionToChecklist!(NoteTextSelection(text: 'Tea'));
    await tester.pump();
    const composing = TextEditingValue(
        text: '茶葉',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2));
    body.controller.value = composing;
    gate.complete();
    editor.store.notes.readGate = null;
    await _save(tester);
    expect(body.controller.value, composing);
    expect(editor.latest('ime-lines').todo, isEmpty);
    expect(editor.latest('ime-lines').description, '茶葉');
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('late writing restore yields to mouse wheel scrolling',
      (tester) async {
    final text = 'A paragraph for later reading.\n' * 60;
    final memory = MemoryNotePositionStorage();
    await NotePositionStore(storage: memory).saveWriting(
        'wheel-editor',
        NoteWritingPosition.capture(
            field: NoteWritingField.body,
            text: text,
            selection: TextSelection.collapsed(offset: text.length - 20)));
    final delayed = _DeferredPositionStorage(memory);
    await open(tester,
        positions: NotePositionStore(storage: delayed),
        note: Note(id: 'wheel-editor', description: text));
    final before = tester.widget<TextField>(_body()).controller!.selection;
    await tester.sendEventToBinding(PointerScrollEvent(
        position: tester.getCenter(find.byType(ListView).first),
        scrollDelta: const Offset(0, 250)));
    await tester.pump();
    delayed.ready.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_body()).controller!.selection, before);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'checklist snackbar Undo targets rows after formatting returns to original content',
      (tester) async {
    final editor = await open(tester,
        note: Note(id: 'same-lines', description: 'Tea\nMilk'));
    await addSelectedLines(
        tester, _body(), const TextSelection(baseOffset: 0, extentOffset: 8));
    await _tap(tester, _body());
    tester.widget<TextField>(_body()).controller!.selection =
        const TextSelection(baseOffset: 0, extentOffset: 3);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('format-bold')));
    await _tap(tester, find.byKey(const ValueKey('format-bold')));
    expect(
        tester
            .widget<NoteBodyEditor>(find.byType(NoteBodyEditor))
            .controller
            .styles,
        isEmpty);
    await _tap(tester, find.widgetWithText(SnackBarAction, S.current.Undo));
    expect(editor.latest('same-lines').todo, isEmpty);
    expect(editor.latest('same-lines').textStyles, isEmpty);
    expect(editor.latest('same-lines').description, 'Tea\nMilk');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'very narrow editor keeps Find Info and Done accessible through More',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(180, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final editor = await open(tester,
        note: Note(id: 'narrow-toolbar', description: 'Tea'));
    expect(find.byKey(const ValueKey('editor-find-note')), findsNothing);
    expect(find.byKey(const ValueKey('editor-more-note')), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('editor-more-note')));
    expect(find.text(S.current.Find_In_Note), findsOneWidget);
    expect(find.text(S.current.Note_Info), findsOneWidget);
    expect(find.text(S.current.Done), findsOneWidget);
    expect(editor.store.saved, isEmpty);
    await _tap(tester, find.text(S.current.Done));
    expect(editor.router.current.name, HomeRoute.name);
    expect(editor.latest('narrow-toolbar').description, 'Tea');
    expect(editor.latest('narrow-toolbar').todo, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
