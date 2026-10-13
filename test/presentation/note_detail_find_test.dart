import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/get_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
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
            page: PageInfo(
              'FindDetailTestRoute',
              builder: (_) => const NoteDetailScreen(noteId: 'note'),
            ))
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

  testWidgets(
      'detail menu finds collapsed completed tasks and search never saves content',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final note = Note(
        id: 'note',
        title: 'Tea note',
        description: 'Tea note body',
        dateTime: DateTime(2026, 10, 6),
        todo: [
          Todo(id: 'active', title: 'Pack tea'),
          Todo(id: 'done', title: 'Tea done', completed: true)
        ]);
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
            GlobalCupertinoLocalizations.delegate
          ],
          supportedLocales: S.delegate.supportedLocales,
        )));
    await tester.pumpAndSettle();
    final completedToggle =
        find.byKey(const ValueKey('checklist-completed-toggle'));
    await tester.ensureVisible(completedToggle);
    await tester.tap(completedToggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('checklist-item-done')), findsNothing);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find in note'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('note-find-query')), 'tea');
    await tester.pumpAndSettle();
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.byKey(const ValueKey('checklist-item-done')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-find-next')));
    await tester.tap(find.byKey(const ValueKey('note-find-next')));
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-find-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-find-query')), findsNothing);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-find-query')), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('note-find-query')))
            .focusNode!
            .hasFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-find-query')), findsNothing);
    expect(DesktopCommands.instance.invoke(DesktopCommand.findInNote), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-find-query')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-find-close')));
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    expect(tester.widget<LoadedView>(find.byType(LoadedView)).note.description,
        'Tea note body');
    expect(tester.takeException(), isNull);
  });
}
