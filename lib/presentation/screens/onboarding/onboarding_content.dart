import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

/// First-launch controls without navigation or native storage dependencies.
class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.onSkip,
    required this.onWriteNote,
    required this.onMakeChecklist,
    this.onRetry,
    this.starting = false,
    this.failed = false,
  });

  final VoidCallback onSkip;
  final VoidCallback onWriteNote;
  final VoidCallback onMakeChecklist;
  final VoidCallback? onRetry;
  final bool starting;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.all(context.tokens.space5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            key: const ValueKey('onboarding-skip'),
                            onPressed: starting ? null : onSkip,
                            child: Text(l10n.Onboarding_Skip),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: context.tokens.space5),
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
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (starting) ...[
                              Semantics(
                                key: const ValueKey('onboarding-starting'),
                                liveRegion: true,
                                label: l10n.Onboarding_Starting,
                                excludeSemantics: true,
                                child: Row(
                                  children: [
                                    SizedBox.square(
                                      dimension: 20,
                                      child: MediaQuery.disableAnimationsOf(
                                              context)
                                          ? const Icon(
                                              Icons.hourglass_top_rounded,
                                              size: 20)
                                          : const CircularProgressIndicator(
                                              strokeWidth: 2),
                                    ),
                                    SizedBox(width: context.tokens.space3),
                                    Expanded(
                                        child: Text(l10n.Onboarding_Starting)),
                                  ],
                                ),
                              ),
                              SizedBox(height: context.tokens.space3),
                            ] else if (failed) ...[
                              Semantics(
                                key: const ValueKey('onboarding-start-error'),
                                liveRegion: true,
                                label: l10n.Onboarding_Start_Failed,
                                excludeSemantics: true,
                                child: Text(
                                  l10n.Onboarding_Start_Failed,
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ),
                              if (onRetry != null)
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton.icon(
                                    key: const ValueKey('onboarding-retry'),
                                    onPressed: onRetry,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: Text(l10n.Retry),
                                  ),
                                ),
                              SizedBox(height: context.tokens.space3),
                            ],
                            FilledButton.icon(
                              key: const ValueKey('onboarding-write-note'),
                              onPressed: starting ? null : onWriteNote,
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(l10n.Onboarding_Write_Note),
                            ),
                            SizedBox(height: context.tokens.space2),
                            OutlinedButton.icon(
                              key: const ValueKey('onboarding-checklist'),
                              onPressed: starting ? null : onMakeChecklist,
                              icon: const Icon(Icons.checklist_rounded),
                              label: Text(l10n.Onboarding_Make_Checklist),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
