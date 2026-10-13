import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/typography.dart';

/// How the sheet is presented.
///
/// * [scrap] — a torn-off sticky / index card (home grid).
/// * [sheet] — a full stationery page (editor and detail).
enum PaperNoteKind { scrap, sheet }

/// Physical paper a note is written on: grain, ruled lines, a folded corner,
/// and (for full sheets) notebook punch holes.
class PaperNote extends StatelessWidget {
  const PaperNote({
    super.key,
    required this.color,
    required this.child,
    this.kind = PaperNoteKind.scrap,
    this.seed = 0,
    this.pinned = false,
    this.selected = false,
    this.pressed = false,
    this.exportMode = false,
    this.tilt = true,
    this.plainPaper,
    this.padding,
    this.theme = NoteTheme.classic,
  });

  final Color color;
  final Widget child;
  final PaperNoteKind kind;
  final int seed;
  final bool pinned;
  final bool selected;
  final bool pressed;
  final bool exportMode;
  final bool tilt;
  final bool? plainPaper;
  final EdgeInsetsGeometry? padding;
  final NoteTheme theme;

  static const _scrapRadius = 5.0;
  static const _sheetRadius = 3.0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppAppearanceSettings.instance,
        builder: (context, _) => _buildSurface(context),
      );

  Widget _buildSurface(BuildContext context) {
    final plain = plainPaper ?? AppAppearanceSettings.instance.plainPaper;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isSheet = kind == PaperNoteKind.sheet;
    final radius = isSheet ? _sheetRadius : _scrapRadius;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final desk = DeskSurface.colorOf(context);
    final tiltTurns = (!tilt || plain || reduceMotion || isSheet)
        ? 0.0
        : ((seed % 13) - 6) * 0.0008;

    final paper = AnimatedContainer(
      duration: reduceMotion || exportMode
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: selected
              ? AppColors.ink.withValues(alpha: 0.55)
              : Color.lerp(color, AppColors.ink, 0.12)!.withValues(alpha: 0.35),
          width: selected ? 1.5 : 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: pressed ? 0.06 : 0.16),
            blurRadius: pressed ? 4 : (isSheet ? 22 : 14),
            offset:
                Offset(pressed ? 0.5 : 1.5, pressed ? 1.5 : (isSheet ? 10 : 6)),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        shape: shape,
        child: Stack(
          children: [
            if (!plain)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: theme == NoteTheme.classic
                        ? _PaperTexturePainter(
                            color: color,
                            seed: seed,
                            kind: kind,
                            holeColor: desk,
                          )
                        : NoteThemePainter(
                            theme: theme,
                            color: color,
                            seed: seed,
                            sheet: isSheet,
                          ),
                  ),
                ),
              ),
            Padding(
              padding: _resolvePadding(context, isSheet),
              child: _PaperNoteThemeScope(
                  theme: theme, plainPaper: plain, child: child),
            ),
            if (pinned)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Semantics(
                    label: S.of(context).Pin,
                    child: Center(
                        child: plain
                            ? const Icon(Icons.push_pin,
                                size: 18, color: AppColors.ink)
                            : _Thumbtack(seed: seed)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    Widget result = RepaintBoundary(child: paper);
    if (tiltTurns != 0) {
      result = Transform.rotate(angle: tiltTurns * math.pi * 2, child: result);
    }
    return result;
  }

  EdgeInsets _resolvePadding(BuildContext context, bool isSheet) {
    final resolved = (padding ??
            EdgeInsets.fromLTRB(
              isSheet ? 28 : 14,
              isSheet ? 22 : 14,
              14,
              isSheet ? 22 : 14,
            ))
        .resolve(Directionality.of(context));
    if (!pinned) return resolved;
    return resolved.copyWith(top: math.max(resolved.top, 30));
  }
}

class _PaperNoteThemeScope extends InheritedWidget {
  const _PaperNoteThemeScope({
    required this.theme,
    required this.plainPaper,
    required super.child,
  });

  final NoteTheme theme;
  final bool plainPaper;

  static _PaperNoteThemeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PaperNoteThemeScope>();

  @override
  bool updateShouldNotify(_PaperNoteThemeScope oldWidget) =>
      oldWidget.theme != theme || oldWidget.plainPaper != plainPaper;
}

/// Warm desk the paper sits on — slightly darker than the sheets so they lift.
class DeskSurface extends StatelessWidget {
  const DeskSurface({super.key, this.child});

  final Widget? child;

