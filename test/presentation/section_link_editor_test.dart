import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_section_link_picker_sheet.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_outline.dart';
import 'package:onlynote/services/voice_memo_service.dart';

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
    ids.forEach(values.remove);
  }
}

class _Store implements NoteAutosaveStore {
  _Store(this.notes);
  final _Notes notes;
  final saved = <Note>[];

  @override
  Future<void> writeDraft(Note note) async {}
  @override
  Future<void> removeDraft(String id) async {}
  @override
  Future<void> saveNote(Note note) async {
    saved.add(note);
    await notes.addUpdateNote(NoteDto.fromNote(note));
  }
}

class _IdleVoicePlatform implements VoiceMemoPlatform {
  @override
  Stream<Object?> get states => const Stream.empty();

  @override
  Future<Object?> invoke(String method,
      [Map<String, Object?>? arguments]) async {
    if (method != 'state' && method != 'stopPlayback') {
      throw StateError('Unexpected native media operation: $method');
    }
    return {'phase': 'idle'};
  }
}

Future<(_Notes, _Store)> _openEditor(WidgetTester tester, Note note) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final notes = _Notes()..values[note.id!] = NoteDto.fromNote(note);
  getIt.pushNewScope();
  getIt.registerSingleton<NoteRepository>(notes);
  final store = _Store(notes);
  final voice = VoiceMemoService(platform: _IdleVoicePlatform());
  final bloc = AddUpdateBloc(AddNoteUsecase(notes), UpdateNoteUsecase(notes));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await bloc.close();
    await voice.dispose();
    await getIt.popScope();
  });
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: BlocProvider.value(
      value: bloc,
      child: AddUpdateNoteScreen(
        note: note,
        autosaveStore: store,
        voiceMemoService: voice,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return (notes, store);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _waitForAutosave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Finder get _body => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.maxLines == 100);

Note _initialNote() => Note(
      id: 'project',
      title: 'A project note',
      description: 'Intro paragraph\nProject plan\nOriginal body',
      tags: ['Work'],
      folderId: 'projects',
      textStyles: const [
        NoteTextStyleRange(start: 16, end: 28, kind: NoteTextStyleKind.heading),
      ],
    );

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() => initializeDateFormatting());
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

  testWidgets(
      'editor heading link persists through typing and heading rename, then jumps within the same note',
      (tester) async {
    final initial = _initialNote();
    final (notes, store) = await _openEditor(tester, initial);
    await _tap(tester, find.byKey(const ValueKey('add-section-link')));
    expect(find.byType(NoteSectionLinkPickerSheet), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('section-choice-project-16')));
    expect(find.byType(NoteSectionLinkPickerSheet), findsNothing);
    expect(store.saved, isNotEmpty);
    final linked = notes.values['project']!.toDomain();
    final link = linked.sectionLinks.single;
    expect(link.noteId, 'project');
    expect(link.headingId, isNotEmpty);
    final heading =
        buildNoteOutline(linked.description!, linked.textStyles).single;
    expect(heading.anchorId, link.headingId);
    expect(heading.text, 'Project plan');

    await tester.ensureVisible(_body);
    await tester.pumpAndSettle();
    await tester.enterText(_body,
        'Intro paragraph\nProject plan\nOriginal body\nKeep typing after linking.');
    await _waitForAutosave(tester);
    expect(notes.values['project']!.toDomain().sectionLinks, [link]);

    const renamedBody =
        'Intro paragraph\nUpdated project plan\nOriginal body\nKeep typing after linking.';
    await tester.enterText(_body, renamedBody);
    await _waitForAutosave(tester);
    final renamed = notes.values['project']!.toDomain();
    final renamedHeading =
        buildNoteOutline(renamedBody, renamed.textStyles).single;
    expect(renamed.description, renamedBody);
    expect(renamedHeading.text, 'Updated project plan');
    expect(renamedHeading.anchorId, link.headingId);
    expect(renamed.sectionLinks, [link]);
    expect(renamed.folderId, initial.folderId);
    expect(renamed.tags, initial.tags);

    final bodyController = tester.widget<TextField>(_body).controller!;
    bodyController.selection =
        TextSelection.collapsed(offset: renamedBody.length);
    await tester.pump();
    final row = find.byKey(ValueKey('section-link-project-${link.headingId}'));
    await _tap(tester, row);
    expect(find.byType(AddUpdateNoteScreen), findsOneWidget);
    expect(bodyController.selection,
        TextSelection.collapsed(offset: renamedHeading.start));
    expect(tester.widget<TextField>(_body).focusNode!.hasFocus, isTrue);
    expect(notes.values['project']!.toDomain().sectionLinks, [link]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'cancelling the heading picker leaves note links and anchors unchanged',
      (tester) async {
    final initial = _initialNote();
    final (notes, store) = await _openEditor(tester, initial);
    await _tap(tester, find.byKey(const ValueKey('add-section-link')));
    expect(find.byType(NoteSectionLinkPickerSheet), findsOneWidget);
    await _tap(tester, find.byTooltip('Close'));
    await _waitForAutosave(tester);
    final saved = notes.values['project']!.toDomain();
    expect(saved.sectionLinks, isEmpty);
    expect(saved.textStyles, initial.textStyles);
    expect(saved.description, initial.description);
    expect(store.saved, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
