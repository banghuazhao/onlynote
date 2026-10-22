import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/backup_settings_tile.dart';
import 'package:onlynote/presentation/components/backup_settings_tile_previews.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  // Widget tests do not get the device's CJK font fallback automatically.
  // Preserve the actual preview controls and metrics, adding bundled fonts
  // only to the capture theme so Chinese labels render as readable glyphs.
  final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
  final theme = app.theme!;
  TextStyle? captureStyle(TextStyle? style) => style?.copyWith(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['DroidSansFallback'],
      );
  await tester.pumpWidget(RepaintBoundary(
    key: const ValueKey('backup-settings-capture'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: app.locale,
      supportedLocales: app.supportedLocales,
      localizationsDelegates: app.localizationsDelegates,
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['DroidSansFallback'],
        ),
        listTileTheme: theme.listTileTheme.copyWith(
          titleTextStyle: captureStyle(theme.listTileTheme.titleTextStyle),
          subtitleTextStyle:
              captureStyle(theme.listTileTheme.subtitleTextStyle),
        ),
      ),
      builder: app.builder,
      home: app.home,
    ),
  ));
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('backup-settings-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-release-feedback');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final (family, asset) in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  testWidgets('backup settings previews remain readable and tappable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (name, preview, size, destination) in [
      (
        'backup-settings-first-use',
        backupSettingsFirstUsePreview,
        const Size(390, 300),
        null,
      ),
      (
        'backup-settings-saved',
        backupSettingsSavedPreview,
        const Size(640, 300),
        BackupExportDestination.saved,
      ),
      (
        'backup-settings-shared-dark',
        backupSettingsSharedPreview,
        const Size(390, 300),
        BackupExportDestination.shared,
      ),
      (
        'backup-settings-chinese-large-text',
        backupSettingsChinesePreview,
        const Size(280, 500),
        BackupExportDestination.shared,
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('backup-settings-capture'),
        child: preview(),
      ));
      await tester.pumpAndSettle();
      final tile = tester.widget<BackupSettingsTile>(
        find.byType(BackupSettingsTile),
      );
      expect(tile.lastExport?.destination, destination);
      expect(
        find.byKey(const ValueKey('settings-backup-status')),
        findsOneWidget,
      );
      if (destination == null) {
        expect(find.text(S.current.Backup_Export_No_Record), findsOneWidget);
      }
      final link = find.byKey(const ValueKey('settings-backup'));
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await _capture(tester, name);
      await tester.tap(link);
      expect(tester.takeException(), isNull);
    }
  });
}
