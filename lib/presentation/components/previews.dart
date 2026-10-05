import 'dart:convert';

import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/presentation/components/note_template_picker_sheet.dart';
import 'package:onlynote/presentation/components/template_name_dialog.dart';
import 'package:onlynote/presentation/components/note_checklist.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/presentation/components/button.dart';
import 'package:onlynote/presentation/components/widget_discovery_card.dart';
import 'package:onlynote/presentation/components/reminder_picker_sheet.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/presentation/theme/button_styles.dart';
import 'package:onlynote/presentation/components/appearance_section.dart';
import 'package:onlynote/presentation/components/note_search_filters.dart';
import 'package:onlynote/presentation/components/note_share_sheet.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/custom_template_images.dart';
import 'package:onlynote/services/reminder_agenda.dart';
import 'package:onlynote/presentation/screens/reminders/reminders_agenda_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

@Preview(name: 'Today and upcoming reminders', size: Size(390, 740))
Widget remindersAgendaPreview() {
  final now = DateTime(2026, 10, 6, 10);
  ReminderAgendaEntry entry(String id, String title, DateTime due,
          {bool snoozed = false,
          ReminderRepeat repeat = ReminderRepeat.none}) =>
      ReminderAgendaEntry(
        note: Note(id: id, title: title),
        reminder: Reminder(
            noteId: id,
            reminderId: id.hashCode & 0x7fffffff,
            reminderDate: due,
            repeat: repeat),
        dueDate: due,
        snoozed: snoozed,
      );
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [S.delegate],
    home: Scaffold(
      appBar: AppBar(title: const Text('Today & Upcoming')),
      body: DeskSurface(
        child: RemindersAgendaList(
          now: now,
          entries: [
            entry('shopping', 'Pick up groceries', DateTime(2026, 10, 5, 17)),
            entry('dentist', 'Call the dentist', DateTime(2026, 10, 6, 10, 10),
                snoozed: true),
            entry('journal', 'Evening journal', DateTime(2026, 10, 6, 20),
                repeat: ReminderRepeat.daily),
            entry('packing', 'Weekend packing', DateTime(2026, 10, 9, 18)),
          ],
          busyReminderId: null,
          onOpen: previewAgendaAction,
          onSnooze: previewAgendaAction,
          onReschedule: previewAgendaAction,
        ),
      ),
    ),
  );
}

void previewAgendaAction(ReminderAgendaEntry _) {}

@Preview(name: 'Widget discovery', size: Size(390, 280))
Widget widgetDiscoveryPreview() => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: WidgetDiscoveryCard(
            title: 'Keep pinned notes in view',
            body:
                'Add a widget to your Home Screen for a quick glance at your notes.',
            actionLabel: 'Add to Home Screen',
            onOpen: previewButtonPressed,
            onDismiss: previewButtonPressed,
          ),
        ),
      ),
    );

@Preview(name: 'Repeating reminder', size: Size(390, 620))
Widget repeatingReminderPreview() => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ReminderPickerSheet(
            current: Reminder(
              noteId: 'preview',
              reminderId: 1,
              reminderDate: DateTime(2024, 1, 1, 9),
              repeat: ReminderRepeat.weekly,
            ),
          ),
        ),
      ),
    );

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

@Preview(name: 'Search filters and matches', size: Size(390, 300))
Widget searchFiltersPreview() => const _SearchPreview();

class _SearchPreview extends StatefulWidget {
  const _SearchPreview();
  @override
  State<_SearchPreview> createState() => _SearchPreviewState();
}

class _SearchPreviewState extends State<_SearchPreview> {
  Set<NoteSearchFilter> filters = {NoteSearchFilter.checklists};
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
            body: DeskSurface(
                child: Column(children: [
          NoteSearchFilters(
              selected: filters,
              onChanged: (value) => setState(() => filters = value)),
          const Padding(
              padding: EdgeInsets.all(24),
              child: PaperNote(
                color: AppColors.parchment,
                tilt: false,
                child: SearchHighlight('Pick up tea at the market',
                    query: 'tea',
                    style: TextStyle(fontSize: 22, color: AppColors.ink)),
              )),
        ]))),
      );
}

@Preview(name: 'Share formats', size: Size(390, 560))
Widget shareFormatsPreview() => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [S.delegate],
      home: const Scaffold(body: NoteShareSheet()),
    );

@Preview(name: 'Appearance controls', size: Size(390, 340))
Widget appearanceControlsPreview() => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [S.delegate],
      home: const Scaffold(
          body:
              Padding(padding: EdgeInsets.all(16), child: AppearanceSection())),
    );

@Preview(name: 'Buttons — light', size: Size(390, 650))
Widget buttonsLightPreview() => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [S.delegate],
      home: const Scaffold(body: DeskSurface(child: ButtonExamples())),
    );

@Preview(
    name: 'Buttons — dark', size: Size(390, 650), brightness: Brightness.dark)
Widget buttonsDarkPreview() => MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [S.delegate],
      home: const Scaffold(body: DeskSurface(child: ButtonExamples())),
    );

void previewButtonPressed() {}