  static Color colorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.deskDark
          : AppColors.desk;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppAppearanceSettings.instance,
        builder: (context, _) => _buildSurface(context),
      );

  Widget _buildSurface(BuildContext context) {
    final plain = AppAppearanceSettings.instance.plainPaper;
    final color = colorOf(context);
    return ColoredBox(
      color: color,
      child: CustomPaint(
        painter: plain ? null : _DeskGrainPainter(color: color),
        // A raster-cache hint requires a painter, including during style changes.
        isComplex: !plain,
        willChange: false,
        child: child,
      ),
    );
  }
}

/// Lined stationery behind long-form writing, matching [lineHeight].
class RuledWritingArea extends StatelessWidget {
  const RuledWritingArea({
    super.key,
    required this.child,
    this.paperColor,
    this.lineHeight = 28,
  });

  final Widget child;
  final Color? paperColor;
  final double lineHeight;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppAppearanceSettings.instance,
        builder: (context, _) => _buildSurface(context),
      );

  Widget _buildSurface(BuildContext context) {
    final paper = _PaperNoteThemeScope.maybeOf(context);
    if (AppAppearanceSettings.instance.plainPaper ||
        paper?.plainPaper == true ||
        (paper?.theme ?? NoteTheme.classic) != NoteTheme.classic) {
      return child;
    }
    final ink = Color.lerp(
      paperColor ?? AppColors.parchment,
      AppColors.ink,
      0.35,
    )!
        .withValues(alpha: 0.18);
    return CustomPaint(
      painter: _RuledLinesPainter(
        ink: ink,
        lineHeight: lineHeight,
      ),
      child: child,
    );
  }
}

/// Compact ink-style checklist row — reads as handwriting, not a settings tile.
class PaperChecklistRow extends StatelessWidget {
  const PaperChecklistRow({
    super.key,
    required this.label,
    required this.completed,
    this.onChanged,
    this.exportMode = false,
    this.maxLines = 2,
    this.dense = false,
    this.searchQuery = '',
    this.textStyle,
  });

  final String label;
  final bool completed;
  final ValueChanged<bool>? onChanged;

  /// Removes interactive ink while keeping the normal row's dimensions.
  final bool exportMode;
  final int maxLines;
  final bool dense;
  final String searchQuery;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final interactive = onChanged != null;
    final size = dense ? 18.0 : 22.0;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: dense ? 2 : 4),
          child: AnimatedSwitcher(
            duration: exportMode || MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 160),
            child: InkCheckbox(
                key: ValueKey(completed), checked: completed, size: size),
          ),
        ),
        SizedBox(width: dense ? 8 : 10),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: exportMode || MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            style: (textStyle ??
                    (dense ? AppTypography.cardBody : AppTypography.formText))
                .copyWith(
              color: AppColors.ink.withValues(alpha: completed ? 0.45 : 0.88),
              decoration: completed ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.ink.withValues(alpha: 0.45),
            ),
            child: SearchHighlight(
              label,
              query: searchQuery,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );

    if (!interactive) return row;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: row,
      ),
    );
    if (exportMode) return content;

    return Semantics(
      button: true,
      checked: completed,
      label: label,
      child: InkWell(
        onTap: () => onChanged!(!completed),
        borderRadius: BorderRadius.circular(6),
        child: content,
      ),
    );
  }
}

/// The hand-drawn checkbox used everywhere a todo is shown, so the editor
/// and the reader draw the same mark.
class InkCheckbox extends StatelessWidget {
  const InkCheckbox({super.key, required this.checked, this.size = 22});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _InkCheckboxPainter(checked: checked),
    );
  }
}

class _InkCheckboxPainter extends CustomPainter {
  const _InkCheckboxPainter({required this.checked});

  final bool checked;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, ink);
    if (checked) {
      final mark = Paint()
        ..color = AppColors.ink.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(size.width * 0.22, size.height * 0.52)
        ..lineTo(size.width * 0.42, size.height * 0.72)
        ..lineTo(size.width * 0.78, size.height * 0.28);
      canvas.drawPath(path, mark);
    }
  }

  @override
  bool shouldRepaint(covariant _InkCheckboxPainter oldDelegate) =>
      oldDelegate.checked != checked;
}

class _Thumbtack extends StatelessWidget {
  const _Thumbtack({required this.seed});

  final int seed;

  static const _heads = [
    Color(0xFFC44536),
    Color(0xFF2A6F6A),
    Color(0xFF3D5A80),
    Color(0xFFC9A227),
  ];

