import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

void _closeCurrentSheet(BuildContext context) {
  if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
  Navigator.pop(context);
}

/// Shared, scrollable modal surface for every in-app action sheet.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: builder(context),
      ),
    );

class AppSheet extends StatelessWidget {
  const AppSheet(
      {super.key, required this.title, required this.child, this.footer});
  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
              child: Row(children: [
                Expanded(
                  child: Semantics(
                    namesRoute: true,
                    header: true,
                    child: Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => _closeCurrentSheet(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ]),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: child,
              ),
            ),
            if (footer != null) ...[
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: footer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppSheetAction {
  const AppSheetAction({
    required this.title,
    required this.onPressed,
    this.leading,
    this.subtitle,
    this.destructive = false,
    this.selected = false,
    this.section,
  });
  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final void Function(BuildContext) onPressed;
  final bool destructive;
  final bool selected;

  /// Consecutive actions with the same label share one section heading.
  /// Omit it to retain the ordinary, ungrouped action-sheet layout.
  final String? section;
}

Future<void> showAppActionSheet({
  required BuildContext context,
  required String title,
  required List<AppSheetAction> actions,
}) async {
  await showAppSheet<void>(
    context: context,
    builder: (context) => AppActionSheet(title: title, actions: actions),
  );
}

/// Shared action content, also usable with local callbacks in widget previews.
class AppActionSheet extends StatelessWidget {
  const AppActionSheet({super.key, required this.title, required this.actions});

  final String title;
  final List<AppSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    final sections = actions.map((action) {
      final label = action.section?.trim();
      return label == null || label.isEmpty ? null : label;
    }).toList(growable: false);
    return AppSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, action) in actions.indexed) ...[
            if (index > 0 &&
                (action.destructive ||
                    (sections[index] != null &&
                        sections[index] != sections[index - 1])))
              const Divider(indent: 12, endIndent: 12, height: 16),
            if (sections[index] != null &&
                (index == 0 || sections[index] != sections[index - 1]))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Semantics(
                  header: true,
                  child: Text(
                    sections[index]!,
                    key: ValueKey('app-sheet-section-$index'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            Builder(builder: (context) {
              final colors = Theme.of(context).colorScheme;
              final foreground =
                  action.destructive ? colors.error : colors.onSurface;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  minVerticalPadding: 14,
                  selected: action.selected,
                  selectedTileColor: colors.primaryContainer,
                  selectedColor: colors.onPrimaryContainer,
                  textColor: foreground,
                  iconColor: foreground,
                  leading: action.leading,
                  title: action.title,
                  subtitle: action.subtitle,
                  trailing:
                      action.selected ? const Icon(Icons.check_rounded) : null,
                  onTap: () => action.onPressed(context),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _closeCurrentSheet(context),
            child: Text(S.of(context).Cancel),
          ),
        ],
      ),
    );
  }
}
