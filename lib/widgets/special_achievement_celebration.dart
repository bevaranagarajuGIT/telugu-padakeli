import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import 'bal_hanuman_character.dart';
import 'engagement_motion.dart';
import 'kids_completion_scene.dart';
import 'kids_learning_text.dart';

/// External artwork is injected only after a separate provenance review.
/// The default character is original articulated Flutter vector geometry.
class SpecialAchievementCelebration extends StatefulWidget {
  const SpecialAchievementCelebration({
    required this.completed,
    this.animate = true,
    this.earnedStar = false,
    this.totalStars,
    this.character,
    this.characterDescription,
    this.onSkip,
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
  final VoidCallback? onSkip;
  final double? sceneHeight;

  @override
  State<SpecialAchievementCelebration> createState() =>
      _SpecialAchievementCelebrationState();
}

class _SpecialAchievementCelebrationState
    extends State<SpecialAchievementCelebration> {
  bool _skipped = false;

  @override
  void didUpdateWidget(SpecialAchievementCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.completed) _skipped = false;
  }

  void _skip() {
    if (_skipped) return;
    setState(() => _skipped = true);
    widget.onSkip?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.completed) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final character = widget.character;
    Widget hero(Animation<double> motion) => character == null
        ? KidsCompletionScene(
            animate: false,
            earnedStar: widget.earnedStar,
            totalStars: widget.totalStars,
            character: BalHanumanCharacter(progress: motion),
            sceneHeight: widget.sceneHeight,
          )
        : Column(
            children: [
              if (widget.totalStars != null)
                KidsLearningText(
                  'సంపాదించిన నక్షత్రాలు: ${widget.totalStars}',
                  english: '${widget.totalStars} earned stars',
                  center: true,
                ),
              SizedBox(
                height: 260,
                child: Semantics(
                  label: widget.characterDescription,
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
      animate: widget.animate && !_skipped,
      builder: (context, motion) => Container(
        key: const ValueKey('special-celebration-stage'),
        padding: const EdgeInsets.all(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
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
            ),
            ExcludeSemantics(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: motion,
                  builder: (context, _) => SizedBox(
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          _VictoryStar(
                            index: i,
                            reveal:
                                ((motion.value * 3.5 - 1.6 - i * 0.25) / 0.25)
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
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: dark ? AppColors.gold : AppColors.purple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  KidsLearningText(
                    'చాలా బాగా చేశావు!',
                    english: 'You did very well!',
                    center: true,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedBuilder(
                animation: motion,
                builder: (context, _) => TextButton.icon(
                  key: const ValueKey('special-celebration-skip'),
                  onPressed: motion.value < 1 ? _skip : null,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ).copyWith(animationDuration: Duration.zero),
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const KidsLearningText.control(
                    'దాటవేయి',
                    english: 'Skip animation',
                  ),
                ),
              ),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.star_rounded,
            color: AppColors.gold,
            size: index == 1 ? 48 : 40,
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
