import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../models/puzzle.dart';
import 'premium_telugu_text.dart';

class ClassicHintsSheet extends StatelessWidget {
  const ClassicHintsSheet({
    required this.clue,
    required this.onRevealFirst,
    required this.onRevealCell,
    required this.onShowSimple,
    super.key,
  });

  final PuzzleClue clue;
  final VoidCallback? onRevealFirst;
  final VoidCallback? onRevealCell;
  final VoidCallback? onShowSimple;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('classic-hints-scroll'),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, right: 10),
                  child: Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.orange,
                    size: 32,
                  ),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: PremiumTeluguText(
                      'సూచనలు (Hints)',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close hints',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PremiumTeluguText(
              '${clue.number}. ${clue.clue}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (final (key, title, subtitle, icon, tint, action) in [
              (
                'hint-basic',
                'సులభమైన సూచన',
                onShowSimple == null
                    ? 'ఈ పదానికి అదనపు సూచన అందుబాటులో లేదు'
                    : 'రచయిత ఇచ్చిన మరో సూచన చూడండి',
                Icons.menu_book_rounded,
                const Color(0xFFFFE1CE),
                onShowSimple,
              ),
              (
                'hint-reveal-first',
                'మొదటి అక్షరం చూపించు',
                'ఎంచుకున్న పదంలో మొదటి నింపని లేదా తప్పు అక్షరం',
                Icons.looks_one_rounded,
                const Color(0xFFEBD8FF),
                onRevealFirst,
              ),
              (
                'hint-reveal-cell',
                'ఒక అక్షరం చూపించు',
                'ఎంచుకున్న గడి లేదా పదంలోని ఒక గడి',
                Icons.visibility_rounded,
                const Color(0xFFD8EFFF),
                onRevealCell,
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: dark
                      ? Color.lerp(tint, theme.colorScheme.surface, 0.85)
                      : tint,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    key: ValueKey(key),
                    enabled: action != null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minVerticalPadding: 12,
                    leading: Icon(
                      icon,
                      color: dark
                          ? theme.colorScheme.onSurface
                          : AppColors.navy,
                      size: 28,
                    ),
                    title: PremiumTeluguText(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: PremiumTeluguText(
                      subtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: action == null
                        ? null
                        : const Icon(Icons.chevron_right_rounded),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: action,
                  ),
                ),
              ),
            PremiumTeluguText(
              'సూచనలు ఎంచుకున్న పదానికే వర్తిస్తాయి.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
