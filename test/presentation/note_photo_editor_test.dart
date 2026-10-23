import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_photo_editor.dart';
import 'package:onlynote/services/note_photo_transform.dart';

import '../support/interaction_feedback_capture.dart';

class _RouteEvents extends NavigatorObserver {
  final popped = <String?>[];
  final removed = <String?>[];

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped.add(route.settings.name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    removed.add(route.settings.name);
  }
}

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
    double scale = 1,
    bool releaseSourceOnResult = false,
    NavigatorObserver? observer,
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
  await tester.pumpWidget(RepaintBoundary(
      key: interactionFeedbackCaptureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorObservers: [if (observer != null) observer],
        theme: const bool.fromEnvironment('CAPTURE_UI')
            ? interactionFeedbackTheme(dark: false)
            : null,
        locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
            builder: (context) => Scaffold(
                  body: Center(
                      child: ElevatedButton(
                          onPressed: () async {
                            final result = await showDialog<NoteEditedPhoto>(
                                context: context,
                                routeSettings:
                                    const RouteSettings(name: 'photo-editor'),
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
      )));
  await tester.tap(find.text('Open editor'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadInteractionFeedbackFonts);

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

  for (final edited in [false, true]) {
    testWidgets(
        'retained Save and Cancel callbacks close ${edited ? 'edited' : 'unchanged'} photo once',
        (tester) async {
      var writes = 0;
      final results = <NoteEditedPhoto?>[];
      final routes = _RouteEvents();
      await _pump(tester, (_, transform) async {
        writes++;
        return const NoteEditedPhoto(path: 'edited', aspectRatio: 2 / 3);
      }, observer: routes, onResult: results.add);
      if (edited) {
        await tester.tap(find.byKey(const ValueKey('photo-edit-rotate')));
        await tester.pump();
      }
      final save = tester
          .widget<TextButton>(find.byKey(const ValueKey('photo-edit-save')))
          .onPressed!;
      final cancel = tester
          .widget<IconButton>(find.byKey(const ValueKey('photo-edit-cancel')))
          .onPressed!;
      save();
      save();
      cancel();
      await tester.pumpAndSettle();
      expect(writes, edited ? 1 : 0);
      expect(results, hasLength(1));
      expect(results.single?.path, edited ? 'edited' : null);
      expect(routes.popped, ['photo-editor']);
      expect(find.text('Open editor'), findsOneWidget);
      expect(find.byType(NotePhotoEditor), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'covered ${edited ? 'edited' : 'unchanged'} photo ignores retained Save and Cancel',
        (tester) async {
      var writes = 0;
      final routes = _RouteEvents();
      await _pump(tester, (_, transform) async {
        writes++;
        return const NoteEditedPhoto(path: 'edited', aspectRatio: 2 / 3);
      }, observer: routes);
      if (edited) {
        await tester.tap(find.byKey(const ValueKey('photo-edit-rotate')));
        await tester.pump();
      }
      final save = tester
          .widget<TextButton>(find.byKey(const ValueKey('photo-edit-save')))
          .onPressed!;
      final cancel = tester
          .widget<IconButton>(find.byKey(const ValueKey('photo-edit-cancel')))
          .onPressed!;
      final navigator =
          Navigator.of(tester.element(find.byType(NotePhotoEditor)));
      unawaited(navigator.push<void>(MaterialPageRoute(
        settings: const RouteSettings(name: 'cover'),
        builder: (_) => const Scaffold(body: Text('Cover photo editor')),
      )));
      await tester.pumpAndSettle();
      save();
      save();
      cancel();
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(routes.popped, isEmpty);
      expect(find.text('Cover photo editor'), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      save();
      await tester.pumpAndSettle();
      expect(writes, edited ? 1 : 0);
      expect(routes.popped, ['cover', 'photo-editor']);
      expect(find.text('Open editor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a covered save completion returns only its original photo route',
      (tester) async {
    final pending = Completer<NoteEditedPhoto>();
    var writes = 0;
    final results = <NoteEditedPhoto?>[];
    final routes = _RouteEvents();
    await _pump(tester, (_, transform) {
      writes++;
      return pending.future;
    }, observer: routes, onResult: results.add);
    await tester.tap(find.byKey(const ValueKey('photo-edit-rotate')));
    await tester.pump();
    final save = tester
        .widget<TextButton>(find.byKey(const ValueKey('photo-edit-save')))
        .onPressed!;
    final cancel = tester
        .widget<IconButton>(find.byKey(const ValueKey('photo-edit-cancel')))
        .onPressed!;
    save();
    save();
    cancel();
    expect(writes, 1);
    final navigator =
        Navigator.of(tester.element(find.byType(NotePhotoEditor)));
    unawaited(navigator.push<void>(MaterialPageRoute(
      settings: const RouteSettings(name: 'cover'),
      builder: (_) => const Scaffold(body: Text('Cover photo editor')),
    )));
    await tester.pumpAndSettle();
    pending.complete(const NoteEditedPhoto(path: 'edited', aspectRatio: 2 / 3));
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(results.single?.path, 'edited');
    expect(routes.popped, isEmpty);
    expect(routes.removed, ['photo-editor']);
    expect(find.text('Cover photo editor'), findsOneWidget);
    save();
    cancel();
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(find.text('Cover photo editor'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  for (final (name, size, chinese) in [
    ('landscape', const Size(812, 300), false),
    ('narrow-chinese', const Size(280, 360), true),
  ]) {
    testWidgets('photo crop and save remain reachable at 2× in $name',
        (tester) async {
      var fail = true;
      var writes = 0;
      NotePhotoTransform? saved;
      await _pump(tester, (_, transform) async {
        saved = transform;
        writes++;
        if (fail) throw StateError('Disk full');
        return const NoteEditedPhoto(path: 'edited', aspectRatio: 2 / 3);
      }, size: size, chinese: chinese, scale: 2);
      expect(tester.takeException(), isNull);
      final canvas = find.byKey(const ValueKey('photo-crop-canvas'));
      final bounds = tester.getSize(canvas);
      expect(bounds.width, greaterThanOrEqualTo(48));
      expect(bounds.height, greaterThanOrEqualTo(48));
      final scrolling = Scrollable.of(tester.element(canvas));
      expect(scrolling.position.maxScrollExtent, greaterThan(0));
      scrolling.position.jumpTo(0);
      await tester.pumpAndSettle();
      final viewport =
          tester.getRect(find.byKey(const ValueKey('photo-editor-scroll')));
      await tester.timedDragFrom(Offset(viewport.left + 8, viewport.center.dy),
          const Offset(0, -80), const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(scrolling.position.pixels, greaterThan(0));
      await tester.ensureVisible(canvas);
      await tester.pumpAndSettle();
      expect(canvas.hitTestable(), findsOneWidget);
      await captureInteractionFeedback(tester, 'photo-editor-$name-canvas');
      final corner = find.byKey(const ValueKey('photo-crop-bottomRight'));
      await tester.ensureVisible(corner);
      await tester.pumpAndSettle();
      expect(corner.hitTestable(), findsOneWidget);
      // Continue beyond gesture recognition so the crop receives real updates
      // while competing with the enclosing vertical scroll view.
      await tester.timedDrag(
          corner, const Offset(-52, -52), const Duration(milliseconds: 300));
      await tester.pump();
      final rotate = find.byKey(const ValueKey('photo-edit-rotate'));
      await tester.ensureVisible(rotate);
      await tester.pumpAndSettle();
      expect(rotate.hitTestable(), findsOneWidget);
      await captureInteractionFeedback(tester, 'photo-editor-$name-controls');
      await tester.tap(rotate);
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('photo-edit-save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(saved!.rotation, 1);
      expect(saved!.crop.width, lessThan(1));
      expect(saved!.crop.height, lessThan(1));
      final error = find.text(S.current.Photo_Edit_Failed);
      await tester.ensureVisible(error);
      await tester.pumpAndSettle();
      expect(error.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      final firstCrop = saved!.crop;
      await tester.ensureVisible(corner);
      await tester.pumpAndSettle();
      await tester.timedDrag(
          corner, const Offset(0, -44), const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      fail = false;
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(writes, 2);
      expect(saved!.crop.height, lessThan(firstCrop.height));
      expect(find.byType(NotePhotoEditor), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

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
