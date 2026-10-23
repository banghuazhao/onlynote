import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_photo_transform.dart';
import 'note_photo_editor.dart';

@Preview(name: 'Simple photo crop — phone', size: Size(390, 844))
Widget photoEditorPhonePreview() => _preview();

@Preview(name: 'Simple photo crop — narrow Chinese', size: Size(320, 540))
Widget photoEditorChinesePreview() => _preview(chinese: true);

@Preview(name: 'Simple photo crop — landscape 2×', size: Size(812, 300))
Widget photoEditorLandscapePreview() => _preview(scale: 2);

@Preview(name: 'Simple photo crop — narrow Chinese 2×', size: Size(280, 360))
Widget photoEditorLargeTextPreview() => _preview(chinese: true, scale: 2);

@Preview(
    name: 'Simple photo crop — dark tablet',
    size: Size(760, 900),
    brightness: Brightness.dark)
Widget photoEditorTabletPreview() => _preview(dark: true);

Widget _preview({bool chinese = false, bool dark = false, double scale = 1}) =>
    MaterialApp(
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const _PhotoPreview(),
    );

class _PhotoPreview extends StatefulWidget {
  const _PhotoPreview();
  @override
  State<_PhotoPreview> createState() => _PhotoPreviewState();
}

class _PhotoPreviewState extends State<_PhotoPreview> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _createPhoto();
  }

  Future<void> _createPhoto() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const rect = Rect.fromLTWH(0, 0, 600, 400);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff96bfcd), Color(0xffe5dfbd)],
          ).createShader(rect));
    canvas.drawPath(
        Path()
          ..moveTo(0, 310)
          ..lineTo(180, 130)
          ..lineTo(330, 320)
          ..lineTo(480, 210)
          ..lineTo(600, 340)
          ..lineTo(600, 400)
          ..lineTo(0, 400)
          ..close(),
        Paint()..color = const Color(0xff6c877d));
    canvas.drawCircle(
        const Offset(460, 90), 38, Paint()..color = const Color(0xffefd493));
    final picture = recorder.endRecording();
    final image = await picture.toImage(600, 400);
    picture.dispose();
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() => _image = image);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (!mounted || _image == null) return;
    await showDialog<NoteEditedPhoto>(
      context: context,
      builder: (_) => NotePhotoEditor(
          image: _image!,
          save: (_, transform) async {
            final rotated = transform.rotation.isOdd;
            return NoteEditedPhoto(
                path: 'preview-photo',
                aspectRatio: (rotated ? 2 / 3 : 3 / 2) *
                    transform.crop.width /
                    transform.crop.height);
          }),
    );
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: _image == null
                ? const CircularProgressIndicator()
                : OutlinedButton.icon(
                    onPressed: _open,
                    icon: const Icon(Icons.crop_rotate_rounded),
                    label: Text(S.of(context).Photo_Edit))),
      );
}
