import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../shared/widgets/app_header.dart';
import '../shared/widgets/feature_card.dart';
import '../shared/widgets/home_artwork.dart';
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
      backgroundColor: theme.brightness == Brightness.dark
          ? AppColors.darkBackground
          : Colors.white,
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
                  padding: const EdgeInsets.all(12),
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
                      if (hasActivePuzzle || hasSavedLearning) ...[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.actionBlue, Color(0xFF006DE8)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: FilledButton.icon(
                            key: const ValueKey('home-resume'),
                            onPressed: onResume ?? onClassic,
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 36,
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 72),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            label: Row(
                              children: [
                                Expanded(
                                  child: KidsLearningText.control(
                                    'కొనసాగించండి',
                                    english:
                                        hasActivePuzzle && !hasSavedLearning
                                        ? 'Resume Classic'
                                        : 'Resume learning',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize:
                                          (theme
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.fontSize ??
                                              16) *
                                          1.25,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    englishStyle: theme.textTheme.bodyLarge
                                        ?.copyWith(
                                          fontFamily: 'Roboto',
                                          color: Colors.white,
                                        ),
                                    center: true,
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final primary = [
                            FeatureCard(
                              key: const ValueKey('home-classic'),
                              title: 'పదకేళి ఆడండి',
                              subtitle: 'Classic Padakeli',
                              icon: Icons.grid_on_rounded,
                              artwork: FeatureCardArtwork.crossword,
                              background: const Color(0xFF873AF2),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF914CF4), Color(0xFF6426D6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              foreground: Colors.white,
                              onTap: onClassic,
                            ),
                            FeatureCard(
                              key: const ValueKey('home-learn'),
                              title: 'చిన్నారుల ఆటలు',
                              subtitle: 'Play & Learn',
                              icon: Icons.child_care_rounded,
                              artwork: FeatureCardArtwork.learn,
                              background: AppColors.orange,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF9C18),
                                  Color(0xFFFF8A00),
                                  Color(0xFFB95100),
                                  Color(0xFFB95100),
                                ],
                                stops: [0, 0.48, 0.60, 1],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              foreground: Colors.white,
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
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: primary.first),
                                const SizedBox(width: 12),
                                Expanded(child: primary.last),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (onRiddles != null) ...[
                        _secondary(
                          context,
                          keyName: 'home-riddles',
                          title: 'పొడుపు కథలు',
                          english: 'Telugu Riddles',
                          artwork: HomeArtwork.riddles,
                          background: AppColors.teal,
                          foreground: AppColors.ink,
                          riddles: true,
                          onTap: onRiddles!,
                        ),
                        const SizedBox(height: 12),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final shortcuts = [
                            _secondary(
                              context,
                              keyName: 'home-daily',
                              title: 'నేటి పదకేళి',
                              english: 'Daily Puzzle',
                              artwork: HomeArtwork.daily,
                              background: theme.colorScheme.primaryContainer,
                              foreground: theme.colorScheme.onPrimaryContainer,
                              onTap: onDaily ?? onClassic,
                              compact: true,
                            ),
                            _secondary(
                              context,
                              keyName: 'home-progress',
                              title: 'నా పురోగతి',
                              english: 'My Progress',
                              artwork: HomeArtwork.progress,
                              background: theme.colorScheme.primaryContainer,
                              foreground: theme.colorScheme.onPrimaryContainer,
                              onTap: onProgress,
                              compact: true,
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
                                shortcuts.first,
                                const SizedBox(height: 12),
                                shortcuts.last,
                              ],
                            );
                          }
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: shortcuts.first),
                                const SizedBox(width: 12),
                                Expanded(child: shortcuts.last),
                              ],
                            ),
                          );
                        },
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
    required String artwork,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    bool compact = false,
    bool riddles = false,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = riddles
        ? Colors.white
        : dark
        ? foreground
        : const Color(0xFF0750AD);
    final fill = riddles
        ? const Color(0xFF007D65)
        : compact
        ? Color.alphaBlend(
            background.withValues(alpha: dark ? 0.30 : 0.08),
            theme.colorScheme.surface,
          )
        : background;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(compact ? 18 : 22),
      side: compact
          ? BorderSide(
              color: dark
                  ? foreground.withValues(alpha: 0.18)
                  : const Color(0xFFD4E5FB),
            )
          : BorderSide.none,
    );
    return Material(
      key: ValueKey(keyName),
      color: fill,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: riddles
            ? const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF009F89), Color(0xFF007D65)],
                  stops: [0, 0.5],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Row(
              children: [
                if (riddles)
                  ExcludeSemantics(
                    child: SizedBox(
                      key: const ValueKey('home-riddles-artwork'),
                      width: 96,
                      height: 76,
                      child: Image.asset(
                        artwork,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                        cacheWidth: 288,
                      ),
                    ),
                  )
                else
                  Image.asset(
                    artwork,
                    width: 34,
                    height: 38,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    cacheWidth: 102,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: KidsLearningText.control(
                    title,
                    english: english,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ink,
                      fontSize:
                          (theme.textTheme.bodyLarge?.fontSize ?? 16) *
                          (compact ? 0.875 : 1.25),
                      fontWeight: FontWeight.w700,
                    ),
                    englishStyle:
                        (compact
                                ? theme.textTheme.bodySmall
                                : theme.textTheme.bodyLarge)
                            ?.copyWith(color: ink, fontFamily: 'Roboto'),
                  ),
                ),
                ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: ink,
                    size: compact ? 18 : 26,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
