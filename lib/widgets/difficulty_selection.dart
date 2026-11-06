import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_colors.dart';
import 'premium_telugu_text.dart';

class DifficultySelection extends StatelessWidget {
  const DifficultySelection({
    required this.availableLevels,
    required this.onSelect,
    this.onBack,
    super.key,
  });

  final Set<String> availableLevels;
  final ValueChanged<String> onSelect;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final titleStyle = theme.textTheme.titleLarge!;
    final titleSize = MediaQuery.textScalerOf(
      context,
    ).scale(titleStyle.fontSize!);
    const difficulties = [
      (
        'Beginner',
        'ప్రారంభ స్థాయి',
        'beginner',
        Color(0xFFB7F59E),
        Color(0xFF64D776),
      ),
      ('Easy', 'సులభ స్థాయి', 'easy', Color(0xFFACE6FF), Color(0xFF68C6FF)),
      ('Medium', 'మధ్యస్థ స్థాయి', null, Color(0xFFDCC5FF), Color(0xFFB08AF4)),
      ('Hard', 'కఠిన స్థాయి', null, Color(0xFFFFE6A3), Color(0xFFFFB85D)),
      ('Expert', 'నిపుణ స్థాయి', null, Color(0xFFF4CBFF), Color(0xFFE992F1)),
    ];

    return Scaffold(
      backgroundColor: dark ? AppColors.darkBackground : AppColors.lightBlue,
      appBar: AppBar(
        backgroundColor: dark ? AppColors.deepBlue : AppColors.blue,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: (titleSize * 1.8 + 16).clamp(64, double.infinity),
        centerTitle: true,
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: 'Back to Home',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(
          'పదకేళి',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle.copyWith(
            fontFamily: PremiumTeluguText.fontFamily,
            height: PremiumTeluguText.lineHeight,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? [AppColors.deepBlue, AppColors.darkBackground]
                : [
                    AppColors.deepBlue,
                    const Color(0xFF91DFFF),
                    AppColors.lightBlue,
                  ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('difficulty-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PremiumTeluguText(
                        'స్థాయిని ఎంచుకోండి',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final (name, title, level, top, bottom)
                        in difficulties)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DifficultyCard(
                          name: name,
                          title: title,
                          top: top,
                          bottom: bottom,
                          onPressed:
                              level != null && availableLevels.contains(level)
                              ? () => onSelect(level)
                              : null,
                        ),
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

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.name,
    required this.title,
    required this.top,
    required this.bottom,
    required this.onPressed,
  });

  final String name;
  final String title;
  final Color top;
  final Color bottom;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final enlarged =
        MediaQuery.textScalerOf(
          context,
        ).scale(theme.textTheme.titleLarge!.fontSize!) >
        32;
    final surfaceTop = dark
        ? Color.lerp(top, AppColors.darkBackground, 0.72)!
        : top;
    final surfaceBottom = dark
        ? Color.lerp(bottom, AppColors.darkBackground, 0.72)!
        : bottom;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumTeluguText(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          name,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        if (onPressed == null)
          Text(
            'Coming Soon',
            style: theme.textTheme.bodySmall?.copyWith(color: ink),
          )
        else
          PremiumTeluguText(
            'ఆడటం ప్రారంభించండి',
            style: theme.textTheme.bodySmall?.copyWith(color: ink),
          ),
      ],
    );
    final emblem = _LevelEmblem(name: name);
    final action = Icon(
      onPressed == null ? Icons.lock_rounded : Icons.chevron_right_rounded,
      color: ink,
      size: 24,
    );

    return Semantics(
      key: ValueKey('difficulty-$name'),
      container: true,
      button: true,
      enabled: onPressed != null,
      label: '$title\n$name',
      value: onPressed == null ? 'Coming Soon' : 'ఆడటం ప్రారంభించండి',
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: surfaceBottom,
          elevation: 5,
          shadowColor: AppColors.deepBlue.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [surfaceTop, surfaceBottom],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.3 : 0.8),
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              canRequestFocus: onPressed != null,
              borderRadius: BorderRadius.circular(22),
              focusColor: ink.withValues(alpha: 0.18),
              hoverColor: ink.withValues(alpha: 0.08),
              child: CustomPaint(
                painter: _LevelHillsPainter(color: ink.withValues(alpha: 0.05)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: enlarged
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [emblem, const Spacer(), action]),
                            const SizedBox(height: 8),
                            copy,
                          ],
                        )
                      : Row(
                          children: [
                            emblem,
                            const SizedBox(width: 14),
                            Expanded(child: copy),
                            const SizedBox(width: 8),
                            action,
                          ],
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

class _LevelEmblem extends StatelessWidget {
  const _LevelEmblem({required this.name});

  final String name;

  Widget _icon(IconData icon, Color color, double size) => Icon(
    icon,
    color: color,
    size: size,
    shadows: const [
      Shadow(color: Color(0x40081A36), offset: Offset(0, 3), blurRadius: 2),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 72,
      child: switch (name) {
        'Beginner' => _icon(Icons.spa_rounded, const Color(0xFF157D35), 62),
        'Easy' => _icon(Icons.star_rounded, AppColors.gold, 66),
        'Medium' => Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: _icon(Icons.star_rounded, AppColors.gold, 40),
            ),
            Positioned(
              left: 0,
              bottom: 3,
              child: _icon(Icons.star_rounded, AppColors.gold, 38),
            ),
            Positioned(
              right: 0,
              bottom: 3,
              child: _icon(Icons.star_rounded, AppColors.gold, 38),
            ),
          ],
        ),
        'Hard' => _icon(Icons.landscape_rounded, AppColors.orange, 66),
        _ => const CustomPaint(painter: _CrownPainter()),
      },
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final crown = Path()
      ..moveTo(size.width * 0.14, size.height * 0.7)
      ..lineTo(size.width * 0.06, size.height * 0.27)
      ..lineTo(size.width * 0.32, size.height * 0.43)
      ..lineTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width * 0.68, size.height * 0.43)
      ..lineTo(size.width * 0.94, size.height * 0.27)
      ..lineTo(size.width * 0.86, size.height * 0.7)
      ..close();
    canvas.drawShadow(crown, AppColors.ink, 3, false);
    canvas.drawPath(crown, Paint()..color = AppColors.gold);
    canvas.drawPath(
      crown,
      Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.53),
      5,
      Paint()..color = AppColors.pink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.14,
          size.height * 0.7,
          size.width * 0.72,
          8,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.purple,
    );
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => false;
}

class _LevelHillsPainter extends CustomPainter {
  const _LevelHillsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final hills = Path()
      ..moveTo(size.width * 0.46, size.height)
      ..lineTo(size.width * 0.7, size.height * 0.38)
      ..lineTo(size.width * 0.85, size.height * 0.57)
      ..lineTo(size.width, size.height * 0.2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hills, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LevelHillsPainter oldDelegate) =>
      oldDelegate.color != color;
}
