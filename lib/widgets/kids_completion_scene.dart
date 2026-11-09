import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../models/telugu_akshara.dart';
import 'engagement_motion.dart';
import 'premium_telugu_text.dart';

class KidsCompletionScene extends StatelessWidget {
  const KidsCompletionScene({
    required this.word,
    this.animate = true,
    this.earnedStar = false,
    this.totalStars,
    this.character,
    super.key,
  }) : assert(totalStars == null || totalStars >= 0);

  final String word;
  final bool animate;
  final bool earnedStar;
  final int? totalStars;
  final Widget? character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counterHeight = math.max(
      48.0,
      MediaQuery.textScalerOf(
            context,
          ).scale(theme.textTheme.titleLarge?.fontSize ?? 22) +
          20,
    );
    return Column(
      children: [
        EngagementTimeline(
          duration: const Duration(milliseconds: 800),
          animate: animate,
          builder: (context, motion) => RepaintBoundary(
            child: SizedBox(
              height:
                  (character == null ? 236.0 : 316.0) +
                  math.max(0.0, counterHeight - 48),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  final hasCounter = totalStars != null || earnedStar;
                  final counter = Rect.fromLTWH(
                    size.width - math.min(140.0, size.width / 2),
                    0,
                    math.min(140.0, size.width / 2),
                    counterHeight,
                  );
                  return AnimatedBuilder(
                    animation: motion,
                    child: Stack(
                      children: [
                        if (character != null)
                          Positioned.fill(
                            top: hasCounter ? counterHeight : 0,
                            child: character!,
                          )
                        else
                          Positioned.fill(
                            child: ExcludeSemantics(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  key: const ValueKey('completion-artwork'),
                                  painter: _AchievementPainter(motion),
                                ),
                              ),
                            ),
                          ),
                        if (hasCounter)
                          Positioned(
                            top: 0,
                            right: 0,
                            width: counter.width,
                            child: AnimatedBuilder(
                              animation: motion,
                              builder: (context, child) {
                                final arrival = ((motion.value - 0.84) / 0.16)
                                    .clamp(0.0, 1.0);
                                return Transform.scale(
                                  key: const ValueKey('completion-bank-pulse'),
                                  scale: earnedStar
                                      ? 1 + 0.08 * math.sin(math.pi * arrival)
                                      : 1,
                                  child: child,
                                );
                              },
                              child: Semantics(
                                label: totalStars == null
                                    ? 'కొత్త నక్షత్రం: 1'
                                    : 'ఈ సెషన్‌లో $totalStars నక్షత్రాలు',
                                child: ExcludeSemantics(
                                  child: Container(
                                    key: const ValueKey(
                                      'completion-star-total',
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.deepBlue,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: AppColors.gold,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            totalStars?.toString() ?? '+1',
                                            key: const ValueKey(
                                              'completion-star-count',
                                            ),
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    builder: (context, child) {
                      final t = motion.value;
                      final flying = earnedStar && t >= 0.34 && t < 0.84;
                      return Stack(
                        children: [
                          child!,
                          if (flying)
                            Positioned(
                              left: 0,
                              top: 0,
                              child: ExcludeSemantics(
                                child: IgnorePointer(
                                  child: Transform.translate(
                                    offset:
                                        _flightPosition(
                                          size,
                                          counter.center,
                                          t,
                                        ) -
                                        const Offset(20, 20),
                                    child: Transform.scale(
                                      scale: 1 - 0.4 * ((t - 0.34) / 0.5),
                                      child: const SizedBox(
                                        key: ValueKey('completion-star-flight'),
                                        width: 40,
                                        height: 40,
                                        child: CustomPaint(
                                          painter: _FlyingStarPainter(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          key: const ValueKey('completion-word'),
          label: word,
          child: ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final akshara in TeluguAkshara.split(word))
                  Container(
                    constraints: const BoxConstraints(minWidth: 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: PremiumTeluguText(
                      akshara,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Offset _medalCenter(Size size) => Offset(size.width / 2, size.height * 0.57);

Offset _flightPosition(Size size, Offset target, double t) {
  final travel = Curves.easeInOutCubic.transform(
    ((t - 0.34) / 0.5).clamp(0.0, 1.0),
  );
  final start = _medalCenter(size);
  final bend = Offset(start.dx + 48, target.dy - 28);
  final remaining = 1 - travel;
  return start * (remaining * remaining) +
      bend * (2 * remaining * travel) +
      target * (travel * travel);
}

Path _starPath(Offset center, double radius) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final angle = -math.pi / 2 + i * math.pi / 5;
    final r = radius * (i.isEven ? 1 : 0.46);
    final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}

void _drawGoldStar(Canvas canvas, Offset center, double radius) {
  final path = _starPath(center, radius);
  canvas.drawPath(
    path.shift(Offset(0, radius * 0.1)),
    Paint()..color = Color.lerp(AppColors.orange, AppColors.gold, 0.35)!,
  );
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(AppColors.gold, Colors.white, 0.65)!,
          AppColors.gold,
          Color.lerp(AppColors.gold, AppColors.orange, 0.2)!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius)),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * 0.025)
      ..color = Color.lerp(AppColors.gold, Colors.white, 0.7)!,
  );
}

class _AchievementPainter extends CustomPainter {
  _AchievementPainter(this.progress) : super(repaint: progress);
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = _medalCenter(size);
    final radius = math.min(86.0, size.width * 0.29);
    final t = progress.value;
    final entrance = Curves.easeOutCubic.transform((t / 0.4).clamp(0.0, 1.0));
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(radius * 0.94, 0),
          width: radius * 0.43,
          height: radius * 0.25,
        ),
        Paint()..color = AppColors.blue.withValues(alpha: 0.12),
      );
      canvas.restore();
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * 0.88),
        width: radius * 1.6,
        height: 14,
      ),
      Paint()..color = AppColors.deepBlue.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.deepBlue],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius - 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.3),
    );
    _drawGoldStar(
      canvas,
      center + Offset(0, 7 * (1 - entrance)),
      radius * (0.64 + 0.08 * entrance),
    );
    if (t >= 1) return;
    const colors = [AppColors.gold, AppColors.teal, AppColors.purple];
    final burst = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 16; i++) {
      final angle = i * 2.399963;
      final distance = math.min(
        radius * (0.9 + 0.4 * burst),
        math.min(center.dx - 6, size.height - center.dy - 16),
      );
      final point =
          center +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + 10 * t * t,
          );
      canvas.drawCircle(
        point,
        2.0 + i % 3,
        Paint()..color = colors[i % colors.length].withValues(alpha: 1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(_AchievementPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FlyingStarPainter extends CustomPainter {
  const _FlyingStarPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      _drawGoldStar(canvas, size.center(Offset.zero), 18);

  @override
  bool shouldRepaint(_FlyingStarPainter oldDelegate) => false;
}
