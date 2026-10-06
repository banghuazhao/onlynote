import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';

VoiceMemo _memo(String id, {String? transcript}) => VoiceMemo(
    id: id,
    path: 'note_audio/$id.m4a',
    durationMs: 42000,
    createdAt: DateTime(2026, 10, 6),
    transcript: transcript);

Widget _host(NoteCard card,
        {Locale locale = const Locale('en'), double scale = 1}) =>
    MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations: true, textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Scaffold(body: SingleChildScrollView(child: card)));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('audio-only card remains visible, recognizable and tappable',
      (tester) async {
    final note = Note(id: 'audio-only', voiceMemos: [_memo('recording')]);
    var opened = false;
    await tester
        .pumpWidget(_host(NoteCard(note: note, onTap: () => opened = true)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.text(S.current.History_Recordings(1)), findsOneWidget);
    expect(tester.getSize(find.byType(NoteCard)).height, greaterThan(88));
    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'search card excerpt reveals a transcript match over other body text',
      (tester) async {
    final transcript = '${'An earlier unrelated sentence. ' * 30}買茶 tomorrow';
    final note = Note(
        id: 'match',
        description: 'Written body without this query',
        voiceMemos: [
          _memo('first', transcript: 'Unrelated recording'),
          _memo('second', transcript: transcript)
        ]);
    await tester.pumpWidget(_host(NoteCard(note: note, searchQuery: '買茶')));
    await tester.pumpAndSettle();
    final excerpt =
        tester.widget<SearchHighlight>(find.byType(SearchHighlight));
    expect(excerpt.text, startsWith('…'));
    expect(excerpt.text, contains('買茶 tomorrow'));
    expect(excerpt.text.length, lessThan(80));
    expect(excerpt.query, '買茶');
    expect(find.text('Written body without this query'), findsNothing);
    expect(find.text(S.current.History_Recordings(2)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio-only card survives Chinese large text on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final note = Note(id: 'zh-audio', voiceMemos: [_memo('recording')]);
    await tester.pumpWidget(_host(NoteCard(note: note),
        locale: const Locale('zh', 'HK'), scale: 2.4));
    await tester.pumpAndSettle();
    expect(find.text('1 段錄音'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
