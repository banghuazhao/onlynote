import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/section_card.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

/// Readable widget setup instructions, also usable without native APIs in previews.
class WidgetGuideContent extends StatelessWidget {
  const WidgetGuideContent({super.key, required this.platform, this.onPin});

  final TargetPlatform platform;
  final VoidCallback? onPin;
  bool get _isMac => platform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      appBar:
          AppBar(title: Text(_isMac ? l10n.Widget_macOS_Title : l10n.Widget)),
      body: DeskSurface(
          child: SafeArea(
              top: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  tokens.space4,
                  tokens.space2,
                  tokens.space4,
                  tokens.space6,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: tokens.contentMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: const _WidgetPreview(),
                            ),
                          ),
                          SizedBox(height: tokens.space4),
                          Text(
                            _isMac
                                ? l10n.Widget_Description_macOS
                                : l10n.Widget_Description,
                            textAlign: TextAlign.center,
                            style: context.textStyles.bodyLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: tokens.space5),
                          if (onPin != null) ...[
                            FilledButton.icon(
                              onPressed: onPin,
                              icon:
                                  const Icon(Icons.add_to_home_screen_rounded),
                              label: Text(l10n.Widget_Add_To_Home),
                            ),
                            SizedBox(height: tokens.space4),
                          ],
                          SectionCard(
                            title: l10n.Widget_Steps_Title,
                            icon: Icons.widgets_outlined,
                            children: [
                              for (final (index, step)
                                  in _steps(l10n).indexed) ...[
                                if (index > 0) SizedBox(height: tokens.space3),
                                _Step(number: index + 1, text: step),
                              ],
                            ],
                          ),
                          SizedBox(height: tokens.space4),
                          SectionCard(
                            title: l10n.Widget_Choose_Note_Title,
                            icon: Icons.checklist_rounded,
                            children: [
                              Text(
                                _isMac
                                    ? l10n.Widget_Choose_Note_macOS
                                    : platform == TargetPlatform.android
                                        ? l10n.Widget_Choose_Note_Android
                                        : l10n.Widget_Choose_Note_iOS,
                                style: context.textStyles.bodyMedium,
                              ),
                              SizedBox(height: tokens.space3),
                              Text(
                                l10n.Widget_Checklist_Tip,
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: tokens.space4),
                          if (_isMac) ...[
                            SectionCard(
                              title: l10n.Widget_Style_Title,
                              icon: Icons.palette_outlined,
                              children: [
                                Text(l10n.Widget_Style_macOS,
                                    style: context.textStyles.bodyMedium),
                              ],
                            ),
                            SizedBox(height: tokens.space4),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 18,
                                color: context.colors.onSurfaceVariant,
                              ),
                              SizedBox(width: tokens.space2),
                              Expanded(
                                child: Text(
                                  _isMac
                                      ? l10n.Widget_Tip_macOS
                                      : l10n.Widget_Tip,
                                  style: context.textStyles.bodySmall?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ))),
    );
  }

  List<String> _steps(S l10n) => switch (platform) {
        TargetPlatform.android => [
            l10n.Widget_Step_Android_1,
            l10n.Widget_Step_Android_2,
            l10n.Widget_Step_Android_3,
            l10n.Widget_Step_Android_4,
          ],
        TargetPlatform.macOS => [
            l10n.Widget_Step_macOS_1,
            l10n.Widget_Step_macOS_2,
            l10n.Widget_Step_macOS_3,
            l10n.Widget_Step_macOS_4,
          ],
        _ => [
            l10n.Widget_Step_iOS_1,
            l10n.Widget_Step_iOS_2,
            l10n.Widget_Step_iOS_3,
            l10n.Widget_Step_iOS_4,
          ],
      };
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final badgeSize = MediaQuery.textScalerOf(context)
            .scale(context.textStyles.labelMedium?.fontSize ?? 12)
            .clamp(16.0, double.infinity)
            .toDouble() *
        1.5;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: context.textStyles.labelMedium?.copyWith(
              color: context.colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: tokens.space3),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text, style: context.textStyles.bodyMedium),
          ),
        ),
      ],
    );
  }
}

/// A miniature of the real widget, so the reader knows what they're looking
/// for in the picker before they go hunting for it.
class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview();

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(tokens.space3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171612) : const Color(0xFFFFF9F0),
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.Onlynote,
                  style: context.textStyles.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: (isDark
                            ? const Color(0xFFFFF9F0)
                            : const Color(0xFF292722))
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space2,
                  vertical: tokens.space1,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4B942),
                  borderRadius: BorderRadius.circular(tokens.radiusLarge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_rounded,
                        size: 11, color: Color(0xFF292722)),
                    SizedBox(width: tokens.space1),
                    Text(
                      l10n.Add_Note,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: const Color(0xFF292722),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space2),
          _PreviewRow(
            color: const Color(0xffF7D9A0),
            title: l10n.Onboarding_Title_1,
            subtitle: l10n.Onboarding_Body_1,
            isDark: isDark,
          ),
          Divider(height: tokens.space4, color: context.colors.outlineVariant),
          _PreviewRow(
            color: const Color(0xffB8E0D2),
            title: l10n.Todo_list,
            subtitle: l10n.Add_todo,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Container(
          width: 3,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: tokens.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFFFF9F0)
                      : const Color(0xFF292722),
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
