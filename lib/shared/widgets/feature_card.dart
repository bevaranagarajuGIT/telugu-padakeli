import 'package:flutter/material.dart';

import '../../widgets/premium_telugu_text.dart';

class FeatureCard extends StatefulWidget {
  const FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

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
      borderRadius: BorderRadius.circular(24),
    );
    return AnimatedScale(
      scale: _pressed && !reducedMotion ? 0.98 : 1,
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 100),
      child: Semantics(
        button: true,
        label: '${widget.title}, ${widget.subtitle}',
        child: Material(
          color: widget.background,
          shape: border,
          child: InkWell(
            customBorder: border,
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minHeight: 180),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, size: 36, color: widget.foreground),
                    const SizedBox(height: 16),
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
                        fontWeight: FontWeight.w500,
                      ),
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
