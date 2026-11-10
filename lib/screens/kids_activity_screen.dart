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
  final _contentScroll = ScrollController(keepScrollOffset: false);
  final _actionKey = GlobalKey();
  int _previousIndex = 0;

  bool get _useActionDock =>
      MediaQuery.sizeOf(context).height >= 560 &&
      MediaQuery.textScalerOf(
            context,
          ).scale(Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) <=
          32;

  bool get _hasQuestionAction =>
      session.answerState == KidsAnswerState.correct ||
      (session.activity.type != KidsActivityType.picture &&
          session.activity.type != KidsActivityType.letter);

  void _revealInlineAction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _useActionDock) return;
      final actionContext = _actionKey.currentContext;
      if (actionContext == null) return;
      Scrollable.ensureVisible(
        actionContext,
        alignment: 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _previousIndex = session.index;
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
    _previousIndex = session.index;
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
    final newQuestion = session.index != _previousIndex;
    final changedCompletion = session.complete != _previousComplete;
    if (newQuestion || changedCompletion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _contentScroll.hasClients) _contentScroll.jumpTo(0);
      });
    } else if (session.answerState == KidsAnswerState.correct &&
        _previousAnswer != KidsAnswerState.correct) {
      _revealInlineAction();
    }
    _previousIndex = session.index;
    _previousAnswer = session.answerState;
    _previousComplete = session.complete;
  }

  @override
  void dispose() {
    session.removeListener(_sessionChanged);
    _contentScroll.dispose();
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
            tooltip: 'ఆటలకు వెళ్లు / Return to activities',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            IconButton(
              tooltip: 'మళ్లీ మొదలుపెట్టు / Restart activity',
              onPressed: session.restart,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        bottomNavigationBar:
            _useActionDock && (session.complete || _hasQuestionAction)
            ? _actionDock(context)
            : null,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            controller: _contentScroll,
            key: ValueKey(
              session.complete
                  ? 'kids-activity-completion-scroll'
                  : 'kids-activity-scroll',
            ),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: session.complete
                    ? _completion(context)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            key: const ValueKey('learning-progress-panel'),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                AppColors.purple.withValues(alpha: 0.1),
                                scheme.surface,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'ప్రశ్న ${session.index + 1} / ${session.activity.questions.length}',
                                  key: const ValueKey(
                                    'learning-question-number',
                                  ),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: session.progress,
                                  color: AppColors.purple,
                                  backgroundColor: AppColors.purple.withValues(
                                    alpha: 0.15,
                                  ),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(20),
                                  semanticsLabel: 'పూర్తయిన ప్రశ్నలు',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _question(context),
                          const SizedBox(height: 12),
                          if (session.activity.type == KidsActivityType.builder)
                            _builder(context)
                          else
                            for (final choice in session.question.choices) ...[
                              _choice(context, choice),
                              const SizedBox(height: 12),
                            ],
                          if (session.answerState != KidsAnswerState.ready) ...[
                            _feedback(context),
                            const SizedBox(height: 16),
                          ],
                          if (!_useActionDock && _hasQuestionAction)
                            _questionAction(context),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const KidsLearningText.control(
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

  Widget _actionDock(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('learning-action-dock'),
      color: scheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: session.complete
                  ? _completionAction(context)
                  : _questionAction(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionAction(BuildContext context) {
    final correct = session.answerState == KidsAnswerState.correct;
    final finalQuestion =
        session.index + 1 == session.activity.questions.length;
    return SizedBox(
      key: _actionKey,
      width: double.infinity,
      child: TapFeedback(
        child: FilledButton.icon(
          key: ValueKey(correct ? 'learning-next' : 'learning-check'),
          onPressed: correct ? session.next : session.check,
          icon: Icon(
            correct ? Icons.arrow_forward_rounded : Icons.check_rounded,
          ),
          iconAlignment: IconAlignment.end,
          style: FilledButton.styleFrom(
            backgroundColor: correct
                ? AppColors.purple
                : Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          label: KidsLearningText.control(
            correct
                ? (finalQuestion ? 'ఆట ముగించు' : 'తరువాతి ప్రశ్న')
                : 'సరిచూడు',
            english: correct
                ? (finalQuestion ? 'Finish activity' : 'Next question')
                : 'Check answer',
            center: true,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _completionAction(BuildContext context) {
    final theme = Theme.of(context);
    return TapFeedback(
      child: FilledButton.icon(
        key: ValueKey(
          widget.onNext == null ? 'learning-return' : 'learning-next-activity',
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
          minimumSize: const Size(48, 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        label: KidsLearningText.control(
          widget.onNext == null ? 'ఆటలకు వెళ్లు' : 'తరువాతి స్థాయి',
          english: widget.onNext == null
              ? 'Return to activities'
              : 'Next level',
          center: true,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _question(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      key: const ValueKey('learning-question-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          AppColors.gold.withValues(alpha: dark ? 0.08 : 0.14),
          scheme.surface,
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: dark ? 0.3 : 0.6),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KidsLearningText(
            session.question.prompt,
            english: session.question.englishPrompt,
            center: true,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (session.question.imageAsset != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(
                          alpha: dark ? 0.16 : 0.3,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Image.asset(
                    session.question.imageAsset!,
                    height: 176,
                    fit: BoxFit.contain,
                    cacheWidth: 600,
                    semanticLabel: session.question.imageDescription,
                  ),
                ],
              ),
            ),
          ],
          if (session.question.display != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: KidsLearningText(
                session.answerState == KidsAnswerState.correct &&
                        session.question.completedWord != null
                    ? session.question.completedWord!
                    : session.question.display!,
                center: true,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (session.activity.type == KidsActivityType.completion)
            KidsLearningText(
              session.question.explanation,
              english: session.question.englishExplanation,
              center: true,
              style: theme.textTheme.bodyLarge,
            ),
        ],
      ),
    );
  }

  Widget _choice(BuildContext context, KidsChoice choice) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final selected = session.choice == choice.telugu;
    final correct = selected && session.answerState == KidsAnswerState.correct;
    final incorrect =
        selected && session.answerState == KidsAnswerState.incorrect;
    final (background, foreground) = switch ((selected, session.answerState)) {
      (true, KidsAnswerState.correct) => (
        dark ? AppColors.darkSuccessBackground : AppColors.successBackground,
        dark ? AppColors.darkSuccessForeground : AppColors.successForeground,
      ),
      (true, KidsAnswerState.incorrect) => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      (true, _) => (AppColors.purple, Colors.white),
      _ => (
        Color.alphaBlend(
          AppColors.purple.withValues(alpha: dark ? 0.12 : 0.04),
          scheme.surface,
        ),
        scheme.onSurface,
      ),
    };
    return Semantics(
      selected: selected,
      child: TapFeedback(
        enabled: !session.locked,
        child: OutlinedButton(
          key: ValueKey('learning-choice-${choice.telugu}'),
          onPressed: session.locked
              ? null
              : () {
                  session.selectChoice(choice.telugu);
                  if (session.activity.type == KidsActivityType.picture ||
                      session.activity.type == KidsActivityType.letter) {
                    session.check();
                  }
                },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background,
            disabledForegroundColor: foreground,
            side: BorderSide(
              color: selected
                  ? correct || incorrect
                        ? foreground
                        : AppColors.purple
                  : AppColors.purple.withValues(alpha: dark ? 0.65 : 0.3),
              width: selected ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            animationDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 120),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? foreground.withValues(alpha: 0.12)
                        : AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    correct
                        ? Icons.check_rounded
                        : incorrect
                        ? Icons.refresh_rounded
                        : selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.circle_outlined,
                    key: ValueKey('learning-choice-status-${choice.telugu}'),
                    color: selected ? foreground : Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: KidsLearningText(
                  choice.telugu,
                  english: choice.english,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
                      deleteButtonTooltipMessage:
                          'ఈ అక్షరం తీసేయి / Remove this letter',
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
              child: const KidsLearningText.control(
                'చివరిది తీసేయి',
                english: 'Undo last tile',
                center: true,
              ),
            ),
            TextButton(
              key: const ValueKey('learning-clear'),
              onPressed: session.locked ? null : session.clearAttempt,
              child: const KidsLearningText.control(
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final foreground = correct
        ? dark
              ? AppColors.darkSuccessForeground
              : AppColors.successForeground
        : scheme.onErrorContainer;
    final background = correct
        ? dark
              ? AppColors.darkSuccessBackground
              : AppColors.successBackground
        : scheme.errorContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: ValueKey(correct ? 'learning-correct' : 'learning-retry'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: foreground.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: foreground,
                    shape: BoxShape.circle,
                  ),
                  child: EngagementReaction(
                    key: ValueKey(
                      'learning-feedback-motion-$_feedbackRevision',
                    ),
                    moment: correct
                        ? EngagementMoment.correct
                        : EngagementMoment.retry,
                    animate: _freshFeedback,
                    child: Icon(
                      correct ? Icons.star_rounded : Icons.refresh_rounded,
                      size: 32,
                      color: correct ? AppColors.gold : background,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KidsLearningText(
                    correct ? 'శభాష్! చాలా బాగా చేశావు!' : 'మళ్లీ ప్రయత్నించు!',
                    english: correct ? 'Well done!' : 'Try again!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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

  Widget _completion(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = dark
        ? Color.lerp(AppColors.purple, Colors.white, 0.5)!
        : AppColors.purple;
    final successBackground = dark
        ? AppColors.darkSuccessBackground
        : AppColors.successBackground;
    final successForeground = dark
        ? AppColors.darkSuccessForeground
        : AppColors.successForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpecialAchievementCelebration(
          key: const ValueKey('learning-completion-motion'),
          completed: session.complete,
          animate: _freshCompletion,
          earnedStar: session.earnedStarOnCompletion,
          totalStars: widget.learning?.stars,
          onSkip: () => _audio?.stop(),
        ),
        const SizedBox(height: 16),
        KidsLearningText(
          'అద్భుతం! ఆట పూర్తయింది.',
          english: 'Wonderful! Activity completed.',
          center: true,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const ValueKey('learning-completion-result'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: successBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: successForeground, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.earnedStarOnCompletion)
                      KidsLearningText(
                        'ఒక నక్షత్రం సంపాదించావు!',
                        english: 'You earned one star!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: successForeground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    KidsLearningText(
                      '${session.score} / ${session.activity.questions.length} ప్రశ్నలు పూర్తి చేశావు.',
                      english: 'All questions completed!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: successForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KidsLearningText(
          'ఈ ఆటకు ఈ సెషన్‌లో ఒక నక్షత్రం. మళ్లీ ఆడినా అదనపు నక్షత్రాలు రావు.',
          english: 'One star per activity in this session. Replay anytime.',
          center: true,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        if (!_useActionDock) _completionAction(context),
        const SizedBox(height: 12),
        TapFeedback(
          child: OutlinedButton.icon(
            key: const ValueKey('learning-restart'),
            onPressed: _leavingCompletion ? null : session.restart,
            icon: const Icon(Icons.replay_rounded),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              backgroundColor: Color.alphaBlend(
                AppColors.purple.withValues(alpha: 0.06),
                scheme.surface,
              ),
              side: BorderSide(color: accent.withValues(alpha: 0.5)),
              minimumSize: const Size(48, 64),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            label: KidsLearningText.control(
              'మళ్లీ ఆడుదాం',
              english: 'Play again',
              center: true,
              style: theme.textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
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
            child: const KidsLearningText.control(
              'ఆటలకు వెళ్లు',
              english: 'Return to activities',
              center: true,
            ),
          ),
      ],
    );
  }
}
