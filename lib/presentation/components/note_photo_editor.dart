import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_photo_transform.dart';

/// A single-purpose editor: drag the corners to crop, rotate, then save.
/// Receives decoded pixels so its previews and gestures need no native plugins.
class NotePhotoEditor extends StatefulWidget {
  const NotePhotoEditor({
    super.key,
    required this.image,
    required this.save,
  });

  final ui.Image image;
  final Future<NoteEditedPhoto> Function(
      ui.Image image, NotePhotoTransform transform) save;

  @override
  State<NotePhotoEditor> createState() => _NotePhotoEditorState();
}

class _NotePhotoEditorState extends State<NotePhotoEditor> {
  late ui.Image _image;
  NotePhotoTransform _transform = const NotePhotoTransform();
  Rect _gestureCrop = const Rect.fromLTWH(0, 0, 1, 1);
  Offset _gestureOrigin = Offset.zero;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // The dialog result completes before its closing animation removes the
    // widget. Its caller can release the source as soon as that result arrives.
    _image = widget.image.clone();
  }

  @override
  void didUpdateWidget(NotePhotoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.image, widget.image)) {
      final previous = _image;
      _image = widget.image.clone();
      previous.dispose();
      _transform = const NotePhotoTransform();
      _failed = false;
    }
  }

  @override
  void dispose() {
    _image.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_transform.isIdentity) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _failed = false;
    });
    final renderingImage = _image.clone();
    try {
      final photo = await widget.save(renderingImage, _transform);
      if (mounted) Navigator.of(context).pop(photo);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    } finally {
      renderingImage.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final rotation = _transform.rotation;
    final ratio = rotation.isOdd
        ? _image.height / _image.width
        : _image.width / _image.height;
    return PopScope(
      canPop: !_saving,
      child: Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('photo-edit-cancel'),
                      tooltip: strings.Cancel,
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    Expanded(
                      child: Text(strings.Photo_Edit,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2),
                    ),
                    TextButton(
                      key: const ValueKey('photo-edit-save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.Photo_Save),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(strings.Photo_Edit_Hint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final width = math.min(
                        constraints.maxWidth, constraints.maxHeight * ratio);
                    final height = width / ratio;
                    return Center(
                      child: SizedBox(
                        key: const ValueKey('photo-crop-canvas'),
                        width: width,
                        height: height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: RotatedBox(
                                quarterTurns: rotation,
                                child:
                                    RawImage(image: _image, fit: BoxFit.fill),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _CropPainter(
                                      crop: _transform.crop,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                              ),
                            ),
                            _moveArea(width, height),
                            for (final corner in _CropCorner.values)
                              _handle(corner, width, height, strings),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_failed)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(strings.Photo_Edit_Failed,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('photo-edit-rotate'),
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                                _transform = _transform.rotateClockwise();
                                _failed = false;
                              }),
                      icon: const Icon(Icons.rotate_right_rounded),
                      label: Text(strings.Photo_Rotate),
                    ),
                    TextButton.icon(
                      key: const ValueKey('photo-edit-reset'),
                      onPressed: _saving || _transform.isIdentity
                          ? null
                          : () => setState(() {
                                _transform = const NotePhotoTransform();
                                _failed = false;
                              }),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(strings.Photo_Reset),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _beginCrop(DragStartDetails details) {
    _gestureOrigin = details.globalPosition;
    _gestureCrop = _transform.crop;
  }

  Widget _moveArea(double width, double height) => Positioned(
        left: _transform.crop.left * width,
        top: _transform.crop.top * height,
        width: _transform.crop.width * width,
        height: _transform.crop.height * height,
        child: GestureDetector(
          key: const ValueKey('photo-crop-move'),
          behavior: HitTestBehavior.opaque,
          onPanStart: _saving ? null : _beginCrop,
          onPanUpdate: _saving
              ? null
              : (details) {
                  final delta = details.globalPosition - _gestureOrigin;
                  final left = (_gestureCrop.left + delta.dx / width)
                      .clamp(0.0, 1 - _gestureCrop.width);
                  final top = (_gestureCrop.top + delta.dy / height)
                      .clamp(0.0, 1 - _gestureCrop.height);
                  setState(() => _transform = _transform.copyWith(
                      crop: Rect.fromLTWH(
                          left, top, _gestureCrop.width, _gestureCrop.height)));
                },
        ),
      );

  Widget _handle(_CropCorner corner, double width, double height, S strings) {
    final crop = _transform.crop;
    final leftSide =
        corner == _CropCorner.topLeft || corner == _CropCorner.bottomLeft;
    final topSide =
        corner == _CropCorner.topLeft || corner == _CropCorner.topRight;
    final x = (leftSide ? crop.left : crop.right) * width;
    final y = (topSide ? crop.top : crop.bottom) * height;
    return Positioned(
      left: (x - 24).clamp(0.0, math.max(0.0, width - 48)),
      top: (y - 24).clamp(0.0, math.max(0.0, height - 48)),
      child: Semantics(
        label: strings.Photo_Edit_Hint,
        button: true,
        onIncrease: _saving
            ? null
            : () => _adjustCorner(
                corner, Offset(leftSide ? -.05 : .05, topSide ? -.05 : .05)),
        onDecrease: _saving
            ? null
            : () => _adjustCorner(
                corner, Offset(leftSide ? .05 : -.05, topSide ? .05 : -.05)),
        child: GestureDetector(
          key: ValueKey('photo-crop-${corner.name}'),
          behavior: HitTestBehavior.opaque,
          onPanStart: _saving ? null : _beginCrop,
          onPanUpdate: _saving
              ? null
              : (details) {
                  final delta = details.globalPosition - _gestureOrigin;
                  _resizeCrop(
                      corner, Offset(delta.dx / width, delta.dy / height));
                },
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 3)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _adjustCorner(_CropCorner corner, Offset delta) {
    _gestureCrop = _transform.crop;
    _resizeCrop(corner, delta);
  }

  void _resizeCrop(_CropCorner corner, Offset delta) {
    const minimum = .05;
    final crop = _gestureCrop;
    final leftSide =
        corner == _CropCorner.topLeft || corner == _CropCorner.bottomLeft;
    final topSide =
        corner == _CropCorner.topLeft || corner == _CropCorner.topRight;
    final left = leftSide
        ? (crop.left + delta.dx).clamp(0.0, crop.right - minimum)
        : crop.left;
    final right = leftSide
        ? crop.right
        : (crop.right + delta.dx).clamp(crop.left + minimum, 1.0);
    final top = topSide
        ? (crop.top + delta.dy).clamp(0.0, crop.bottom - minimum)
        : crop.top;
    final bottom = topSide
        ? crop.bottom
        : (crop.bottom + delta.dy).clamp(crop.top + minimum, 1.0);
    setState(() {
      _transform =
          _transform.copyWith(crop: Rect.fromLTRB(left, top, right, bottom));
      _failed = false;
    });
  }
}

enum _CropCorner { topLeft, topRight, bottomLeft, bottomRight }

class _CropPainter extends CustomPainter {
  const _CropPainter({required this.crop, required this.color});
  final Rect crop;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(crop.left * size.width, crop.top * size.height,
        crop.right * size.width, crop.bottom * size.height);
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(rect);
    canvas.drawPath(
        outside, Paint()..color = Colors.black.withValues(alpha: .55));
    canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .55)
      ..strokeWidth = 1;
    for (var index = 1; index < 3; index++) {
      final x = rect.left + rect.width * index / 3;
      final y = rect.top + rect.height * index / 3;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
    }
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) =>
      crop != oldDelegate.crop || color != oldDelegate.color;
}
