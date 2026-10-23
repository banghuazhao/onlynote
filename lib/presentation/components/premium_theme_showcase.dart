import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

import 'note_theme_labels.dart';
import 'note_theme_surface.dart';
import 'paper_note.dart';

/// Localized display samples only; these never create or modify library notes.
class PremiumThemeShowcase extends StatelessWidget {
  const PremiumThemeShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(strings.Premium_Showcase_Title,
              style: context.textStyles.titleLarge),
        ),
        SizedBox(height: tokens.space3),
        LayoutBuilder(builder: (context, constraints) {
          final samples = [
            _SampleNote(
              theme: NoteTheme.dottedJournal,
              title: strings.Premium_Showcase_Note_Title,
              body: strings.Premium_Showcase_Note_Body,
            ),
            _SampleNote(
              theme: NoteTheme.kraftNotebook,
              title: strings.Premium_Showcase_Checklist_Title,
              body: strings.Premium_Showcase_Checklist_Item,
              checklist: true,
            ),
          ];
          final sideBySide = constraints.maxWidth >= 340 &&
              MediaQuery.textScalerOf(context).scale(16) < 24;
          return sideBySide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: samples[0]),
                    SizedBox(width: tokens.space3),
                    Expanded(child: samples[1]),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    samples[0],
                    SizedBox(height: tokens.space4),
                    samples[1],
                  ],
                );
        }),
      ],
    );
  }
}

class _SampleNote extends StatelessWidget {
  const _SampleNote({
    required this.theme,
    required this.title,
    required this.body,
    this.checklist = false,
  });

  final NoteTheme theme;
  final String title;
  final String body;
  final bool checklist;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bodyStyle = context.textStyles.bodyMedium
        ?.copyWith(color: AppColors.ink, height: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaperNote(
          key: ValueKey('premium-showcase-${theme.name}'),
          theme: theme,
          color: noteThemePaperColor(theme),
          seed: checklist ? 8 : 3,
          plainPaper: false,
          tilt: false,
          exportMode: true,
          padding: EdgeInsets.all(tokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: context.textStyles.titleSmall
                      ?.copyWith(color: AppColors.ink)),
              SizedBox(height: tokens.space3),
              if (checklist)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(Icons.check_box_outlined,
                          size: 18, color: AppColors.ink),
                    ),
                    SizedBox(width: tokens.space2),
                    Expanded(child: Text(body, style: bodyStyle)),
                  ],
                )
              else
                Text(body, style: bodyStyle),
            ],
          ),
        ),
        SizedBox(height: tokens.space2),
        Text(noteThemeLabel(theme, S.of(context)),
            style: context.textStyles.bodySmall
                ?.copyWith(color: context.colors.onSurface)),
      ],
    );
  }
}
