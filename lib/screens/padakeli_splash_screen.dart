import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_colors.dart';
import '../shared/widgets/opening_artwork.dart';
import '../widgets/premium_telugu_text.dart';

class PadakeliSplashScreen extends StatelessWidget {
  const PadakeliSplashScreen({
    this.error,
    this.onRetry,
    this.onEntered,
    this.animateEntrance = true,
    super.key,
  });

  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onEntered;
  final bool animateEntrance;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final insets = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: const ValueKey('padakeli-splash'),
        backgroundColor: const Color(0xFFFFD65E),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final sceneHeight = math
                .max(constraints.maxWidth * 1.4, constraints.maxHeight * 0.70)
                .clamp(420.0, 820.0);
            return SingleChildScrollView(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(animateEntrance),
                tween: Tween(begin: reduced ? 1 : 0.85, end: 1),
                duration: reduced || !animateEntrance
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
                onEnd: animateEntrance ? onEntered : null,
                builder: (context, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OpeningScenery(
                      minHeight: sceneHeight,
                      child: Stack(
                        children: [
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: FestiveCanopy(),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              insets.top + 40,
                              20,
                              0,
                            ),
                            child: Column(
                              children: [
                                const OpeningPuzzleMark(),
                                const SizedBox(height: 8),
                                const TeluguTitle(light: true),
                                Text(
                                  'Telugu Padakeli',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const OpeningGoldAccent(),
                                SizedBox(
                                  width: double.infinity,
                                  height: constraints.maxWidth * 0.70,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    OpeningPaperPanel(
                      golden: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(
                            0,
                            constraints.maxHeight - sceneHeight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            const Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: OpeningFooter(golden: true),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                28,
                                32,
                                28,
                                72 + insets.bottom,
                              ),
                              child: Column(
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 300,
                                    ),
                                    child: PremiumTeluguText(
                                      error ??
                                          'తెలుగు పదాలతో ఆడుతూ నేర్చుకుందాం...',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: AppColors.navy,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (error == null)
                                    Semantics(
                                      label: 'యాప్ తెరుచుకుంటోంది',
                                      child: SizedBox.square(
                                        dimension: 34,
                                        child: reduced
                                            ? const Icon(
                                                Icons.hourglass_bottom_rounded,
                                                color: AppColors.deepBlue,
                                              )
                                            : const CircularProgressIndicator(
                                                strokeWidth: 5,
                                                color: AppColors.deepBlue,
                                                backgroundColor: AppColors.gold,
                                              ),
                                      ),
                                    )
                                  else
                                    FilledButton(
                                      onPressed: onRetry,
                                      child: const Text('మళ్లీ ప్రయత్నించండి'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
