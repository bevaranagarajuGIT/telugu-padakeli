import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/premium_telugu_text.dart';
import 'home_artwork.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.onSettings,
    this.celebrating = false,
    super.key,
  });

  final VoidCallback onSettings;
  final bool celebrating;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bodySize = MediaQuery.textScalerOf(
      context,
    ).scale(textTheme.bodyLarge?.fontSize ?? 16);
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: PremiumTeluguText(
            'తెలుగు పదకేళి',
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PremiumTeluguText(
          'పదాలతో ఆట, భాషతో ఆనందం',
          style: textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.actionBlue, AppColors.deepBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Telugu Padakeli',
                            style: textTheme.titleLarge?.copyWith(
                              fontFamily: 'Roboto',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onSettings,
                          tooltip: 'Settings',
                          color: Colors.white,
                          icon: const Icon(Icons.settings_outlined, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.deepBlue),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBackground
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 736),
                  child: bodySize <= 22
                      ? HomeScenery(
                          celebrating: celebrating,
                          foreground: title,
                          reserveMascotSpace: true,
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.deepBlue,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: title,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
