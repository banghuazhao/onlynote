import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/generated/l10n.dart';

import 'folder_name_search.dart';

Widget _app({
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double scale = 1,
  double keyboardHeight = 0,
}) {
  final theme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xff657349),
    brightness: brightness,
    fontFamilyFallback: const ['DroidSansFallback'],
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        viewInsets: EdgeInsets.only(bottom: keyboardHeight),
      ),
      child: child!,
    ),
    home: const Scaffold(body: _MoveFolderPreview()),
  );
}

@Preview(name: 'Folder name search · light', size: Size(390, 700))
Widget folderNameSearchLightPreview() => _app();

@Preview(name: 'Folder name search · dark', size: Size(390, 700))
Widget folderNameSearchDarkPreview() => _app(brightness: Brightness.dark);

@Preview(name: 'Folder name search · Chinese 2× narrow', size: Size(180, 700))
Widget folderNameSearchChinesePreview() =>
    _app(locale: const Locale('zh'), scale: 2);

@Preview(
    name: 'Folder name search · Hong Kong Chinese keyboard',
    size: Size(568, 320))
Widget folderNameSearchKeyboardPreview() =>
    _app(locale: const Locale('zh', 'HK'), scale: 2, keyboardHeight: 96);

class _MoveFolderPreview extends StatefulWidget {
  const _MoveFolderPreview();

  @override
  State<_MoveFolderPreview> createState() => _MoveFolderPreviewState();
}

class _MoveFolderPreviewState extends State<_MoveFolderPreview> {
  String? _selected = 'work';
  int _generation = 0;

  @override
  Widget build(BuildContext context) => MoveToFolderSheet(
        key: ValueKey(_generation),
        folders: [
          Folder(id: 'work', name: 'Work'),
          Folder(id: 'research', name: 'Research [2026]'),
          Folder(id: 'literal', name: 'C++'),
          Folder(id: 'reading', name: '閱讀與研究筆記'),
          Folder(id: 'projects', name: '工作項目和重要事項'),
        ],
        selectedFolderId: _selected,
        onSelected: (id) => setState(() {
          _selected = id;
          _generation++;
        }),
        onCancel: () => setState(() => _generation++),
      );
}
