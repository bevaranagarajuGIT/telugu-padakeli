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
                                width: 56,
                                height: 56,
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
                                    : Image.asset(
                                        widget.artwork!.asset,
                                        fit: BoxFit.contain,
                                        excludeFromSemantics: true,
                                        cacheWidth: 168,
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
