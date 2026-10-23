import 'package:flutter/material.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';

import 'onboarding_content.dart';

@RoutePage(name: 'OnboardingRoute')
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.completeOnboarding});

  /// Allows isolated interaction tests without writing platform preferences.
  final Future<void> Function()? completeOnboarding;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _starting = false;
  bool _failed = false;
  NoteEditorStart? _retryStart;

  Future<void> _finish({NoteEditorStart? start}) async {
    if (!mounted || _starting || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    setState(() {
      _starting = true;
      _failed = false;
      _retryStart = start;
    });
    try {
      await (widget.completeOnboarding?.call() ??
          OnboardingSettings.instance.complete());
    } catch (_) {
      if (mounted) {
        setState(() {
          _starting = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) {
      setState(() => _starting = false);
      return;
    }

    if (start == null) {
      context.router.replace(const HomeRoute());
    } else {
      // Keep Home under the editor so Done and Back land in the note library.
      context.router.replaceAll([
        const HomeRoute(),
        AddUpdateNoteRoute(start: start),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) => OnboardingContent(
        starting: _starting,
        failed: _failed,
        onSkip: () => _finish(),
        onWriteNote: () => _finish(start: NoteEditorStart.quickNote),
        onMakeChecklist: () => _finish(start: NoteEditorStart.checklist),
        onRetry: () => _finish(start: _retryStart),
      );
}
