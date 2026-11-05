import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/premium_telugu_text.dart';

enum FeatureCardArtwork { crossword, learn, daily, progress }

class FeatureCard extends StatefulWidget {
  const FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.artwork,
    this.status,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final FeatureCardArtwork? artwork;
  final String? status;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
    );
    return AnimatedScale(
      scale: _pressed && !reducedMotion ? 0.975 : 1,
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 100),
      child: Semantics(
        container: true,
        button: true,
        label: [
          widget.title,
          widget.subtitle,
          if (widget.status != null) widget.status!,
        ].join(', '),
        onTap: widget.onTap,
        child: Material(
          color: widget.background,
          shape: border,
          elevation: _pressed ? 1 : 5,
          child: InkWell(
            customBorder: border,
            excludeFromSemantics: true,
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: ExcludeSemantics(
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.background,
                      Color.lerp(widget.background, Colors.black, 0.08)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: border.borderRadius,
                ),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 172),
                  padding: const EdgeInsets.all(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final statusInline =
                          widget.status != null && constraints.maxWidth >= 220;
                      final statusBadge = widget.status == null
                          ? null
                          : Container(
                              constraints: const BoxConstraints(maxWidth: 132),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.foreground.withValues(
                                  alpha: 0.13,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: PremiumTeluguText(
                                widget.status!,
                                style: textTheme.labelSmall?.copyWith(
                                  color: widget.foreground,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: widget.foreground.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: widget.artwork == null
                                    ? Icon(
                                        widget.icon,
                                        size: 29,
                                        color: widget.foreground,
                                      )
                                    : CustomPaint(
                                        painter: _FeatureIconPainter(
                                          artwork: widget.artwork!,
                                          color: widget.foreground,
                                        ),
                                        child: const SizedBox.expand(),
                                      ),
                              ),
                              if (statusInline) ...[
                                const Spacer(),
                                statusBadge!,
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          PremiumTeluguText(
                            widget.title,
                            style: textTheme.titleLarge?.copyWith(
                              color: widget.foreground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          PremiumTeluguText(
                            widget.subtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: widget.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.status != null && !statusInline) ...[
                            const SizedBox(height: 6),
                            statusBadge!,
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureIconPainter extends CustomPainter {
  const _FeatureIconPainter({required this.artwork, required this.color});

  final FeatureCardArtwork artwork;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final accent = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (artwork) {
      case FeatureCardArtwork.crossword:
        for (var row = 0; row < 2; row++) {
          for (var column = 0; column < 2; column++) {
            final rect = Rect.fromLTWH(6 + column * 18, 6 + row * 18, 15, 15);
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(4)),
              row == 0 && column == 1 ? accent : fill,
            );
          }
        }
        canvas.drawCircle(const Offset(38, 38), 4, accent);
      case FeatureCardArtwork.learn:
        final book = Path()
          ..moveTo(5, 14)
          ..quadraticBezierTo(16, 10, 24, 17)
          ..quadraticBezierTo(32, 10, 43, 14)
          ..lineTo(43, 37)
          ..quadraticBezierTo(32, 34, 24, 40)
          ..quadraticBezierTo(16, 34, 5, 37)
          ..close();
        canvas.drawPath(book, line);
        canvas.drawLine(const Offset(24, 18), const Offset(24, 38), line);
        canvas.drawLine(const Offset(10, 20), const Offset(18, 22), line);
        canvas.drawLine(const Offset(30, 22), const Offset(38, 20), line);
        canvas.drawCircle(const Offset(24, 9), 4, accent);
      case FeatureCardArtwork.daily:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(7, 10, 34, 31),
            const Radius.circular(7),
          ),
          line,
        );
        canvas.drawLine(const Offset(7, 19), const Offset(41, 19), line);
        canvas.drawLine(const Offset(16, 7), const Offset(16, 14), line);
        canvas.drawLine(const Offset(32, 7), const Offset(32, 14), line);
        for (final point in const [
          Offset(16, 26),
          Offset(25, 26),
          Offset(34, 26),
          Offset(16, 34),
          Offset(25, 34),
        ]) {
          canvas.drawCircle(point, 1.8, accent);
        }
      case FeatureCardArtwork.progress:
        canvas.drawLine(const Offset(8, 39), const Offset(41, 39), line);
        for (final bar in const [
          Rect.fromLTWH(11, 27, 6, 12),
          Rect.fromLTWH(22, 20, 6, 19),
          Rect.fromLTWH(33, 11, 6, 28),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(bar, const Radius.circular(3)),
            fill,
          );
        }
        final trend = Path()
          ..moveTo(11, 23)
          ..lineTo(24, 16)
          ..lineTo(35, 8);
        canvas.drawPath(
          trend,
          Paint()
            ..color = AppColors.gold
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(const Offset(35, 8), 3, accent);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FeatureIconPainter oldDelegate) =>
      oldDelegate.artwork != artwork || oldDelegate.color != color;
}
