import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/delete_multiple_notes.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/home/bloc/multiple_delete/multiple_delete_bloc.dart';

class _Notes extends Fake implements NoteRepository {}

class _PendingDelete extends DeleteMultipleNotesUsecase {
  _PendingDelete() : super(_Notes());
  final requests = <List<String>>[];
  final completion = Completer<Either<NoteError, Unit>>();

  @override
  Future<Either<NoteError, Unit>> call(List<String> ids) {
    requests.add(List.of(ids));
    return completion.future;
  }
}

class _RetryDelete extends DeleteMultipleNotesUsecase {
  _RetryDelete() : super(_Notes());
  final requests = <List<String>>[];

  @override
  Future<Either<NoteError, Unit>> call(List<String> ids) async {
    requests.add(List.of(ids));
    return requests.length == 1
        ? left(NoteError(message: 'Could not move notes to Trash. Try again.'))
        : right(unit);
  }
}

Future<void> _turn() => Future<void>.delayed(Duration.zero);

void main() {
  testWidgets('failed deletion retains selected notes and permits retry',
      (tester) async {
    final deletion = _RetryDelete();
    final bloc = MultipleDeleteBloc(deletion);
    final router = AppRouter();
    getIt.registerSingleton<AppRouter>(router);
    addTearDown(() async {
      await bloc.close();
      await tester.pumpWidget(const SizedBox.shrink());
      await getIt.unregister<AppRouter>();
      router.dispose();
    });
    await tester.pumpWidget(MaterialApp(
      navigatorKey: router.navigatorKey,
      home: Scaffold(
        body: BlocBuilder<MultipleDeleteBloc, MultipleDeleteState>(
          bloc: bloc,
          builder: (context, state) => Column(children: [
            Text(state.mapOrNull(
                    selected: (value) =>
                        'Selected ${value.selectedIds.join(', ')}',
                    success: (_) => 'Deleted') ??
                'Ready'),
            TextButton(
              onPressed: () => bloc.add(const MultipleDeleteEvent.delete()),
              child: const Text('Delete selected'),
            ),
          ]),
        ),
      ),
    ));
    bloc.add(const MultipleDeleteEvent.toggleSelect('first'));
    bloc.add(const MultipleDeleteEvent.toggleSelect('second'));
    await tester.pump();
    expect(find.text('Selected first, second'), findsOneWidget);

    await tester.tap(find.text('Delete selected'));
    await tester.pumpAndSettle();
    expect(find.text('Selected first, second'), findsOneWidget);
    expect(
        find.text('Could not move notes to Trash. Try again.'), findsOneWidget);
    expect(bloc.isSelected('first'), isTrue);
    expect(bloc.isSelected('second'), isTrue);

    await tester.tap(find.text('Delete selected'));
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsOneWidget);
    expect(deletion.requests, [
      ['first', 'second'],
      ['first', 'second'],
    ]);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('rapidly changing the last selected card retains the new selection',
      () async {
    final bloc = MultipleDeleteBloc(_PendingDelete());
    addTearDown(bloc.close);
    bloc.add(const MultipleDeleteEvent.toggleSelect('first'));
    await _turn();
    expect(bloc.state, const MultipleDeleteState.selected(['first']));

    bloc.add(const MultipleDeleteEvent.toggleSelect('first'));
    bloc.add(const MultipleDeleteEvent.toggleSelect('second'));
    await _turn();
    expect(bloc.state, const MultipleDeleteState.selected(['second']));
    expect(bloc.isSelected('second'), isTrue);
    expect(bloc.isSelected('first'), isFalse);
  });

  for (final direct in [false, true]) {
    test(
        'pending delete ignores selection and duplicate requests direct=$direct',
        () async {
      final deletion = _PendingDelete();
      final bloc = MultipleDeleteBloc(deletion);
      addTearDown(() async {
        if (!deletion.completion.isCompleted) {
          deletion.completion.complete(right(unit));
        }
        await bloc.close();
      });
      bloc.add(const MultipleDeleteEvent.toggleSelect('first'));
      await _turn();
      bloc.add(direct
          ? const MultipleDeleteEvent.deleteIds(['first'])
          : const MultipleDeleteEvent.delete());
      await _turn();
      expect(bloc.state, const MultipleDeleteState.deleting());

      bloc.add(const MultipleDeleteEvent.toggleSelect('second'));
      bloc.add(const MultipleDeleteEvent.clearAll());
      bloc.add(const MultipleDeleteEvent.deleteIds(['second']));
      bloc.add(const MultipleDeleteEvent.delete());
      await _turn();
      expect(bloc.state, const MultipleDeleteState.deleting());
      expect(deletion.requests, [
        ['first']
      ]);

      deletion.completion.complete(right(unit));
      await _turn();
      expect(bloc.state, const MultipleDeleteState.success(['first']));
      bloc.add(const MultipleDeleteEvent.clearAll());
      await _turn();
      expect(bloc.state, const MultipleDeleteState.initial());
      bloc.add(const MultipleDeleteEvent.toggleSelect('second'));
      await _turn();
      expect(bloc.state, const MultipleDeleteState.selected(['second']));
    });
  }
}
