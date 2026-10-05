import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/generated/l10n.dart';

class TemplateNameDialog extends StatefulWidget {
  const TemplateNameDialog({super.key, required this.title, this.initial});
  final String title;
  final String? initial;

  @override
  State<TemplateNameDialog> createState() => _TemplateNameDialogState();
}

class _TemplateNameDialogState extends State<TemplateNameDialog> {
  late final _controller = TextEditingController(
    text: (widget.initial ?? '')
        .characters
        .take(maxTemplateNameLength)
        .toString(),
  );

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
        icon: const Icon(Icons.bookmarks_outlined),
        title: Text(widget.title),
        content: TextField(
          key: const ValueKey('template-name'),
          controller: _controller,
          autofocus: true,
          maxLength: maxTemplateNameLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: S.of(context).Template_Name),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).Cancel),
          ),
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
