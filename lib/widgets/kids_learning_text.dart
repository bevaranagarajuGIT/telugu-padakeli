import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_settings_controller.dart';
import 'premium_telugu_text.dart';

class KidsLearningText extends StatelessWidget {
  const KidsLearningText(
    this.telugu, {
    this.english,
    this.style,
    this.center = false,
    super.key,
  }) : _isControl = false;

  const KidsLearningText.control(
    this.telugu, {
    required String this.english,
    this.style,
    this.center = false,
    super.key,
  }) : _isControl = true;

  final String telugu;
  final String? english;
  final TextStyle? style;
  final bool center;
  final bool _isControl;

  @override
  Widget build(BuildContext context) {
    final showEnglish =
        _isControl ||
        context.select<AppSettingsController, bool>(
          (settings) => settings.englishHelper,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        PremiumTeluguText(
          telugu,
          style: style,
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        if (showEnglish && english != null) ...[
          const SizedBox(height: 4),
          Text(
            english!,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  style?.color ??
                  DefaultTextStyle.of(context).style.color ??
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
