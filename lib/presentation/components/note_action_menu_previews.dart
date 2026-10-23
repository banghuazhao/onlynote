import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import 'app_sheet.dart';

@Preview(name: 'Note actions — grouped', group: 'Note', size: Size(390, 700))
Widget noteActionMenuPreview() => const _NoteActionMenuPreview();

@Preview(
  name: 'Note actions — dark narrow 2×',
  group: 'Note',
  size: Size(240, 700),
  brightness: Brightness.dark,
)
Widget noteActionMenuDarkPreview() =>
    const _NoteActionMenuPreview(dark: true, textScale: 2);

@Preview(name: 'Note actions — Chinese 2×', group: 'Note', size: Size(280, 700))
Widget noteActionMenuChinesePreview() =>
    const _NoteActionMenuPreview(locale: Locale('zh', 'HK'), textScale: 2);

/// Choosing a fixture action only updates its local selection indicator.
class _NoteActionMenuPreview extends StatefulWidget {
  const _NoteActionMenuPreview({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
  });

  final bool dark;
  final Locale locale;
  final double textScale;

  @override
  State<_NoteActionMenuPreview> createState() => _NoteActionMenuPreviewState();
}

class _NoteActionMenuPreviewState extends State<_NoteActionMenuPreview> {
  String? _selected;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          brightness: widget.dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: const Color(0xFF685947),
          fontFamilyFallback: const ['DroidSansFallback'],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(body: Builder(builder: (context) {
          final s = S.of(context);
          AppSheetAction action(String id, String label, IconData icon,
                  {String? section, bool destructive = false}) =>
              AppSheetAction(
                title: Text(label),
                section: section,
                leading: Icon(icon),
                destructive: destructive,
                selected: _selected == id,
                onPressed: (_) => setState(() => _selected = id),
              );
          return Align(
            alignment: Alignment.bottomCenter,
            child: AppActionSheet(title: s.More_Options, actions: [
              action('edit', s.Edit, Icons.edit_outlined,
                  section: s.Note_Menu_Editing),
              action(
                  'outline', s.Note_Outline, Icons.format_list_bulleted_rounded,
                  section: s.Note_Menu_Editing),
              action('find', s.Find_In_Note, Icons.manage_search_rounded,
                  section: s.Note_Menu_Editing),
              action('tags', s.Edit_Tags, Icons.sell_outlined,
                  section: s.Note_Menu_Organization),
              action('links', s.Link_Note, Icons.link_rounded,
                  section: s.Note_Menu_Organization),
              action('archive', s.Archive_Note, Icons.archive_outlined,
                  section: s.Note_Menu_Organization),
              action('share', s.Share, Icons.share_outlined,
                  section: s.Note_Menu_Sharing),
              action('info', s.Note_Info, Icons.info_outline_rounded,
                  section: s.Note_Menu_Details),
              action('history', s.History_Title, Icons.history_rounded,
                  section: s.Note_Menu_Details),
              action('delete', s.Delete, Icons.delete_outline,
                  destructive: true),
            ]),
          );
        })),
      );
}
