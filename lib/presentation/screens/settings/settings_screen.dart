import 'package:flutter/material.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  String _fontSizeLabel(BuildContext context, AppFontSize fontSize) {
    switch (fontSize) {
      case AppFontSize.small:
        return S.of(context).Small;
      case AppFontSize.medium:
        return S.of(context).Medium;
      case AppFontSize.large:
        return S.of(context).Large;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppTypographySettings.instance;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).Settings)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacings.xl),
            children: [
              Text(S.of(context).Font_Style, style: AppTypography.headline6),
              const SizedBox(height: AppSpacings.m),
              for (final fontFamily in kAppFontFamilies.keys)
                RadioListTile<String>(
                  value: fontFamily,
                  groupValue: settings.fontFamily,
                  title: Text(
                    fontFamily,
                    style: kAppFontFamilies[fontFamily]!(fontSize: 16, color: AppColors.title),
                  ),
                  onChanged: (value) {
                    if (value != null) settings.setFontFamily(value);
                  },
                ),
              const SizedBox(height: AppSpacings.xl),
              Text(S.of(context).Font_Size, style: AppTypography.headline6),
              const SizedBox(height: AppSpacings.m),
              for (final fontSize in AppFontSize.values)
                RadioListTile<AppFontSize>(
                  value: fontSize,
                  groupValue: settings.fontSize,
                  title: Text(
                    _fontSizeLabel(context, fontSize),
                    style: TextStyle(fontSize: 14 * fontSize.scale, color: AppColors.title),
                  ),
                  onChanged: (value) {
                    if (value != null) settings.setFontSize(value);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
