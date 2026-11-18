import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import 'premium_telugu_text.dart';

enum EngagementMoment { correct, retry, completion }

class AnswerCharacterCelebration extends StatefulWidget {
  const AnswerCharacterCelebration({
    required this.child,
    this.animate = true,
    this.answerIndex = 0,
    super.key,
  }) : assert(answerIndex >= 0);

  final Widget child;
  final bool animate;
  final int answerIndex;
  static const artworks = [
    AssetImage('assets/artwork/kids/hanuman-answer-wave.png'),
    AssetImage('assets/artwork/kids/hanuman-answer-clap.png'),
  ];

  @override
  State<AnswerCharacterCelebration> createState() =>
      _AnswerCharacterCelebrationState();
}

class _AnswerCharacterCelebrationState
    extends State<AnswerCharacterCelebration> {
  final _portal = OverlayPortalController()..show();

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    final artwork =
        AnswerCharacterCelebration.artworks[widget.answerIndex %
            AnswerCharacterCelebration.artworks.length];
    return EngagementTimeline(
      duration: const Duration(milliseconds: 900),
      builder: (context, motion) => OverlayPortal(
        controller: _portal,
        overlayLocation: OverlayChildLocation.rootOverlay,
        overlayChildBuilder: (context) => AnimatedBuilder(
          animation: motion,
          builder: (context, _) {
            if (motion.value >= 1) return const SizedBox.shrink();
            final entrance = Curves.easeOutCubic.transform(
              (motion.value / 0.18).clamp(0.0, 1.0),
            );
            final exit = ((1 - motion.value) / 0.12).clamp(0.0, 1.0);
            final frame = math.min(17, (motion.value * 18).floor());
            return Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: exit,
                    child: ColoredBox(
                      key: const ValueKey('answer-celebration-popup'),
                      color: Colors.black.withValues(alpha: 0.76 * entrance),
                      child: SafeArea(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Transform.scale(
                                scale: 0.86 + 0.14 * entrance,
                                child: SizedBox(
                                  width: 340,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const PremiumTeluguText(
                                        'శభాష్!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 46,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.gold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              offset: Offset(0, 3),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox.square(
                                        dimension: 340,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            CustomPaint(
                                              painter: _AnswerSunburst(
                                                motion.value,
                                              ),
                                            ),
                                            ClipRect(
                                              child: Stack(
                                                children: [
                                                  Positioned(
                                                    key: const ValueKey(
                                                      'answer-hanuman-sprite',
                                                    ),
                                                    left: -(frame % 6) * 340.0,
                                                    top: -(frame ~/ 6) * 340.0,
                                                    width: 2040,
                                                    height: 1020,
                                                    child: Image(
                                                      image: artwork,
                                                      key: const ValueKey(
                                                        'answer-hanuman-artwork',
                                                      ),
                                                      fit: BoxFit.fill,
                                                      filterQuality:
                                                          FilterQuality.medium,
                                                      excludeFromSemantics:
                                                          true,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Well done!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          decoration: TextDecoration.none,
                                        ),
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
                  ),
                ),
              ),
            );
          },
        ),
        child: widget.child,
      ),
    );
  }
}

class _AnswerSunburst extends CustomPainter {
  const _AnswerSunburst(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.58),
            AppColors.gold.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );
    final rays = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.55),
          AppColors.gold.withValues(alpha: 0),
        ],
      ).createShader(bounds);
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 + progress * 0.12;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(angle - 0.11) * radius,
          center.dy + math.sin(angle - 0.11) * radius,
        )
        ..lineTo(
          center.dx + math.cos(angle + 0.11) * radius,
          center.dy + math.sin(angle + 0.11) * radius,
        )
        ..close();
      canvas.drawPath(path, rays);
    }
    for (var i = 0; i < 7; i++) {
      final angle = i * 2.4;
      final distance = radius * (0.65 + 0.25 * progress);
      final point =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      final length = 4 + 3 * math.sin(math.pi * progress);
      canvas.drawPath(
        Path()
          ..moveTo(point.dx, point.dy - length)
          ..lineTo(point.dx + length / 3, point.dy)
          ..lineTo(point.dx, point.dy + length)
          ..lineTo(point.dx - length / 3, point.dy)
          ..close(),
        Paint()..color = AppColors.gold,
      );
    }
  }

  @override
  bool shouldRepaint(_AnswerSunburst oldDelegate) =>
      oldDelegate.progress != progress;
}

bool _motionAllowed(BuildContext context, bool foreground) =>
    foreground &&
    !MediaQuery.disableAnimationsOf(context) &&
    TickerMode.valuesOf(context).enabled &&
    (ModalRoute.isCurrentOf(context) ?? true);

