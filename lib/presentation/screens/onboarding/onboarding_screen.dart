import 'package:flutter/material.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

@RoutePage(name: 'OnboardingRoute')
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _starting = false;

  Future<void> _finish({NoteEditorStart? start}) async {
    if (_starting) return;
    setState(() => _starting = true);
    await OnboardingSettings.instance.complete();
    if (!mounted) return;

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
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: EdgeInsets.all(context.tokens.space5),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _starting ? null : () => _finish(),
                      child: Text(l10n.Onboarding_Skip),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 56,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            SizedBox(height: context.tokens.space5),
                            Text(
                              l10n.Onboarding_Title_1,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            SizedBox(height: context.tokens.space3),
                            Text(
                              l10n.Onboarding_Body_1,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _starting
                          ? null
                          : () => _finish(start: NoteEditorStart.quickNote),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.Onboarding_Write_Note),
                    ),
                  ),
                  SizedBox(height: context.tokens.space2),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _starting
                          ? null
                          : () => _finish(start: NoteEditorStart.checklist),
                      icon: const Icon(Icons.checklist_rounded),
                      label: Text(l10n.Onboarding_Make_Checklist),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
