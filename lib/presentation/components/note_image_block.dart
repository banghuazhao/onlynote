import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'note_block_image.dart';

typedef NoteBlockImageBuilder = Widget Function(
    BuildContext context, String path);

class NoteImageDrag {
  const NoteImageDrag(this.path);
  final String path;
}

/// A photo stays inside the writing page. Only the selected photo shows tools.
class NoteImageBlock extends StatefulWidget {
  const NoteImageBlock({
    super.key,
    required this.layout,
    this.selected = false,
    this.onSelected,
    this.onLayoutChanged,
    this.onDragStarted,
    this.onDragEnded,
    this.onDragPosition,
    this.onMoveEarlier,
    this.onMoveLater,
    this.onRemove,
    this.onImageTap,
    this.imageBuilder,
  });

  final NoteImageLayout layout;
  final bool selected;
  final VoidCallback? onSelected;
  final ValueChanged<NoteImageLayout>? onLayoutChanged;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final ValueChanged<DragUpdateDetails>? onDragPosition;
  final VoidCallback? onMoveEarlier;
  final VoidCallback? onMoveLater;
  final VoidCallback? onRemove;
  final VoidCallback? onImageTap;
  final NoteBlockImageBuilder? imageBuilder;

  @override
  State<NoteImageBlock> createState() => _NoteImageBlockState();
}

class _NoteImageBlockState extends State<NoteImageBlock> {
  double? _sourceAspectRatio;
  double _resizeStartWidth = 0;
  Offset _resizeDelta = Offset.zero;
  Offset _resizeOrigin = Offset.zero;

  @override
  void initState() {
    super.initState();
    _readAspectRatio();
  }

