import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_colors.dart';
import '../core/learning_progress.dart';
import '../core/kids_learning_controller.dart';
import '../models/kids_learning.dart';
import '../services/kids_learning_service.dart';
import '../widgets/app_page.dart';
import '../widgets/kids_learning_text.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({this.onResume, this.onLearn, super.key});
  final VoidCallback? onResume;
  final VoidCallback? onLearn;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with WidgetsBindingObserver {
  Timer? _calendarRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calendarRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _calendarRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<LearningProgress?>();
    final theme = Theme.of(context);
    final questions = saved?.todayQuestions ?? 0;
    final goal = saved?.dailyGoal ?? 3;
    final checked = saved?.checkedQuestions ?? 0;
    final first = saved?.firstAttemptCorrect ?? 0;
    final activities = const KidsLearningService().getActivities();
    final canResume = saved?.lastDestination != null && widget.onResume != null;
    ColorScheme metricColors(Color seed) =>
        ColorScheme.fromSeed(seedColor: seed, brightness: theme.brightness);
    final firstAttemptColors = metricColors(AppColors.purple);
    return AppPage(
      title: 'నా పురోగతి / My Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dailySummary(context, saved, questions, goal),
          if (canResume || widget.onLearn != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              key: ValueKey(canResume ? 'progress-resume' : 'progress-start'),
              onPressed: canResume ? widget.onResume : widget.onLearn,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: Icon(
                canResume ? Icons.play_arrow_rounded : Icons.school_outlined,
              ),
              label: KidsLearningText.control(
                canResume ? 'కొనసాగించండి' : 'ఆటలను చూడండి',
                english: canResume
                    ? 'Resume or revisit'
                    : 'Explore learning activities',
                center: true,
              ),
            ),
          ],
          if (checked == 0 && (saved?.completedPuzzles.isEmpty ?? true))
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: KidsLearningText.control(
                'ఇంకా అభ్యాసం లేదు. ఒక చిన్న ఆటతో మొదలుపెడదాం!',
                english:
                    'No recorded learning yet. Start an activity—there is no ranking or accuracy to estimate.',
              ),
            ),
          const SizedBox(height: 28),
          _heading(context, 'ఇప్పటి వరకు', 'All-time progress'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final largeText =
                  MediaQuery.textScalerOf(
                    context,
                  ).scale(theme.textTheme.bodyMedium!.fontSize!) >
                  18;
              final columns = constraints.maxWidth >= 280 && !largeText ? 2 : 1;
              final stats = [
                _stat(
                  context,
                  id: 'activities',
                  icon: Icons.task_alt_rounded,
                  colors: metricColors(AppColors.blue),
                  value: '${saved?.completedActivities.length ?? 0}',
                  telugu: 'పూర్తి చేసిన ఆటలు',
                  english: 'Completed activities',
                ),
                _stat(
                  context,
                  id: 'puzzles',
                  icon: Icons.grid_on_rounded,
                  colors: metricColors(AppColors.teal),
                  value: '${saved?.completedPuzzles.length ?? 0}',
                  telugu: 'పదకేళీలు',
                  english: 'Classic puzzles',
                ),
                _stat(
                  context,
                  id: 'stars',
                  icon: Icons.star_rounded,
                  colors: metricColors(AppColors.gold),
                  value: '${saved?.stars ?? 0}',
                  telugu: 'నక్షత్రాలు',
                  english: 'Earned stars',
                ),
                _stat(
                  context,
                  id: 'streak',
                  icon: Icons.local_fire_department_outlined,
                  colors: metricColors(AppColors.orange),
                  value: '${saved?.currentStreak ?? 0}',
                  telugu: 'వరుస అభ్యాస రోజులు',
                  english: 'Current day streak',
                  detail:
                      'అత్యధికం: ${saved?.bestStreak ?? 0} · '
                      'Best: ${saved?.bestStreak ?? 0} '
                      '${saved?.bestStreak == 1 ? 'day' : 'days'}',
                ),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (
                    var index = 0;
                    index < stats.length;
                    index += columns
                  ) ...[
                    if (index > 0) const SizedBox(height: 12),
                    if (columns == 1)
                      stats[index]
                    else
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: stats[index]),
                            const SizedBox(width: 12),
                            Expanded(child: stats[index + 1]),
                          ],
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          _heading(context, 'మొదటి ప్రయత్నం', 'First attempts'),
          const SizedBox(height: 12),
          _surface(
            key: const ValueKey('progress-first-surface'),
            colors: firstAttemptColors,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checked == 0 ? '—' : '${(first * 100 / checked).round()}%',
                    key: const ValueKey('progress-first-percentage'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: firstAttemptColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    checked == 0
                        ? 'No checked questions yet.'
                        : '$first / $checked correct on the first check.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: firstAttemptColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${saved?.attempts ?? 0} submitted checks · '
                    '${saved?.eventuallyCorrect ?? 0} questions eventually correct.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: firstAttemptColors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          _heading(context, 'అభ్యాస దారులు', 'Learning paths'),
          const SizedBox(height: 4),
          for (final category in LearningCategory.values) ...[
            Builder(
              builder: (context) {
                final path = activities
                    .where((item) => item.categories.contains(category))
                    .toList();
                final done = path
                    .where(
                      (item) => KidsActivitySession.hasSavedCompletion(
                        item,
                        savedMap(saved?.sessions[item.id]),
                      ),
                    )
                    .length;
                final colors = metricColors(switch (category) {
                  LearningCategory.early => AppColors.teal,
                  LearningCategory.explorers => AppColors.blue,
                  LearningCategory.champions => AppColors.purple,
                });
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _surface(
                    key: ValueKey('progress-path-${category.name}'),
                    colors: colors,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ExcludeSemantics(
                                child: Icon(switch (category) {
                                  LearningCategory.early => Icons.toys_outlined,
                                  LearningCategory.explorers =>
                                    Icons.explore_outlined,
                                  LearningCategory.champions =>
                                    Icons.auto_stories_outlined,
                                }, color: colors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: KidsLearningText.control(
                                  category.title,
                                  english: category.english,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _bar(
                            context,
                            value: path.isEmpty ? 0 : done / path.length,
                            label:
                                '${category.english}: '
                                '$done of ${path.length} activities completed',
                            foreground: colors.primary,
                            background: colors.primary.withValues(alpha: 0.16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$done / ${path.length} activities completed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          if (canResume && widget.onLearn != null)
            FilledButton.tonalIcon(
              key: const ValueKey('progress-explore'),
              onPressed: widget.onLearn,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.school_outlined),
              label: const KidsLearningText.control(
                'ఆటలను చూడండి',
                english: 'Explore learning activities',
                center: true,
              ),
            ),
          const SizedBox(height: 28),
          _heading(context, 'గుర్తింపులు', 'Achievements'),
          const SizedBox(height: 12),
          for (final (id, telugu, label, requirement) in [
            (
              'first-activity',
              'మొదటి ఆట',
              'First activity',
              'Complete one activity',
            ),
            (
              'first-puzzle',
              'మొదటి పదకేళి',
              'First crossword',
              'Complete one Classic puzzle',
            ),
            (
              'ten-first-answers',
              'జాగ్రత్తగా ఆరంభం',
              'Careful start',
              '10 first-check correct questions',
            ),
            (
              'three-learning-days',
              'నిరంతర అభ్యాసం',
              'Steady learner',
              '3 consecutive local learning days',
            ),
          ])
            _achievement(
              context,
              id: id,
              telugu: telugu,
              label: label,
              requirement: requirement,
              earned: saved?.achievements.contains(id) == true,
            ),
          const SizedBox(height: 16),
          ExpansionTile(
            key: const ValueKey('progress-details'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 16),
            title: KidsLearningText.control(
              'లెక్కల గురించి',
              english: 'How progress is counted',
              style: theme.textTheme.titleMedium,
            ),
            children: const [
              Text(
                'Today: distinct correctly answered questions and completed activities. '
                'Change the modest daily goal in Settings.',
              ),
              SizedBox(height: 12),
              Text(
                'Kids and original practice only. First attempt means the '
                'first-ever submitted check for each unchanged question. '
                'Retries and replays never turn a missed first answer into a first-attempt success.',
              ),
              SizedBox(height: 12),
              Text(
                'A streak counts consecutive local calendar days with a '
                'correct answer or completion, not consecutive answers. '
                'Today may be empty while yesterday’s streak stays available. '
                'Clock changes do not erase future records or award the same saved reward twice.',
              ),
              SizedBox(height: 12),
              Text(
                'This device’s data is not a mastery assessment or a cloud backup.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.phone_android_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KidsLearningText.control(
                  'ఈ పరికరంలోని పురోగతి',
                  english: 'Device-local progress · not a cloud backup',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dailySummary(
    BuildContext context,
    LearningProgress? saved,
    int questions,
    int goal,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reached = questions >= goal;
    final foreground = scheme.onPrimaryContainer;
    final date = DateTime.parse(saved?.today ?? calendarDay(DateTime.now()));
    return Container(
      key: const ValueKey('progress-daily-goal'),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _heading(
                    context,
                    'ఈ రోజు లక్ష్యం',
                    'Today’s goal',
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 12),
                ExcludeSemantics(
                  child: Icon(
                    reached ? Icons.verified_rounded : Icons.wb_sunny_outlined,
                    size: 32,
                    color: foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              MaterialLocalizations.of(context).formatMediumDate(date),
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '$questions',
                  key: const ValueKey('progress-today-count'),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                KidsLearningText.control(
                  'సరైన సమాధానాలు',
                  english: 'Correct questions today',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _bar(
              context,
              value: (questions / goal).clamp(0, 1),
              label: '$questions correct questions today. Daily goal: $goal.',
              foreground: scheme.primary,
              background: scheme.surface,
            ),
            const SizedBox(height: 12),
            KidsLearningText.control(
              reached ? 'లక్ష్యం పూర్తయింది!' : 'రోజువారీ లక్ష్యం: $goal',
              english: reached
                  ? 'Daily goal reached · Goal: $goal ${goal == 1 ? 'question' : 'questions'}'
                  : 'Daily goal: $goal ${goal == 1 ? 'question' : 'questions'}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'నేటి పూర్తి చేసిన ఆటలు: ${saved?.todayActivities ?? 0}',
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            Text(
              '${saved?.todayActivities ?? 0} '
              '${saved?.todayActivities == 1 ? 'activity' : 'activities'} completed today',
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(
    BuildContext context,
    String telugu,
    String english, {
    Color? color,
  }) => Semantics(
    header: true,
    child: KidsLearningText.control(
      telugu,
      english: english,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _surface({
    Key? key,
    required ColorScheme colors,
    required Widget child,
  }) => Container(
    key: key,
    decoration: BoxDecoration(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
    ),
    child: child,
  );

  Widget _stat(
    BuildContext context, {
    required String id,
    required IconData icon,
    required ColorScheme colors,
    required String value,
    required String telugu,
    required String english,
    String? detail,
  }) => _surface(
    key: ValueKey('progress-stat-$id'),
    colors: colors,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(icon, color: colors.primary, size: 24),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          KidsLearningText.control(
            telugu,
            english: english,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer),
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _bar(
    BuildContext context, {
    required double value,
    required String label,
    Color? foreground,
    Color? background,
  }) => LinearProgressIndicator(
    value: value,
    minHeight: 8,
    borderRadius: BorderRadius.circular(8),
    color: foreground ?? Theme.of(context).colorScheme.primary,
    backgroundColor:
        background ?? Theme.of(context).colorScheme.surfaceContainerHighest,
    semanticsLabel: label,
  );

  Widget _achievement(
    BuildContext context, {
    required String id,
    required String telugu,
    required String label,
    required String requirement,
    required bool earned,
  }) {
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey('progress-achievement-$id'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              earned ? Icons.verified_rounded : Icons.emoji_events_outlined,
              color: earned
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KidsLearningText.control(
                  telugu,
                  english: label,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(requirement, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  earned
                      ? 'సాధించారు · Earned'
                      : 'ఇంకా సాధించలేదు · Not yet earned',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: earned
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
