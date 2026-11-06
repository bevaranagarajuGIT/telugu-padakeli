import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_colors.dart';
import '../models/kids_question.dart';
import '../services/kids_question_service.dart';
import '../shared/widgets/home_artwork.dart';
import '../widgets/premium_telugu_text.dart';

class KidsGameScreen extends StatefulWidget {
  const KidsGameScreen({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  State<KidsGameScreen> createState() => _KidsGameScreenState();
}

class _KidsGameScreenState extends State<KidsGameScreen> {
  final _levels = const KidsQuestionService().getLevels();
  Timer? _advanceTimer;
  Timer? _clearFeedbackTimer;
  int _levelIndex = 0;
  int _index = 0;
  int _score = 0;
  bool _hasScored = false;
  bool _isAdvancing = false;
  bool _isComplete = false;
  String? _selectedAnswer;
  String? _message;
  bool? _wasCorrect;

  KidsQuestionLevel get _currentLevel => _levels[_levelIndex];
  KidsQuestion get _currentQuestion => _currentLevel.questions[_index];
  Color get _levelColor => const [
    AppColors.teal,
    AppColors.blue,
    AppColors.purple,
    AppColors.orange,
    AppColors.pink,
  ][_levelIndex];
  Color get _accent => Theme.of(context).brightness == Brightness.dark
      ? Color.lerp(AppColors.purple, Colors.white, 0.5)!
      : AppColors.purple;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _clearFeedbackTimer?.cancel();
    super.dispose();
  }

  void _check() {
    if (_isAdvancing || _isComplete) {
      return;
    }
    _clearFeedbackTimer?.cancel();
    if (_selectedAnswer == null) {
      setState(() {
        _message = 'ఒక అక్షరం ఎంచుకోండి.';
        _wasCorrect = null;
      });
      return;
    }

    final isCorrect = _selectedAnswer == _currentQuestion.answer;
    setState(() {
      _wasCorrect = isCorrect;
      if (isCorrect) {
        if (!_hasScored) {
          _score++;
          _hasScored = true;
        }
        _message = 'సరైంది! మీ స్కోరు పెరిగింది.';
        _isAdvancing = true;
      } else {
        _message = 'తప్పు సమాధానం. మళ్ళీ ప్రయత్నించండి.';
      }
    });

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
      return;
    }

    if (_levelIndex + 1 < _levels.length) {
      setState(() {
        _levelIndex++;
        _index = 0;
        _hasScored = false;
        _isAdvancing = false;
        _selectedAnswer = null;
        _message = 'కొత్త స్థాయి: ${_levels[_levelIndex].title}';
        _wasCorrect = true;
      });
      _clearFeedbackTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _message = null;
            _wasCorrect = null;
          });
        }
      });
      return;
    }

    setState(() {
      _isComplete = true;
      _isAdvancing = false;
    });
  }

  void _restart() {
    _advanceTimer?.cancel();
    _clearFeedbackTimer?.cancel();
    setState(() {
      _levelIndex = 0;
      _index = 0;
      _score = 0;
      _hasScored = false;
      _isAdvancing = false;
      _isComplete = false;
      _selectedAnswer = null;
      _message = null;
      _wasCorrect = null;
    });
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
      appBar: AppBar(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: (titleSize * 1.6 + 16).clamp(56, double.infinity),
        leading: widget.onBack == null
            ? null
            : IconButton(
                tooltip: 'Back to Home',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(
          'Play & Learn',
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
            key: const ValueKey('kids-scroll'),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _isComplete
                    ? _completion()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _status(),
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
                  PremiumTeluguText(
                    'స్థాయి ${_levelIndex + 1} · ${_currentLevel.name}',
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
                label: 'Score: $_score',
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
            label: 'Question progress',
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
        PremiumTeluguText(
          'తప్పిన అక్షరాన్ని ఎంచుకోండి',
          textAlign: TextAlign.center,
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
                for (final option in _currentQuestion.options)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      selected: _selectedAnswer == option,
                      child: OutlinedButton(
                        key: ValueKey('kids-answer-$option'),
                        onPressed: _isAdvancing
                            ? null
                            : () => setState(() => _selectedAnswer = option),
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
        FilledButton.icon(
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
          label: const Text('Check'),
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
            Icon(
              _wasCorrect == null
                  ? Icons.info_outline_rounded
                  : _wasCorrect!
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: foreground,
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
                          child: PremiumTeluguText(
                            _currentQuestion.hint,
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
        Image.asset(
          HomeArtwork.celebration,
          width: 120,
          height: 128,
          excludeFromSemantics: true,
          cacheWidth: 360,
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
        FilledButton.icon(
          onPressed: _restart,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('మళ్లీ ఆడండి'),
        ),
      ],
    );
  }
}
