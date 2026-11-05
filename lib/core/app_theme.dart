import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../widgets/premium_telugu_text.dart';

class AppTheme {
  static ThemeData light(double fontScale) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.actionBlue,
          onPrimary: Colors.white,
          secondary: const Color(0xFF007D65),
          onSecondary: Colors.white,
          tertiary: AppColors.purple,
          onTertiary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.navy,
        );
    return _theme(colorScheme, fontScale);
  }

  static ThemeData dark(double fontScale) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.dark,
    );
    return _theme(colorScheme, fontScale);
  }

  static ThemeData _theme(ColorScheme colorScheme, double fontScale) {
    final material = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: PremiumTeluguText.fontFamily,
      fontFamilyFallback: const ['Roboto'],
    );
    // ThemeData's paint styles have no sizes until locale geometry is merged.
    final base = ThemeData.localize(material, material.typography.englishLike);

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.background,
      textTheme: _scaledTextTheme(
        base.textTheme,
        colorScheme.onSurface,
        fontScale,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(fontSizeFactor: fontScale),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          textStyle: TextStyle(
            fontFamily: PremiumTeluguText.fontFamily,
            fontFamilyFallback: const ['Roboto'],
            fontSize: 19 * fontScale,
            fontWeight: FontWeight.w700,
            height: PremiumTeluguText.lineHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          _scaleStyle(base.textTheme.labelMedium, fontScale)?.copyWith(
            fontFamily: 'Roboto',
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static TextTheme _scaledTextTheme(
    TextTheme textTheme,
    Color textColor,
    double scale,
  ) {
    final coloredTheme = textTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    return coloredTheme.copyWith(
      displayLarge: _scaleStyle(coloredTheme.displayLarge, scale),
      displayMedium: _scaleStyle(coloredTheme.displayMedium, scale),
      displaySmall: _scaleStyle(coloredTheme.displaySmall, scale),
      headlineLarge: _scaleStyle(coloredTheme.headlineLarge, scale),
      headlineMedium: _scaleStyle(coloredTheme.headlineMedium, scale),
      headlineSmall: _scaleStyle(coloredTheme.headlineSmall, scale),
      titleLarge: _scaleStyle(coloredTheme.titleLarge, scale),
      titleMedium: _scaleStyle(coloredTheme.titleMedium, scale),
      titleSmall: _scaleStyle(coloredTheme.titleSmall, scale),
      bodyLarge: _scaleStyle(coloredTheme.bodyLarge, scale),
      bodyMedium: _scaleStyle(coloredTheme.bodyMedium, scale),
      bodySmall: _scaleStyle(coloredTheme.bodySmall, scale),
      labelLarge: _scaleStyle(coloredTheme.labelLarge, scale),
      labelMedium: _scaleStyle(coloredTheme.labelMedium, scale),
      labelSmall: _scaleStyle(coloredTheme.labelSmall, scale),
    );
  }

  static TextStyle? _scaleStyle(TextStyle? style, double scale) {
    final fontSize = style?.fontSize;
    if (style == null || fontSize == null) {
      return style;
    }
    return style.copyWith(
      fontSize: fontSize * scale,
      height: PremiumTeluguText.lineHeight,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }
}
