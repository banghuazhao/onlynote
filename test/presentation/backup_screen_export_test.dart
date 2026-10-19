import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppExitResponse;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/Tools/export_archive.dart';
import 'package:onlynote/presentation/components/backup_export_section.dart';
import 'package:onlynote/presentation/components/note_export_section.dart';
import 'package:onlynote/presentation/screens/settings/backup_screen.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';
import 'package:onlynote/services/note_bulk_export.dart';
import 'package:onlynote/services/note_export_format_store.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:share_plus/share_plus.dart';

import '../support/memory_preferences.dart';

class _ControlledStatusStore extends BackupExportStatusStore {
  final initialRead = Completer<BackupExportRecord?>();
  final recorded = <BackupExportRecord>[];

  @override
  Future<BackupExportRecord?> read() => initialRead.future;

  @override
  Future<void> record(BackupExportRecord record) async => recorded.add(record);
}

class _FailingStatusStore extends BackupExportStatusStore {
  @override
  Future<BackupExportRecord?> read() async => throw StateError('Read failed');

  @override
  Future<void> record(BackupExportRecord record) async =>
      throw StateError('Write failed');
}

class _ControlledFormatStore extends NoteExportFormatStore {
  final initialRead = Completer<NoteBulkExportFormat>();
  final written = <NoteBulkExportFormat>[];
  Completer<void>? pendingWrite;

  @override
  Future<NoteBulkExportFormat> read() => initialRead.future;

  @override
  Future<void> write(NoteBulkExportFormat format) async {
    written.add(format);
    await pendingWrite?.future;
  }
}

class _FailingFormatStore extends NoteExportFormatStore {
  @override
  Future<NoteBulkExportFormat> read() async => throw StateError('Read failed');

  @override
  Future<void> write(NoteBulkExportFormat format) async =>
      throw StateError('Write failed');
}

class _PendingFormatPreferences extends MemoryPreferences {
  final firstWrite = Completer<void>();
  final writes = <String>[];

  @override
  Future<void> setString(String key, String value) async {
    writes.add(value);
    if (writes.length == 1) await firstWrite.future;
    await super.setString(key, value);
  }
}

NoteBulkExportFormat _visibleFormat(WidgetTester tester) =>
    tester.widget<NoteExportSection>(find.byType(NoteExportSection)).format;

BackupExportRecord? _visibleRecord(WidgetTester tester) => tester
    .widget<BackupExportSection>(find.byType(BackupExportSection))
    .lastExport;

Widget _host(BackupScreen screen) => MaterialApp(
      locale: const Locale('en'),
      theme: AppTheme.light,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: screen,
    );

Finder get _exportButton =>
    find.widgetWithText(FilledButton, S.current.Backup_Export);
Finder get _restoreButton =>
    find.widgetWithText(OutlinedButton, S.current.Backup_Choose);
Finder get _exportNotesButton =>
    find.widgetWithText(OutlinedButton, S.current.Export_Notes);
Finder get _saveNotesButton =>
    find.widgetWithText(OutlinedButton, S.current.Export_Notes_Save_As);
Finder _formatChip(NoteBulkExportFormat format) =>
    find.byKey(ValueKey('note-export-format-${format.name}'));

/// A finished archive, standing in for one the real builder streamed to disk.
/// The file itself is written in setUp: a widget test's own zone never
/// completes real file I/O, so touching the disk inside a test body would
/// leave the export pending forever.
NoteArchiveExport _archive(
  File file, {
  int exported = 2,
  int skipped = 0,
  int failed = 0,
}) =>
    NoteArchiveExport(
        file,
        NoteBulkExportResult(
            exported: exported, skipped: skipped, failed: failed));

