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
              : const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: child,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                onSettings: onSettings,
                celebrating: hasActivePuzzle,
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: PremiumTeluguText(
                            'Choose your game',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const gap = 14.0;
                            final enlarged =
                                MediaQuery.textScalerOf(context).scale(
                                  theme.textTheme.bodyLarge?.fontSize ?? 16,
                                ) >
                                18;
                            final columns =
                                enlarged || constraints.maxWidth < 340
                                ? 1
                                : constraints.maxWidth >= 900
                                ? 4
                                : 2;
                            final cards = [
                              FeatureCard(
                                title: 'పదకేళి ఆడండి',
                                subtitle: 'Classic Padakeli',
                                icon: Icons.grid_on_rounded,
                                artwork: FeatureCardArtwork.crossword,
                                background: AppColors.purple,
                                foreground: Colors.white,
                                onTap: onClassic,
                              ),
                              FeatureCard(
                                title: 'చిన్నారుల ఆటలు',
                                subtitle: 'Play & Learn',
                                icon: Icons.child_care_rounded,
                                artwork: FeatureCardArtwork.learn,
                                background: AppColors.orange,
                                foreground: AppColors.ink,
                                onTap: onLearn,
                              ),
                              FeatureCard(
                                title: 'నేటి పదకేళి',
                                subtitle: 'Daily Puzzle',
                                icon: Icons.today_rounded,
                                artwork: FeatureCardArtwork.daily,
                                background: AppColors.teal,
                                foreground: AppColors.ink,
                                status: 'Coming Soon',
                                onTap: () => _dailyComingSoon(context),
                              ),
                              FeatureCard(
                                title: 'నా పురోగతి',
                                subtitle: 'My Progress',
                                icon: Icons.insights_rounded,
                                artwork: FeatureCardArtwork.progress,
                                background: AppColors.pink,
                                foreground: AppColors.ink,
                                status: 'Coming Soon',
                                onTap: onProgress,
                              ),
                            ];
                            if (columns == 1) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (
                                    var index = 0;
                                    index < cards.length;
                                    index++
                                  )
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index == cards.length - 1
                                            ? 0
                                            : gap,
                                      ),
                                      child: cards[index],
                                    ),
                                ],
                              );
                            }

                            final rows = <Widget>[];
                            for (
                              var start = 0;
                              start < cards.length;
                              start += columns
                            ) {
                              final rowCards = cards
                                  .skip(start)
                                  .take(columns)
                                  .toList();
                              rows.add(
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: start + columns >= cards.length
                                        ? 0
                                        : gap,
                                  ),
                                  child: SizedBox(
                                    height: 214,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (
                                          var index = 0;
                                          index < rowCards.length;
                                          index++
                                        )
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right:
                                                    index == rowCards.length - 1
                                                    ? 0
                                                    : gap,
                                              ),
                                              child: rowCards[index],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: rows,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.brightness == Brightness.dark
                                ? scheme.surfaceContainerHigh
                                : scheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: scheme.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.shadow.withValues(alpha: 0.07),
                                offset: const Offset(0, 5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(
                                          alpha: 0.28,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: AppColors.actionBlue,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Semantics(
                                        header: true,
                                        child: PremiumTeluguText(
                                          'Continue Playing',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                PremiumTeluguText(
                                  hasActivePuzzle
                                      ? 'మీ పదకేళిని కొనసాగించండి.'
                                      : 'ఆటను ప్రారంభించి ఇక్కడ నుంచి కొనసాగించండి.',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 14),
                                PrimaryButton(
                                  label: hasActivePuzzle
                                      ? 'Resume Classic'
                                      : 'Start Classic',
                                  icon: hasActivePuzzle
                                      ? Icons.play_arrow_rounded
                                      : Icons.add_rounded,
                                  onPressed: onClassic,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.brightness == Brightness.dark
                                ? scheme.surfaceContainerHigh
                                : AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: scheme.brightness == Brightness.dark
                                  ? scheme.outlineVariant
                                  : AppColors.blue.withValues(alpha: 0.12),
                            ),
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
