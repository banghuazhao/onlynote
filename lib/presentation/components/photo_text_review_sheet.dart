import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/photo_text_result.dart';

import 'app_sheet.dart';
import 'toast.dart';

/// Explicit review before insertion. Copy never inserts or closes the sheet.
class PhotoTextReviewSheet extends StatefulWidget {
  const PhotoTextReviewSheet({super.key, required this.text});
  final String text;

  @override
  State<PhotoTextReviewSheet> createState() => _PhotoTextReviewSheetState();
}

class _PhotoTextReviewSheetState extends State<PhotoTextReviewSheet> {
  late final TextEditingController _controller;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _controller.addListener(_edited);
  }

  void _edited() => setState(() => _copied = false);

  Future<void> _copy() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted && _controller.text.trim() == text) {
        setState(() => _copied = true);
      }
    } catch (_) {
      if (mounted) {
        showTransientSnackBar(context,
            SnackBar(content: Text(S.of(context).Photo_Text_Copy_Failed)));
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_edited);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final hasText = _controller.text.trim().isNotEmpty;
    return AppSheet(
      title: l10n.Photo_Text_Review,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Text(l10n.Photo_Text_Review_Hint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              key: const ValueKey('photo-text-review'),
              controller: _controller,
              minLines: 5,
              maxLines: 10,
              maxLength: maxPhotoTextLength,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: l10n.Photo_Text_Field,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: hasText
                ? () => Navigator.pop(context, _controller.text.trim())
                : null,
            icon: const Icon(Icons.note_add_outlined),
            label: Text(l10n.Photo_Text_Insert),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: hasText ? _copy : null,
            icon: Icon(_copied ? Icons.check_rounded : Icons.copy_outlined),
            label:
                Text(_copied ? l10n.Photo_Text_Copied : l10n.Photo_Text_Copy),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.Cancel),
          ),
        ],
      ),
    );
  }
}
