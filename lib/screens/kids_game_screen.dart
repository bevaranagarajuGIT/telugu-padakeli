import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_colors.dart';
import '../core/learning_progress.dart';
import '../models/kids_question.dart';
import '../models/telugu_akshara.dart';
import '../services/kids_answer_order.dart';
import '../services/kids_question_service.dart';
import '../services/engagement_audio_manager.dart';
import '../shared/widgets/home_artwork.dart';
import '../widgets/premium_telugu_text.dart';
import '../widgets/kids_learning_text.dart';
import '../widgets/engagement_motion.dart';
import '../widgets/learning_action_footer.dart';
import '../widgets/special_achievement_celebration.dart';

class KidsGameScreen extends StatefulWidget {
  const KidsGameScreen({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  State<KidsGameScreen> createState() => _KidsGameScreenState();
}

class _KidsGameScreenState extends State<KidsGameScreen> {
  final _levels = const KidsQuestionService().getLevels();
  final _scrollController = ScrollController();
  final _headingFocus = FocusNode();
  Timer? _advanceTimer;
  int _answerOrderSeed = newAnswerOrderSeed();
  int _levelIndex = 0;
  int _index = 0;
  int _score = 0;
  bool _hasScored = false;
  bool _isAdvancing = false;
  bool _isComplete = false;
  bool _isLevelComplete = false;
  String? _selectedAnswer;
  String? _message;
  bool? _wasCorrect;
  int _feedbackRevision = 0;
  EngagementAudioManager? _audio;
  LearningProgress? _storage;
  bool _restored = false;
  bool _freshCompletion = false;
  String get _questionId =>
      'practice:${_currentLevel.name}:${_currentQuestion.prompt}';
  String get _signature => contentSignature([
    for (final level in _levels)
      [
        level.name,
        for (final question in level.questions)
          [
            question.prompt,
            question.answer,
            question.options,
            question.hint,
            question.englishHint,
          ],
      ],
  ]);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.read<EngagementAudioManager?>();
    _storage = context.read<LearningProgress?>();
    if (!_restored) {
      _restored = true;
      final saved = _storage?.practice ?? {};
      final seed = saved['answerOrderSeed'];
      if (seed is int && seed >= 0 && seed <= 0x7fffffff) {
        _answerOrderSeed = seed;
      }
      if (saved['signature'] == _signature) {
        final level = _levels.indexWhere((item) => item.name == saved['level']);
        if (level >= 0) {
          _levelIndex = level;
          final index = _currentLevel.questions.indexWhere(
            (item) => item.prompt == saved['question'],
          );
          if (index >= 0) _index = index;
          final score = saved['score'];
          final maximum = _levels.fold<int>(
            0,
            (sum, item) => sum + item.questions.length,
          );
          _score = score is int && score >= 0 && score <= maximum ? score : 0;
          final choice = saved['choice'];
          if (choice is String && _currentQuestion.options.contains(choice)) {
            _selectedAnswer = choice;
          }
          _hasScored =
              saved['scored'] == true &&
              _selectedAnswer != null &&
              TeluguAkshara.equivalent(
                _selectedAnswer!,
                _currentQuestion.answer,
              );
          _isComplete = saved['complete'] == true && _score == maximum;
          _isLevelComplete =
              !_isComplete &&
              saved['levelComplete'] == true &&
              _levelIndex + 1 < _levels.length &&
              _index == _currentLevel.questions.length - 1 &&
              _hasScored;
        }
      } else if (saved.isNotEmpty) {
        _message =
            'Practice content changed. A fresh attempt starts; your earned rewards are kept.';
      }
    }
  }

  void _save() => _storage?.savePractice({
    'signature': _signature,
    'level': _currentLevel.name,
    'question': _currentQuestion.prompt,
    'score': _score,
    'choice': _selectedAnswer,
    'scored': _hasScored,
    'complete': _isComplete,
    'levelComplete': _isLevelComplete,
    'answerOrderSeed': _answerOrderSeed,
  });

  void _play(EngagementCue cue) => _audio?.play(
    cue,
    isForeground:
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true),
  );

