part of '../add_update_note_screen.dart';

class _BuildImageSection extends StatelessWidget {
  const _BuildImageSection({Key? key, required this.state}) : super(key: key);
  final AddUpdateFormState state;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final savedPath = await ImageStorage.saveImage(File(picked.path));
    if (context.mounted) {
      context.read<AddUpdateFormBloc>().add(AddUpdateFormEvent.addImage(savedPath));
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
                  context.read<AddUpdateFormBloc>().add(AddUpdateFormEvent.removeImage(path));
                },
              ),
            ),
          GestureDetector(
            onTap: () => _showImageSourceSheet(context),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacings.m),
                color: Colors.black.withOpacity(0.06),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.title),
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
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
