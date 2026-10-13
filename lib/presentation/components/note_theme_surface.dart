import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/presentation/theme/colors.dart';

/// Paper stays light because note text, checkboxes and highlights use dark ink.
/// A note's explicit color always takes precedence over the preset palette.
Color noteThemePaperColor(NoteTheme theme, {Color? customColor}) =>
    customColor ??
    switch (theme) {
      NoteTheme.classic => AppColors.parchment,
      NoteTheme.sticky => const Color(0xFFFFF1AA),
      NoteTheme.legalPad => const Color(0xFFFFF5C9),
      NoteTheme.ruledNotebook => const Color(0xFFFFFDF5),
      NoteTheme.gridPaper => const Color(0xFFF3F8F3),
      NoteTheme.dottedJournal => const Color(0xFFFAF8F0),
      NoteTheme.kraftNotebook => const Color(0xFFE9D5B4),
      NoteTheme.parchment => const Color(0xFFF5E8CD),
    };

/// A decorative, web-safe sample for appearance choices. The parent supplies
/// its accessible label and interaction; the painted paper receives no taps.
class NoteThemeSample extends StatelessWidget {
  const NoteThemeSample({
    super.key,
    required this.theme,
    this.customColor,
    this.selected = false,
    this.height = 68,
  });

  final NoteTheme theme;
  final Color? customColor;
  final bool selected;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = noteThemePaperColor(theme, customColor: customColor);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: AppColors.ink.withValues(alpha: selected ? .55 : .18),
                width: selected ? 1.5 : .6,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: NoteThemePainter(theme: theme, color: color),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stationery decoration only: no text, layout, files, or mutable app state.
/// Classic full-note rendering continues to use the original paper painter.
class NoteThemePainter extends CustomPainter {
  const NoteThemePainter({
    required this.theme,
    required this.color,
    this.seed = 0,
    this.sheet = false,
  });

  final NoteTheme theme;
  final Color color;
  final int seed;
  final bool sheet;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (theme) {
      case NoteTheme.classic:
        _grain(canvas, size, count: 48);
        _rules(canvas, size, alpha: .07);
        _fold(canvas, size);
      case NoteTheme.sticky:
        final adhesive = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.ink.withValues(alpha: .055), Colors.transparent],
          ).createShader(Rect.fromLTWH(0, 0, size.width, 16));
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 16), adhesive);
        _grain(canvas, size, count: 30, alpha: .022);
        _fold(canvas, size);
      case NoteTheme.legalPad:
        _grain(canvas, size, count: 36, alpha: .025);
        _rules(canvas, size, alpha: .14, blue: true);
        _margin(canvas, size, doubleLine: true);
      case NoteTheme.ruledNotebook:
        _rules(canvas, size, alpha: .12, blue: true);
        _margin(canvas, size);
      case NoteTheme.gridPaper:
        _grid(canvas, size);
      case NoteTheme.dottedJournal:
        _dots(canvas, size);
      case NoteTheme.kraftNotebook:
        _grain(canvas, size, count: 100, alpha: .065);
        final binding = Paint()
          ..color = AppColors.ink.withValues(alpha: .12)
          ..strokeWidth = 1;
        canvas.drawLine(const Offset(4, 0), Offset(4, size.height), binding);
      case NoteTheme.parchment:
        final wash = Paint()
          ..shader = RadialGradient(
            radius: .85,
            colors: [Colors.transparent, AppColors.ink.withValues(alpha: .055)],
          ).createShader(Offset.zero & size);
        canvas.drawRect(Offset.zero & size, wash);
        _grain(canvas, size, count: 95, alpha: .045);
    }
    final edge = Paint()
      ..color = Colors.white.withValues(alpha: .30)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(5, 1), Offset(size.width - 5, 1), edge);
    canvas.restore();
  }

  void _grain(Canvas canvas, Size size,
      {required int count, double alpha = .035}) {
    final random = math.Random(seed == 0 ? 7 : seed);
    final paint = Paint()..color = AppColors.ink.withValues(alpha: alpha);
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        .35 + random.nextDouble() * .8,
        paint,
      );
    }
    paint
      ..strokeWidth = .5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 10, y + 1.5), paint);
    }
  }

  void _rules(Canvas canvas, Size size,
      {required double alpha, bool blue = false}) {
    final paint = Paint()
      ..color = (blue ? const Color(0xFF386C88) : AppColors.ink)
          .withValues(alpha: alpha)
      ..strokeWidth = .8;
    final spacing = math.max(26.0, size.height / 500);
    final path = Path();
    for (var y = sheet ? 36.0 : 22.0; y < size.height - 8; y += spacing) {
      path
        ..moveTo(sheet ? 24 : 8, y)
        ..lineTo(size.width - 8, y);
    }
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  void _margin(Canvas canvas, Size size, {bool doubleLine = false}) {
    final x = sheet ? 22.0 : 7.0;
    final paint = Paint()
      ..color = const Color(0xFFAF5454).withValues(alpha: .28)
      ..strokeWidth = .8;
    canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), paint);
    if (doubleLine) {
      canvas.drawLine(Offset(x - 2, 8), Offset(x - 2, size.height - 8), paint);
    }
  }

  void _grid(Canvas canvas, Size size) {
    final path = Path();
    final rowStep = math.max(18.0, size.height / 500);
    final columnStep = math.max(18.0, size.width / 160);
    for (var y = rowStep; y < size.height; y += rowStep) {
      path
        ..moveTo(0, y)
        ..lineTo(size.width, y);
    }
    for (var x = columnStep; x < size.width; x += columnStep) {
      path
        ..moveTo(x, 0)
        ..lineTo(x, size.height);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF386C66).withValues(alpha: .11)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65);
  }

  void _dots(Canvas canvas, Size size) {
    // Keep tall notes inexpensive as well as ordinary cards and full sheets.
    final step = math.max(20.0, math.sqrt(size.width * size.height / 2400));
    final paint = Paint()..color = AppColors.ink.withValues(alpha: .16);
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), .7, paint);
      }
    }
  }

  void _fold(Canvas canvas, Size size) {
    final extent =
        math.min(sheet ? 20.0 : 14.0, math.min(size.width, size.height) / 3);
    final path = Path()
      ..moveTo(size.width - extent, size.height)
      ..lineTo(size.width, size.height - extent)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
        path, Paint()..color = Color.lerp(color, AppColors.ink, .10)!);
    canvas.drawLine(
        Offset(size.width - extent, size.height),
        Offset(size.width, size.height - extent),
        Paint()
          ..color = AppColors.ink.withValues(alpha: .15)
          ..strokeWidth = .7);
  }

  @override
  bool shouldRepaint(covariant NoteThemePainter oldDelegate) =>
      oldDelegate.theme != theme ||
      oldDelegate.color != color ||
      oldDelegate.seed != seed ||
      oldDelegate.sheet != sheet;
}
