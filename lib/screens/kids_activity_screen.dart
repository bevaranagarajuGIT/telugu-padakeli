import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_colors.dart';
import '../core/kids_learning_controller.dart';
import '../models/kids_learning.dart';
import '../services/engagement_audio_manager.dart';
import '../widgets/engagement_motion.dart';
import '../widgets/special_achievement_celebration.dart';
import '../widgets/kids_learning_text.dart';

class KidsActivityScreen extends StatefulWidget {
  const KidsActivityScreen({
    required this.session,
    this.learning,
    this.onNext,
    super.key,
  });
  final KidsActivitySession session;
  final KidsLearningController? learning;
  final VoidCallback? onNext;

  @override
  State<KidsActivityScreen> createState() => _KidsActivityScreenState();
}

class _KidsActivityScreenState extends State<KidsActivityScreen> {
  KidsActivitySession get session => widget.session;
  EngagementAudioManager? _audio;
  late KidsAnswerState _previousAnswer;
  late bool _previousComplete;
  int _feedbackRevision = 0;
  bool _freshFeedback = false;
  bool _freshCompletion = false;
  bool _leavingCompletion = false;

  @override
  void initState() {
    super.initState();
    _previousAnswer = session.answerState;
    _previousComplete = session.complete;
    session.addListener(_sessionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.read<EngagementAudioManager?>();
  }

  @override
  void didUpdateWidget(KidsActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session == session) return;
    oldWidget.session.removeListener(_sessionChanged);
    _audio?.stop();
    _previousAnswer = session.answerState;
    _previousComplete = session.complete;
    _freshFeedback = false;
    _freshCompletion = false;
    _leavingCompletion = false;
    _feedbackRevision++;
    session.addListener(_sessionChanged);
  }

