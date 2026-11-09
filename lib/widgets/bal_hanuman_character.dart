import 'dart:math' as math;

import 'package:flutter/material.dart';

@immutable
class BalHanumanPose {
  const BalHanumanPose({
    required this.scale,
    required this.rise,
    required this.headTilt,
    required this.armRaise,
    required this.handWave,
    required this.gadaTilt,
    required this.tailSwing,
    required this.eyeOpen,
  });

  factory BalHanumanPose.at(double progress) {
    final seconds = progress.clamp(0.0, 1.0) * 3.5;
    final entrance = Curves.easeOutBack.transform(
      (seconds / 0.6).clamp(0.0, 1.0),
    );
    final celebration = ((seconds - 0.6) / 1.0).clamp(0.0, 1.0);
    final sway = math.sin(celebration * math.pi * 2);
    final wave = ((seconds - 1.1) / 0.5).clamp(0.0, 1.0);
    final blink = ((seconds - 0.95) / 0.24).clamp(0.0, 1.0);
    return BalHanumanPose(
      scale: 0.88 + 0.12 * entrance,
      rise: 24 * (1 - entrance),
      headTilt: 0.045 * sway,
      armRaise:
          1.9 *
          Curves.easeInOutCubic.transform(
            ((seconds - 0.6) / 0.5).clamp(0.0, 1.0),
          ),
      handWave: 0.16 * math.sin(wave * math.pi * 4),
      gadaTilt: -0.13 * sway,
      tailSwing: 0.10 * sway,
      eyeOpen: 1 - 0.9 * math.sin(blink * math.pi),
    );
  }

  final double scale;
  final double rise;
  final double headTilt;
  final double armRaise;
  final double handWave;
  final double gadaTilt;
  final double tailSwing;
  final double eyeOpen;
}

/// Original vector geometry; each articulated part has its own canvas pivot.
/// The parent owns the finite timeline and all lifecycle/reduced-motion gates.
class BalHanumanCharacter extends StatelessWidget {
  const BalHanumanCharacter({required this.progress, super.key});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'చిన్న హనుమంతుడు చిరునవ్వుతో చేయి ఊపుతూ అభినందిస్తున్నాడు',
    image: true,
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('bal-hanuman-character'),
            painter: BalHanumanPainter(progress),
            size: const Size(280, 320),
          ),
        ),
      ),
    ),
  );
}

class BalHanumanPainter extends CustomPainter {
  BalHanumanPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;
  BalHanumanPose get pose => BalHanumanPose.at(progress.value);

  static const _skin = Color(0xFFE9A765);
  static const _light = Color(0xFFFFDBAA);
  static const _shade = Color(0xFFC97942);
  static const _hair = Color(0xFF733D29);
  static const _ink = Color(0xFF49281F);
  static const _gold = Color(0xFFF3BC43);
  static const _goldLight = Color(0xFFFFE69B);
  static const _orange = Color(0xFFF18732);
  static const _orangeShade = Color(0xFFC64E26);

  Paint _fill(Color color) => Paint()..color = color;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _gradient(Rect bounds, List<Color> colors) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(bounds);

  void _pivot(Canvas canvas, Offset origin, double angle, VoidCallback draw) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    canvas.translate(-origin.dx, -origin.dy);
    draw();
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = pose;
    final fit = math.min(size.width / 280, size.height / 320);
    canvas.save();
    canvas.translate(
      (size.width - 280 * fit) / 2,
      (size.height - 320 * fit) / 2,
    );
    canvas.scale(fit);
    canvas.drawOval(
      const Rect.fromLTWH(72, 297, 136, 12),
      _fill(_hair.withValues(alpha: 0.10)),
    );
    canvas.translate(140, 286 + p.rise);
    canvas.scale(p.scale);
    canvas.translate(-140, -286);

    _pivot(canvas, const Offset(165, 224), p.tailSwing, () {
      final tail = Path()
        ..moveTo(165, 224)
        ..cubicTo(209, 246, 251, 280, 256, 230)
        ..cubicTo(263, 194, 221, 185, 227, 214)
        ..cubicTo(231, 228, 248, 220, 240, 209);
      canvas.drawPath(tail, _stroke(_shade, 12));
      canvas.drawPath(tail, _stroke(_light, 6));
    });