  @override
  void didUpdateWidget(NoteImageBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout.path != widget.layout.path) {
      _sourceAspectRatio = null;
      _readAspectRatio();
    }
  }

  Future<void> _readAspectRatio() async {
    if (widget.imageBuilder != null) return;
    final path = widget.layout.path;
    final ratio = await readNoteBlockAspectRatio(path);
    if (mounted &&
        widget.layout.path == path &&
        ratio != null &&
        ratio.isFinite &&
        ratio > 0) {
      setState(() => _sourceAspectRatio = ratio);
    }
  }

  Widget _tools(S strings) => Align(
        alignment: Alignment.center,
        child: TextFieldTapRegion(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.parchment,
                border: Border.all(color: AppColors.ink.withValues(alpha: .2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(children: [
                _ImageTool(
                    label: strings.Image_Move_Before,
                    icon: Icons.arrow_upward_rounded,
                    onPressed: widget.onMoveEarlier,
                    key: ValueKey('image-earlier-${widget.layout.path}')),
                _ImageTool(
                    label: strings.Image_Move_After,
                    icon: Icons.arrow_downward_rounded,
                    onPressed: widget.onMoveLater,
                    key: ValueKey('image-later-${widget.layout.path}')),
                _ImageTool(
                    label: strings.Image_Remove,
                    icon: Icons.delete_outline_rounded,
                    onPressed: widget.onRemove,
                    key: ValueKey('image-remove-${widget.layout.path}')),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final layout = widget.layout;
        final selected = widget.selected;
        final onLayoutChanged = widget.onLayoutChanged;
        final available = constraints.maxWidth;
        final width = available * layout.widthFactor;
        final ratio = _sourceAspectRatio ?? layout.aspectRatio;
        final height = width / ratio;
        final stackHeight = height < 48 ? 48.0 : height;
        final left = (available - width) * layout.xFactor;
        final strings = S.of(context);
        final editable = onLayoutChanged != null;
        final photo = SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: (widget.imageBuilder ?? buildNoteBlockImage)(
                context, layout.path),
          ),
        );
        Widget image = GestureDetector(
          key: ValueKey('image-select-${layout.path}'),
          behavior: HitTestBehavior.opaque,
          onTap: editable ? widget.onSelected : widget.onImageTap,
          child: photo,
        );
        if (editable && selected) {
          var dragDx = 0.0;
          image = Draggable<NoteImageDrag>(
            data: NoteImageDrag(layout.path),
            feedback: Material(
              color: Colors.transparent,
              child: Opacity(opacity: .85, child: photo),
            ),
            childWhenDragging: Opacity(opacity: .25, child: image),
            onDragStarted: widget.onDragStarted,
            onDragUpdate: (details) {
              widget.onDragPosition?.call(details);
              dragDx += details.delta.dx;
              final free = available - width;
              if (free > 0) {
                onLayoutChanged(layout.copyWith(
                  xFactor: (layout.xFactor + dragDx / free).clamp(0.0, 1.0),
                  aspectRatio: ratio,
                ));
              }
            },
            onDragEnd: (_) => widget.onDragEnded?.call(),
            child: image,
          );
        }
        if (editable) {
          image = Semantics(
              button: true,
              selected: selected,
              label: strings.Image_Move,
              onTap: widget.onSelected,
              child: ExcludeSemantics(child: image));
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selected && editable) _tools(strings),
              SizedBox(
                height: stackHeight,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                      left: left,
                      top: 0,
                      width: width,
                      height: height,
                      child: image),
                  if (selected && editable) ...[
                    Positioned(
                      left: left,
                      top: 0,
                      width: width,
                      height: height,
                      child: IgnorePointer(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                          border: Border.all(color: AppColors.ink, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        )),
                      ),
                    ),
                    Positioned(
                      left: (left + width - 36)
                          .clamp(0.0, math.max(0.0, available - 48)),
                      top: height > MediaQuery.sizeOf(context).height * .8
                          ? 0
                          : (height - 36).clamp(0.0, stackHeight - 48),
                      child: Semantics(
                        label: strings.Image_Resize,
                        value: '${(layout.widthFactor * 100).round()}%',
                        increasedValue:
                            '${((layout.widthFactor + .1).clamp(.25, 1.0) * 100).round()}%',
                        decreasedValue:
                            '${((layout.widthFactor - .1).clamp(.25, 1.0) * 100).round()}%',
                        button: true,
                        onIncrease: () => onLayoutChanged(layout.copyWith(
                            widthFactor:
                                (layout.widthFactor + .1).clamp(.25, 1.0),
                            aspectRatio: ratio)),
                        onDecrease: () => onLayoutChanged(layout.copyWith(
                            widthFactor:
                                (layout.widthFactor - .1).clamp(.25, 1.0),
                            aspectRatio: ratio)),
                        child: Tooltip(
                          message: strings.Image_Resize,
                          child: GestureDetector(
                            key: ValueKey('image-resize-${layout.path}'),
                            behavior: HitTestBehavior.opaque,
                            onPanDown: (details) {
                              _resizeStartWidth = layout.widthFactor;
                              _resizeDelta = Offset.zero;
                              _resizeOrigin = details.globalPosition;
                            },
                            onPanStart: (details) {
                              _resizeDelta =
                                  details.globalPosition - _resizeOrigin;
                              final change =
                                  (_resizeDelta.dx + _resizeDelta.dy / ratio) /
                                      (1 + 1 / (ratio * ratio));
                              onLayoutChanged(layout.copyWith(
                                widthFactor:
                                    (_resizeStartWidth + change / available)
                                        .clamp(.25, 1.0),
                                aspectRatio: ratio,
                              ));
                            },
                            onPanUpdate: (details) {
                              _resizeDelta += details.delta;
                              final change =
                                  (_resizeDelta.dx + _resizeDelta.dy / ratio) /
                                      (1 + 1 / (ratio * ratio));
                              onLayoutChanged(layout.copyWith(
                                widthFactor:
                                    (_resizeStartWidth + change / available)
                                        .clamp(.25, 1.0),
                                aspectRatio: ratio,
                              ));
                            },
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                  child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.parchment,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                      color: AppColors.ink, width: 2),
                                ),
                                child: const Icon(Icons.open_in_full_rounded,
                                    size: 15, color: AppColors.ink),
                              )),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            ],
          ),
        );
      });
}

class _ImageTool extends StatelessWidget {
  const _ImageTool(
      {super.key, required this.label, required this.icon, this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
        ),
      );
}
