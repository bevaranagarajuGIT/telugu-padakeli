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
              AppHeader(onSettings: onSettings, celebrating: hasActivePuzzle),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasActivePuzzle) ...[
                          _ResumePanel(active: true, onClassic: onClassic),
                          const SizedBox(height: 24),
                        ],
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
                            final enlarged =
                                MediaQuery.textScalerOf(context).scale(
                                  theme.textTheme.bodyLarge?.fontSize ?? 16,
                                ) >
                                18;
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
                            ];
                            if (enlarged || constraints.maxWidth < 340) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  cards[0],
                                  const SizedBox(height: 14),
                                  cards[1],
                                ],
                              );
                            }
                            return SizedBox(
                              height: 214,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: cards[0]),
                                  const SizedBox(width: 14),
                                  Expanded(child: cards[1]),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        if (!hasActivePuzzle) ...[
                          _ResumePanel(active: false, onClassic: onClassic),
                          const SizedBox(height: 24),
                        ],
                        Semantics(
                          header: true,
                          child: PremiumTeluguText(
                            'త్వరలో మరిన్ని',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _UpcomingFeature(
                          title: 'నేటి పదకేళి',
                          subtitle: 'Daily Puzzle',
                          icon: Icons.today_rounded,
                          accent: AppColors.teal,
                          onTap: () => _dailyComingSoon(context),
                        ),
                        const SizedBox(height: 10),
                        _UpcomingFeature(
                          title: 'నా పురోగతి',
                          subtitle: 'My Progress',
                          icon: Icons.insights_rounded,
                          accent: AppColors.pink,
                          onTap: onProgress,
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

class _ResumePanel extends StatelessWidget {
  const _ResumePanel({required this.active, required this.onClassic});
  final bool active;
  final VoidCallback onClassic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: const ValueKey('home-resume-panel'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: AppColors.actionBlue,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: PremiumTeluguText(
                      'Continue Playing',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            PremiumTeluguText(
              active
                  ? 'మీ పదకేళిని కొనసాగించండి.'
                  : 'ఆటను ప్రారంభించి ఇక్కడ నుంచి కొనసాగించండి.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: active ? 'Resume Classic' : 'Start Classic',
              icon: active ? Icons.play_arrow_rounded : Icons.add_rounded,
              onPressed: onClassic,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingFeature extends StatelessWidget {
  const _UpcomingFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      button: true,
      label: '$title, $subtitle, Coming Soon',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.06),
            scheme.surface,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(icon, color: scheme.onSurface, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PremiumTeluguText(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(subtitle, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Coming Soon',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
