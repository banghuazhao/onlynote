import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_bar.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/button.dart';
import 'package:onlynote/presentation/components/library_filters_sheet.dart';
import 'package:onlynote/presentation/components/note_search_filters.dart';
import 'package:onlynote/presentation/screens/home/widgets/home_menu_item_label.dart';
import 'package:onlynote/presentation/theme/button_styles.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_search.dart';

@Preview(name: 'Library top navigation, 320', size: Size(320, 360))
Widget libraryTopNavigationNarrowPreview() => _libraryPreview();

@Preview(
    name: 'Library top navigation, dark 390',
    size: Size(390, 360),
    brightness: Brightness.dark)
Widget libraryTopNavigationDarkPreview() => _libraryPreview(dark: true);

@Preview(
    name: 'Library top navigation, large Chinese 320', size: Size(320, 440))
Widget libraryTopNavigationLargeChinesePreview() =>
    _libraryPreview(chinese: true, textScale: 2);

@Preview(
    name: 'Library top navigation, large Chinese dark 390',
    size: Size(390, 440),
    brightness: Brightness.dark)
Widget libraryTopNavigationLargeChineseDarkPreview() =>
    _libraryPreview(dark: true, chinese: true, textScale: 2);

@Preview(name: 'Library active search, 320', size: Size(320, 360))
Widget libraryTopNavigationActiveSearchPreview() =>
    _libraryPreview(searching: true);

@Preview(name: 'Library active search, wide 600', size: Size(600, 360))
Widget libraryTopNavigationActiveSearchWidePreview() =>
    _libraryPreview(searching: true);

Widget _libraryPreview(
        {bool dark = false,
        bool chinese = false,
        double textScale = 1,
        bool searching = false}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale), disableAnimations: true),
        child: child!,
      ),
      home: _LibraryTopNavigation(
          showFilterCount: dark || textScale > 1, startSearching: searching),
    );

class _LibraryTopNavigation extends StatefulWidget {
  const _LibraryTopNavigation(
      {required this.showFilterCount, this.startSearching = false});
  final bool showFilterCount;
  final bool startSearching;

  @override
  State<_LibraryTopNavigation> createState() => _LibraryTopNavigationState();
}

class _LibraryTopNavigationState extends State<_LibraryTopNavigation> {
  late Set<NoteSearchFilter> _filters = {
    if (widget.showFilterCount) NoteSearchFilter.photos,
    if (widget.showFilterCount) NoteSearchFilter.pinned,
  };
  late bool _searching = widget.startSearching;
  String? _selectedAction;

  Future<void> _openFilters() async {
    final result = await showAppSheet<LibraryFilterResult>(
      context: context,
      builder: (_) => LibraryFiltersSheet(filters: _filters),
    );
    if (!mounted || result is! ApplyLibraryFilters) return;
    setState(() => _filters = Set.of(result.filters));
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: NoteAppBar(
        autoImplementLeading: false,
        leading: IconButton(
          tooltip: strings.Settings,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => setState(() {
            _searching = false;
            _selectedAction = strings.Settings;
          }),
        ),
        titleWidget:
            Text(strings.notes, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          LibraryFiltersButton(count: _filters.length, onPressed: _openFilters),
          if (width >= 440)
            AppButton(
              tooltip:
                  _searching ? strings.Cancel_Searching : strings.Search_Notes,
              child: HomeSearchStatusIcon(
                  icon: _searching ? Icons.search_off : Icons.search,
                  active: _searching),
              onPressed: () => setState(() => _searching = !_searching),
            ),
          if (width >= 360)
            AppButton(
              tooltip: strings.Today_Title,
              child: const Icon(Icons.today_outlined),
              onPressed: () =>
                  setState(() => _selectedAction = strings.Today_Title),
            ),
          PopupMenuButton<String>(
            tooltip: _searching && width < 440
                ? '${strings.More_Options}, ${strings.Search_Active}'
                : strings.More_Options,
            style: AppButtonStyles.icon(Theme.of(context).colorScheme),
            icon: HomeSearchStatusIcon(
                icon: Icons.more_horiz_rounded,
                active: _searching && width < 440),
            itemBuilder: (_) => [
              if (width < 440)
                PopupMenuItem(
                    value: 'search',
                    child: HomeMenuItemLabel(
                        _searching
                            ? strings.Cancel_Searching
                            : strings.Search_Notes,
                        icon: _searching ? Icons.search_off : Icons.search,
                        activeSearch: _searching)),
              PopupMenuItem(
                  value: 'today',
                  child: HomeMenuItemLabel(strings.Today_Title,
                      icon: Icons.today_outlined)),
              PopupMenuItem(
                  value: 'reminders',
                  child: HomeMenuItemLabel(strings.Reminders_Title,
                      icon: Icons.alarm_outlined)),
              PopupMenuItem(
                  value: 'templates',
                  child: HomeMenuItemLabel(strings.Templates,
                      icon: Icons.dashboard_customize_outlined)),
              PopupMenuItem(
                  value: 'daily-calendar',
                  child: HomeMenuItemLabel(strings.Daily_Note_Calendar,
                      icon: Icons.calendar_month_outlined)),
            ],
            onSelected: (action) => setState(() {
              if (action == 'search') {
                _searching = !_searching;
                _selectedAction = null;
                return;
              }
              _selectedAction = switch (action) {
                'today' => strings.Today_Title,
                'reminders' => strings.Reminders_Title,
                'templates' => strings.Templates,
                'daily-calendar' => strings.Daily_Note_Calendar,
                _ => null,
              };
            }),
          ),
          AppButton(
            primary: true,
            tooltip: strings.Add_Note,
            child: const Icon(Icons.add),
            onPressed: () => setState(() {
              _searching = false;
              _selectedAction = strings.Add_Note;
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _searching
            ? TextField(
                decoration: InputDecoration(
                    hintText: strings.Search_Notes,
                    prefixIcon: const Icon(Icons.search)))
            : Text(_selectedAction ?? strings.notes),
      ),
    );
  }
}
