import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_bulk_export.dart';

import 'note_export_section.dart';

@Preview(
  name: 'Remembered export — plain text',
  group: 'Backup',
  size: Size(390, 500),
)
Widget rememberedPlainTextExportPreview() => const _ExportFormatPreview(
      initialFormat: NoteBulkExportFormat.plainText,
    );

@Preview(
  name: 'Remembered export — PDF on Mac, dark',
  group: 'Backup',
  size: Size(640, 420),
  brightness: Brightness.dark,
)
Widget rememberedPdfExportPreview() => const _ExportFormatPreview(
      initialFormat: NoteBulkExportFormat.pdf,
      saveToFile: true,
      dark: true,
    );

@Preview(
  name: 'Remembered export — Chinese 2× narrow',
  group: 'Backup',
  size: Size(280, 900),
)
Widget rememberedExportChinesePreview() => const _ExportFormatPreview(
      initialFormat: NoteBulkExportFormat.markdown,
      chinese: true,
      textScale: 2,
    );

/// The restored preference is supplied in memory, keeping native storage and
/// actual file export outside the preview's interactive format controls.
class _ExportFormatPreview extends StatefulWidget {
  const _ExportFormatPreview({
    required this.initialFormat,
    this.saveToFile = false,
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final NoteBulkExportFormat initialFormat;
  final bool saveToFile;
  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_ExportFormatPreview> createState() => _ExportFormatPreviewState();
}

class _ExportFormatPreviewState extends State<_ExportFormatPreview> {
  late var _format = widget.initialFormat;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: widget.dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: NoteExportSection(
              saveToFile: widget.saveToFile,
              format: _format,
              onFormatChanged: (format) => setState(() => _format = format),
              onExport: () {},
            ),
          ),
        ),
      );
}
