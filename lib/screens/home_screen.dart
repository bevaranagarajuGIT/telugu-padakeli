import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../shared/widgets/app_buttons.dart';
import '../shared/widgets/app_header.dart';
import '../shared/widgets/feature_card.dart';
import '../widgets/premium_telugu_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onClassic,
    required this.onLearn,
    required this.onProgress,
    required this.onSettings,
    this.hasActivePuzzle = false,
    super.key,
  });

  final VoidCallback onClassic;
  final VoidCallback onLearn;
  final VoidCallback onProgress;
  final VoidCallback onSettings;
  final bool hasActivePuzzle;

  void _dailyComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: PremiumTeluguText('Daily Puzzle త్వరలో వస్తుంది'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey('home-scroll'),
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('dashboard-entrance'),
          tween: Tween(begin: 0, end: 1),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) =>
              Opacity(opacity: 0.9 + 0.1 * value, child: child),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(onSettings: onSettings),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const gap = 14.0;
                            final enlarged =
                                MediaQuery.textScalerOf(context).scale(
                                  theme.textTheme.bodyLarge?.fontSize ?? 16,
                                ) >
                                22;
                            final columns =
                                enlarged || constraints.maxWidth < 340
                                ? 1
                                : constraints.maxWidth >= 900
                                ? 4
                                : 2;
                            final width =
                                (constraints.maxWidth - gap * (columns - 1)) /
                                columns;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                  width: width,
                                  child: FeatureCard(
                                    title: 'పదకేళి ఆడండి',
                                    subtitle: 'Classic Padakeli',
                                    icon: Icons.grid_on_rounded,
                                    background: AppColors.purple,
                                    foreground: Colors.white,
                                    onTap: onClassic,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: FeatureCard(
                                    title: 'చిన్నారుల ఆటలు',
                                    subtitle: 'Play & Learn',
                                    icon: Icons.child_care_rounded,
                                    background: AppColors.orange,
                                    foreground: AppColors.ink,
                                    onTap: onLearn,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: FeatureCard(
                                    title: 'నేటి పదకేళి',
                                    subtitle: 'Daily Puzzle',
                                    icon: Icons.today_rounded,
                                    background: AppColors.teal,
                                    foreground: AppColors.ink,
                                    onTap: () => _dailyComingSoon(context),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: FeatureCard(
                                    title: 'నా పురోగతి',
                                    subtitle: 'My Progress',
                                    icon: Icons.insights_rounded,
                                    background: AppColors.pink,
                                    foreground: AppColors.ink,
                                    onTap: onProgress,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        Semantics(
                          header: true,
                          child: PremiumTeluguText(
                            'Continue Playing',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        PremiumTeluguText(
                          hasActivePuzzle
                              ? 'మీ పదకేళిని కొనసాగించండి.'
                              : 'ఆటను ప్రారంభించి ఇక్కడ నుంచి కొనసాగించండి.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: hasActivePuzzle
                              ? 'Resume Classic'
                              : 'Start Classic',
                          icon: hasActivePuzzle
                              ? Icons.play_arrow_rounded
                              : Icons.add_rounded,
                          onPressed: onClassic,
                        ),
                        const SizedBox(height: 28),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.brightness == Brightness.dark
                                ? scheme.surfaceContainerHigh
                                : AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AppColors.actionBlue,
                                    size: 32,
                                  ),
                                ),
                                PremiumTeluguText(
                                  'Featured Daily Challenge',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                PremiumTeluguText(
                                  'Coming Soon',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                PremiumTeluguText(
                                  'కొత్త రోజువారీ పదకేళి త్వరలో ఇక్కడ వస్తుంది.',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 12),
                                SecondaryButton(
                                  label: 'Try the sample puzzle',
                                  onPressed: onClassic,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
