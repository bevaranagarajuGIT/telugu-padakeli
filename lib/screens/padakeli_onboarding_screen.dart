import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_colors.dart';
import '../shared/widgets/opening_artwork.dart';
import '../widgets/premium_telugu_text.dart';

class PadakeliOnboardingScreen extends StatelessWidget {
  const PadakeliOnboardingScreen({
    required this.onComplete,
    this.busy = false,
    this.error,
    super.key,
  });

  final VoidCallback onComplete;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: const ValueKey('padakeli-onboarding'),
        backgroundColor: const Color(0xFF58AB28),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final sceneHeight = math
                .min(constraints.maxWidth * 1.03, constraints.maxHeight * 0.49)
                .clamp(240.0, 520.0);
            return SingleChildScrollView(
              key: const ValueKey('onboarding-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OpeningScenery(
                    family: true,
                    minHeight: sceneHeight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, insets.top + 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth - 40,
                            ),
                            child: FilledButton(
                              key: const ValueKey('onboarding-skip'),
                              onPressed: busy ? null : onComplete,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF3FBFF),
                                foregroundColor: AppColors.navy,
                                minimumSize: const Size(64, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                side: const BorderSide(color: Colors.white),
                              ),
                              child: PremiumTeluguText(
                                'దాటవేయి',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: constraints.maxWidth * 0.70,
                          ),
                        ],
                      ),
                    ),
                  ),
                  OpeningPaperPanel(
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
                            child: OpeningFooter(),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              28,
                              28,
                              28,
                              64 + insets.bottom,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 500,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PremiumTeluguText(
                                      'అందరికీ స్వాగతం...',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: const Color(0xFF801C22),
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const TeluguTitle(),
                                    const OpeningGoldAccent(flower: true),
                                    const SizedBox(height: 4),
                                    PremiumTeluguText(
                                      'పదకేళి ఆడుతూ తెలుగు పద సంపదను పెంపొందించుకోండి, పిల్లలతో సరదాగా కుటుంబం మొత్తం ఆనందించండి.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.navy,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 18),
                                    Semantics(
                                      label: 'స్వాగతం, పేజీ 1 / 1',
                                      child: ExcludeSemantics(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: openingCream,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.deepBlue,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    if (error != null) ...[
                                      Semantics(
                                        liveRegion: true,
                                        child: PremiumTeluguText(
                                          error!,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: const Color(0xFF9B1C1C),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    PrimaryActionButton(
                                      onPressed: onComplete,
                                      busy: busy,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: insets.bottom + 2,
                            right: 12,
                            child: IconButton(
                              tooltip: 'Artwork credits',
                              color: AppColors.navy,
                              iconSize: 18,
                              onPressed: () => showLicensePage(
                                context: context,
                                applicationName: 'Telugu Padakeli',
                              ),
                              icon: const Icon(Icons.info_outline_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
