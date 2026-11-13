import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../shared/widgets/app_header.dart';
import '../shared/widgets/feature_card.dart';
import '../widgets/kids_learning_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onClassic,
    required this.onLearn,
    required this.onProgress,
    required this.onSettings,
    this.onDaily,
    this.onRiddles,
    this.onResume,
    this.hasActivePuzzle = false,
    this.hasSavedLearning = false,
    this.storageNotice,
    super.key,
  });

  final VoidCallback onClassic;
  final VoidCallback onLearn;
  final VoidCallback onProgress;
  final VoidCallback onSettings;
  final VoidCallback? onDaily;
  final VoidCallback? onRiddles;
  final VoidCallback? onResume;
  final bool hasActivePuzzle;
  final bool hasSavedLearning;
  final String? storageNotice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey('home-scroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(onSettings: onSettings, celebrating: hasActivePuzzle),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (storageNotice != null) ...[
                        MaterialBanner(
                          content: Text(storageNotice!),
                          actions: [
                            TextButton(
                              onPressed: onSettings,
                              child: const Text('Settings / వివరాలు'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          'Choose your game',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (hasActivePuzzle || hasSavedLearning) ...[
                        FilledButton.icon(
                          key: const ValueKey('home-resume'),
                          onPressed: onResume ?? onClassic,
                          icon: const Icon(Icons.play_arrow_rounded),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 64),
                            padding: const EdgeInsets.all(12),
                          ),
                          label: KidsLearningText.control(
                            'కొనసాగించండి',
                            english: hasActivePuzzle && !hasSavedLearning
                                ? 'Resume Classic'
                                : 'Resume learning',
                            center: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final primary = [
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
                          final large =
                              MediaQuery.textScalerOf(context).scale(
                                theme.textTheme.bodyLarge?.fontSize ?? 16,
                              ) >
                              18;
                          if (constraints.maxWidth < 340 || large) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                primary.first,
                                const SizedBox(height: 12),
                                primary.last,
                              ],
                            );
                          }
                          return SizedBox(
                            height: 214,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: primary.first),
                                const SizedBox(width: 14),
                                Expanded(child: primary.last),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      if (onRiddles != null) ...[
                        _secondary(
                          context,
                          keyName: 'home-riddles',
                          title: 'పొడుపు కథలు',
                          english: 'Telugu Riddles',
                          icon: Icons.psychology_alt_rounded,
                          background: AppColors.teal,
                          foreground: AppColors.ink,
                          onTap: onRiddles!,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _secondary(
                        context,
                        keyName: 'home-daily',
                        title: 'నేటి పదకేళి',
                        english: 'Daily Puzzle',
                        icon: Icons.today_rounded,
                        background: AppColors.gold,
                        foreground: AppColors.ink,
                        onTap: onDaily ?? onClassic,
                      ),
                      const SizedBox(height: 12),
                      _secondary(
                        context,
                        keyName: 'home-progress',
                        title: 'నా పురోగతి',
                        english: 'My Progress',
                        icon: Icons.insights_rounded,
                        background: AppColors.deepBlue,
                        foreground: Colors.white,
                        onTap: onProgress,
                      ),
                      if (!hasActivePuzzle && !hasSavedLearning)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'ఆటను ప్రారంభించండి. ఇక్కడి నుంచే కొనసాగించవచ్చు.\n'
                            'Start an activity. Your place will be saved here.',
                            style: theme.textTheme.bodyMedium,
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
    );
  }

  Widget _secondary(
    BuildContext context, {
    required String keyName,
    required String title,
    required String english,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) => ListTile(
    key: ValueKey(keyName),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    minVerticalPadding: 16,
    horizontalTitleGap: 14,
    leading: Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 28, color: foreground),
    ),
    title: KidsLearningText.control(
      title,
      english: english,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w700,
      ),
    ),
    trailing: Icon(Icons.arrow_forward_rounded, color: foreground),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    tileColor: background,
  );
}