  KidsQuestionLevel get _currentLevel => _levels[_levelIndex];
  KidsQuestion get _currentQuestion => _currentLevel.questions[_index];
  List<String> get _options => orderedKidsChoices(
    _currentQuestion.options,
    isAnswer: (option) =>
        TeluguAkshara.equivalent(option, _currentQuestion.answer),
    seed: _answerOrderSeed,
    questionIndex:
        _index +
        _levels
            .take(_levelIndex)
            .fold<int>(0, (total, level) => total + level.questions.length),
  );
  static const _levelColors = [
    AppColors.teal,
    AppColors.blue,
    AppColors.purple,
    AppColors.orange,
    AppColors.pink,
  ];
  Color get _levelColor => _levelColors[_levelIndex % _levelColors.length];
  Color get _accent => Theme.of(context).brightness == Brightness.dark
      ? Color.lerp(AppColors.purple, Colors.white, 0.5)!
      : AppColors.purple;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _scrollController.dispose();
    _headingFocus.dispose();
    _audio?.stop();
    super.dispose();
  }

  void _check() {
    if (_isAdvancing || _isComplete || _isLevelComplete) {
      return;
    }
    if (_selectedAnswer == null) {
      setState(() {
        _feedbackRevision++;
        _message = 'ఒక అక్షరం ఎంచుకోండి.';
        _wasCorrect = null;
      });
      return;
    }

    final isCorrect = TeluguAkshara.equivalent(
      _selectedAnswer!,
      _currentQuestion.answer,
    );
    if (!_hasScored) {
      _storage?.recordAnswer(
        '$_questionId:${contentSignature([_currentQuestion.answer, _currentQuestion.options, _currentQuestion.hint, _currentQuestion.englishHint])}',
        isCorrect,
      );
    }
    setState(() {
      _feedbackRevision++;
      _wasCorrect = isCorrect;
      if (isCorrect) {
        if (!_hasScored) {
          _score++;
          _hasScored = true;
        }
        _message = 'శభాష్! సరైన సమాధానం.';
        _isAdvancing = true;
      } else {
        _message = 'మళ్లీ ప్రయత్నించు! నువ్వు చేయగలవు.';
      }
    });
    _play(isCorrect ? EngagementCue.correct : EngagementCue.retry);
    _save();

    if (isCorrect) {
      _advanceTimer = Timer(const Duration(milliseconds: 1100), _advance);
    }
  }

  void _advance() {
    if (!mounted) {
      return;
    }

    if (_index + 1 < _currentLevel.questions.length) {
      setState(() {
        _index++;
        _hasScored = false;
        _isAdvancing = false;
        _selectedAnswer = null;
        _message = null;
        _wasCorrect = null;
      });
      _save();
      _resetScrollAndFocus();
      return;
    }

    if (_levelIndex + 1 < _levels.length) {
      _storage?.completeActivity('practice:${_currentLevel.name}');
      setState(() {
        _isLevelComplete = true;
        _isAdvancing = false;
      });
      _save();
      _play(EngagementCue.completion);
      _resetScrollAndFocus();
      return;
    }

    setState(() {
      _isComplete = true;
      _isAdvancing = false;
      _freshCompletion = true;
    });
    _storage?.completeActivity('practice:${_currentLevel.name}');
    _save();
    _play(EngagementCue.completion);
    _resetScrollAndFocus();
  }

  void _nextLevel() {
    if (!_isLevelComplete) return;
    setState(() {
      _isLevelComplete = false;
      _levelIndex++;
      _index = 0;
      _hasScored = false;
      _selectedAnswer = null;
      _message = null;
      _wasCorrect = null;
    });
    _save();
    _resetScrollAndFocus();
  }

  void _resetScrollAndFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      _headingFocus.requestFocus();
    });
  }

  void _restart() {
    _advanceTimer?.cancel();
    _audio?.stop();
    setState(() {
      _answerOrderSeed = newAnswerOrderSeed();
      _levelIndex = 0;
      _index = 0;
      _score = 0;
      _hasScored = false;
      _isAdvancing = false;
      _isComplete = false;
      _isLevelComplete = false;
      _freshCompletion = false;
      _selectedAnswer = null;
      _message = null;
      _wasCorrect = null;
    });
    _save();
    _resetScrollAndFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleSize = MediaQuery.textScalerOf(
      context,
    ).scale(theme.textTheme.titleMedium?.fontSize ?? 16);
    return Scaffold(
      backgroundColor: scheme.surface,
      bottomNavigationBar: _isLevelComplete
          ? LearningActionFooter(
              child: FilledButton.icon(
                key: const ValueKey('legacy-next-level'),
                onPressed: _nextLevel,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 56),
                  padding: const EdgeInsets.all(16),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                iconAlignment: IconAlignment.end,
                label: const KidsLearningText.control(
                  'తరువాతి స్థాయి',
                  english: 'Next level',
                  center: true,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: (titleSize * 1.6 + 16).clamp(56, double.infinity),
        leading: widget.onBack == null
            ? null
            : IconButton(
                tooltip: 'ఆటలకు వెళ్లు / Return to activities',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(
          'పదాన్ని పూర్తి చేయి',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(AppColors.purple, scheme.surface, 0.82)!,
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            controller: _scrollController,
            key: ValueKey(
              _isComplete ? 'kids-completion-scroll' : 'kids-scroll',
            ),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _isLevelComplete
                    ? _levelCompletion()
                    : _isComplete
                    ? Focus(
                        focusNode: _headingFocus,
                        includeSemantics: false,
                        child: _completion(),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Focus(
                            focusNode: _headingFocus,
                            includeSemantics: false,
                            child: _status(),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final enlarged =
                                  MediaQuery.textScalerOf(context).scale(
                                    theme.textTheme.bodyLarge?.fontSize ?? 16,
                                  ) >
                                  22;
                              if (constraints.maxWidth >= 640 && !enlarged) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _question(),
                                          const SizedBox(height: 12),
                                          _hint(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(child: _answers()),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _question(),
                                  const SizedBox(height: 12),
                                  _hint(),
                                  const SizedBox(height: 16),
                                  _answers(),
                                ],
                              );
                            },
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

  Widget _status() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: ValueKey('kids-level-status-$_levelIndex'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KidsLearningText(
                    'స్థాయి ${_levelIndex + 1} · ${_currentLevel.title}',
                    english: _currentLevel.name,
                    key: const ValueKey('kids-level'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  PremiumTeluguText(
                    _currentLevel.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Semantics(
                label: 'స్కోరు: $_score',
                child: ExcludeSemantics(
                  child: Container(
                    key: const ValueKey('kids-score'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color.lerp(AppColors.gold, scheme.surface, 0.78),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: scheme.onSurface,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_score',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PremiumTeluguText(
            'ప్రశ్న ${_index + 1} / ${_currentLevel.questions.length}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            label: 'ప్రశ్న పురోగతి',
            value: '${_index + 1} of ${_currentLevel.questions.length}',
            child: Row(
              children: [
                for (
                  var index = 0;
                  index < _currentLevel.questions.length;
                  index++
                )
                  Expanded(
                    child: Container(
                      key: ValueKey('kids-question-progress-$index'),
                      height: 6,
                      margin: EdgeInsets.only(
                        right: index == _currentLevel.questions.length - 1
                            ? 0
                            : 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: index <= _index
                            ? _levelColor
                            : scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _question() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey('kids-question-panel'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _accent.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.1),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            HomeArtwork.learn,
            width: 104,
            height: 104,
            excludeFromSemantics: true,
            cacheWidth: 312,
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: PremiumTeluguText(
              _currentQuestion.prompt,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _answers() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KidsLearningText(
          'తప్పిన అక్షరాన్ని ఎంచుకోండి',
          english: 'Choose the missing letter.',
          center: true,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final fontSize = MediaQuery.textScalerOf(
              context,
            ).scale(theme.textTheme.headlineSmall?.fontSize ?? 24);
            final minimum = fontSize * 2 + 24;
            final columns = constraints.maxWidth >= minimum * 4 + gap * 3
                ? 4
                : constraints.maxWidth >= minimum * 2 + gap
                ? 2
                : 1;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final option in _options)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      selected: _selectedAnswer == option,
                      child: OutlinedButton(
                        key: ValueKey('kids-answer-$option'),
                        onPressed: _isAdvancing
                            ? null
                            : () {
                                setState(() => _selectedAnswer = option);
                                _save();
                              },
                        style:
                            OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 64),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              backgroundColor: _selectedAnswer == option
                                  ? AppColors.purple
                                  : scheme.surface,
                              foregroundColor: _selectedAnswer == option
                                  ? Colors.white
                                  : scheme.onSurface,
                              disabledBackgroundColor: _selectedAnswer == option
                                  ? AppColors.purple
                                  : scheme.surface,
                              disabledForegroundColor: _selectedAnswer == option
                                  ? Colors.white
                                  : scheme.onSurfaceVariant,
                              side: BorderSide(
                                color: _selectedAnswer == option
                                    ? AppColors.purple
                                    : _accent.withValues(alpha: 0.35),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 3,
                              shadowColor: AppColors.purple.withValues(
                                alpha: 0.18,
                              ),
                              animationDuration: reduced
                                  ? Duration.zero
                                  : const Duration(milliseconds: 120),
                            ).copyWith(
                              elevation: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.pressed) ||
                                        states.contains(WidgetState.disabled)
                                    ? 0
                                    : 3,
                              ),
                            ),
                        child: PremiumTeluguText(
                          option,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _selectedAnswer == option
                                ? Colors.white
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        TapFeedback(
          enabled: !_isAdvancing,
          child: FilledButton.icon(
            onPressed: _isAdvancing ? null : _check,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.check_rounded),
            label: const KidsLearningText.control(
              'సరిచూడు',
              english: 'Check answer',
              center: true,
            ),
          ),
        ),
        if (_message != null) ...[const SizedBox(height: 12), _feedback()],
      ],
    );
  }

  Widget _feedback() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = _wasCorrect == null
        ? scheme.onSecondaryContainer
        : _wasCorrect!
        ? AppColors.ink
        : scheme.onErrorContainer;
    return Container(
      key: ValueKey(
        _wasCorrect == null
            ? 'kids-feedback-neutral'
            : _wasCorrect!
            ? 'kids-feedback-success'
            : 'kids-feedback-error',
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _wasCorrect == null
            ? scheme.secondaryContainer
            : _wasCorrect!
            ? AppColors.teal
            : scheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: EngagementReaction(
                key: ValueKey('legacy-feedback-motion-$_feedbackRevision'),
                moment: _wasCorrect == true
                    ? EngagementMoment.correct
                    : EngagementMoment.retry,
                animate: _wasCorrect != null,
                child: Icon(
                  _wasCorrect == null
                      ? Icons.info_outline_rounded
                      : _wasCorrect!
                      ? Icons.star_rounded
                      : Icons.refresh_rounded,
                  color: foreground,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PremiumTeluguText(
                _message!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hint() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enlarged =
        MediaQuery.textScalerOf(
          context,
        ).scale(theme.textTheme.bodyLarge?.fontSize ?? 16) >
        22;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              HomeArtwork.background,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              excludeFromSemantics: true,
              cacheWidth: 960,
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: scheme.surface.withValues(alpha: 0.88)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color.lerp(AppColors.gold, scheme.surface, 0.78),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          color: scheme.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: KidsLearningText(
                            _currentQuestion.hint,
                            english: _currentQuestion.englishHint,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!enlarged) ...[
                  const SizedBox(width: 12),
                  Image.asset(
                    _wasCorrect == true
                        ? HomeArtwork.celebration
                        : HomeArtwork.welcome,
                    width: 80,
                    height: 96,
                    excludeFromSemantics: true,
                    cacheWidth: 240,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _completion() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpecialAchievementCelebration(
          key: const ValueKey('legacy-completion-motion'),
          completed: _isComplete,
          animate: _freshCompletion,
        ),
        const SizedBox(height: 16),
        PremiumTeluguText(
          'అన్ని స్థాయిలు పూర్తయ్యాయి!',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        PremiumTeluguText(
          'మొత్తం స్కోరు: $_score / ${_levels.fold<int>(0, (total, level) => total + level.questions.length)}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        PremiumTeluguText(
          'అభినందనలు! అన్ని ${_levels.length} స్థాయిలను పూర్తి చేశారు.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (widget.onBack != null) ...[
          TapFeedback(
            child: FilledButton.icon(
              key: const ValueKey('legacy-completion-return'),
              onPressed: widget.onBack,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.ink,
                minimumSize: const Size(48, 56),
                padding: const EdgeInsets.all(16),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              iconAlignment: IconAlignment.end,
              label: const KidsLearningText.control(
                'ఆటలకు వెళ్లు',
                english: 'Return to activities',
                center: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TapFeedback(
          child: OutlinedButton.icon(
            key: const ValueKey('legacy-completion-restart'),
            onPressed: _restart,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 56),
              padding: const EdgeInsets.all(16),
            ),
            icon: const Icon(Icons.replay_rounded),
            label: const KidsLearningText.control(
              'మళ్లీ ఆడండి',
              english: 'Play again',
              center: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _levelCompletion() {
    final theme = Theme.of(context);
    final next = _levels[_levelIndex + 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          focusNode: _headingFocus,
          includeSemantics: false,
          child: Semantics(
            header: true,
            liveRegion: true,
            child: KidsLearningText(
              '${_currentLevel.title} పూర్తయింది!',
              key: const ValueKey('legacy-level-complete-heading'),
              english: '${_currentLevel.name} complete!',
              center: true,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        KidsLearningText(
          'స్థాయి ${_levelIndex + 1} / ${_levels.length} • స్కోరు: $_score',
          english:
              'Level ${_levelIndex + 1} of ${_levels.length} • Score: $_score',
          center: true,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Icon(Icons.check_circle_rounded, color: _levelColor, size: 64),
        const SizedBox(height: 24),
        KidsLearningText(
          'తరువాత: ${next.title}',
          english: 'Next: ${next.name}. Tap Next level when you are ready.',
          center: true,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
