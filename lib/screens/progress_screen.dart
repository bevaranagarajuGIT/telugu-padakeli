import 'package:flutter/material.dart';

import '../widgets/app_page.dart';
import '../widgets/premium_telugu_text.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      title: 'My Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.auto_graph_rounded,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          PremiumTeluguText(
            'మీ అభ్యాస ప్రయాణం',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          PremiumTeluguText(
            'మీరు పూర్తి చేసిన ఆటలు, నేర్చుకున్న పదాల వివరాలు '
            'త్వరలో ఇక్కడ చూడవచ్చు.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          PremiumTeluguText(
            'Progress tracking is coming soon.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
