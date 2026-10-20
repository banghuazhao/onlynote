import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';

Finder get _closeButton => find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == 'Close');

class _Reader extends StatelessWidget {
  const _Reader();

  @override
  Widget build(BuildContext context) => Scaffold(
        key: const ValueKey('reader-page'),
        body: Column(children: [
          TextButton(
            onPressed: () => showAppSheet<void>(
              context: context,
              builder: (_) => const AppSheet(
                title: 'Sheet',
                child: Text('Sheet content'),
              ),
            ),
            child: const Text('Open sheet'),
          ),
          TextButton(
            onPressed: () => showAppActionSheet(
              context: context,
              title: 'Actions',
              actions: const [],
            ),
            child: const Text('Open actions'),
          ),
        ]),
      );
}

Future<void> _open(WidgetTester tester, String action) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [S.delegate],
    routes: {'/reader': (_) => const _Reader()},
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.pushNamed(context, '/reader'),
          child: const Text('Open reader'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open reader'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

void main() {
  for (final action in ['Open sheet', 'Open actions']) {
    testWidgets('$action repeated dismissal preserves the underlying reader',
        (tester) async {
      await _open(tester, action);
      final callback = action == 'Open sheet'
          ? tester.widget<IconButton>(_closeButton).onPressed!
          : tester
              .widget<OutlinedButton>(find.ancestor(
                of: find.text(S.current.Cancel),
                matching: find.byType(OutlinedButton),
              ))
              .onPressed!;
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reader-page')), findsOneWidget);
      expect(find.byType(AppSheet), findsNothing);
      callback();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reader-page')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a covered sheet cannot close a newer dialog', (tester) async {
    await _open(tester, 'Open sheet');
    final callback = tester.widget<IconButton>(_closeButton).onPressed!;
    final context = tester.element(find.byType(AppSheet));
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('Newer dialog')),
    );
    await tester.pumpAndSettle();
    callback();
    await tester.pumpAndSettle();
    expect(find.text('Newer dialog'), findsOneWidget);
    expect(find.byType(AppSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
