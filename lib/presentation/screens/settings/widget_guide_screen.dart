import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:onlynote/Tools/widget_discovery_settings.dart';
import 'package:onlynote/Tools/widget_sync.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'widget_guide_content.dart';

/// Explains how to put the home screen widget on the device.
///
/// This exists because a widget nobody can find is the same as no widget at
/// all — which is exactly what a reviewer reported before it was built.
class WidgetGuideScreen extends StatefulWidget {
  const WidgetGuideScreen({super.key});

  @override
  State<WidgetGuideScreen> createState() => _WidgetGuideScreenState();
}

class _WidgetGuideScreenState extends State<WidgetGuideScreen> {
  /// Android launchers can offer a one-tap "pin this widget" prompt, but only
  /// from API 26 and only if the launcher implements it. iOS has no equivalent.
  bool _canPin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(WidgetDiscoverySettings.instance.complete());
    });
    _checkPinSupport();
  }

  Future<void> _checkPinSupport() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      if (!mounted) return;
      setState(() => _canPin = supported ?? false);
    } catch (_) {
      // Leave the manual steps as the only path.
    }
  }

  Future<void> _pin() async {
    try {
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: WidgetSync.androidWidgetName,
      );
    } catch (_) {
      if (!mounted) return;
      showTransientSnackBar(
        context,
        SnackBar(content: Text(S.of(context).Widget_Add_Unsupported)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => WidgetGuideContent(
        platform: defaultTargetPlatform,
        onPin: _canPin ? _pin : null,
      );
}
