import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_colors.dart';
import '../core/kids_learning_controller.dart';
import '../core/learning_progress.dart';
import '../models/kids_learning.dart';
import '../services/kids_learning_service.dart';
import '../services/engagement_audio_manager.dart';
import '../shared/widgets/home_artwork.dart';
import '../widgets/kids_learning_text.dart';
import 'kids_activity_screen.dart';
import 'kids_game_screen.dart';
import 'settings_screen.dart';

class KidsLearningScreen extends StatefulWidget {
  const KidsLearningScreen({
    required this.onBack,
    this.resumeRequest = 0,
    super.key,
  });
  final VoidCallback onBack;
  final int resumeRequest;

  @override
  State<KidsLearningScreen> createState() => _KidsLearningScreenState();
}

class _KidsLearningScreenState extends State<KidsLearningScreen> {
  late final KidsLearningController _learning;
  List<KidsLearningActivity>? _activities;
  String? _error;
  bool _legacyOpen = false;
  bool _legacyVisited = false;

  @override
  void initState() {
    super.initState();
    _learning = KidsLearningController(
      storage: context.read<LearningProgress?>(),
    );
    _load();
    if (widget.resumeRequest > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resume());
    }
  }

  @override
  void didUpdateWidget(KidsLearningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resumeRequest != oldWidget.resumeRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resume());
    }
  }

  void _resume() {
    if (!mounted) return;
    final saved = context.read<LearningProgress?>();
    if (saved?.lastDestination == 'practice') {
      _showLegacy(true);
    } else {
      final activity = _activities
          ?.where((item) => item.id == saved?.lastActivity)
          .firstOrNull;
      if (activity != null) {
        _learning.selectCategory(activity.categories.first);
        _open(activity);
      }
    }
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

  Future<void> _open(KidsLearningActivity initial) async {
    var activity = initial;
    while (mounted) {
      final path = _activities!
          .where((item) => item.categories.contains(_learning.category))
          .toList();
      final index = path.indexWhere((item) => item.id == activity.id);
      final next = index >= 0 && index + 1 < path.length
          ? path[index + 1]
          : null;
      final session = _learning.sessionFor(activity);
      final advance = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (routeContext) => KidsActivityScreen(
            session: session,
            learning: _learning,
            onNext: next == null
                ? null
                : () => Navigator.of(routeContext).pop(true),
          ),
        ),
      );
      if (!mounted || advance != true || !session.complete || next == null) {
        break;
      }
      activity = next;
    }
    if (mounted) setState(() {});
  }

  void _showLegacy(bool open) {
    context.read<EngagementAudioManager?>()?.stop();
    setState(() {
      if (open) _legacyVisited = true;
      _legacyOpen = open;
    });
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: _legacyOpen ? 1 : 0,
    children: [
      TickerMode(enabled: !_legacyOpen, child: _dashboard(context)),
      _legacyVisited
          ? TickerMode(
              enabled: _legacyOpen,
              child: KidsGameScreen(onBack: () => _showLegacy(false)),
            )
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
            tooltip: 'హోమ్‌కు వెళ్లు / Back to Home',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            IconButton(
              tooltip: 'సెట్టింగ్స్ / Settings',
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
                    _LearningWelcome(stars: _learning.stars),
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
                            label: KidsLearningText.control(
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
                        child: const KidsLearningText.control(
                          'మళ్లీ ప్రయత్నించు',
                          english: 'Try again',
                          center: true,
                        ),
                      ),
                    ] else
                      for (final (index, activity)
                          in _activities!
                              .where(
                                (activity) => activity.categories.contains(
                                  _learning.category,
                                ),
                              )
                              .indexed) ...[
                        _activityCard(activity, index + 1, scheme),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('kids-legacy'),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const KidsLearningText.control(
                        'మునుపటి అక్షరాభ్యాసం',
                        english: 'Original seven-level practice',
                      ),
                      onPressed: () => _showLegacy(true),
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

  Widget _activityCard(
    KidsLearningActivity activity,
    int round,
    ColorScheme scheme,
  ) {
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
    final previous = _learning.sessionFor(activity);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
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
                        'రౌండ్ $round',
                        english: 'Round $round',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      KidsLearningText.control(
                        activity.title,
                        english: activity.englishTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${previous.score} / ${activity.questions.length} ప్రశ్నలు',
                      ),
                      const SizedBox(height: 6),
                      ExcludeSemantics(
                        child: LinearProgressIndicator(
                          value: previous.progress,
                          color: color,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
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
      ),
    );
  }
}

class _LearningWelcome extends StatelessWidget {
  const _LearningWelcome({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showMascot =
        MediaQuery.textScalerOf(
          context,
        ).scale(theme.textTheme.bodyLarge?.fontSize ?? 16) <=
        24;
    return Container(
      key: const ValueKey('kids-welcome-panel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.purple, AppColors.deepBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KidsLearningText(
                  'తెలుగు నేర్చుకుందాం — ఆడుతూ, ఆనందంగా!',
                  english: 'Learn Telugu through play!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'మొత్తం $stars నక్షత్రాలు',
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$stars',
                          key: const ValueKey('kids-stars'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ఈ పరికరంలో',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showMascot) ...[
            const SizedBox(width: 10),
            Image.asset(
              HomeArtwork.welcome,
              width: 72,
              height: 86,
              excludeFromSemantics: true,
              cacheWidth: 216,
            ),
          ],
        ],
      ),
    );
  }
}
