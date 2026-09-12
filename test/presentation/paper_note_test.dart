import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/theme.dart';

void main() {
  testWidgets('PaperNote renders its child on a paper surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PaperNote(
            color: const Color(0xFFFFF4C2),
            seed: 8,
            child: const Text('Market list'),
          ),
        ),
      ),
    );

    expect(find.text('Market list'), findsOneWidget);
    expect(find.byType(PaperNote), findsOneWidget);
  });

  testWidgets('PaperChecklistRow toggles when tapped', (tester) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PaperChecklistRow(
              label: 'Bring tote bags',
              completed: completed,
              onChanged: (value) => setState(() => completed = value),
            ),
          ),
        ),
      ),
    );

    expect(
        tester.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(44));
    await tester.tap(find.text('Bring tote bags'));
    await tester.pump();
    expect(completed, isTrue);
  });

  test('desk colors stay distinct from parchment so paper can lift', () {
    expect(AppColors.desk, isNot(AppColors.parchment));
    expect(AppColors.deskDark, isNot(AppColors.nightSurface));
  });
}
