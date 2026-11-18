import 'package:flutter/material.dart';

import '../../widgets/premium_telugu_text.dart';
import 'home_artwork.dart';

enum FeatureCardArtwork {
  crossword(HomeArtwork.classic),
  learn(HomeArtwork.learn),
  daily(HomeArtwork.daily),
  progress(HomeArtwork.progress);

  const FeatureCardArtwork(this.asset);

  final String asset;
}

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
    this.gradient,
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
  final Gradient? gradient;

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
      borderRadius: BorderRadius.circular(18),
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
          elevation: 0,
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
                  gradient:
                      widget.gradient ??
                      LinearGradient(
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
                  constraints: const BoxConstraints(minHeight: 204),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 104,
                            child: widget.artwork == null
                                ? Icon(
                                    widget.icon,
                                    size: 48,
                                    color: widget.foreground,
                                  )
                                : Image.asset(
                                    widget.artwork!.asset,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                    cacheWidth: 456,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          PremiumTeluguText(
                            widget.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize:
                                  (textTheme.bodyLarge?.fontSize ?? 16) * 1.125,
                              color: widget.foreground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: PremiumTeluguText(
                              widget.subtitle,
                              style: textTheme.bodyLarge?.copyWith(
                                color: widget.foreground,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: widget.foreground,
                            size: 20,
                          ),
                        ],
                      ),
                      if (widget.status != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.foreground.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: PremiumTeluguText(
                            widget.status!,
                            style: textTheme.labelSmall?.copyWith(
                              color: widget.foreground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
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