bool get _appIsForeground =>
    WidgetsBinding.instance.lifecycleState == null ||
    WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

/// Presentation only: a new keyed instance represents a new gameplay event.
/// The child can be replaced by approved artwork without changing game state.
class EngagementReaction extends StatelessWidget {
  const EngagementReaction({
    required this.moment,
    required this.child,
    this.animate = true,
    super.key,
  });

  final EngagementMoment moment;
  final Widget child;
  final bool animate;

  Duration get _duration => switch (moment) {
    EngagementMoment.correct => const Duration(milliseconds: 420),
    EngagementMoment.retry => const Duration(milliseconds: 220),
    EngagementMoment.completion => const Duration(milliseconds: 900),
  };

  @override
  Widget build(BuildContext context) {
    final completion = moment == EngagementMoment.completion;
    return EngagementTimeline(
      duration: _duration,
      animate: animate,
      builder: (context, motion) => ExcludeSemantics(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: SizedBox(
              height: completion ? 120 : 48,
              child: ClipRect(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (completion)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CelebrationParticles(motion),
                        ),
                      ),
                    AnimatedBuilder(
                      animation: motion,
                      child: child,
                      builder: (context, child) {
                        final pulse = math.sin(math.pi * motion.value);
                        return Transform.translate(
                          offset: Offset(
                            0,
                            moment == EngagementMoment.retry ? 0 : -2 * pulse,
                          ),
                          child: Transform.scale(
                            scale: moment == EngagementMoment.retry
                                ? 1
                                : 1 + 0.18 * pulse,
                            child: Opacity(
                              opacity: moment == EngagementMoment.retry
                                  ? 0.75 + 0.25 * motion.value
                                  : 1,
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shares one-shot lifecycle gates without exposing a reward callback.
class EngagementTimeline extends StatefulWidget {
  const EngagementTimeline({
    required this.duration,
    required this.builder,
    this.animate = true,
    super.key,
  });

  final Duration duration;
  final bool animate;
  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  State<EngagementTimeline> createState() => _EngagementTimelineState();
}

class _EngagementTimelineState extends State<EngagementTimeline>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;
  bool _foreground = true;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    _foreground = _appIsForeground;
    _motion = AnimationController(vsync: this, duration: widget.duration);
    WidgetsBinding.instance.addObserver(this);
  }

  void _syncMotion() {
    if (!widget.animate || !_motionAllowed(context, _foreground)) {
      _motion.value = 1;
      _played = true;
    } else if (!_played) {
      _played = true;
      _motion.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(EngagementTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _motion.duration = widget.duration;
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _motion.view);
}

class _CelebrationParticles extends CustomPainter {
  _CelebrationParticles(this.progress) : super(repaint: progress);
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t >= 1) return;
    const colors = [AppColors.gold, AppColors.purple, AppColors.teal];
    final center = size.center(Offset.zero);
    final radius = math.max(0.0, math.min(size.width, size.height) / 2 - 8);
    final travel = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 16; i++) {
      final angle = i * 2.399963;
      final distance = radius * travel * (0.65 + (i % 3) * 0.15);
      final point =
          center +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + 8 * t * t,
          );
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 1 - t);
      if (i.isEven) {
        canvas.drawCircle(point, 2.5, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: point, width: 4, height: 6),
            const Radius.circular(1),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CelebrationParticles oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Leaves the Material child's callbacks, semantics and hit area unchanged.
class TapFeedback extends StatefulWidget {
  const TapFeedback({required this.child, this.enabled = true, super.key});
  final Widget child;
  final bool enabled;

  @override
  State<TapFeedback> createState() => _TapFeedbackState();
}

class _TapFeedbackState extends State<TapFeedback>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _press;
  bool _foreground = true;

  bool get _allowed => widget.enabled && _motionAllowed(context, _foreground);

  @override
  void initState() {
    super.initState();
    _foreground = _appIsForeground;
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_allowed) _press.value = 0;
  }

  @override
  void didUpdateWidget(TapFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_allowed) _press.value = 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _press.value = 0;
  }

  void _release() {
    if (_allowed) {
      _press.reverse();
    } else {
      _press.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      if (_allowed) _press.forward();
    },
    onPointerUp: (_) => _release(),
    onPointerCancel: (_) => _release(),
    child: AnimatedBuilder(
      animation: _press,
      child: widget.child,
      builder: (context, child) => Transform.scale(
        scale: 1 - 0.025 * Curves.easeOutCubic.transform(_press.value),
        transformHitTests: false,
        child: child,
      ),
    ),
  );
}
