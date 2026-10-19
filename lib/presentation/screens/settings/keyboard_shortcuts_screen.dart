import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

/// A reference for existing Mac commands, without registering any shortcuts.
class KeyboardShortcutsScreen extends StatelessWidget {
  const KeyboardShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final material = MaterialLocalizations.of(context);
    final tokens = context.tokens;
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle ??
        context.textStyles.titleLarge;
    final titlePainter = TextPainter(
      text: TextSpan(text: l10n.Keyboard_Shortcuts, style: titleStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.localeOf(context),
      maxLines: 2,
    )..layout(
        // Reserve space for the back button even in standalone previews.
        maxWidth: (MediaQuery.sizeOf(context).width -
                kToolbarHeight -
                2 * (Theme.of(context).appBarTheme.titleSpacing ?? 16))
            .clamp(1, double.infinity)
            .toDouble(),
      );
    final toolbarHeight = (titlePainter.height + tokens.space4)
        .clamp(kToolbarHeight, double.infinity)
        .toDouble();
    titlePainter.dispose();
    final command = material.keyboardKeyMetaMacOs;
    final shift = material.keyboardKeyShift;
    final shortcuts = [
      _Shortcut(
        id: 'new-note',
        label: l10n.Desktop_Menu_New_Note,
        keys: const ['⌘', 'N'],
        spokenKeys: [command, 'N'],
      ),
      _Shortcut(
        id: 'find',
        label: '${l10n.Search_Notes} / ${l10n.Find_In_Note}',
        hint: l10n.Keyboard_Shortcuts_Find_Context,
        keys: const ['⌘', 'F'],
        spokenKeys: [command, 'F'],
      ),
      _Shortcut(
        id: 'settings',
        label: l10n.Settings,
        keys: const ['⌘', ','],
        spokenKeys: [command, ','],
      ),
      _Shortcut(
        id: 'undo',
        label: l10n.Note_Undo,
        keys: const ['⌘', 'Z'],
        spokenKeys: [command, 'Z'],
      ),
      _Shortcut(
        id: 'redo',
        label: l10n.Note_Redo,
        keys: const ['⇧', '⌘', 'Z'],
        spokenKeys: [shift, command, 'Z'],
      ),
      _Shortcut(
        id: 'cut',
        label: material.cutButtonLabel,
        keys: const ['⌘', 'X'],
        spokenKeys: [command, 'X'],
      ),
      _Shortcut(
        id: 'copy',
        label: material.copyButtonLabel,
        keys: const ['⌘', 'C'],
        spokenKeys: [command, 'C'],
      ),
      _Shortcut(
        id: 'paste',
        label: material.pasteButtonLabel,
        keys: const ['⌘', 'V'],
        spokenKeys: [command, 'V'],
      ),
      _Shortcut(
        id: 'select-all',
        label: material.selectAllButtonLabel,
        keys: const ['⌘', 'A'],
        spokenKeys: [command, 'A'],
      ),
    ];

    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      appBar: AppBar(
        title: Text(
          l10n.Keyboard_Shortcuts,
          key: const ValueKey('keyboard-shortcuts-title'),
          style: titleStyle,
          maxLines: 2,
        ),
        toolbarHeight: toolbarHeight,
      ),
      body: DeskSurface(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const ValueKey('keyboard-shortcuts-list'),
            padding: EdgeInsets.fromLTRB(
              tokens.space4,
              tokens.space2,
              tokens.space4,
              tokens.space6,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: tokens.contentMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.Keyboard_Shortcuts_Description,
                        style: context.textStyles.bodyLarge?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: tokens.space4),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(tokens.space4),
                          child: Column(
                            children: [
                              for (final (index, shortcut)
                                  in shortcuts.indexed) ...[
                                if (index > 0) Divider(height: tokens.space5),
                                _ShortcutRow(shortcut: shortcut),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut({
    required this.id,
    required this.label,
    required this.keys,
    required this.spokenKeys,
    this.hint,
  });

  final String id;
  final String label;
  final List<String> keys;
  final List<String> spokenKeys;
  final String? hint;
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.shortcut});

  final _Shortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shortcut.label, style: context.textStyles.titleSmall),
        if (shortcut.hint case final hint?) ...[
          SizedBox(height: tokens.space1),
          Text(
            hint,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    final keys = Semantics(
      key: ValueKey('keyboard-shortcut-${shortcut.id}-keys'),
      label: shortcut.spokenKeys.join(' + '),
      excludeSemantics: true,
      child: Wrap(
        spacing: tokens.space1,
        runSpacing: tokens.space1,
        children: [
          for (final key in shortcut.keys)
            Container(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.symmetric(
                horizontal: tokens.space2,
                vertical: tokens.space1,
              ),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Text(
                key,
                textAlign: TextAlign.center,
                style: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );

    return MergeSemantics(
      key: ValueKey('keyboard-shortcut-${shortcut.id}'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <
              MediaQuery.textScalerOf(context).scale(380)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, SizedBox(height: tokens.space2), keys],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: label),
              SizedBox(width: tokens.space4),
              keys,
            ],
          );
        },
      ),
    );
  }
}