  void _play(EngagementCue cue) => _audio?.play(
    cue,
    isForeground:
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true),
  );

  void _leaveCompletion(VoidCallback action) {
    if (!session.complete || _leavingCompletion) return;
    setState(() => _leavingCompletion = true);
    _audio?.stop();
    action();
  }

  void _sessionChanged() {
    if (session.complete && !_previousComplete) {
      _freshCompletion = true;
      _play(
        session.earnedStarOnCompletion
            ? EngagementCue.reward
            : EngagementCue.completion,
      );
    } else if (!session.complete) {
      _freshCompletion = false;
      if (session.answerState != _previousAnswer &&
          session.answerState != KidsAnswerState.ready) {
        _feedbackRevision++;
        _freshFeedback = true;
        _play(
          session.answerState == KidsAnswerState.correct
              ? EngagementCue.correct
              : EngagementCue.retry,
        );
      }
    }
    _previousAnswer = session.answerState;
    _previousComplete = session.complete;
  }

  @override
  void dispose() {
    session.removeListener(_sessionChanged);
    _audio?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: session,
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
          title: Text(
            session.activity.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            tooltip: 'ఆటలకు వెళ్లు',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            IconButton(
              tooltip: 'మళ్లీ మొదలుపెట్టు',
              onPressed: session.restart,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('kids-activity-scroll'),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: session.complete
                    ? _completion(context)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'ప్రశ్న ${session.index + 1} / ${session.activity.questions.length}',
                            key: const ValueKey('learning-question-number'),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: session.progress,
                            color: AppColors.purple,
                            semanticsLabel: 'పూర్తయిన ప్రశ్నలు',
                          ),
                          const SizedBox(height: 24),
                          KidsLearningText(
                            session.question.prompt,
                            english: session.question.englishPrompt,
                            center: true,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          if (session.question.imageAsset != null)
                            Image.asset(
                              session.question.imageAsset!,
                              height: 200,
                              fit: BoxFit.contain,
                              cacheWidth: 600,
                              semanticLabel: session.question.imageDescription,
                            ),
                          if (session.question.display != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: KidsLearningText(
                                session.answerState ==
                                            KidsAnswerState.correct &&
                                        session.question.completedWord != null
                                    ? session.question.completedWord!
                                    : session.question.display!,
                                center: true,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (session.activity.type ==
                              KidsActivityType.completion) ...[
                            KidsLearningText(
                              session.question.explanation,
                              english: session.question.englishExplanation,
                              center: true,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (session.activity.type == KidsActivityType.builder)
                            _builder(context)
                          else
                            for (final choice in session.question.choices) ...[
                              TapFeedback(
                                enabled: !session.locked,
                                child: OutlinedButton(
                                  key: ValueKey(
                                    'learning-choice-${choice.telugu}',
                                  ),
                                  onPressed: session.locked
                                      ? null
                                      : () {
                                          session.selectChoice(choice.telugu);
                                          if (session.activity.type ==
                                                  KidsActivityType.picture ||
                                              session.activity.type ==
                                                  KidsActivityType.letter) {
                                            session.check();
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(48, 64),
                                    padding: const EdgeInsets.all(16),
                                    backgroundColor:
                                        session.choice == choice.telugu
                                        ? AppColors.purple
                                        : scheme.surface,
                                    foregroundColor:
                                        session.choice == choice.telugu
                                        ? Colors.white
                                        : scheme.onSurface,
                                    disabledBackgroundColor:
                                        session.choice == choice.telugu
                                        ? AppColors.purple
                                        : scheme.surface,
                                    disabledForegroundColor:
                                        session.choice == choice.telugu
                                        ? Colors.white
                                        : scheme.onSurfaceVariant,
                                    side: BorderSide(
                                      color: session.choice == choice.telugu
                                          ? AppColors.purple
                                          : scheme.outline,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    animationDuration:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 120),
                                  ),
                                  child: KidsLearningText(
                                    choice.telugu,
                                    english: choice.english,
                                    center: true,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: session.choice == choice.telugu
                                              ? Colors.white
                                              : scheme.onSurface,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          if (session.answerState != KidsAnswerState.ready) ...[
                            _feedback(context),
                            const SizedBox(height: 16),
                          ],
                          if (session.answerState == KidsAnswerState.correct)
                            TapFeedback(
                              child: FilledButton(
                                key: const ValueKey('learning-next'),
                                onPressed: session.next,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: KidsLearningText(
                                    session.index + 1 ==
                                            session.activity.questions.length
                                        ? 'ఆట ముగించు'
                                        : 'తరువాతి ప్రశ్న',
                                    english:
                                        session.index + 1 ==
                                            session.activity.questions.length
                                        ? 'Finish activity'
                                        : 'Next question',
                                    center: true,
                                  ),
                                ),
                              ),
                            )
                          else if (session.activity.type !=
                                  KidsActivityType.picture &&
                              session.activity.type != KidsActivityType.letter)
                            TapFeedback(
                              child: FilledButton(
                                key: const ValueKey('learning-check'),
                                onPressed: session.check,
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: KidsLearningText(
                                    'సరిచూడు',
                                    english: 'Check answer',
                                    center: true,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const KidsLearningText(
                              'ఆటలకు వెళ్లు',
                              english: 'Return to activities',
                              center: true,
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

  Widget _builder(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('learning-built-word'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                session.selectedTiles.isEmpty
                    ? '…'
                    : session.selectedTiles
                          .map((i) => session.question.tiles[i])
                          .join(),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final i in session.selectedTiles)
                    InputChip(
                      key: ValueKey('learning-selected-$i'),
                      label: Text(session.question.tiles[i]),
                      deleteButtonTooltipMessage: 'ఈ అక్షరం తీసేయి',
                      onDeleted: session.locked
                          ? null
                          : () => session.removeTile(i),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < session.question.tiles.length; i++)
              TapFeedback(
                enabled: !session.locked && !session.selectedTiles.contains(i),
                child: OutlinedButton(
                  key: ValueKey('learning-tile-$i'),
                  onPressed: session.locked || session.selectedTiles.contains(i)
                      ? null
                      : () => session.selectTile(i),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 64),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: Text(
                    session.question.tiles[i],
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            TextButton(
              key: const ValueKey('learning-undo'),
              onPressed: session.locked || session.selectedTiles.isEmpty
                  ? null
                  : session.undoTile,
              child: const KidsLearningText(
                'చివరిది తీసేయి',
                english: 'Undo last tile',
                center: true,
              ),
            ),
            TextButton(
              key: const ValueKey('learning-clear'),
              onPressed: session.locked ? null : session.clearAttempt,
              child: const KidsLearningText(
                'మళ్లీ అమర్చు',
                english: 'Reset attempt',
                center: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _feedback(BuildContext context) {
    final correct = session.answerState == KidsAnswerState.correct;
    final scheme = Theme.of(context).colorScheme;
    final foreground = correct
        ? scheme.onSecondaryContainer
        : scheme.onErrorContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: ValueKey(correct ? 'learning-correct' : 'learning-retry'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: correct ? scheme.secondaryContainer : scheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EngagementReaction(
              key: ValueKey('learning-feedback-motion-$_feedbackRevision'),
              moment: correct
                  ? EngagementMoment.correct
                  : EngagementMoment.retry,
              animate: _freshFeedback,
              child: Icon(
                correct ? Icons.star_rounded : Icons.refresh_rounded,
                size: 36,
                color: foreground,
              ),
            ),
            const SizedBox(height: 8),
            KidsLearningText(
              correct ? 'శభాష్! చాలా బాగా చేశావు!' : 'మళ్లీ ప్రయత్నించు!',
              english: correct ? 'Well done!' : 'Try again!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: foreground),
            ),
            if (correct) ...[
              const SizedBox(height: 8),
              KidsLearningText(
                session.question.explanation,
                english: session.question.englishExplanation,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: foreground),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _completion(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SpecialAchievementCelebration(
        key: const ValueKey('learning-completion-motion'),
        completed: session.complete,
        word: session.question.completedWord ?? session.question.answer,
        animate: _freshCompletion,
        earnedStar: session.earnedStarOnCompletion,
        totalStars: widget.learning?.stars,
        onSkip: () => _audio?.stop(),
      ),
      const SizedBox(height: 20),
      KidsLearningText(
        'అద్భుతం! ఆట పూర్తయింది.',
        english: 'Wonderful! Activity completed.',
        center: true,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 16),
      if (session.earnedStarOnCompletion)
        const KidsLearningText(
          'ఒక నక్షత్రం సంపాదించావు!',
          english: 'You earned one star!',
          center: true,
        ),
      KidsLearningText(
        '${session.score} / ${session.activity.questions.length} ప్రశ్నలు పూర్తి చేశావు.',
        english: 'All questions completed!',
        center: true,
      ),
      const SizedBox(height: 12),
      const KidsLearningText(
        'ఈ ఆటకు ఈ సెషన్‌లో ఒక నక్షత్రం. మళ్లీ ఆడినా అదనపు నక్షత్రాలు రావు.',
        english: 'One star per activity in this session. Replay anytime.',
        center: true,
      ),
      const SizedBox(height: 24),
      TapFeedback(
        child: FilledButton.icon(
          key: ValueKey(
            widget.onNext == null
                ? 'learning-return'
                : 'learning-next-activity',
          ),
          onPressed: _leavingCompletion
              ? null
              : () => _leaveCompletion(
                  widget.onNext ?? () => Navigator.of(context).pop(),
                ),
          icon: const Icon(Icons.arrow_forward_rounded),
          iconAlignment: IconAlignment.end,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.ink,
            minimumSize: const Size(48, 56),
          ),
          label: Padding(
            padding: const EdgeInsets.all(12),
            child: KidsLearningText(
              widget.onNext == null ? 'ఆటలకు వెళ్లు' : 'తరువాతి స్థాయి',
              english: widget.onNext == null
                  ? 'Return to activities'
                  : 'Next level',
              center: true,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TapFeedback(
        child: OutlinedButton.icon(
          key: const ValueKey('learning-restart'),
          onPressed: _leavingCompletion ? null : session.restart,
          icon: const Icon(Icons.replay_rounded),
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 56)),
          label: const Padding(
            padding: EdgeInsets.all(12),
            child: KidsLearningText(
              'మళ్లీ ఆడుదాం',
              english: 'Play again',
              center: true,
            ),
          ),
        ),
      ),
      if (widget.onNext != null)
        TextButton(
          key: const ValueKey('learning-return'),
          onPressed: _leavingCompletion
              ? null
              : () => _leaveCompletion(() => Navigator.of(context).pop()),
          child: const KidsLearningText(
            'ఆటలకు వెళ్లు',
            english: 'Return to activities',
            center: true,
          ),
        ),
    ],
  );
}
