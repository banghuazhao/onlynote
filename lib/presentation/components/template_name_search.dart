import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Searches displayed names literally, retaining each original value and order.
List<T> filterTemplateNames<T>(Iterable<T> templates, String query,
    {required String Function(T) displayName}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return templates.toList(growable: false);
  final pattern =
      RegExp(RegExp.escape(trimmed), caseSensitive: false, unicode: true);
  return templates
      .where((template) => pattern.hasMatch(displayName(template)))
      .toList(growable: false);
}

/// Uses the caller's local query state and never loads or changes a template.
class TemplateNameSearchField extends StatelessWidget {
  const TemplateNameSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextField(
        key: const ValueKey('template-name-search'),
        controller: controller,
        enabled: enabled,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          labelText: S.of(context).Search_Templates,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('template-name-clear-search'),
                  tooltip: S.of(context).Clear_Search,
                  onPressed: !enabled
                      ? null
                      : () {
                          if (!context.mounted ||
                              ModalRoute.of(context)?.isCurrent == false) {
                            return;
                          }
                          controller.clear();
                          onChanged('');
                        },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      );
}

class TemplateNameSearchEmpty extends StatelessWidget {
  const TemplateNameSearchEmpty({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Semantics(
          liveRegion: true,
          child: Text(
            S.of(context).Templates_Search_Empty,
            key: const ValueKey('template-name-search-empty'),
          ),
        ),
      );
}
