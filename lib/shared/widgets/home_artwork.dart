import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

abstract final class HomeArtwork {
  static const background = 'assets/artwork/home/home-background.png';
  static const welcome = 'assets/artwork/home/parrot-refined.png';
  static const celebration = 'assets/artwork/home/parrot-celebrate.png';
  static const classic = 'assets/artwork/home/classic-refined.png';
  static const learn = 'assets/artwork/home/learn-refined.png';
  static const riddles = 'assets/artwork/home/riddles-refined.png';
  static const daily = 'assets/artwork/home/daily-refined.png';
  static const progress = 'assets/artwork/home/progress-refined.png';

  static const assets = [
    background,
    welcome,
    celebration,
    classic,
    learn,
    riddles,
    daily,
    progress,
  ];
}

class HomeScenery extends StatefulWidget {
  const HomeScenery({
    this.celebrating = false,
    this.foreground,
    this.reserveMascotSpace = false,
    super.key,
  });

  final bool celebrating;
  final Widget? foreground;
  final bool reserveMascotSpace;

  @override
  State<HomeScenery> createState() => _HomeSceneryState();
}

class _HomeSceneryState extends State<HomeScenery>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;
  Timer? _idleTimer;
  bool _motionAllowed = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _motion =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && _motionAllowed) {
            _scheduleIdleMotion();
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateMotion();
  }

  void _updateMotion() {
    final allowed =
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (allowed == _motionAllowed) return;
    _motionAllowed = allowed;
    _idleTimer?.cancel();
    if (allowed) {
      _scheduleIdleMotion();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  void _scheduleIdleMotion() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted && _motionAllowed) _motion.forward(from: 0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.foreground == null ? 320 : double.infinity,
    height: widget.foreground == null ? 184 : null,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final mascotWidth = widget.foreground == null
            ? 156.0
            : (constraints.maxWidth * 0.34).clamp(104.0, 132.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0756C5), Color(0xFF007CC1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              if (widget.foreground != null)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.deepBlue.withValues(alpha: 0.24),
                          AppColors.deepBlue.withValues(alpha: 0.16),
                          AppColors.deepBlue.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.80, 1],
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -4,
                bottom: -6,
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) => Transform.translate(
                    key: const ValueKey('home-mascot-motion'),
                    offset: Offset(
                      0,
                      -(widget.celebrating ? 3 : 2) *
                          math.sin(math.pi * _motion.value),
                    ),
                    child: child,
                  ),
                  child: Image.asset(
                    HomeArtwork.welcome,
                    width: mascotWidth,
                    height: widget.foreground == null ? 184 : 156,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    cacheWidth: 468,
                  ),
                ),
              ),
              if (widget.foreground != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 140),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      widget.reserveMascotSpace ? mascotWidth + 24 : 80,
                      16,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: widget.foreground,
                    ),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
