part of '../add_update_note_screen.dart';

class _BuildImageSection extends StatelessWidget {
  const _BuildImageSection({Key? key, required this.state}) : super(key: key);
  final AddUpdateFormState state;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final savedPath = await ImageStorage.saveImage(File(picked.path));
    if (context.mounted) {
      context
          .read<AddUpdateFormBloc>()
          .add(AddUpdateFormEvent.addImage(savedPath));
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    showAdaptiveActionSheet(
      context: context,
      androidBorderRadius: 30,
      actions: <BottomSheetAction>[
        BottomSheetAction(
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(S.of(context).Choose_From_Gallery),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _pickImage(context, ImageSource.gallery);
          },
        ),
        BottomSheetAction(
          leading: const Icon(Icons.camera_alt_outlined),
          title: Text(S.of(context).Take_Photo),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _pickImage(context, ImageSource.camera);
          },
        ),
      ],
      cancelAction: CancelAction(title: Text(S.of(context).Cancel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final path in state.imagePaths)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacings.m),
              child: _ImageThumbnail(
                path: path,
                onRemove: () {
                  context
                      .read<AddUpdateFormBloc>()
                      .add(AddUpdateFormEvent.removeImage(path));
                },
              ),
            ),
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(context.tokens.radiusSmall),
            child: InkWell(
              borderRadius: BorderRadius.circular(context.tokens.radiusSmall),
              onTap: () => _showImageSourceSheet(context),
              child: SizedBox(
                width: 80,
                height: 80,
                child: const Icon(Icons.add_photo_alternate_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({Key? key, required this.path, required this.onRemove})
      : super(key: key);
  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacings.m),
          child: Image.file(
            File(ImageStorage.resolvePath(path)),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: IconButton.filled(
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: onRemove,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ),
      ],
    );
  }
}
