import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:onlynote/Tools/widget_sync.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

/// Explains how to put the home screen widget on the device.
///
/// This exists because a widget nobody can find is the same as no widget at
/// all — which is exactly what a reviewer reported before it was built.
class WidgetGuideScreen extends StatefulWidget {
  const WidgetGuideScreen({super.key});

  @override
  State<WidgetGuideScreen> createState() => _WidgetGuideScreenState();
}

class _WidgetGuideScreenState extends State<WidgetGuideScreen> {
  /// Android launchers can offer a one-tap "pin this widget" prompt, but only
  /// from API 26 and only if the launcher implements it. iOS has no equivalent.
  bool _canPin = false;

  @override
  void initState() {
    super.initState();
    _checkPinSupport();
  }

  Future<void> _checkPinSupport() async {
    if (!Platform.isAndroid) return;
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      if (!mounted) return;
      setState(() => _canPin = supported ?? false);
    } catch (_) {
      // Leave the manual steps as the only path.
    }
  }

  Future<void> _pin() async {
    try {
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: WidgetSync.androidWidgetName,
      );
    } catch (_) {
      if (!mounted) return;
      showTransientSnackBar(
        context,
        SnackBar(content: Text(S.of(context).Widget_Add_Unsupported)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      appBar: AppBar(title: Text(l10n.Widget)),
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
                          const _WidgetPreview(),
                          SizedBox(height: tokens.space4),
                          Text(
                            l10n.Widget_Description,
                            textAlign: TextAlign.center,
                            style: context.textStyles.bodyLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: tokens.space5),
                          if (_canPin) ...[
                            FilledButton.icon(
                              onPressed: _pin,
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
                                  l10n.Widget_Tip,
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

  List<String> _steps(S l10n) {
    if (Platform.isAndroid) {
      return [
        l10n.Widget_Step_Android_1,
        l10n.Widget_Step_Android_2,
        l10n.Widget_Step_Android_3,
        l10n.Widget_Step_Android_4,
      ];
    }
    return [
      l10n.Widget_Step_iOS_1,
      l10n.Widget_Step_iOS_2,
      l10n.Widget_Step_iOS_3,
      l10n.Widget_Step_iOS_4,
    ];
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
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
