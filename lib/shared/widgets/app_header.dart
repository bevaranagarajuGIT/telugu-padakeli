import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/premium_telugu_text.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({required this.onSettings, super.key});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
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
                        Icons.menu_book_rounded,
                        color: AppColors.gold,
                        size: 28,
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
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
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
                            ),
                          ),
                          if (showArt) ...[
                            const SizedBox(width: 12),
                            const ExcludeSemantics(
                              child: CustomPaint(
                                size: Size(108, 116),
                                painter: _TeluguLetterArt(),
                              ),
                            ),
                          ],
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
    );
  }
}

class _TeluguLetterArt extends CustomPainter {
  const _TeluguLetterArt();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 108, size.height / 116);
    final paint = Paint()..color = AppColors.gold;
    canvas.drawLine(
      const Offset(4, 8),
      const Offset(104, 8),
      paint..strokeWidth = 2,
    );
    for (final x in [14.0, 34.0, 54.0, 74.0, 94.0]) {
      final leaf = Path()
        ..moveTo(x, 8)
        ..quadraticBezierTo(x - 9, 18, x, 26)
        ..quadraticBezierTo(x + 9, 18, x, 8);
      canvas.drawPath(leaf, paint);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 34, 96, 78),
        const Radius.circular(14),
      ),
      paint..color = Colors.white,
    );
    const letters = ['అ', 'ఆ', 'క', 'ళి'];
    for (var index = 0; index < letters.length; index++) {
      final column = index % 2;
      final row = index ~/ 2;
      final painter = TextPainter(
        text: TextSpan(
          text: letters[index],
          style: const TextStyle(
            fontFamily: PremiumTeluguText.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.deepBlue,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(30 + column * 46 - painter.width / 2, 38 + row * 34),
      );
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(_TeluguLetterArt oldDelegate) => false;
}
