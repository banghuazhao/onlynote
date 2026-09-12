part of '../add_update_note_screen.dart';

class _BuildImageSection extends StatelessWidget {
  const _BuildImageSection({required this.state});
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
    showAppActionSheet(
      context: context,
      title: S.of(context).Add_Image,
      actions: <AppSheetAction>[
        AppSheetAction(
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(S.of(context).Choose_From_Gallery),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _pickImage(context, ImageSource.gallery);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.camera_alt_outlined),
          title: Text(S.of(context).Take_Photo),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            _pickImage(context, ImageSource.camera);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
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
            color: Colors.white.withValues(alpha: 0.55),
            elevation: 1,
            shadowColor: Colors.black26,
            child: InkWell(
              onTap: () => _showImageSourceSheet(context),
              child: const SizedBox(
                width: 80,
                height: 80,
                child: Icon(Icons.add_photo_alternate_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.path, required this.onRemove});
  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0.5, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: NoteImage(path: path, width: 80, height: 66),
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
