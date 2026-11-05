import 'package:flutter/material.dart';

/// Wrapping Telugu text for parents that allow content-driven height.
class PremiumTeluguText extends StatelessWidget {
  const PremiumTeluguText(
    this.data, {
    this.style,
    this.textAlign = TextAlign.start,
    super.key,
  });

  static const fontFamily = 'TeluguPremium';
  static const lineHeight = 1.6;

  final String data;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style
        .merge(style)
        .copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: const ['Roboto'],
          height: lineHeight,
          leadingDistribution: TextLeadingDistribution.even,
          letterSpacing: 0,
        );
    final textScaler = MediaQuery.textScalerOf(context);
    final fontSize = effectiveStyle.fontSize ?? 16;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: textScaler.scale(fontSize) * 0.1),
      child: Text(
        data,
        style: effectiveStyle,
        locale: const Locale('te'),
        textAlign: textAlign,
        textScaler: textScaler,
        softWrap: true,
        overflow: TextOverflow.visible,
        // A non-forced strut is a floor, not a ceiling on glyph ascent/descent.
        strutStyle: StrutStyle.fromTextStyle(
          effectiveStyle,
          forceStrutHeight: false,
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: true,
          applyHeightToLastDescent: true,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    );
  }
}
