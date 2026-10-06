part of '../add_update_note_screen.dart';

class _BuildImageSection extends StatelessWidget {
  const _BuildImageSection({
    required this.state,
    required this.onAddPhoto,
    required this.addingPhoto,
  });
  final AddUpdateFormState state;
  final ValueChanged<ImageSource> onAddPhoto;
  final bool addingPhoto;

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
            onAddPhoto(ImageSource.gallery);
          },
        ),
        AppSheetAction(
          leading: const Icon(Icons.camera_alt_outlined),
          title: Text(S.of(context).Take_Photo),
          onPressed: (sheetContext) {
            Navigator.pop(sheetContext);
            onAddPhoto(ImageSource.camera);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const ValueKey('editor-add-photo'),
          style: AppButtonStyles.paperAction(),
          onPressed: addingPhoto ? null : () => _showImageSourceSheet(context),
          icon: const SizedBox(
              width: 28,
              child: Icon(Icons.add_photo_alternate_outlined, size: 20)),
          label: Text(S.of(context).Add_Image),
        ),
      );
}
