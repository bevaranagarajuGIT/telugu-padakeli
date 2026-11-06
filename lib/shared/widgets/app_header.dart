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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 26,
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
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bodySize = MediaQuery.textScalerOf(
                          context,
                        ).scale(textTheme.bodyLarge?.fontSize ?? 16);
                        final showArt = bodySize <= 22;
                        final title = Column(
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
                        );
                        if (!showArt) return title;
                        final artwork = HomeScenery(celebrating: celebrating);
                        if (constraints.maxWidth < 640) {
                          return HomeScenery(
                            celebrating: celebrating,
                            foreground: title,
                            reserveMascotSpace: bodySize > 18,
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: title),
                            const SizedBox(width: 18),
                            artwork,
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
      ),
    );
  }
}
