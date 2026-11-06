import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/premium_telugu_text.dart';

const openingTempleAsset = 'assets/artwork/opening/tirumala-temple.webp';
const openingFamilyAsset = 'assets/artwork/opening/telugu-family.webp';
const openingCream = Color(0xFFFFF8E8);

class OpeningScenery extends StatelessWidget {
  const OpeningScenery({
    required this.minHeight,
    required this.child,
    this.family = false,
    super.key,
  });

  final double minHeight;
  final Widget child;
  final bool family;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: family
                      ? const [Color(0xFF0079FF), Color(0xFF75D4FB)]
                      : const [
                          Color(0xFF0345CF),
                          Color(0xFF0066E8),
                          Color(0xFF48BEFA),
                        ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white, Colors.white],
                stops: [0, 0.16, 1],
              ).createShader(bounds),
              child: CulturalBackground(family: family),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}

class OpeningPaperPanel extends StatelessWidget {
  const OpeningPaperPanel({
    required this.child,
    this.golden = false,
    super.key,
  });

  final Widget child;
  final bool golden;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(0, -24),
    child: CustomPaint(
      painter: _PaperPanelPainter(golden: golden),
      child: child,
    ),
  );
}

class _PaperPanelPainter extends CustomPainter {
  const _PaperPanelPainter({required this.golden});
  final bool golden;

  @override
  void paint(Canvas canvas, Size size) {
    final crest = Path()
      ..moveTo(0, 28)
      ..quadraticBezierTo(size.width * 0.5, -28, size.width, 28);
    final paper = Path.from(crest)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      paper,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFFCF4),
            openingCream,
            golden ? const Color(0xFFFFE7A0) : const Color(0xFFFFF5DB),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      crest,
      Paint()
        ..color = const Color(0xFFFFD968)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(_PaperPanelPainter oldDelegate) =>
      golden != oldDelegate.golden;
}

class OpeningGoldAccent extends StatelessWidget {
  const OpeningGoldAccent({this.flower = false, super.key});

  final bool flower;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 220,
      height: 20,
      child: CustomPaint(painter: _GoldAccentPainter(flower: flower)),
    ),
  );
}

class _GoldAccentPainter extends CustomPainter {
  const _GoldAccentPainter({required this.flower});
  final bool flower;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFB900);
    final center = Offset(size.width / 2, size.height / 2);
    if (!flower) {
      canvas.drawPath(
        Path()
          ..moveTo(12, center.dy + 3)
          ..quadraticBezierTo(center.dx, -1, size.width - 12, center.dy)
          ..quadraticBezierTo(center.dx, 5, 12, center.dy + 3),
        paint,
      );
      return;
    }
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(0, center.dy), center - const Offset(18, 0), paint);
    canvas.drawLine(
      center + const Offset(18, 0),
      Offset(size.width, center.dy),
      paint,
    );
    for (final angle in [-0.9, -0.45, 0.0, 0.45, 0.9]) {
      canvas.save();
      canvas.translate(center.dx, center.dy + 5);
      canvas.rotate(angle);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-7, -7, 0, -17)
          ..quadraticBezierTo(7, -7, 0, 0),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GoldAccentPainter oldDelegate) =>
      flower != oldDelegate.flower;
}

class CulturalBackground extends StatelessWidget {
  const CulturalBackground({this.family = false, super.key});

  final bool family;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      family ? openingFamilyAsset : openingTempleAsset,
      key: ValueKey(family ? 'opening-family-art' : 'opening-temple-art'),
      fit: BoxFit.contain,
      cacheWidth: 960,
      excludeFromSemantics: true,
    );
  }
}

class TeluguTitle extends StatelessWidget {
  const TeluguTitle({this.light = false, super.key});

  final bool light;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: PremiumTeluguText(
      'తెలుగు పదకేళి',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
        color: light ? Colors.white : AppColors.deepBlue,
        fontWeight: FontWeight.w800,
        shadows: light
            ? const [
                Shadow(
                  color: Color(0x55001A63),
                  offset: Offset(0, 2),
                  blurRadius: 3,
                ),
              ]
            : null,
      ),
    ),
  );
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.gold, Color(0xFFFFB900)],
      ),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: const Color(0xFFFFE67A), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFB97400).withValues(alpha: 0.22),
          offset: const Offset(0, 5),
          blurRadius: 12,
        ),
      ],
    ),
    child: FilledButton(
      key: const ValueKey('onboarding-start'),
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: AppColors.navy,
        disabledForegroundColor: AppColors.navy,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 64),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: PremiumTeluguText(
              busy ? 'దాచుతున్నాము...' : 'ప్రారంభిద్దాం',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          if (busy && MediaQuery.disableAnimationsOf(context))
            const Icon(Icons.hourglass_bottom_rounded, color: AppColors.navy)
          else if (busy)
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.navy,
              ),
            )
          else
            const Icon(Icons.arrow_forward_rounded, color: AppColors.navy),
        ],
      ),
    ),
  );
}

