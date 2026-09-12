import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/toast.dart';

void main() {
  testWidgets('a snack bar posted under a modal route still goes away',
      (tester) async {
    late BuildContext pageContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    // ScaffoldMessenger only starts its dismissal timer while the snack bar's
    // own route is the current one, so a message posted with a dialog or
    // sheet on top never gets one and can sit on screen indefinitely.
    unawaited(showDialog<void>(
      context: pageContext,
      builder: (_) => const AlertDialog(content: Text('confirm')),
    ));
    await tester.pumpAndSettle();

    showTransientSnackBar(
      pageContext,
      const SnackBar(
        content: Text('Moved to Trash'),
        duration: Duration(seconds: 2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Moved to Trash'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Moved to Trash'), findsNothing);
  });
}
