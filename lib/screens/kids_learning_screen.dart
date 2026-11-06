import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../core/kids_learning_controller.dart';
import '../models/kids_learning.dart';
import '../services/kids_learning_service.dart';
import '../shared/widgets/home_artwork.dart';
import '../widgets/kids_learning_text.dart';
import 'kids_activity_screen.dart';
import 'kids_game_screen.dart';
import 'settings_screen.dart';

class KidsLearningScreen extends StatefulWidget {
  const KidsLearningScreen({required this.onBack, super.key});
  final VoidCallback onBack;

  @override
  State<KidsLearningScreen> createState() => _KidsLearningScreenState();
}

class _KidsLearningScreenState extends State<KidsLearningScreen> {
  final _learning = KidsLearningController();
  List<KidsLearningActivity>? _activities;
  String? _error;
  bool _legacyOpen = false;
  bool _legacyVisited = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      _activities = const KidsLearningService().getActivities();
      _error = null;
    } on FormatException catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Kids learning content',
        ),
      );
      _error = 'ఆటల సమాచారం తెరవలేకపోయాం. మళ్లీ ప్రయత్నించండి.';
    }
  }

  @override
  void dispose() {
    _learning.dispose();
    super.dispose();
  }

  Future<void> _open(KidsLearningActivity activity) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            KidsActivityScreen(session: _learning.sessionFor(activity)),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: _legacyOpen ? 1 : 0,
    children: [
      _dashboard(context),
      _legacyVisited
          ? KidsGameScreen(onBack: () => setState(() => _legacyOpen = false))
          : const SizedBox.shrink(),
    ],
  );

  Widget _dashboard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: _learning,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          toolbarHeight:
              (MediaQuery.textScalerOf(
                            context,
                          ).scale(theme.textTheme.titleLarge?.fontSize ?? 22) *
                          2.6 +
                      16)
                  .clamp(64, double.infinity),
          title: const Text(
            'పిల్లల ఆటలు',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            tooltip: 'హోమ్‌కు వెళ్లు',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            IconButton(
              tooltip: 'సెట్టింగ్స్',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('kids-dashboard-scroll'),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KidsLearningText(
                            'తెలుగు నేర్చుకుందాం — ఆడుతూ, ఆనందంగా!',
                            english: 'Learn Telugu through play!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Image.asset(
                                HomeArtwork.welcome,
                                width: 92,
                                height: 110,
                                excludeFromSemantics: true,
                                cacheWidth: 276,
                              ),
                              Semantics(
                                label:
                                    'ఈ సెషన్‌లో ${_learning.stars} నక్షత్రాలు',
                                child: ExcludeSemantics(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.gold,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_learning.stars}',
                                        key: const ValueKey('kids-stars'),
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ఒక ఆట పూర్తి చేస్తే ఒక నక్షత్రం. '
                            'ఈ యాప్ సెషన్‌లో మాత్రమే.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    KidsLearningText(
                      'మీ అభ్యాస దారిని ఎంచుకోండి',
                      english:
                          'Choose a learning path. You can switch anytime.',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in LearningCategory.values)
                          ChoiceChip(
                            key: ValueKey('kids-category-${category.name}'),
                            selected: _learning.category == category,
                            onSelected: (_) =>
                                _learning.selectCategory(category),
                            padding: const EdgeInsets.all(10),
                            label: KidsLearningText(
                              '${category.title} · ${category.ages}',
                              english: category.english,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Text(_error!),
                      TextButton(
                        onPressed: () => setState(_load),
                        child: const Text('మళ్లీ ప్రయత్నించు'),
                      ),
                    ] else
                      for (final activity in _activities!.where(
                        (activity) =>
                            activity.categories.contains(_learning.category),
                      )) ...[
                        _activityCard(activity, scheme),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('kids-legacy'),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const KidsLearningText(
                        'మునుపటి అక్షరాభ్యాసం',
                        english: 'Original five-level practice',
                      ),
                      onPressed: () => setState(() {
                        _legacyVisited = true;
                        _legacyOpen = true;
                      }),
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

  Widget _activityCard(KidsLearningActivity activity, ColorScheme scheme) {
    final color = switch (activity.type) {
      KidsActivityType.picture => AppColors.orange,
      KidsActivityType.letter => AppColors.actionBlue,
      KidsActivityType.completion => AppColors.purple,
      KidsActivityType.builder => AppColors.teal,
      KidsActivityType.meaning => AppColors.pink,
    };
    final image = switch (activity.type) {
      KidsActivityType.picture || KidsActivityType.letter => HomeArtwork.learn,
      KidsActivityType.completion ||
      KidsActivityType.builder => HomeArtwork.classic,
      KidsActivityType.meaning => HomeArtwork.progress,
    };
    final previous = _learning.existingSession(activity.id);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('kids-activity-${activity.id}'),
        onTap: () => _open(activity),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(
                image,
                width: 64,
                height: 76,
                excludeFromSemantics: true,
                cacheWidth: 192,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KidsLearningText(
                      activity.title,
                      english: activity.englishTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${previous?.score ?? 0} / ${activity.questions.length} ప్రశ్నలు',
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: previous?.progress ?? 0,
                      color: color,
                      backgroundColor: scheme.surfaceContainerHighest,
                      semanticsLabel: '${activity.title} పురోగతి',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _learning.completed(activity.id)
                    ? Icons.star_rounded
                    : Icons.chevron_right_rounded,
                color: scheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
