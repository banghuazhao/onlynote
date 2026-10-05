import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:onlynote/Tools/widget_discovery_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/widget_discovery_card.dart';
import 'package:onlynote/presentation/screens/settings/widget_guide_screen.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

/// Shown after pinning a note, once per installation. Widget lookup and
/// preferences are loaded lazily so this does not delay app startup.
class WidgetDiscoveryPrompt extends StatefulWidget {
  const WidgetDiscoveryPrompt({super.key, required this.eligible});

  final bool eligible;

  @override
  State<WidgetDiscoveryPrompt> createState() => _WidgetDiscoveryPromptState();
}

class _WidgetDiscoveryPromptState extends State<WidgetDiscoveryPrompt>
    with WidgetsBindingObserver {
  final _settings = WidgetDiscoverySettings.instance;
  bool _ready = false;
  bool _checking = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_settingsChanged);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _settings.removeListener(_settingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  void _settingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    if (_checking || !_supported) return;
    _checking = true;
    try {
      await _settings.load();
      if (!_settings.handled) {
        try {
          // The plugin returns widgets belonging to this app on both platforms.
          // A user who already added one does not need the invitation.
          if ((await HomeWidget.getInstalledWidgets()).isNotEmpty) {
            await _settings.complete();
          }
        } catch (_) {
          // Older OS versions and unsupported launchers can still use the guide.
        }
      }
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      debugPrint('Could not load widget discovery preference: $error');
    } finally {
      _checking = false;
    }
  }

  void _openGuide() {
    unawaited(_settings.complete());
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const WidgetGuideScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported || !_ready || !widget.eligible || _settings.handled) {
      return const SizedBox.shrink();
    }
    final l10n = S.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(context.tokens.space4, context.tokens.space2,
          context.tokens.space4, 0),
      child: WidgetDiscoveryCard(
        title: l10n.Widget_Discovery_Title,
        body: l10n.Widget_Discovery_Body,
        actionLabel: l10n.Widget_Add_To_Home,
        onOpen: _openGuide,
        onDismiss: () => unawaited(_settings.complete()),
      ),
    );
  }
}
