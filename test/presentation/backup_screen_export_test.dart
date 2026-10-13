import 'dart:async';
import 'dart:ui' show AppExitResponse;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/presentation/screens/settings/backup_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:share_plus/share_plus.dart';

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

Future<void> _drainFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
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
}
