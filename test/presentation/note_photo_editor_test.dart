import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_photo_editor.dart';
import 'package:onlynote/services/note_photo_transform.dart';

Future<ui.Image> _photo() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 300, 200),
      ui.Paint()..color = const Color(0xff86b8ae));
  final picture = recorder.endRecording();
  final photo = await picture.toImage(300, 200);
  picture.dispose();
  return photo;
}

Future<void> _pump(WidgetTester tester,
    Future<NoteEditedPhoto> Function(ui.Image, NotePhotoTransform) save,
    {Size size = const Size(390, 844),
    bool chinese = false,
    bool releaseSourceOnResult = false,
    ValueChanged<NoteEditedPhoto?>? onResult}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final photo = await tester.runAsync(_photo);
  var sourceReleased = false;
  addTearDown(() {
    if (!sourceReleased) photo!.dispose();
  });
  await tester.pumpWidget(MaterialApp(
    locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    home: Builder(
        builder: (context) => Scaffold(
              body: Center(
                  child: ElevatedButton(
                      onPressed: () async {
                        final result = await showDialog<NoteEditedPhoto>(
                            context: context,
                            builder: (_) =>
                                NotePhotoEditor(image: photo!, save: save));
                        if (releaseSourceOnResult && !sourceReleased) {
                          photo!.dispose();
                          sourceReleased = true;
                        }
                        onResult?.call(result);
                      },
                      child: const Text('Open editor'))),
            )),
  ));
  await tester.tap(find.text('Open editor'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('unchanged save and cancel do not write photo copies',
      (tester) async {
    var writes = 0;
    NoteEditedPhoto? result;
    await _pump(tester, (_, transform) async {
      writes++;
      return const NoteEditedPhoto(path: 'copy', aspectRatio: 1);
    }, onResult: (value) => result = value);
    await tester.tap(find.byKey(const ValueKey('photo-edit-save')));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(result, isNull);
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo-edit-rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('photo-edit-cancel')));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(result, isNull);
  });

  testWidgets('dragging a crop corner and rotating saves the selected region',
      (tester) async {
    NotePhotoTransform? saved;
    await _pump(tester, (_, transform) async {
      saved = transform;
      return const NoteEditedPhoto(path: 'cropped', aspectRatio: 1);
    });
    await tester.drag(find.byKey(const ValueKey('photo-crop-bottomRight')),
        const Offset(-90, -55));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('photo-edit-rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('photo-edit-save')));
    await tester.pumpAndSettle();
    expect(saved!.rotation, 1);
    expect(saved!.crop.width, lessThan(1));
    expect(saved!.crop.height, lessThan(1));
    expect(saved!.crop.left, greaterThan(0));
    expect(find.byType(NotePhotoEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset restores original pixels and save failures allow retry',
      (tester) async {
    var writes = 0;
    var fail = true;
    await _pump(tester, (_, transform) async {
      writes++;
      if (fail) throw StateError('Disk full');
      return const NoteEditedPhoto(path: 'edited', aspectRatio: .66);
    });
    await tester.tap(find.byKey(const ValueKey('photo-edit-rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('photo-edit-reset')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('photo-edit-rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('photo-edit-save')));
    await tester.pumpAndSettle();
    expect(find.byType(NotePhotoEditor), findsOneWidget);
    expect(writes, 1);
    final strings = S.of(tester.element(find.byType(NotePhotoEditor)));
    expect(find.text(strings.Photo_Edit_Failed), findsOneWidget);
    fail = false;
    await tester.tap(find.byKey(const ValueKey('photo-edit-save')));
    await tester.pumpAndSettle();
    expect(writes, 2);
    expect(find.byType(NotePhotoEditor), findsNothing);
  });

  testWidgets('crop controls fit a narrow Chinese window', (tester) async {
    await _pump(
        tester,
        (_, transform) async =>
            const NoteEditedPhoto(path: 'edited', aspectRatio: 1),
        size: const Size(320, 540),
        chinese: true);
    await tester.tap(find.byKey(const ValueKey('photo-edit-rotate')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('photo-crop-bottomRight')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('caller can dispose source when Save returns during dialog fade',
      (tester) async {
    var returned = false;
    ui.Image? savedHandle;
    await _pump(tester, (image, transform) async {
      savedHandle = image;
      expect(image.width, 300);
      expect(image.height, 200);
      return const NoteEditedPhoto(path: 'edited', aspectRatio: 2 / 3);
    }, releaseSourceOnResult: true, onResult: (_) => returned = true);
    await tester.tap(find.byKey(const ValueKey('photo-edit-rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('photo-edit-save')));
    await tester.pump();
    expect(returned, isTrue);
    expect(savedHandle, isNotNull);
    // The dialog still exists while the caller has already released its source.
    expect(find.byType(NotePhotoEditor), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byType(NotePhotoEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
