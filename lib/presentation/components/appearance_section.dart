import 'package:flutter/material.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/section_card.dart';
import 'package:onlynote/presentation/components/settings_choice.dart';
import 'package:onlynote/presentation/components/toast.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  Future<void> _save(BuildContext context, Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      if (context.mounted) {
        context.showToast(S.of(context).Settings_Save_Failed, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppAppearanceSettings.instance;
    final s = S.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SectionCard(
        title: s.Appearance,
        icon: Icons.palette_outlined,
        children: [
          SettingsChoice<ThemeMode>(
            values: ThemeMode.values,
            selected: settings.themeMode,
            label: (mode) => switch (mode) {
              ThemeMode.system => s.Theme_System,
              ThemeMode.light => s.Theme_Light,
              ThemeMode.dark => s.Theme_Dark,
            },
            onSelected: (mode) => _save(context, settings.setThemeMode(mode)),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(s.Plain_Paper),
            subtitle: Text(s.Plain_Paper_Description),
            value: settings.plainPaper,
            onChanged: (value) => _save(context, settings.setPlainPaper(value)),
          ),
        ],
      ),
    );
  }
}
