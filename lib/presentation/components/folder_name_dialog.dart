import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

class FolderNameDialog extends StatefulWidget {
  const FolderNameDialog({
    super.key,
    required this.title,
    this.initial,
    this.labelText,
    this.icon = Icons.folder_outlined,
    this.maxLength,
  });
  final String title;
  final String? initial;
  final String? labelText;
  final IconData icon;
  final int? maxLength;

  @override
  State<FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<FolderNameDialog> {
  late final _controller = TextEditingController(text: widget.initial ?? '');

  @override
  void initState() {
    super.initState();
    _controller.selection =
        TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        icon: Icon(widget.icon),
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
              labelText: widget.labelText ?? S.of(context).Folder_Name),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).Cancel)),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => FilledButton(
              onPressed: value.text.trim().isEmpty ? null : _submit,
              child: Text(S.of(context).OK),
            ),
          ),
        ],
      );
}
