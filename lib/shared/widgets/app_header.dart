import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/premium_telugu_text.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({required this.onSettings, super.key});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.actionBlue, AppColors.deepBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PremiumTeluguText(
                            'Telugu Padakeli',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onSettings,
                          tooltip: 'Settings',
                          color: Colors.white,
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final showArt =
                            constraints.maxWidth >= 320 &&
                            MediaQuery.textScalerOf(
                                  context,
                                ).scale(textTheme.bodyLarge?.fontSize ?? 16) <=
                                22;
                        final title = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: PremiumTeluguText(
                                'తెలుగు పదకేళి',
                                style: textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            PremiumTeluguText(
                              'పదాలతో ఆట, భాషతో ఆనందం',
                              style: textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                        if (!showArt) return title;
                        if (constraints.maxWidth < 560) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              title,
                              const SizedBox(height: 8),
                              const Align(
                                alignment: Alignment.centerRight,
                                child: _HeaderArtwork(),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: title),
                            const SizedBox(width: 18),
                            const _HeaderArtwork(),
                          ],
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

class _HeaderArtwork extends StatefulWidget {
  const _HeaderArtwork();

  @override
  State<_HeaderArtwork> createState() => _HeaderArtworkState();
}

class _HeaderArtworkState extends State<_HeaderArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  Timer? _idleTimer;
  bool _motionAllowed = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motionAllowed = false;
      _idleTimer?.cancel();
      _motion.stop();
      _motion.value = 0;
    } else if (!_motionAllowed) {
      _motionAllowed = true;
      _scheduleIdleMotion();
    }
  }

  void _scheduleIdleMotion() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted || !_motionAllowed) return;
      _motion.forward(from: 0).whenComplete(() {
        if (mounted && _motionAllowed) _scheduleIdleMotion();
      });
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _motion,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -3 * math.sin(math.pi * _motion.value)),
        child: child,
      ),
      child: CustomPaint(
        size: const Size(198, 142),
        painter: _TeluguLandscapeArt(blink: _motion.value > 0.97),
      ),
    ),
  );
}

class _TeluguLandscapeArt extends CustomPainter {
  const _TeluguLandscapeArt({required this.blink});