class OpeningPuzzleMark extends StatelessWidget {
  const OpeningPuzzleMark({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SizedBox.square(
      dimension: 88,
      child: CustomPaint(painter: _PuzzleMarkPainter()),
    ),
  );
}

class _PuzzleMarkPainter extends CustomPainter {
  const _PuzzleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    Path piece(Rect rect, List<Offset> tabs, List<Offset> sockets) {
      var shape = Path()..addRect(rect);
      for (final center in tabs) {
        shape = Path.combine(
          PathOperation.union,
          shape,
          Path()..addOval(Rect.fromCircle(center: center, radius: 7)),
        );
      }
      for (final center in sockets) {
        shape = Path.combine(
          PathOperation.difference,
          shape,
          Path()..addOval(Rect.fromCircle(center: center, radius: 7)),
        );
      }
      return shape;
    }

    for (final (shape, color) in [
      (
        piece(
          const Rect.fromLTRB(8, 8, 50, 50),
          [const Offset(29, 8)],
          [const Offset(50, 29), const Offset(29, 50)],
        ),
        AppColors.gold,
      ),
      (
        piece(
          const Rect.fromLTRB(50, 8, 92, 50),
          [const Offset(92, 29), const Offset(50, 29)],
          [const Offset(71, 50)],
        ),
        const Color(0xFFFFA51F),
      ),
      (
        piece(
          const Rect.fromLTRB(8, 50, 50, 92),
          [const Offset(29, 50)],
          [const Offset(50, 71)],
        ),
        AppColors.teal,
      ),
      (
        piece(const Rect.fromLTRB(50, 50, 92, 92), [
          const Offset(71, 50),
          const Offset(50, 71),
          const Offset(71, 92),
        ], []),
        const Color(0xFF42D8F5),
      ),
    ]) {
      canvas.drawShadow(shape, const Color(0xFF10294B), 3, false);
      canvas.drawPath(shape, Paint()..color = color);
      canvas.drawPath(
        shape,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PuzzleMarkPainter oldDelegate) => false;
}

class FestiveCanopy extends StatelessWidget {
  const FestiveCanopy({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SizedBox(
      height: 72,
      width: double.infinity,
      child: CustomPaint(painter: _CanopyPainter()),
    ),
  );
}

class _CanopyPainter extends CustomPainter {
  const _CanopyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (final right in [false, true]) {
      canvas.save();
      if (right) {
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
      }
      final width = math.min(size.width * 0.34, 150.0);
      for (var i = 0; i < 6; i++) {
        final x = width * i / 6;
        final y = 5 + i * 1.5;
        final leaf = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 30, y + 14, x + 14, y + 52)
          ..quadraticBezierTo(x - 5, y + 25, x, y);
        canvas.drawPath(
          leaf,
          Paint()..color = i.isEven ? const Color(0xFF75B42F) : AppColors.teal,
        );
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 14, y + 45),
          Paint()
            ..color = const Color(0xFFB9E963)
            ..strokeWidth = 0.7,
        );
        if (i.isEven) {
          for (var j = 0; j < 4 - i ~/ 2; j++) {
            final center = Offset(x + 5, y + 13 + j * 13);
            for (var petal = 0; petal < 8; petal++) {
              final angle = petal * math.pi / 4;
              canvas.drawCircle(
                center + Offset(math.cos(angle), math.sin(angle)) * 4,
                3.2,
                Paint()
                  ..color = j.isEven ? AppColors.gold : const Color(0xFFFFA51F),
              );
            }
            canvas.drawCircle(
              center,
              3,
              Paint()..color = const Color(0xFFF07C00),
            );
          }
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CanopyPainter oldDelegate) => false;
}

class OpeningFooter extends StatelessWidget {
  const OpeningFooter({this.golden = false, super.key});

  final bool golden;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: double.infinity,
      height: 64,
      child: CustomPaint(painter: _FooterPainter(golden: golden)),
    ),
  );
}

class _FooterPainter extends CustomPainter {
  const _FooterPainter({required this.golden});

  final bool golden;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (height, color) in [
      (0.25, golden ? const Color(0xFFFFF2BB) : const Color(0xFFE7F4B2)),
      (0.55, golden ? const Color(0xFFFFE27C) : const Color(0xFFACD957)),
      (0.85, golden ? const Color(0xFFFFD65E) : const Color(0xFF58AB28)),
    ]) {
      final shape = Path()
        ..moveTo(0, size.height * height)
        ..quadraticBezierTo(
          size.width * 0.45,
          size.height * 1.35,
          size.width,
          size.height * (1 - height),
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(shape, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_FooterPainter oldDelegate) =>
      golden != oldDelegate.golden;
}
