import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import 'bal_hanuman_character.dart';
import 'engagement_motion.dart';
import 'kids_completion_scene.dart';
import 'kids_learning_text.dart';

/// External artwork is injected only after a separate provenance review.
/// The default character is original articulated Flutter vector geometry.
class SpecialAchievementCelebration extends StatelessWidget {
  const SpecialAchievementCelebration({
    required this.completed,
    this.animate = true,
    this.earnedStar = false,
    this.totalStars,
    this.character,
    this.characterDescription,
    this.sceneHeight,
    super.key,
  }) : assert(
         character == null ||
             (characterDescription != null && characterDescription != ''),
       );

  final bool completed;
  final bool animate;
  final bool earnedStar;
  final int? totalStars;
  final Widget? character;
  final String? characterDescription;
  final double? sceneHeight;

  @override
  Widget build(BuildContext context) {
    if (!completed) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    Widget hero(Animation<double> motion) => character == null
        ? KidsCompletionScene(
            animate: false,
            earnedStar: earnedStar,
            totalStars: totalStars,
            character: BalHanumanCharacter(progress: motion),
            sceneHeight:
                sceneHeight ??
                (MediaQuery.sizeOf(context).height * 0.2).clamp(80, 128),
          )
        : Column(
            children: [
              if (totalStars != null)
                KidsLearningText(
                  'సంపాదించిన నక్షత్రాలు: $totalStars',
                  english: '$totalStars earned stars',
                  center: true,
                ),
              SizedBox(
                height: sceneHeight ?? 128,
                child: Semantics(
                  label: characterDescription,
                  child: ExcludeSemantics(
                    child: Center(
                      child: FittedBox(fit: BoxFit.contain, child: character),
                    ),
                  ),
                ),
              ),
            ],
          );
    return EngagementTimeline(
      duration: const Duration(milliseconds: 3500),
      animate: animate,
      builder: (context, motion) => Container(
        key: const ValueKey('special-celebration-stage'),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            AppColors.gold.withValues(alpha: dark ? 0.08 : 0.14),
            theme.colorScheme.surface,
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: dark ? 0.3 : 0.65),
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final illustration = RepaintBoundary(
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: motion,
                  child: hero(motion),
                  builder: (context, child) {
                    final seconds = motion.value * 3.5;
                    final entrance = Curves.easeOutBack.transform(
                      (seconds / 0.6).clamp(0.0, 1.0),
                    );
                    final celebration = ((seconds - 0.6) / 1.0).clamp(0.0, 1.0);
                    final sway = math.sin(celebration * math.pi * 2);
                    final phase = switch (seconds) {
                      < 0.6 => 'entrance',
                      < 1.6 => 'celebration',
                      < 2.6 => 'victory',
                      _ => 'completion',
                    };
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ExcludeSemantics(
                            child: IgnorePointer(
                              child: CustomPaint(
                                key: ValueKey('special-phase-$phase'),
                                painter: _MagicCelebrationPainter(motion),
                              ),
                            ),
                          ),
                        ),
                        if (character == null)
                          child!
                        else
                          Transform.translate(
                            key: const ValueKey('special-character-motion'),
                            offset: Offset(0, 14 * (1 - entrance) + 2 * sway),
                            child: Transform.rotate(
                              angle: -0.025 * (1 - entrance) + 0.012 * sway,
                              child: Transform.scale(
                                scale: 0.96 + 0.04 * entrance,
                                child: child,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
            final praise = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: motion,
                      builder: (context, _) => SizedBox(
                        height: 36,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 3; i++)
                              _VictoryStar(
                                index: i,
                                reveal:
                                    ((motion.value * 3.5 - 1.6 - i * 0.25) /
                                            0.25)
                                        .clamp(0.0, 1.0),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  liveRegion: true,
                  child: Column(
                    children: [
                      KidsLearningText(
                        'శభాష్!',
                        english: 'Well done!',
                        center: true,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: dark ? AppColors.gold : AppColors.purple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final textSize = MediaQuery.textScalerOf(
              context,
            ).scale(theme.textTheme.bodyLarge?.fontSize ?? 16);
            if (constraints.maxWidth >= 240 && textSize <= 24) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: illustration),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: praise),
                ],
              );
            }
            return Column(children: [illustration, praise]);
          },
        ),
      ),
    );
  }
}

class _VictoryStar extends StatelessWidget {
  const _VictoryStar({required this.index, required this.reveal});
  final int index;
  final double reveal;

  @override
  Widget build(BuildContext context) => Opacity(
    key: ValueKey('special-victory-star-$index'),
    opacity: reveal,
    child: Transform.translate(
      offset: Offset(0, (1 - Curves.easeOutCubic.transform(reveal)) * 8),
      child: Transform.scale(
        scale: 0.8 + 0.2 * Curves.easeOutCubic.transform(reveal),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.star_rounded,
            color: AppColors.gold,
            size: index == 1 ? 32 : 28,
          ),
        ),
      ),
    ),
  );
}

class _MagicCelebrationPainter extends CustomPainter {
  _MagicCelebrationPainter(this.progress) : super(repaint: progress);
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = progress.value * 3.5;
    final entrance = Curves.easeOutCubic.transform(
      (seconds / 0.6).clamp(0.0, 1.0),
    );
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = math.min(size.width * 0.48, size.height * 0.4);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.22 * entrance),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    if (seconds >= 2.6) return;
    if (seconds < 1.6) {
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + 0.12 * entrance;
        final point =
            center +
            Offset(
              math.cos(angle) * radius * 0.85,
              math.sin(angle) * radius * 0.85,
            );
        canvas.drawCircle(
          point,
          2.5,
          Paint()..color = AppColors.gold.withValues(alpha: 0.65 * entrance),
        );
      }
      return;
    }
    final fall = (seconds - 1.6).clamp(0.0, 1.0);
    const colors = [AppColors.gold, AppColors.teal, AppColors.purple];
    for (var i = 0; i < 16; i++) {
      final x = size.width * (0.08 + (i * 0.618034 % 0.84));
      final y =
          size.height * (0.08 + 0.72 * fall) + math.sin(i + fall * math.pi) * 5;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i.isEven ? 1 : -1) * fall * 0.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-2, -3, 4, 6),
          const Radius.circular(1),
        ),
        Paint()..color = colors[i % colors.length].withValues(alpha: 1 - fall),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MagicCelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
