import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// First-use guidance for the unfiltered note library, using existing actions.
class EmptyNoteLibrary extends StatelessWidget {
  const EmptyNoteLibrary({
    super.key,
    required this.onAdd,
    required this.onTemplates,
    this.criteriaSummary,
  });

  final VoidCallback onAdd;
  final VoidCallback onTemplates;
  final Widget? criteriaSummary;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (criteriaSummary != null) ...[
                criteriaSummary!,
                const SizedBox(height: 16),
              ],
              Image.asset(
                'assets/empty_notes.png',
                width: 190,
                height: 190,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  strings.No_notes_found,
                  key: const ValueKey('empty-library-title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.Empty_Library_Description,
                key: const ValueKey('empty-library-description'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('empty-library-add'),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text(strings.Add_Note),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const ValueKey('empty-library-templates'),
                onPressed: onTemplates,
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: Text(strings.Use_Template),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
