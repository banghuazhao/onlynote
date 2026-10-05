import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/services/note_templates.dart';

Future<NoteTemplate?> showNoteTemplatePickerSheet(BuildContext context) =>
    showAppSheet<NoteTemplate>(
      context: context,
      builder: (_) => const NoteTemplatePickerSheet(),
    );

class NoteTemplatePickerSheet extends StatelessWidget {
  const NoteTemplatePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    return AppSheet(
      title: strings.Templates,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Text(
              strings.Templates_Description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          for (final template in NoteTemplate.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: ListTile(
                  key: ValueKey('template-${template.name}'),
                  minVerticalPadding: 16,
                  leading: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        switch (template) {
                          NoteTemplate.shopping =>
                            Icons.shopping_basket_outlined,
                          NoteTemplate.packing => Icons.luggage_outlined,
                          NoteTemplate.dailyPlan => Icons.today_outlined,
                          NoteTemplate.meeting => Icons.groups_outlined,
                        },
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                  ),
                  title: Text(template.content(strings).title),
                  subtitle: Text(template.content(strings).summary),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, template),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
