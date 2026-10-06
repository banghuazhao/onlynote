import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/photo_text_review_sheet.dart';

Future<void> _open(WidgetTester tester, List<String?> results,
    {Locale locale = const Locale('en'),
    double scale = 1,
    bool reducedMotion = false,
    String text = 'Milk\n牛奶'}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reducedMotion),
      child: child!,
    ),
    home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  onPressed: () async => results.add(await showAppSheet<String>(
                      context: context,
                      builder: (_) => PhotoTextReviewSheet(text: text))),
                  child: const Text('Read photo'),
                ))),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Read photo'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('edited extracted text is inserted only after confirmation',
      (tester) async {
    final results = <String?>[];
    await _open(tester, results);
    expect(results, isEmpty);
    await tester.enterText(
        find.byKey(const ValueKey('photo-text-review')), 'Oat milk\n燕麦奶');
    await tester.ensureVisible(find.text('Insert text'));
    await tester.tap(find.text('Insert text'));
    await tester.pumpAndSettle();
    expect(results, ['Oat milk\n燕麦奶']);
  });

  testWidgets('copy keeps the sheet open and does not insert text',
      (tester) async {
    final results = <String?>[];
    String? copied;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await _open(tester, results);
    await tester.enterText(
        find.byKey(const ValueKey('photo-text-review')), '燕麥奶');
    await tester.ensureVisible(find.text('Copy text'));
    await tester.tap(find.text('Copy text'));
    await tester.pumpAndSettle();
    expect(copied, '燕麥奶');
    expect(results, isEmpty);
    expect(find.text('Text copied'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });

  testWidgets('empty review text disables copy and insertion', (tester) async {
    await _open(tester, []);
    await tester.enterText(
        find.byKey(const ValueKey('photo-text-review')), '   ');
    await tester.pump();
    final insert = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Insert text'));
    final copy = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Copy text'));
    expect(insert.onPressed, isNull);
    expect(copy.onPressed, isNull);
  });

  testWidgets('clipboard failure keeps editable review for retry',
      (tester) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'clipboard_unavailable');
      }
      return null;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final results = <String?>[];
    await _open(tester, results);
    await tester.ensureVisible(find.text('Copy text'));
    await tester.tap(find.text('Copy text'));
    await tester.pumpAndSettle();
    expect(results, isEmpty);
    expect(find.text('Could not copy text. Please try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Traditional Chinese review remains usable at large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final results = <String?>[];
    await _open(tester, results,
        locale: const Locale('zh', 'HK'),
        scale: 2,
        reducedMotion: true,
        text: '購物清單\n牛奶\n麵包');
    final context = tester.element(find.byType(PhotoTextReviewSheet));
    final label = S.of(context).Photo_Text_Insert;
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    expect(results, ['購物清單\n牛奶\n麵包']);
  });
}