  @override
  Widget build(BuildContext context) {
    final head = _heads[seed.abs() % _heads.length];
    return SizedBox(
      width: 18,
      height: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 0.9,
            colors: [
              Color.lerp(head, Colors.white, 0.45)!,
              head,
              Color.lerp(head, Colors.black, 0.25)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 3,
              offset: const Offset(0.5, 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter({
    required this.color,
    required this.seed,
    required this.kind,
    required this.holeColor,
  });

  final Color color;
  final int seed;
  final PaperNoteKind kind;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = math.Random(seed == 0 ? 7 : seed);
    final ink = AppColors.ink;

    // Fiber / grain specks.
    final grainCount = (size.width * size.height / 420).clamp(28, 140).toInt();
    for (var i = 0; i < grainCount; i++) {
      final speck = Paint()
        ..color = ink.withValues(alpha: 0.025 + random.nextDouble() * 0.04);
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        0.4 + random.nextDouble() * 1.1,
        speck,
      );
    }

    // A few longer pulp fibers.
    final fiber = Paint()
      ..color = ink.withValues(alpha: 0.035)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final y = random.nextDouble() * size.height;
      final x = random.nextDouble() * size.width * 0.6;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 18 + random.nextDouble() * 28,
            y + (random.nextDouble() - 0.5) * 4),
        fiber,
      );
    }

    // Ruled lines — faint on scraps, clearer on full sheets.
    final lineAlpha = kind == PaperNoteKind.sheet ? 0.11 : 0.06;
    final linePaint = Paint()
      ..color = ink.withValues(alpha: lineAlpha)
      ..strokeWidth = 1;
    final startY = kind == PaperNoteKind.sheet ? 36.0 : 22.0;
    const spacing = 26.0;
    for (var y = startY; y < size.height - 8; y += spacing) {
      canvas.drawLine(Offset(kind == PaperNoteKind.sheet ? 24 : 8, y),
          Offset(size.width - 8, y), linePaint);
    }

    if (kind == PaperNoteKind.sheet) {
      // Notebook margin.
      final margin = Paint()
        ..color = const Color(0xFFC45C5C).withValues(alpha: 0.45)
        ..strokeWidth = 1.1;
      canvas.drawLine(const Offset(22, 8), Offset(22, size.height - 8), margin);

      // Punch holes so the desk shows through.
      const holeXs = [11.0];
      final holeYs = [
        size.height * 0.18,
        size.height * 0.50,
        size.height * 0.82,
      ];
      final holeFill = Paint()..color = holeColor;
      final holeRing = Paint()
        ..color = ink.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final x in holeXs) {
        for (final y in holeYs) {
          canvas.drawCircle(Offset(x, y), 5.2, holeFill);
          canvas.drawCircle(Offset(x, y), 5.2, holeRing);
        }
      }
    }

    // Top edge highlight — paper thickness.
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.2;
    canvas.drawLine(
        const Offset(6, 1.2), Offset(size.width - 6, 1.2), highlight);

    // Folded dog-ear.
    final foldSize = kind == PaperNoteKind.sheet ? 22.0 : 16.0;
    final foldFace = Paint()..color = Color.lerp(color, ink, 0.16)!;
    final foldBack = Paint()..color = Color.lerp(color, Colors.white, 0.18)!;
    final crease = Paint()
      ..color = ink.withValues(alpha: 0.18)
      ..strokeWidth = 0.8;

    final fold = Path()
      ..moveTo(size.width - foldSize, size.height)
      ..lineTo(size.width, size.height - foldSize)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(fold, foldFace);

    final underside = Path()
      ..moveTo(size.width - foldSize, size.height)
      ..lineTo(size.width - foldSize * 0.38, size.height - foldSize * 0.38)
      ..lineTo(size.width, size.height - foldSize)
      ..close();
    canvas.drawPath(underside, foldBack);
    canvas.drawLine(
      Offset(size.width - foldSize, size.height),
      Offset(size.width, size.height - foldSize),
      crease,
    );
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.seed != seed ||
        oldDelegate.kind != kind ||
        oldDelegate.holeColor != holeColor;
  }
}

class _RuledLinesPainter extends CustomPainter {
  const _RuledLinesPainter({required this.ink, required this.lineHeight});

  final Color ink;
  final double lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink
      ..strokeWidth = 1;
    for (var y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuledLinesPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.lineHeight != lineHeight;
}

class _DeskGrainPainter extends CustomPainter {
  const _DeskGrainPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = math.Random(21);
    final dark = Color.lerp(color, Colors.black, 0.18)!;
    final light = Color.lerp(color, Colors.white, 0.08)!;

    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          light.withValues(alpha: 0.35),
          Colors.transparent,
          dark.withValues(alpha: 0.2)
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);

    final grain = Paint()..color = Colors.black.withValues(alpha: 0.03);
    final count = (size.width * size.height / 900).clamp(40, 160).toInt();
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        random.nextDouble() * 1.4,
        grain,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DeskGrainPainter oldDelegate) =>
      oldDelegate.color != color;
}
