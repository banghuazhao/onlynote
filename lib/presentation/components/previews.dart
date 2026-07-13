import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:onlynote/presentation/components/section_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';

@Preview(name: 'Settings section — light', size: Size(390, 260))
Widget settingsSectionLightPreview() => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SectionCard(
            title: 'Purchases',
            subtitle: 'Manage upgrades and restore previous purchases.',
            icon: Icons.workspace_premium_outlined,
            children: const [
              ListTile(
                leading: Icon(Icons.block_outlined),
                title: Text('Remove Ads'),
                subtitle: Text('One-time purchase'),
              ),
            ],
          ),
        ),
      ),
    );

@Preview(
  name: 'Settings section — dark',
  size: Size(390, 260),
  brightness: Brightness.dark,
)
Widget settingsSectionDarkPreview() => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            children: const [ListTile(title: Text('Typography'))],
          ),
        ),
      ),
    );