  final bool blink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 198, size.height / 142);
    final paint = Paint()..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 5, 194, 135),
        const Radius.circular(24),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    paint.color = AppColors.gold;
    canvas.drawCircle(const Offset(163, 28), 15, paint);
    for (var ray = 0; ray < 8; ray++) {
      final angle = ray * 0.785;
      final start = Offset(
        163 + 20 * math.cos(angle),
        28 + 20 * math.sin(angle),
      );
      final end = Offset(163 + 24 * math.cos(angle), 28 + 24 * math.sin(angle));
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = AppColors.gold
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawOval(const Rect.fromLTWH(15, 29, 47, 15), cloud);
    canvas.drawCircle(const Offset(28, 28), 9, cloud);
    canvas.drawCircle(const Offset(43, 26), 12, cloud);
    canvas.drawOval(const Rect.fromLTWH(105, 45, 37, 12), cloud);
    canvas.drawCircle(const Offset(116, 43), 7, cloud);
    canvas.drawCircle(const Offset(130, 42), 9, cloud);

    final mountain = Path()
      ..moveTo(0, 104)
      ..lineTo(34, 68)
      ..lineTo(62, 96)
      ..lineTo(91, 61)
      ..lineTo(128, 104)
      ..close();
    canvas.drawPath(mountain, Paint()..color = const Color(0xFF74CBE0));
    final farHill = Path()
      ..moveTo(0, 103)
      ..quadraticBezierTo(39, 67, 83, 101)
      ..quadraticBezierTo(137, 65, 198, 97)
      ..lineTo(198, 142)
      ..lineTo(0, 142)
      ..close();
    canvas.drawPath(farHill, Paint()..color = const Color(0xFF65D3A4));
    final nearHill = Path()
      ..moveTo(0, 119)
      ..quadraticBezierTo(57, 91, 105, 119)
      ..quadraticBezierTo(153, 89, 198, 111)
      ..lineTo(198, 142)
      ..lineTo(0, 142)
      ..close();
    canvas.drawPath(nearHill, Paint()..color = const Color(0xFF20B58B));

    final tilePaint = Paint()..color = const Color(0xFFFFFCF2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(25, 55, 80, 68),
        const Radius.circular(15),
      ),
      Paint()
        ..color = AppColors.deepBlue.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 50, 80, 68),
        const Radius.circular(15),
      ),
      tilePaint,
    );
    final tileColors = [
      const Color(0xFFFFD66E),
      const Color(0xFFFF9C72),
      const Color(0xFF76D6BF),
      const Color(0xFFB7A2FF),
    ];
    const letters = ['అ', 'ఆ', 'క', 'ళి'];
    for (var index = 0; index < letters.length; index++) {
      final column = index % 2;
      final row = index ~/ 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(29 + column * 33, 56 + row * 30, 29, 27),
          const Radius.circular(7),
        ),
        Paint()..color = tileColors[index],
      );
      final painter = TextPainter(
        text: TextSpan(
          text: letters[index],
          style: const TextStyle(
            fontFamily: PremiumTeluguText.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.deepBlue,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(43 + column * 33 - painter.width / 2, 55 + row * 30),
      );
      painter.dispose();
    }

    final birdShadow = Paint()
      ..color = AppColors.deepBlue.withValues(alpha: 0.2);
    canvas.drawOval(const Rect.fromLTWH(128, 121, 46, 8), birdShadow);
    canvas.drawOval(
      const Rect.fromLTWH(133, 76, 35, 48),
      Paint()..color = const Color(0xFF18BFC5),
    );
    final wing = Path()
      ..moveTo(139, 94)
      ..quadraticBezierTo(157, 85, 164, 104)
      ..quadraticBezierTo(151, 115, 137, 108)
      ..close();
    canvas.drawPath(wing, Paint()..color = const Color(0xFF087F9B));
    canvas.drawOval(
      const Rect.fromLTWH(140, 55, 32, 33),
      Paint()..color = const Color(0xFF24D0C2),
    );
    final crest = Path()
      ..moveTo(145, 58)
      ..quadraticBezierTo(137, 46, 149, 51)
      ..quadraticBezierTo(151, 43, 158, 53)
      ..quadraticBezierTo(166, 47, 164, 59)
      ..close();
    canvas.drawPath(crest, Paint()..color = const Color(0xFFFFC857));
    canvas.drawCircle(const Offset(162, 70), 7, Paint()..color = Colors.white);
    if (blink) {
      canvas.drawLine(
        const Offset(159, 70),
        const Offset(165, 70),
        Paint()
          ..color = AppColors.ink
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawCircle(
        const Offset(163, 70),
        3,
        Paint()..color = AppColors.ink,
      );
    }
    final beak = Path()
      ..moveTo(170, 73)
      ..quadraticBezierTo(184, 70, 180, 81)
      ..quadraticBezierTo(174, 85, 169, 80)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFF9B45));
    canvas.drawOval(
      const Rect.fromLTWH(143, 111, 17, 7),
      Paint()..color = const Color(0xFFB8F2D7),
    );
    canvas.drawLine(
      const Offset(145, 121),
      const Offset(142, 126),
      Paint()
        ..color = const Color(0xFFFF9B45)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(157, 121),
      const Offset(160, 126),
      Paint()
        ..color = const Color(0xFFFF9B45)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    for (final flower in const [Offset(17, 124), Offset(115, 130)]) {
      canvas.drawCircle(flower, 3, Paint()..color = Colors.white);
      canvas.drawCircle(flower, 1.2, Paint()..color = const Color(0xFFFFC857));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TeluguLandscapeArt oldDelegate) =>
      oldDelegate.blink != blink;
}
