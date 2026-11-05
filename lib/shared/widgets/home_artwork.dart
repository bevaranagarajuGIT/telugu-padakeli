import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class HomeArtwork {
  static const background = 'assets/artwork/home/home-background.png';
  static const welcome = 'assets/artwork/home/parrot-welcome.png';
  static const celebration = 'assets/artwork/home/parrot-celebrate.png';
  static const classic = 'assets/artwork/home/classic.png';
  static const learn = 'assets/artwork/home/learn.png';
  static const daily = 'assets/artwork/home/daily.png';
  static const progress = 'assets/artwork/home/progress.png';

  static const assets = [
    background,
    welcome,
    celebration,
    classic,
    learn,
    daily,
    progress,
  ];
}

class HomeScenery extends StatefulWidget {
  const HomeScenery({this.celebrating = false, super.key});

  final bool celebrating;

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
    _motion = AnimationController(
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
        TickerMode.of(context) &&
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
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 320,
      height: 184,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              HomeArtwork.background,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              cacheWidth: 960,
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 4),
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) => Transform.translate(
                    key: const ValueKey('home-mascot-motion'),
                    offset: Offset(0, -3 * math.sin(math.pi * _motion.value)),
                    child: child,
                  ),
                  child: Image.asset(
                    widget.celebrating
                        ? HomeArtwork.celebration
                        : HomeArtwork.welcome,
                    width: 156,
                    height: 168,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    cacheWidth: 468,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
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
