import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_reorder_card.dart';
import 'package:onlynote/presentation/theme/note_grid_layout.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('zh', 'HK'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() => SharedPreferences.setMockInitialValues({}));
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

  test('card density respects narrow windows and both text-size settings', () {
    expect(
        noteGridColumns(
            width: 180, textScaler: TextScaler.noScaling, preferredColumns: 3),
        1);
    expect(
        noteGridColumns(
            width: 390, textScaler: TextScaler.noScaling, preferredColumns: 3),
        2);
    final ordinary = noteGridColumns(
        width: 850, textScaler: TextScaler.noScaling, preferredColumns: 3);
    final enlarged = noteGridColumns(
        width: 850,
        textScaler: const TextScaler.linear(2),
        appFontScale: 1.2,
        preferredColumns: 3);
    expect(enlarged, lessThan(ordinary));
    expect(enlarged, greaterThanOrEqualTo(1));
    expect(
        noteGridColumns(
            width: 1200, textScaler: TextScaler.noScaling, preferredColumns: 1),
        2,
        reason: 'A spacious tablet may add only one column to the preference');
  });

  testWidgets('drag cards retain meaningful titles for media-only notes',
      (tester) async {
    final notes = [
      Note(id: 'blank-title', title: '   ', description: 'Body identity'),
      Note(id: 'checklist', todo: [
        Todo(title: ' '),
        Todo(title: 'Task identity'),
      ]),
      Note(id: 'audio', voiceMemos: [
        VoiceMemo(
            id: 'memo',
            path: 'note_audio/memo.m4a',
            durationMs: 1000,
            createdAt: DateTime(2026, 10, 7)),
      ]),
      Note(id: 'photo', imagePaths: ['note_images/photo.jpg']),
    ];
    await tester.pumpWidget(_host(GridView.count(
      crossAxisCount: 2,
      children: [for (final note in notes) NoteReorderCard(note: note)],
    )));
    await tester.pumpAndSettle();
    expect(find.text('Body identity'), findsOneWidget);
    expect(find.text('Task identity'), findsOneWidget);
    expect(find.text(S.current.Voice_Memo), findsOneWidget);
    expect(find.text(S.current.History_Photos(1)), findsOneWidget);
    expect(find.byType(PaperChecklistRow), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(InkWell), findsNothing,
        reason: 'Dragging must not trigger task changes or sharing');
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag headlines and dates fit narrow and enlarged note grids',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final note = Note(
      id: 'long',
      title: '需要一個清楚的標題，讓我知道這是哪一篇筆記，並可輕鬆調整順序',
      dateTime: DateTime(2026, 10, 7),
      isPinned: true,
    );
    try {
      await AppTypographySettings.instance.setFontSize(AppFontSize.large);
      for (final width in [180.0, 320.0, 390.0, 600.0, 850.0]) {
        for (final scale in [1.0, 2.4]) {
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpWidget(_host(LayoutBuilder(
            builder: (context, constraints) {
              final columns = noteGridColumns(
                width: constraints.maxWidth,
                textScaler: MediaQuery.textScalerOf(context),
                preferredColumns: 3,
                appFontScale: AppTypographySettings.instance.scale,
              );
              return GridView.count(
                padding: const EdgeInsets.all(AppSpacings.xl),
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacings.l,
                mainAxisSpacing: AppSpacings.xl,
                childAspectRatio: noteReorderAspectRatio(
                  width: constraints.maxWidth,
                  columns: columns,
                  textScaler: MediaQuery.textScalerOf(context),
                  appFontScale: AppTypographySettings.instance.scale,
                ),
                children: [NoteReorderCard(note: note)],
              );
            },
          ), scale: scale));
          await tester.pumpAndSettle();
          final headline = find.text(note.title!);
          final date = find.text('2026年10月7日');
          expect(headline, findsOneWidget);
          expect(date, findsOneWidget);
          expect(tester.getRect(headline).bottom,
              lessThanOrEqualTo(tester.getRect(date).top));
          expect(tester.getSize(date).height, greaterThan(0));
          expect(tester.takeException(), isNull,
              reason: 'width $width, system scale $scale, app scale 1.2');
        }
      }
    } finally {
      await AppTypographySettings.instance.setFontSize(AppFontSize.medium);
    }
  });
}
