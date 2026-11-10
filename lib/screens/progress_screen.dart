import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return AppPage(
      title: 'నా పురోగతి / My Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ఈ రోజు · ${saved?.today ?? calendarDay(DateTime.now())}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '$questions / $goal ప్రశ్నలు · Today’s correct questions',
            key: const ValueKey('progress-daily-goal'),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (questions / goal).clamp(0, 1),
            minHeight: 8,
            semanticsLabel: '$questions of $goal daily questions completed',
          ),
          const SizedBox(height: 12),
          Text(
            'నేటి పూర్తి చేసిన ఆటలు: ${saved?.todayActivities ?? 0}\n'
            'Today: distinct correctly answered questions and completed activities. '
            'Change the modest daily goal in Settings.',
          ),
          const SizedBox(height: 20),
          if (checked == 0 && (saved?.completedPuzzles.isEmpty ?? true))
            const Text(
              'ఇంకా అభ్యాసం లేదు. ఒక చిన్న ఆటతో మొదలుపెడదాం!\n'
              'No recorded learning yet. Start an activity—there is no ranking or accuracy to estimate.',
            ),
          const SizedBox(height: 12),
          _stat(
            context,
            'పూర్తి చేసిన ఆటలు / Completed activities',
            '${saved?.completedActivities.length ?? 0}',
          ),
          _stat(
            context,
            'పూర్తి చేసిన పదకేళీలు / Classic puzzles',
            '${saved?.completedPuzzles.length ?? 0}',
          ),
          _stat(
            context,
            'సంపాదించిన నక్షత్రాలు / Earned stars',
            '${saved?.stars ?? 0}',
          ),
          _stat(
            context,
            'వరుస అభ్యాస రోజులు / Current · best day streak',
            '${saved?.currentStreak ?? 0} · ${saved?.bestStreak ?? 0}',
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              'మొదటి ప్రయత్నం / First attempts',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            checked == 0
                ? 'No checked questions yet.'
                : '$first / $checked correct on the first check '
                      '(${(first * 100 / checked).round()}%).',
          ),
          Text(
            '${saved?.attempts ?? 0} submitted checks · '
            '${saved?.eventuallyCorrect ?? 0} questions eventually correct.',
          ),
          const Text(
            'Kids and original practice only. First attempt means the '
            'first-ever submitted check for each unchanged question. '
            'Retries and replays never turn a missed first answer into a first-attempt success.',
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              'అభ్యాస దారులు / Learning paths',
              style: theme.textTheme.titleLarge,
            ),
          ),
          for (final category in LearningCategory.values) ...[
            const SizedBox(height: 12),
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KidsLearningText.control(
                      category.title,
                      english: category.english,
                    ),
                    Text('$done / ${path.length} activities completed'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: path.isEmpty ? 0 : done / path.length,
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              'గుర్తింపులు / Achievements',
              style: theme.textTheme.titleLarge,
            ),
          ),
          for (final (id, label) in [
            ('first-activity', 'First activity · complete one activity'),
            ('first-puzzle', 'First crossword · complete one Classic puzzle'),
            (
              'ten-first-answers',
              'Careful start · 10 first-check correct questions',
            ),
            (
              'three-learning-days',
              'Steady learner · 3 consecutive local learning days',
            ),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                saved?.achievements.contains(id) == true
                    ? Icons.verified_rounded
                    : Icons.radio_button_unchecked_rounded,
              ),
              title: Text(label),
              subtitle: Text(
                saved?.achievements.contains(id) == true
                    ? 'Earned'
                    : 'Not yet earned',
              ),
            ),
          const SizedBox(height: 16),
          if (saved?.lastDestination != null && widget.onResume != null)
            FilledButton.icon(
              key: const ValueKey('progress-resume'),
              onPressed: widget.onResume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const KidsLearningText.control(
                'కొనసాగించండి',
                english: 'Resume or revisit',
              ),
            ),
          if (widget.onLearn != null)
            OutlinedButton(
              onPressed: widget.onLearn,
              child: const KidsLearningText.control(
                'ఆటలను చూడండి',
                english: 'Explore learning activities',
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'A streak counts consecutive local calendar days with a '
            'correct answer or completion, not consecutive answers. '
            'Today may be empty while yesterday’s streak stays available. '
            'Clock changes do not erase future records or award the same saved reward twice. '
            'This device’s data is not a mastery assessment or a cloud backup.',
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Card(
    margin: const EdgeInsets.symmetric(vertical: 5),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    ),
  );
}
