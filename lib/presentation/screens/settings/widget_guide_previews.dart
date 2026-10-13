import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/widget_discovery_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'widget_guide_content.dart';

@Preview(name: 'Mac desktop widgets', group: 'Widgets', size: Size(1100, 760))
Widget macWidgetGuidePreview() =>
    _host(const WidgetGuideContent(platform: TargetPlatform.macOS));

@Preview(
    name: 'Mac widget guide, Chinese 2×',
    group: 'Widgets',
    size: Size(560, 640))
Widget macWidgetGuideChinesePreview() =>
    _host(const WidgetGuideContent(platform: TargetPlatform.macOS),
        chinese: true, scale: 2);

@Preview(
    name: 'Mac widget guide, dark',
    group: 'Widgets',
    size: Size(900, 760),
    brightness: Brightness.dark)
Widget macWidgetGuideDarkPreview() =>
    _host(const WidgetGuideContent(platform: TargetPlatform.macOS), dark: true);

@Preview(name: 'Mac widget invitation', group: 'Widgets', size: Size(760, 360))
Widget macWidgetDiscoveryPreview() => _host(const _DiscoveryPreview());

@Preview(name: 'iOS widget guide', group: 'Widgets', size: Size(390, 844))
Widget iOSWidgetGuidePreview() =>
    _host(const WidgetGuideContent(platform: TargetPlatform.iOS));

Widget _host(Widget screen,
        {bool dark = false, bool chinese = false, double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: (dark ? AppTheme.dark : AppTheme.light)
          .copyWith(platform: TargetPlatform.macOS),
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: screen,
    );

/// Guide navigation and dismissal stay local; no native plugin or preference I/O.
class _DiscoveryPreview extends StatefulWidget {
  const _DiscoveryPreview();

  @override
  State<_DiscoveryPreview> createState() => _DiscoveryPreviewState();
}

class _DiscoveryPreviewState extends State<_DiscoveryPreview> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _dismissed
              ? TextButton(
                  onPressed: () => setState(() => _dismissed = false),
                  child: Text(S.of(context).Retry),
                )
              : WidgetDiscoveryCard(
                  title: S.of(context).Widget_Discovery_Title,
                  body: S.of(context).Widget_Discovery_Body_macOS,
                  actionLabel: S.of(context).Widget_Add_To_Desktop,
                  icon: Icons.desktop_windows_outlined,
                  onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const WidgetGuideContent(
                              platform: TargetPlatform.macOS))),
                  onDismiss: () => setState(() => _dismissed = true),
                ),
        ),
      );
}
