import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/get_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_outline_sheet.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:screenshot/screenshot.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';

class _Notes implements NoteRepository {
  _Notes(this.note);
  final NoteDto note;
  int writes = 0;
  @override
  Future<NoteDto> getNote(String id) async => note;
  @override
  List<NoteDto> getAllNotes() => [note];
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
  }

  @override
  Future<void> deleteNote(String id) async {}
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {}
}

class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo('OutlineDetailTestRoute',
                builder: (_) => const NoteDetailScreen(noteId: 'note'))),
      ];
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    await initializeDateFormatting();
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
  setUp(() {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  for (final sections in [1, 2]) {
    testWidgets(
        'reader outline is contextual ($sections sections) and never saves',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const body = 'First heading\nBody\nSecond heading\nMore';
      final note = Note(
        id: 'note',
        title: 'Project',
        description: body,
        dateTime: DateTime(2026, 10, 7),
        textStyles: [
          const NoteTextStyleRange(
              start: 0, end: 13, kind: NoteTextStyleKind.heading),
          if (sections == 2)
            NoteTextStyleRange(
                start: body.indexOf('Second heading'),
                end: body.indexOf('Second heading') + 14,
                kind: NoteTextStyleKind.heading),
        ],
      );
      final repository = _Notes(NoteDto.fromNote(note));
      final detail = NoteDetailBloc(
          GetNoteUsecase(repository), UpdateNoteUsecase(repository));
      final router = _Router();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await detail.close();
      });
      await tester.pumpWidget(BlocProvider.value(
        value: detail,
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
      await tester.tap(find.byTooltip(S.current.More_Options));
      await tester.pumpAndSettle();
      expect(find.text(S.current.Note_Outline),
          sections == 2 ? findsOneWidget : findsNothing);
      if (sections == 2) {
        await tester.tap(find.text(S.current.Note_Outline));
        await tester.pumpAndSettle();
        expect(find.byType(NoteOutlineSheet), findsOneWidget);
        await tester.tap(find.byKey(
            ValueKey('note-outline-entry-${body.indexOf('Second heading')}')));
        await tester.pumpAndSettle();
        expect(find.byType(NoteOutlineSheet), findsNothing);
      }
      expect(repository.writes, 0);
      expect(
          detail.state.whenOrNull(success: (note) => note.description), body);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'actual reader folds sections while image export includes all text',
      (tester) async {
    const body = 'Heading\nSecret paragraph\nNext\nLast';
    final next = body.indexOf('Next');
    final note = Note(
        id: 'export-sections',
        title: 'Notes',
        description: body,
        dateTime: DateTime(2026, 10, 7),
        textStyles: [
          const NoteTextStyleRange(
              start: 0, end: 7, kind: NoteTextStyleKind.heading),
          NoteTextStyleRange(
              start: next, end: next + 4, kind: NoteTextStyleKind.heading),
        ]);
    var exporting = false;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
          update = setState;
          return LoadedView(
              note: note,
              screenshotController: ScreenshotController(),
              onReminderTap: null,
              exportMode: exporting,
              onCopySelection: (_) {});
        }))));
    await tester.pumpAndSettle();
    final secret = find.byWidgetPredicate((widget) =>
        widget is FormattedNoteText && widget.text == 'Secret paragraph\n');
    expect(secret, findsOneWidget);
    final toggle = find.byKey(const ValueKey('note-section-toggle-0'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(secret, findsNothing);
    update(() => exporting = true);
    await tester.pumpAndSettle();
    expect(toggle, findsNothing);
    final exported =
        tester.widget<NoteDocumentView>(find.byType(NoteDocumentView));
    expect(exported.collapsibleSections, isFalse);
    expect(exported.onCopySelection, isNull);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is FormattedNoteText &&
            widget.text == body &&
            !widget.selectable),
        findsOneWidget);
    update(() => exporting = false);
    await tester.pumpAndSettle();
    expect(secret, findsNothing);
    expect(toggle, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