Future<void> _drainFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('last completed backup export', () {
    final priorDate = DateTime.utc(2025, 1, 2, 13, 14);

    Future<BackupExportStatusStore> previousExport(
        MemoryPreferences preferences) async {
      final store = BackupExportStatusStore(preferences: preferences);
      await store.record(BackupExportRecord(
          exportedAt: priorDate, destination: BackupExportDestination.saved));
      return store;
    }

    testWidgets('no recorded export has a neutral first-use status',
        (tester) async {
      await tester.pumpWidget(_host(BackupScreen(
          backupStatusStore:
              BackupExportStatusStore(preferences: MemoryPreferences()))));
      await tester.pumpAndSettle();
      expect(find.text(S.current.Backup_Export_No_Record), findsOneWidget);
      expect(_visibleRecord(tester), isNull);
      expect(tester.takeException(), isNull);
    });

    for (final status in ShareResultStatus.values) {
      testWidgets('$status updates status only for a confirmed share',
          (tester) async {
        final preferences = MemoryPreferences();
        final store = await previousExport(preferences);
        await tester.pumpWidget(_host(BackupScreen(
          backupStatusStore: store,
          exportBackup: () async => Uint8List.fromList([1]),
          shareBackup: (_) async => ShareResult('action', status),
        )));
        await tester.pumpAndSettle();
        expect(_visibleRecord(tester)!.exportedAt, priorDate);
        await tester.tap(_exportButton);
        await tester.pumpAndSettle();
        final record = _visibleRecord(tester)!;
        if (status == ShareResultStatus.success) {
          expect(record.destination, BackupExportDestination.shared);
          expect(record.exportedAt.isAfter(priorDate), isTrue);
          expect(find.textContaining('Last backup shared:'), findsOneWidget);
        } else {
          expect(record.destination, BackupExportDestination.saved);
          expect(record.exportedAt, priorDate);
        }
        await _drainFeedback(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(_host(BackupScreen(
          backupStatusStore: BackupExportStatusStore(preferences: preferences),
        )));
        await tester.pumpAndSettle();
        final reopened = _visibleRecord(tester)!;
        expect(reopened.destination, record.destination);
        expect(reopened.exportedAt.millisecondsSinceEpoch,
            record.exportedAt.millisecondsSinceEpoch);
        expect(tester.takeException(), isNull);
      });
    }

    for (final saved in [true, false]) {
      testWidgets(
          'Mac ${saved ? 'save' : 'cancellation'} retains accurate status',
          (tester) async {
        final preferences = MemoryPreferences();
        await tester.pumpWidget(_host(BackupScreen(
          backupStatusStore: await previousExport(preferences),
          exportBackup: () async => Uint8List.fromList([1]),
          saveBackup: (_, __) async => saved,
        )));
        await tester.pumpAndSettle();
        await tester
            .tap(find.widgetWithText(FilledButton, S.current.Backup_Save_As));
        await tester.pumpAndSettle();
        final record = _visibleRecord(tester)!;
        expect(record.destination, BackupExportDestination.saved);
        expect(record.exportedAt.isAfter(priorDate), saved);
        expect(find.textContaining('Last backup saved:'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _drainFeedback(tester);
      }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
    }

    for (final stage in ['preparation', 'share', 'save']) {
      testWidgets('$stage failure preserves the previous status',
          (tester) async {
        final preferences = MemoryPreferences();
        await tester.pumpWidget(_host(BackupScreen(
          backupStatusStore: await previousExport(preferences),
          exportBackup: () async {
            if (stage == 'preparation') throw StateError('Preparation failed');
            return Uint8List.fromList([1]);
          },
          shareBackup: (_) async => throw StateError('Share failed'),
          saveBackup: (_, __) async => throw StateError('Save failed'),
        )));
        await tester.pumpAndSettle();
        await tester.tap(stage == 'save'
            ? find.widgetWithText(FilledButton, S.current.Backup_Save_As)
            : _exportButton);
        await tester.pumpAndSettle();
        expect(_visibleRecord(tester)!.exportedAt, priorDate);
        expect(
            _visibleRecord(tester)!.destination, BackupExportDestination.saved);
        expect(
            (await BackupExportStatusStore(preferences: preferences).read())!
                .exportedAt,
            priorDate);
        expect(tester.takeException(), isNull);
        await _drainFeedback(tester);
      },
          variant: TargetPlatformVariant.only(
              stage == 'save' ? TargetPlatform.macOS : TargetPlatform.android));
    }

    testWidgets('status dates the snapshot before waiting for preparation',
        (tester) async {
      final prepared = Completer<Uint8List>();
      final store = _ControlledStatusStore()..initialRead.complete(null);
      late DateTime preparationStarted;
      await tester.pumpWidget(_host(BackupScreen(
        backupStatusStore: store,
        exportBackup: () {
          preparationStarted = DateTime.now().toUtc();
          return prepared.future;
        },
        shareBackup: (_) async =>
            const ShareResult('action', ShareResultStatus.success),
      )));
      await tester.pumpAndSettle();
      final beforeExport = DateTime.now().toUtc();
      await tester.tap(_exportButton);
      await tester.pump();
      expect(store.recorded, isEmpty);
      prepared.complete(Uint8List.fromList([1]));
      await tester.pumpAndSettle();
      final recorded = store.recorded.single;
      expect(recorded.exportedAt.isUtc, isTrue);
      expect(recorded.exportedAt.isBefore(beforeExport), isFalse);
      expect(recorded.exportedAt.isAfter(preparationStarted), isFalse);
      await _drainFeedback(tester);
    });

    testWidgets('a delayed initial read cannot replace a completed share',
        (tester) async {
      final store = _ControlledStatusStore();
      await tester.pumpWidget(_host(BackupScreen(
        backupStatusStore: store,
        exportBackup: () async => Uint8List.fromList([1]),
        shareBackup: (_) async =>
            const ShareResult('action', ShareResultStatus.success),
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportButton);
      await tester.pumpAndSettle();
      final recorded = store.recorded.single;
      store.initialRead.complete(BackupExportRecord(
          exportedAt: priorDate, destination: BackupExportDestination.saved));
      await tester.pumpAndSettle();
      expect(_visibleRecord(tester), same(recorded));
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });

    testWidgets('status storage failures preserve a successful export outcome',
        (tester) async {
      await tester.pumpWidget(_host(BackupScreen(
        backupStatusStore: _FailingStatusStore(),
        exportBackup: () async => Uint8List.fromList([1]),
        shareBackup: (_) async =>
            const ShareResult('action', ShareResultStatus.success),
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportButton);
      await tester.pumpAndSettle();
      expect(find.text(S.current.Backup_Export_Shared), findsOneWidget);
      expect(
          _visibleRecord(tester)!.destination, BackupExportDestination.shared);
      expect(find.text(S.current.Backup_Export_Share_Failed), findsNothing);
      expect(tester.widget<FilledButton>(_exportButton).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });

    testWidgets('a save completed after disposal is still recorded safely',
        (tester) async {
      final saved = Completer<bool>();
      final store = _ControlledStatusStore()..initialRead.complete(null);
      await tester.pumpWidget(_host(BackupScreen(
        backupStatusStore: store,
        exportBackup: () async => Uint8List.fromList([1]),
        saveBackup: (_, __) => saved.future,
      )));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(FilledButton, S.current.Backup_Save_As));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      saved.complete(true);
      await tester.pumpAndSettle();
      expect(store.recorded.single.destination, BackupExportDestination.saved);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });

  for (final saved in [true, false]) {
    testWidgets('Mac Save As reports ${saved ? 'saved' : 'cancelled'}',
        (tester) async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      var shares = 0;
      String? filename;
      await tester.pumpWidget(_host(BackupScreen(
        exportBackup: () async => bytes,
        saveBackup: (content, suggestedName) async {
          expect(content, bytes);
          filename = suggestedName;
          return saved;
        },
        shareBackup: (_) async {
          shares++;
          return ShareResult.unavailable;
        },
      )));
      await tester.pumpAndSettle();
      final button =
          find.widgetWithText(FilledButton, S.current.Backup_Save_As);
      expect(find.text(S.current.Backup_Export_Desktop_Description),
          findsOneWidget);
      expect(find.text(S.current.Backup_Export_Description), findsNothing);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(shares, 0);
      expect(filename,
          matches(r'^Onlynote-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.onlynote$'));
      expect(
          find.text(saved
              ? S.current.Backup_Export_Saved
              : S.current.Backup_Export_Save_Cancelled),
          findsOneWidget);
      expect(find.text(S.current.Backup_Export_Shared), findsNothing);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }

  testWidgets('Mac save failure can retry without reporting a shared backup',
      (tester) async {
    var saves = 0;
    await tester.pumpWidget(_host(BackupScreen(
      exportBackup: () async => Uint8List.fromList([1]),
      saveBackup: (_, __) async {
        saves++;
        if (saves == 1) throw StateError('Disk full');
        return true;
      },
    )));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, S.current.Backup_Save_As);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text(S.current.Backup_Export_Save_Failed), findsOneWidget);
    expect(find.text(S.current.Backup_Export_Share_Failed), findsNothing);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await _drainFeedback(tester);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(saves, 2);
    expect(find.text(S.current.Backup_Export_Saved), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Mac pending save blocks repeated exports and handles disposal',
      (tester) async {
    final saved = Completer<bool>();
    var exports = 0;
    await tester.pumpWidget(_host(BackupScreen(
      exportBackup: () async {
        exports++;
        return Uint8List.fromList([1]);
      },
      saveBackup: (_, __) => saved.future,
    )));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, S.current.Backup_Save_As);
    final export = tester.widget<FilledButton>(button).onPressed!;
    export();
    await tester.pump();
    export();
    await tester.pump();
    expect(exports, 1);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    expect(
        await DesktopCommands.instance.prepareToExit(), AppExitResponse.cancel);
    await tester.pumpWidget(const SizedBox.shrink());
    saved.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(
        await DesktopCommands.instance.prepareToExit(), AppExitResponse.exit);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Mac allows Quit after a pending backup finishes saving',
      (tester) async {
    final saved = Completer<bool>();
    await tester.pumpWidget(_host(BackupScreen(
      exportBackup: () async => Uint8List.fromList([1]),
      saveBackup: (_, __) => saved.future,
    )));
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(FilledButton, S.current.Backup_Save_As));
    await tester.pump();
    expect(
        await DesktopCommands.instance.prepareToExit(), AppExitResponse.cancel);
    saved.complete(true);
    await tester.pumpAndSettle();
    expect(
        await DesktopCommands.instance.prepareToExit(), AppExitResponse.exit);
    expect(find.text(S.current.Backup_Export_Saved), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  for (final (status, message) in [
    (ShareResultStatus.success, (S strings) => strings.Backup_Export_Shared),
    (
      ShareResultStatus.dismissed,
      (S strings) => strings.Backup_Export_Cancelled
    ),
    (
      ShareResultStatus.unavailable,
      (S strings) => strings.Backup_Export_Prepared
    ),
  ]) {
    testWidgets('export reports $status and preserves the prepared share file',
        (tester) async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      var exports = 0;
      ShareParams? captured;
      await tester.pumpWidget(_host(BackupScreen(
        exportBackup: () async {
          exports++;
          return bytes;
        },
        shareBackup: (params) async {
          captured = params;
          return ShareResult('test-action', status);
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportButton);
      await tester.pumpAndSettle();

      expect(exports, 1);
      expect(find.text(message(S.current)), findsOneWidget);
      expect(find.text(S.current.Backup_Export_Failed), findsNothing);
      expect(find.text(S.current.Backup_Export_Share_Failed), findsNothing);
      expect(tester.widget<FilledButton>(_exportButton).onPressed, isNotNull);
      expect(
          tester.widget<OutlinedButton>(_restoreButton).onPressed, isNotNull);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      final params = captured!;
      expect(params.files, hasLength(1));
      expect(params.fileNameOverrides, hasLength(1));
      final filename = params.fileNameOverrides!.single;
      expect(filename,
          matches(r'^Onlynote-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.onlynote$'));
      // Native XFile.fromData ignores name; the override supplies the filename.
      expect(await params.files!.single.length(), bytes.length);
      expect(params.files!.single.mimeType, 'application/octet-stream');
      expect(await params.files!.single.readAsBytes(), bytes);
      expect(params.sharePositionOrigin, isNotNull);
      expect(params.sharePositionOrigin!.width, greaterThan(0));
      expect(params.sharePositionOrigin!.height, greaterThan(0));
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });
  }

  testWidgets(
      'pending preparation and sharing reject repeat taps and can export again',
      (tester) async {
    final prepared = Completer<Uint8List>();
    final shared = Completer<ShareResult>();
    var exports = 0;
    var shares = 0;
    final bytes = Uint8List.fromList([1]);
    await tester.pumpWidget(_host(BackupScreen(
      exportBackup: () {
        exports++;
        return exports == 1 ? prepared.future : Future.value(bytes);
      },
      shareBackup: (_) {
        shares++;
        return shares == 1
            ? shared.future
            : Future.value(ShareResult.unavailable);
      },
    )));
    await tester.pumpAndSettle();
    final initialButton = tester.widget<FilledButton>(_exportButton);
    initialButton.onPressed!();
    initialButton.onPressed!();
    await tester.pump();
    expect(exports, 1);
    expect(shares, 0);
    expect(tester.widget<FilledButton>(_exportButton).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(_restoreButton).onPressed, isNull);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text(S.current.Backup_Preparing), findsOneWidget);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

    prepared.complete(bytes);
    await tester.pump();
    expect(shares, 1);
    initialButton.onPressed!();
    await tester.pump();
    expect(exports, 1);
    expect(tester.widget<FilledButton>(_exportButton).onPressed, isNull);

    shared.complete(const ShareResult('', ShareResultStatus.dismissed));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Backup_Export_Cancelled), findsOneWidget);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    await tester.tap(_exportButton);
    await tester.pumpAndSettle();
    expect(exports, 2);
    expect(shares, 2);
    expect(find.text(S.current.Backup_Export_Prepared), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  testWidgets('creation failure does not share and retry succeeds',
      (tester) async {
    var exports = 0;
    var shares = 0;
    await tester.pumpWidget(_host(BackupScreen(
      exportBackup: () async {
        exports++;
        if (exports == 1) throw StateError('Preparation failed');
        return Uint8List.fromList([1]);
      },
      shareBackup: (_) async {
        shares++;
        return const ShareResult('test-action', ShareResultStatus.success);
      },
    )));
    await tester.pumpAndSettle();
    await tester.tap(_exportButton);
    await tester.pumpAndSettle();
    expect(find.text(S.current.Backup_Export_Failed), findsOneWidget);
    expect(find.text(S.current.Backup_Export_Share_Failed), findsNothing);
    expect(shares, 0);
    expect(tester.widget<FilledButton>(_exportButton).onPressed, isNotNull);
    await _drainFeedback(tester);

    await tester.tap(_exportButton);
    await tester.pumpAndSettle();
    expect(exports, 2);
    expect(shares, 1);
    expect(find.text(S.current.Backup_Export_Shared), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  testWidgets('share failure reports preparation accurately and retry succeeds',
      (tester) async {
    var exports = 0;
    var shares = 0;
    await tester.pumpWidget(_host(BackupScreen(
      exportBackup: () async {
        exports++;
        return Uint8List.fromList([1]);
      },
      shareBackup: (_) async {
        shares++;
        if (shares == 1) throw StateError('Sharing failed');
        return ShareResult.unavailable;
      },
    )));
    await tester.pumpAndSettle();
    await tester.tap(_exportButton);
    await tester.pumpAndSettle();
    expect(find.text(S.current.Backup_Export_Share_Failed), findsOneWidget);
    expect(find.text(S.current.Backup_Export_Failed), findsNothing);
    expect(tester.widget<FilledButton>(_exportButton).onPressed, isNotNull);
    await _drainFeedback(tester);

    await tester.tap(_exportButton);
    await tester.pumpAndSettle();
    expect(exports, 2);
    expect(shares, 2);
    expect(find.text(S.current.Backup_Export_Prepared), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  testWidgets('disposal during preparation prevents starting a share',
      (tester) async {
    final prepared = Completer<Uint8List>();
    var shares = 0;
    await tester.pumpWidget(_host(BackupScreen(
      exportBackup: () => prepared.future,
      shareBackup: (_) async {
        shares++;
        return ShareResult.unavailable;
      },
    )));
    await tester.pumpAndSettle();
    await tester.tap(_exportButton);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    prepared.complete(Uint8List.fromList([1]));
    await tester.pumpAndSettle();
    expect(shares, 0);
    expect(tester.takeException(), isNull);
  });

  for (final fail in [false, true]) {
    testWidgets(
        'disposal during sharing safely handles ${fail ? 'an error' : 'a result'}',
        (tester) async {
      final shared = Completer<ShareResult>();
      var shares = 0;
      await tester.pumpWidget(_host(BackupScreen(
        exportBackup: () async => Uint8List.fromList([1]),
        shareBackup: (_) {
          shares++;
          return shared.future;
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportButton);
      await tester.pump();
      expect(shares, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      if (fail) {
        shared.completeError(StateError('Sharing failed'));
      } else {
        shared.complete(
            const ShareResult('test-action', ShareResultStatus.success));
      }
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  group('readable note export', () {
    late Directory directory;
    late File archiveFile;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('onlynote-export-ui');
      archiveFile = File('${directory.path}/Onlynote-notes.zip');
      await archiveFile.writeAsBytes([1, 2, 3, 4]);
    });

    /// Every section fits without scrolling, so a tap always lands on the
    /// button it names rather than on whatever the list happens to show.
    void showWholeScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    testWidgets('readable exports do not change the full backup status',
        (tester) async {
      final preferences = MemoryPreferences();
      final store = BackupExportStatusStore(preferences: preferences);
      final priorDate = DateTime.utc(2025, 1, 2);
      await store.record(BackupExportRecord(
          exportedAt: priorDate, destination: BackupExportDestination.saved));
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        backupStatusStore: store,
        exportNotes: (format, onProgress) async => _archive(archiveFile),
        shareNotes: (_) async =>
            const ShareResult('action', ShareResultStatus.success),
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(find.text(S.current.Export_Notes_Shared), findsOneWidget);
      expect(_visibleRecord(tester)!.exportedAt, priorDate);
      expect(
          _visibleRecord(tester)!.destination, BackupExportDestination.saved);
      expect(
          (await BackupExportStatusStore(preferences: preferences).read())!
              .exportedAt,
          priorDate);
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });

    for (final saved in [true, false]) {
      testWidgets('Mac save reports ${saved ? 'saved' : 'cancelled'}',
          (tester) async {
        File? savedFile;
        String? suggested;
        showWholeScreen(tester);
        await tester.pumpWidget(_host(BackupScreen(
          exportNotes: (format, onProgress) async {
            onProgress(1, 2);
            onProgress(2, 2);
            return _archive(archiveFile);
          },
          saveNotes: (file, name) async {
            savedFile = file;
            suggested = name;
            return saved;
          },
        )));
        await tester.pumpAndSettle();
        expect(find.text(S.current.Export_Notes_Desktop_Description),
            findsOneWidget);
        expect(find.text(S.current.Export_Notes_Description), findsNothing);
        await tester.tap(_saveNotesButton);
        await tester.pumpAndSettle();
        expect(savedFile!.path, archiveFile.path);
        expect(suggested, 'Onlynote-notes.zip');
        expect(
            find.text(saved
                ? S.current.Export_Notes_Saved
                : S.current.Export_Notes_Save_Cancelled),
            findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
        await _drainFeedback(tester);
      }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
    }

    for (final (status, message) in [
      (ShareResultStatus.success, (S strings) => strings.Export_Notes_Shared),
      (
        ShareResultStatus.dismissed,
        (S strings) => strings.Export_Notes_Cancelled
      ),
      (
        ShareResultStatus.unavailable,
        (S strings) => strings.Export_Notes_Prepared
      ),
    ]) {
      testWidgets('sharing the archive reports $status', (tester) async {
        ShareParams? captured;
        showWholeScreen(tester);
        await tester.pumpWidget(_host(BackupScreen(
          exportNotes: (format, onProgress) async => _archive(archiveFile),
          shareNotes: (params) async {
            captured = params;
            return ShareResult('test-action', status);
          },
        )));
        await tester.pumpAndSettle();
        await tester.tap(_exportNotesButton);
        await tester.pumpAndSettle();
        expect(find.text(message(S.current)), findsOneWidget);
        expect(find.text(S.current.Export_Notes_Failed), findsNothing);
        final params = captured!;
        expect(params.fileNameOverrides, ['Onlynote-notes.zip']);
        expect(params.files!.single.mimeType, 'application/zip');
        // The archive is shared from disk, so the prepared file survives.
        expect(params.files!.single.path, archiveFile.path);
        expect(params.sharePositionOrigin, isNotNull);
        expect(tester.takeException(), isNull);
        await _drainFeedback(tester);
      });
    }

    testWidgets('the chosen format reaches the builder', (tester) async {
      final formats = <NoteBulkExportFormat>[];
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore:
            NoteExportFormatStore(preferences: MemoryPreferences()),
        exportNotes: (format, onProgress) async {
          formats.add(format);
          return _archive(archiveFile);
        },
        shareNotes: (_) async =>
            const ShareResult('test-action', ShareResultStatus.success),
      )));
      await tester.pumpAndSettle();
      // Markdown is the default, because it keeps the most of a note.
      expect(
          tester
              .widget<ChoiceChip>(_formatChip(NoteBulkExportFormat.markdown))
              .selected,
          isTrue);
      await tester.tap(_formatChip(NoteBulkExportFormat.pdf));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(formats, [NoteBulkExportFormat.pdf]);
      await _drainFeedback(tester);
    });

    testWidgets('reopening shares pending format writes and the latest choice',
        (tester) async {
      final preferences = _PendingFormatPreferences();
      final store = NoteExportFormatStore(preferences: preferences);
      final formats = <NoteBulkExportFormat>[];
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(exportFormatStore: store)));
      await tester.pumpAndSettle();
      await tester.tap(_formatChip(NoteBulkExportFormat.pdf));
      await tester.pump();
      await tester.tap(_formatChip(NoteBulkExportFormat.plainText));
      await tester.pump();
      expect(preferences.writes, ['pdf']);
      expect(preferences.values[NoteExportFormatStore.storageKey], isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore: store,
        exportNotes: (format, onProgress) async {
          formats.add(format);
          return _archive(archiveFile);
        },
        shareNotes: (_) async => ShareResult.unavailable,
      )));
      await tester.pumpAndSettle();
      expect(_visibleFormat(tester), NoteBulkExportFormat.plainText);
      await tester.tap(_formatChip(NoteBulkExportFormat.markdown));
      await tester.pump();
      expect(_visibleFormat(tester), NoteBulkExportFormat.markdown);
      expect(preferences.writes, ['pdf']);
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(formats, [NoteBulkExportFormat.markdown]);

      preferences.firstWrite.complete();
      await tester.pumpAndSettle();
      expect(preferences.writes, ['pdf', 'plainText', 'markdown']);
      expect(preferences.values[NoteExportFormatStore.storageKey], 'markdown');
      await _drainFeedback(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore: NoteExportFormatStore(preferences: preferences),
      )));
      await tester.pumpAndSettle();
      expect(_visibleFormat(tester), NoteBulkExportFormat.markdown);
      expect(tester.takeException(), isNull);
    });

    for (final format in NoteBulkExportFormat.values) {
      testWidgets('$format is remembered and used after reopening',
          (tester) async {
        final preferences = MemoryPreferences()
          ..values[NoteExportFormatStore.storageKey] =
              NoteBulkExportFormat.pdf.name;
        final formats = <NoteBulkExportFormat>[];
        showWholeScreen(tester);
        await tester.pumpWidget(_host(BackupScreen(
          exportFormatStore: NoteExportFormatStore(preferences: preferences),
        )));
        await tester.pumpAndSettle();
        expect(_visibleFormat(tester), NoteBulkExportFormat.pdf);
        await tester.tap(_formatChip(format));
        await tester.pumpAndSettle();
        expect(_visibleFormat(tester), format);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(_host(BackupScreen(
          exportFormatStore: NoteExportFormatStore(preferences: preferences),
          exportNotes: (selected, onProgress) async {
            formats.add(selected);
            return _archive(archiveFile);
          },
          shareNotes: (_) async => ShareResult.unavailable,
        )));
        await tester.pumpAndSettle();
        expect(_visibleFormat(tester), format);
        expect(tester.widget<ChoiceChip>(_formatChip(format)).selected, isTrue);
        await tester.tap(_exportNotesButton);
        await tester.pumpAndSettle();
        expect(formats, [format]);
        expect(tester.takeException(), isNull);
        await _drainFeedback(tester);
      });
    }

    testWidgets('preference failures keep the chosen format exportable',
        (tester) async {
      final formats = <NoteBulkExportFormat>[];
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore: _FailingFormatStore(),
        exportNotes: (format, onProgress) async {
          formats.add(format);
          return _archive(archiveFile);
        },
        shareNotes: (_) async => ShareResult.unavailable,
      )));
      await tester.pumpAndSettle();
      expect(_visibleFormat(tester), NoteBulkExportFormat.markdown);
      await tester.tap(_formatChip(NoteBulkExportFormat.plainText));
      await tester.pumpAndSettle();
      expect(_visibleFormat(tester), NoteBulkExportFormat.plainText);
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(formats, [NoteBulkExportFormat.plainText]);
      expect(find.text(S.current.Export_Notes_Prepared), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });

    testWidgets('a late preference read never replaces an explicit choice',
        (tester) async {
      final store = _ControlledFormatStore();
      final formats = <NoteBulkExportFormat>[];
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore: store,
        exportNotes: (format, onProgress) async {
          formats.add(format);
          return _archive(archiveFile);
        },
        shareNotes: (_) async => ShareResult.unavailable,
      )));
      await tester.pumpAndSettle();
      await tester.tap(_formatChip(NoteBulkExportFormat.pdf));
      await tester.pumpAndSettle();
      store.initialRead.complete(NoteBulkExportFormat.plainText);
      await tester.pumpAndSettle();
      expect(_visibleFormat(tester), NoteBulkExportFormat.pdf);
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(formats, [NoteBulkExportFormat.pdf]);
      expect(store.written, [NoteBulkExportFormat.pdf]);
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });

    testWidgets('full backup work does not discard a delayed format preference',
        (tester) async {
      final store = _ControlledFormatStore();
      final backup = Completer<Uint8List>();
      final formats = <NoteBulkExportFormat>[];
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore: store,
        exportBackup: () => backup.future,
        shareBackup: (_) async => ShareResult.unavailable,
        exportNotes: (format, onProgress) async {
          formats.add(format);
          return _archive(archiveFile);
        },
        shareNotes: (_) async => ShareResult.unavailable,
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportButton);
      await tester.pump();
      store.initialRead.complete(NoteBulkExportFormat.pdf);
      await tester.pump();
      expect(_visibleFormat(tester), NoteBulkExportFormat.pdf);
      backup.complete(Uint8List.fromList([1]));
      await tester.pumpAndSettle();
      await _drainFeedback(tester);
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(formats, [NoteBulkExportFormat.pdf]);
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });

    testWidgets(
        'a late read cannot change a pending or completed export choice',
        (tester) async {
      final store = _ControlledFormatStore();
      final pending = Completer<NoteArchiveExport?>();
      final formats = <NoteBulkExportFormat>[];
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore: store,
        exportNotes: (format, onProgress) {
          formats.add(format);
          return pending.future;
        },
        shareNotes: (_) async => ShareResult.unavailable,
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pump();
      expect(formats, [NoteBulkExportFormat.markdown]);
      store.initialRead.complete(NoteBulkExportFormat.pdf);
      await tester.pump();
      await tester.tap(_formatChip(NoteBulkExportFormat.plainText));
      await tester.pump();
      expect(_visibleFormat(tester), NoteBulkExportFormat.markdown);
      expect(store.written, isEmpty);
      pending.complete(_archive(archiveFile));
      await tester.pumpAndSettle();
      expect(_visibleFormat(tester), NoteBulkExportFormat.markdown);
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });

    testWidgets('a preference read after export completes keeps its format',
        (tester) async {
      final store = _ControlledFormatStore();
      final formats = <NoteBulkExportFormat>[];
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore: store,
        exportNotes: (format, onProgress) async {
          formats.add(format);
          return _archive(archiveFile);
        },
        shareNotes: (_) async => ShareResult.unavailable,
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      store.initialRead.complete(NoteBulkExportFormat.pdf);
      await tester.pumpAndSettle();
      expect(formats, [NoteBulkExportFormat.markdown]);
      expect(_visibleFormat(tester), NoteBulkExportFormat.markdown);
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });

    testWidgets('rapid choices apply immediately while preference writes wait',
        (tester) async {
      final store = _ControlledFormatStore()
        ..initialRead.complete(NoteBulkExportFormat.markdown)
        ..pendingWrite = Completer<void>();
      final formats = <NoteBulkExportFormat>[];
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore: store,
        exportNotes: (format, onProgress) async {
          formats.add(format);
          return _archive(archiveFile);
        },
        shareNotes: (_) async => ShareResult.unavailable,
      )));
      await tester.pumpAndSettle();
      for (final format in [
        NoteBulkExportFormat.pdf,
        NoteBulkExportFormat.markdown,
        NoteBulkExportFormat.plainText,
      ]) {
        await tester.tap(_formatChip(format));
        await tester.pump();
        expect(_visibleFormat(tester), format);
      }
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(formats, [NoteBulkExportFormat.plainText]);
      expect(store.written, [
        NoteBulkExportFormat.pdf,
        NoteBulkExportFormat.markdown,
        NoteBulkExportFormat.plainText,
      ]);
      store.pendingWrite!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);
    });

    for (final fail in [false, true]) {
      testWidgets('format read after disposal safely handles error: $fail',
          (tester) async {
        final store = _ControlledFormatStore();
        showWholeScreen(tester);
        await tester.pumpWidget(_host(BackupScreen(exportFormatStore: store)));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        if (fail) {
          store.initialRead.completeError(StateError('Read failed'));
        } else {
          store.initialRead.complete(NoteBulkExportFormat.pdf);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('disposal during a chosen export and delayed read is safe',
        (tester) async {
      final store = _ControlledFormatStore()..pendingWrite = Completer<void>();
      final pending = Completer<NoteArchiveExport?>();
      final formats = <NoteBulkExportFormat>[];
      var shares = 0;
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportFormatStore: store,
        exportNotes: (format, onProgress) {
          formats.add(format);
          return pending.future;
        },
        shareNotes: (_) async {
          shares++;
          return ShareResult.unavailable;
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(_formatChip(NoteBulkExportFormat.pdf));
      await tester.pump();
      await tester.tap(_exportNotesButton);
      await tester.pump();
      expect(formats, [NoteBulkExportFormat.pdf]);
      await tester.pumpWidget(const SizedBox.shrink());
      store.initialRead.complete(NoteBulkExportFormat.plainText);
      store.pendingWrite!.complete();
      pending.complete(_archive(archiveFile));
      await tester.pumpAndSettle();
      expect(shares, 0);
      expect(store.written, [NoteBulkExportFormat.pdf]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty library says so instead of sharing', (tester) async {
      var shares = 0;
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportNotes: (format, onProgress) async => null,
        shareNotes: (_) async {
          shares++;
          return const ShareResult('test-action', ShareResultStatus.success);
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(shares, 0);
      expect(find.text(S.current.Export_Notes_Empty), findsOneWidget);
      await _drainFeedback(tester);
    });

    testWidgets('notes that could not be exported are counted in the result',
        (tester) async {
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportNotes: (format, onProgress) async =>
            _archive(archiveFile, exported: 8, failed: 2),
        shareNotes: (_) async =>
            const ShareResult('test-action', ShareResultStatus.success),
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(
          find.text('${S.current.Export_Notes_Shared} '
              '${S.current.Export_Notes_Incomplete(2)}'),
          findsOneWidget);
      await _drainFeedback(tester);
    });

    testWidgets('an export where every note failed reports a failure',
        (tester) async {
      var shares = 0;
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportNotes: (format, onProgress) async =>
            _archive(archiveFile, exported: 0, failed: 3),
        shareNotes: (_) async {
          shares++;
          return const ShareResult('test-action', ShareResultStatus.success);
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(shares, 0);
      expect(find.text(S.current.Export_Notes_Failed), findsOneWidget);
      await _drainFeedback(tester);
    });

    testWidgets('a failed build reports failure and can be retried',
        (tester) async {
      var attempts = 0;
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportNotes: (format, onProgress) async {
          attempts++;
          if (attempts == 1) throw StateError('Disk full');
          return _archive(archiveFile);
        },
        shareNotes: (_) async =>
            const ShareResult('test-action', ShareResultStatus.success),
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(find.text(S.current.Export_Notes_Failed), findsOneWidget);
      expect(tester.widget<OutlinedButton>(_exportNotesButton).onPressed,
          isNotNull);
      await tester.tap(_exportNotesButton);
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text(S.current.Export_Notes_Shared), findsOneWidget);
      await _drainFeedback(tester);
    });

    testWidgets('a pending export blocks the backup actions and vice versa',
        (tester) async {
      final pending = Completer<NoteArchiveExport?>();
      var backups = 0;
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportNotes: (format, onProgress) => pending.future,
        shareNotes: (_) async =>
            const ShareResult('test-action', ShareResultStatus.success),
        exportBackup: () async {
          backups++;
          return Uint8List.fromList([1]);
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(_exportButton).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(_restoreButton).onPressed, isNull);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      await tester.tap(_exportButton, warnIfMissed: false);
      await tester.pump();
      expect(backups, 0);
      pending.complete(_archive(archiveFile));
      await tester.pumpAndSettle();
      expect(find.text(S.current.Export_Notes_Shared), findsOneWidget);
      expect(tester.widget<FilledButton>(_exportButton).onPressed, isNotNull);
      await _drainFeedback(tester);
    });

    testWidgets('progress counts notes as the export walks the library',
        (tester) async {
      final pending = Completer<NoteArchiveExport?>();
      late void Function(int, int) report;
      showWholeScreen(tester);
      await tester.pumpWidget(_host(BackupScreen(
        exportNotes: (format, onProgress) {
          report = onProgress;
          return pending.future;
        },
        shareNotes: (_) async =>
            const ShareResult('test-action', ShareResultStatus.success),
      )));
      await tester.pumpAndSettle();
      await tester.tap(_exportNotesButton);
      await tester.pump();
      expect(find.text(S.current.Export_Notes_Preparing), findsOneWidget);
      report(3, 40);
      await tester.pump();
      expect(find.text('3 / 40'), findsOneWidget);
      pending.complete(_archive(archiveFile));
      await tester.pumpAndSettle();
      await _drainFeedback(tester);
    });
  });
}