class ButtonExamples extends StatelessWidget {
  const ButtonExamples({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Everyday actions',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
                onPressed: previewButtonPressed,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add note')),
            OutlinedButton(
                onPressed: previewButtonPressed, child: const Text('Restore')),
            TextButton(
                onPressed: previewButtonPressed, child: const Text('Cancel')),
          ]),
          const SizedBox(height: 24),
          Text('Toolbar', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 4, runSpacing: 8, children: [
            IconButton(
                tooltip: 'Settings',
                onPressed: previewButtonPressed,
                icon: const Icon(Icons.settings_outlined)),
            const AppButton(
                tooltip: 'Search',
                onPressed: previewButtonPressed,
                child: Icon(Icons.search)),
            const AppButton(
                tooltip: 'Delete',
                destructive: true,
                onPressed: previewButtonPressed,
                child: Icon(Icons.delete_outline)),
            const AppButton(
                primary: true,
                onPressed: previewButtonPressed,
                child: Text('Done')),
          ]),
          const SizedBox(height: 24),
          Text('On paper', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          PaperNote(
              color: AppColors.parchment,
              tilt: false,
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                IconButton(
                    tooltip: 'Share',
                    style: AppButtonStyles.paper(),
                    onPressed: previewButtonPressed,
                    icon: const Icon(Icons.ios_share_rounded)),
                IconButton(
                    tooltip: 'Selected',
                    style: AppButtonStyles.paper(selected: true),
                    isSelected: true,
                    onPressed: previewButtonPressed,
                    icon: const Icon(Icons.check_rounded)),
                IconButton(
                    tooltip: 'Remove photo',
                    style: AppButtonStyles.paper(destructive: true),
                    onPressed: previewButtonPressed,
                    icon: const Icon(Icons.close_rounded)),
              ])),
          const SizedBox(height: 24),
          const Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: null, child: Text('Unavailable')),
            AppButton(
                isLoading: true, onPressed: null, child: Text('Save note')),
          ]),
        ]),
      );
}

@Preview(name: 'Starter templates', size: Size(390, 640))
Widget starterTemplatesPreview() => const _TemplatePickerPreview();

@Preview(name: 'Saved and starter templates', size: Size(390, 740))
Widget customTemplatesPreview() =>
    const _TemplatePickerPreview(includeCustom: true);

@Preview(name: 'Template name', size: Size(390, 500))
Widget templateNamePreview() => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [S.delegate],
      home: const Scaffold(
        body: Center(
          child: TemplateNameDialog(
            title: 'Save as template',
            initial: 'Weekend packing',
          ),
        ),
      ),
    );

class _TemplatePickerPreview extends StatefulWidget {
  const _TemplatePickerPreview({this.includeCustom = false});
  final bool includeCustom;

  @override
  State<_TemplatePickerPreview> createState() => _TemplatePickerPreviewState();
}

class _TemplatePickerPreviewState extends State<_TemplatePickerPreview> {
  late final CustomNoteTemplateStore _store;

  @override
  void initState() {
    super.initState();
    final preferences = _PreviewTemplatePreferences();
    if (widget.includeCustom) {
      final template = CustomNoteTemplate(
        id: 'preview-weekend-packing',
        name: 'Weekend packing',
        title: 'Weekend trip',
        body: 'Destination:\nTravel plans:',
        items: ['Travel documents', 'Phone and charger', 'Clothes'],
        color: AppColors.parchment.toARGB32(),
        createdAt: DateTime(2024, 1, 1),
      );
      preferences.values[CustomNoteTemplateStore.storageKey] = jsonEncode({
        'version': 1,
        'templates': [template.toJson()],
      });
    }
    _store = CustomNoteTemplateStore(
      preferences: preferences,
      images: _PreviewTemplateImages(),
    );
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [S.delegate],
        home: Scaffold(body: NoteTemplatePickerSheet(store: _store)),
      );
}

/// Preview edits stay in memory and never touch the app's saved templates.
class _PreviewTemplatePreferences implements SharedPreferencesAsync {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unsupported preview preference operation');
}

class _PreviewTemplateImages implements CustomTemplateImages {
  @override
  Future<List<String>> copyToTemplate(List<String> sources) async => [];

  @override
  Future<List<String>> copyToNote(List<String> sources) async => [];

  @override
  Future<void> deleteTemplates(List<String> paths) async {}

  @override
  Future<void> pruneTemplates(Set<String> keep) async {}
}

@Preview(name: 'Checklist progress', size: Size(390, 500))
Widget checklistProgressPreview() => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
          body: Padding(
        padding: const EdgeInsets.all(20),
        child: PaperNote(
          kind: PaperNoteKind.sheet,
          color: AppColors.parchment,
          child: NoteChecklist(todos: [
            Todo(id: 'one', title: 'Pick up fresh bread'),
            Todo(id: 'two', title: 'Bring a reusable bag', completed: true),
            Todo(id: 'three', title: 'Plan dinner'),
          ], onToggle: previewChecklistToggle, onReset: previewChecklistReset),
        ),
      )),
    );

void previewChecklistToggle(String id) {}
Future<void> previewChecklistReset() async {}
