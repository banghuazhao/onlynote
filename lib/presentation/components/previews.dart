import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/confirm_dialog.dart';
import 'package:onlynote/presentation/components/folder_name_dialog.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/section_card.dart';
import 'package:onlynote/presentation/theme/colors.dart';
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

@Preview(name: 'Paper scrap on desk', size: Size(390, 340))
Widget paperScrapPreview() => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.desk,
        body: DeskSurface(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: PaperNote(
              color: const Color(0xFFFFF4C2),
              seed: 12,
              child: const Text(
                'Pick up dry cleaning\nCall the dentist at 3',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );

@Preview(name: 'Notebook sheet', size: Size(390, 560))
Widget paperSheetPreview() => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.desk,
        body: DeskSurface(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PaperNote(
              color: const Color(0xFFFFF6D8),
              kind: PaperNoteKind.sheet,
              seed: 4,
              tilt: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Saturday market',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Bread, citrus, and the good olives.\nLeave a note for the florist.',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  PaperChecklistRow(label: 'Bring tote bags', completed: true),
                  PaperChecklistRow(
                      label: 'Cash for the stall', completed: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );

@Preview(name: 'Sheets and alerts — light', size: Size(390, 650))
Widget modalLightPreview() => _modalPreview(AppTheme.light);

@Preview(name: 'Sheets and alerts — dark', size: Size(390, 650))
Widget modalDarkPreview() => _modalPreview(AppTheme.dark);

Widget _modalPreview(ThemeData theme) => MaterialApp(
      theme: theme,
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        backgroundColor: theme.brightness == Brightness.dark
            ? AppColors.deskDark
            : AppColors.desk,
        body: Builder(
            builder: (context) => Center(
                  child: Wrap(spacing: 12, runSpacing: 12, children: [
                    FilledButton(
                      onPressed: () => showAppActionSheet(
                          context: context,
                          title: 'Note actions',
                          actions: [
                            AppSheetAction(
                                title: const Text('Pin'),
                                leading: const Icon(Icons.push_pin_outlined),
                                onPressed: (context) => Navigator.pop(context)),
                            AppSheetAction(
                                title: const Text('Move to folder'),
                                selected: true,
                                leading: const Icon(Icons.folder_outlined),
                                onPressed: (context) => Navigator.pop(context)),
                            AppSheetAction(
                                title: const Text('Delete'),
                                destructive: true,
                                leading: const Icon(Icons.delete_outline),
                                onPressed: (context) => Navigator.pop(context)),
                          ]),
                      child: const Text('Open sheet'),
                    ),
                    OutlinedButton(
                      onPressed: () => showConfirmDialog(context,
                          title: 'Delete this note?',
                          message:
                              'This note will be moved to Trash. You can restore it later.'),
                      child: const Text('Delete alert'),
                    ),
                    OutlinedButton(
                      onPressed: () => showDialog<String>(
                          context: context,
                          builder: (_) =>
                              const FolderNameDialog(title: 'New folder')),
                      child: const Text('Folder dialog'),
                    ),
                  ]),
                )),
      ),
    );

@Preview(name: 'Backup and restore section', size: Size(390, 360))
Widget backupSectionPreview() => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.desk,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SectionCard(
            title: 'Create backup',
            icon: Icons.inventory_2_outlined,
            subtitle:
                'Save your notes, checklists, folders, photos, and reminder dates in one Onlynote file.',
            children: [
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Create backup'),
                  )),
            ],
          ),
        ),
      ),
    );
