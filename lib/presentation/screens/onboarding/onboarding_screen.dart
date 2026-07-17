import 'package:flutter/material.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

@RoutePage(name: 'OnboardingRoute')
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    (
      icon: Icons.edit_note_rounded,
      titleKey: 0,
      bodyKey: 0,
    ),
    (
      icon: Icons.folder_special_outlined,
      titleKey: 1,
      bodyKey: 1,
    ),
    (
      icon: Icons.notifications_active_outlined,
      titleKey: 2,
      bodyKey: 2,
    ),
  ];

  Future<void> _finish() async {
    await OnboardingSettings.instance.complete();
    if (!mounted) return;
    context.router.replace(const HomeRoute());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final titles = [
      l10n.Onboarding_Title_1,
      l10n.Onboarding_Title_2,
      l10n.Onboarding_Title_3,
    ];
    final bodies = [
      l10n.Onboarding_Body_1,
      l10n.Onboarding_Body_2,
      l10n.Onboarding_Body_3,
    ];
    final isLast = _index == _pages.length - 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.tokens.space5),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l10n.Onboarding_Skip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 56,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        SizedBox(height: context.tokens.space5),
                        Text(
                          titles[index],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: context.tokens.space3),
                        Text(
                          bodies[index],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final selected = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: selected ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              SizedBox(height: context.tokens.space5),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: Text(
                    isLast
                        ? l10n.Onboarding_Get_Started
                        : l10n.Onboarding_Next,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