    _feet(canvas);
    _gada(canvas, p);
    _body(canvas);
    _raisedArm(canvas, p);
    _holdingHand(canvas);
    _pivot(canvas, const Offset(139, 146), p.headTilt, () => _head(canvas, p));
    canvas.restore();
  }

  void _feet(Canvas canvas) {
    for (final x in [105.0, 151.0]) {
      final leg = Rect.fromLTWH(x, 251, 25, 40);
      canvas.drawRRect(
        RRect.fromRectAndRadius(leg, const Radius.circular(12)),
        _gradient(leg, [_light, _skin, _shade]),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(87, 280, 46, 19),
      _gradient(const Rect.fromLTWH(87, 280, 46, 19), [_light, _skin]),
    );
    canvas.drawOval(
      const Rect.fromLTWH(147, 280, 46, 19),
      _gradient(const Rect.fromLTWH(147, 280, 46, 19), [_light, _skin]),
    );
    for (final x in [112.0, 119.0, 155.0, 162.0]) {
      canvas.drawLine(Offset(x, 285), Offset(x, 289), _stroke(_shade, 1.2));
    }
    canvas.drawLine(
      const Offset(104, 275),
      const Offset(127, 275),
      _stroke(_gold, 4),
    );
    canvas.drawLine(
      const Offset(151, 275),
      const Offset(175, 275),
      _stroke(_gold, 4),
    );
  }

  void _gada(Canvas canvas, BalHanumanPose p) {
    _pivot(canvas, const Offset(184, 188), p.gadaTilt, () {
      canvas.drawLine(
        const Offset(171, 235),
        const Offset(203, 119),
        _stroke(_orangeShade, 9),
      );
      canvas.drawLine(
        const Offset(171, 235),
        const Offset(203, 119),
        _stroke(_gold, 6),
      );
      canvas.drawCircle(
        const Offset(214, 104),
        25,
        _gradient(const Rect.fromLTWH(189, 79, 50, 50), const [
          _goldLight,
          _gold,
          Color(0xFFC78A25),
        ]),
      );
      for (final x in [204.0, 214.0, 224.0]) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, 104), width: 12, height: 42),
          -math.pi / 2,
          math.pi,
          false,
          _stroke(_orangeShade.withValues(alpha: 0.35), 1.5),
        );
      }
      canvas.drawCircle(
        const Offset(206, 96),
        5,
        _fill(_goldLight.withValues(alpha: 0.8)),
      );
      canvas.drawLine(
        const Offset(211, 130),
        const Offset(219, 132),
        _stroke(_goldLight, 4),
      );
    });
  }

  void _body(Canvas canvas) {
    const torso = Rect.fromLTWH(94, 141, 87, 91);
    canvas.drawOval(torso, _gradient(torso, [_light, _skin, _shade]));
    canvas.drawOval(
      const Rect.fromLTWH(111, 165, 52, 55),
      _fill(_light.withValues(alpha: 0.45)),
    );
    final dhoti = Path()
      ..moveTo(97, 217)
      ..quadraticBezierTo(139, 206, 181, 217)
      ..lineTo(187, 260)
      ..quadraticBezierTo(163, 274, 141, 262)
      ..quadraticBezierTo(112, 274, 90, 260)
      ..close();
    canvas.drawPath(
      dhoti,
      _gradient(const Rect.fromLTWH(90, 210, 98, 65), [_orange, _orangeShade]),
    );
    canvas.drawPath(
      Path()
        ..moveTo(135, 220)
        ..quadraticBezierTo(123, 244, 136, 263)
        ..lineTo(149, 265)
        ..quadraticBezierTo(140, 241, 147, 220),
      _fill(const Color(0xFFFFB95E)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(106, 228)
        ..lineTo(100, 255)
        ..moveTo(171, 228)
        ..lineTo(178, 255),
      _stroke(_goldLight.withValues(alpha: 0.6), 2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(100, 218)
        ..quadraticBezierTo(139, 229, 179, 218),
      _stroke(_gold, 7),
    );
    canvas.drawCircle(const Offset(140, 223), 7, _fill(_goldLight));
    canvas.drawCircle(const Offset(140, 223), 3, _fill(_orangeShade));
    final necklace = Path()
      ..moveTo(111, 148)
      ..quadraticBezierTo(137, 186, 163, 148);
    canvas.drawPath(necklace, _stroke(_gold, 5));
    canvas.drawCircle(const Offset(138, 171), 7, _fill(_goldLight));
    canvas.drawCircle(const Offset(138, 171), 3, _fill(_orangeShade));
  }

  void _raisedArm(Canvas canvas, BalHanumanPose p) {
    _pivot(canvas, const Offset(105, 157), p.armRaise, () {
      final arm = Path()
        ..moveTo(105, 157)
        ..quadraticBezierTo(88, 177, 83, 204);
      canvas.drawPath(arm, _stroke(_shade, 19));
      canvas.drawPath(arm, _stroke(_skin, 15));
      canvas.drawLine(
        const Offset(75, 195),
        const Offset(91, 199),
        _stroke(_gold, 5),
      );
      _pivot(canvas, const Offset(83, 207), p.handWave, () {
        canvas.drawOval(
          const Rect.fromLTWH(73, 200, 21, 22),
          _gradient(const Rect.fromLTWH(73, 200, 21, 22), [_light, _skin]),
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(
            Offset(76 + i * 5, 215),
            Offset(73 + i * 6, 230 - (i == 0 || i == 3 ? 3 : 0)),
            _stroke(_skin, 5),
          );
        }
        canvas.drawLine(
          const Offset(75, 207),
          const Offset(67, 215),
          _stroke(_skin, 6),
        );
      });
    });
  }

  void _holdingHand(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(173, 155)
        ..quadraticBezierTo(191, 169, 184, 187),
      _stroke(_skin, 17),
    );
    canvas.drawLine(
      const Offset(177, 178),
      const Offset(192, 182),
      _stroke(_gold, 5),
    );
    canvas.drawOval(
      const Rect.fromLTWH(174, 181, 22, 18),
      _gradient(const Rect.fromLTWH(174, 181, 22, 18), [_light, _skin]),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(183, 185 + i * 4),
        Offset(191, 187 + i * 4),
        _stroke(_shade, 1.2),
      );
    }
  }

  void _head(Canvas canvas, BalHanumanPose p) {
    for (final x in [77.0, 196.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 99), width: 32, height: 39),
        _fill(_shade),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 99), width: 19, height: 26),
        _fill(const Color(0xFFF0B195)),
      );
      canvas.drawCircle(Offset(x, 119), 7, _stroke(_gold, 3.5));
    }
    const face = Rect.fromLTWH(83, 44, 108, 116);
    canvas.drawOval(face, _gradient(face, [_light, _skin, _shade]));
    final hair = Path()
      ..moveTo(83, 88)
      ..cubicTo(75, 51, 96, 39, 118, 44)
      ..quadraticBezierTo(131, 27, 140, 39)
      ..quadraticBezierTo(164, 24, 163, 44)
      ..cubicTo(188, 44, 199, 67, 191, 88)
      ..quadraticBezierTo(181, 59, 159, 63)
      ..quadraticBezierTo(138, 73, 112, 64)
      ..quadraticBezierTo(92, 69, 83, 88);
    canvas.drawPath(
      hair,
      _gradient(const Rect.fromLTWH(80, 30, 116, 62), [_hair, _ink]),
    );
    canvas.drawOval(
      const Rect.fromLTWH(96, 108, 82, 44),
      _gradient(const Rect.fromLTWH(96, 108, 82, 44), [
        const Color(0xFFFFEAC9),
        _light,
      ]),
    );
    for (final x in [114.0, 160.0]) {
      _eye(canvas, Offset(x, 97), p.eyeOpen);
      canvas.drawPath(
        Path()
          ..moveTo(x - 12, 78)
          ..quadraticBezierTo(x, 71, x + 12, 78),
        _stroke(_hair, 3),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(127, 113, 20, 13),
      _gradient(const Rect.fromLTWH(127, 113, 20, 13), [_skin, _shade]),
    );
    canvas.drawPath(
      Path()
        ..moveTo(121, 133)
        ..quadraticBezierTo(137, 150, 154, 133),
      _stroke(_ink, 2.5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(130, 75)
        ..lineTo(137, 81)
        ..lineTo(144, 75),
      _stroke(const Color(0xFFFFF2D8), 3),
    );
    canvas.drawLine(
      const Offset(137, 70),
      const Offset(137, 79),
      _stroke(_orangeShade, 3),
    );
    for (final x in [101.0, 172.0]) {
      canvas.drawCircle(
        Offset(x, 119),
        6,
        _fill(const Color(0xFFE88D73).withValues(alpha: 0.35)),
      );
    }
  }

  void _eye(Canvas canvas, Offset center, double openness) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, openness);
    canvas.drawOval(
      const Rect.fromLTWH(-13, -16, 26, 32),
      _fill(const Color(0xFFFFFBF0)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-13, -16, 26, 32),
      _stroke(_shade, 1.2),
    );
    canvas.drawOval(const Rect.fromLTWH(-8, -9, 17, 24), _fill(_hair));
    canvas.drawOval(const Rect.fromLTWH(-5, -7, 12, 20), _fill(_ink));
    canvas.drawCircle(const Offset(-3, -6), 4, _fill(Colors.white));
    canvas.drawCircle(const Offset(4, 7), 1.7, _fill(_goldLight));
    canvas.restore();
  }

  @override
  bool shouldRepaint(BalHanumanPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
