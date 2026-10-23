import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';

import 'onboarding_content.dart';

@Preview(name: 'Onboarding — ready', group: 'Onboarding', size: Size(375, 740))
Widget onboardingReadyPreview({ThemeData? theme}) =>
    _OnboardingPreview(theme: theme);

@Preview(name: 'Onboarding — saving', group: 'Onboarding', size: Size(375, 740))
Widget onboardingPendingPreview({ThemeData? theme}) =>
    _OnboardingPreview(pending: true, theme: theme);

@Preview(
    name: 'Onboarding — retry, dark', group: 'Onboarding', size: Size(375, 740))
Widget onboardingRetryDarkPreview({ThemeData? theme}) =>
    _OnboardingPreview(failed: true, dark: true, theme: theme);

@Preview(
    name: 'Onboarding — Chinese retry 2×',
    group: 'Onboarding',
    size: Size(280, 640))
Widget onboardingRetryChinesePreview({ThemeData? theme}) =>
    _OnboardingPreview(failed: true, chinese: true, textScale: 2, theme: theme);

/// Feedback only: no preferences, route changes, or platform APIs.
class _OnboardingPreview extends StatefulWidget {
  const _OnboardingPreview(
      {this.pending = false,
      this.failed = false,
      this.dark = false,
      this.chinese = false,
      this.textScale = 1,
      this.theme});

  final bool pending;
  final bool failed;
  final bool dark;
  final bool chinese;
  final double textScale;
  final ThemeData? theme;

  @override
  State<_OnboardingPreview> createState() => _OnboardingPreviewState();
}

class _OnboardingPreviewState extends State<_OnboardingPreview> {
  late bool _starting = widget.pending;
  late bool _failed = widget.failed;

  Future<void> _tryStart() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _failed = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _starting = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: widget.theme ?? (widget.dark ? AppTheme.dark : AppTheme.light),
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(widget.textScale),
                disableAnimations: true),
            child: child!),
        home: OnboardingContent(
            starting: _starting,
            failed: _failed,
            onSkip: _tryStart,
            onWriteNote: _tryStart,
            onMakeChecklist: _tryStart,
            onRetry: _tryStart),
      );
}
