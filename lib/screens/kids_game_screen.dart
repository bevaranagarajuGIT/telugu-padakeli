import 'dart:async';

import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../models/kids_question.dart';
import '../services/kids_question_service.dart';
import '../widgets/app_page.dart';

class KidsGameScreen extends StatefulWidget {
  const KidsGameScreen({super.key});

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
  Color get _levelForeground =>
      _levelIndex == 1 || _levelIndex == 2 ? Colors.white : AppColors.ink;

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
    final scheme = Theme.of(context).colorScheme;
    if (_isComplete) {
      return AppPage(
        title: 'Kids Game Mode',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.emoji_events_rounded, size: 72, color: scheme.tertiary),
            const SizedBox(height: 20),
            Text(
              'అన్ని స్థాయిలు పూర్తయ్యాయి!',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'మొత్తం స్కోరు: $_score / ${_levels.fold<int>(0, (total, level) => total + level.questions.length)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'అభినందనలు! అన్ని ${_levels.length} స్థాయిలను పూర్తి చేశారు.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('మళ్లీ ఆడండి'),
            ),
          ],
        ),
      );
    }

    return AppPage(
      title: 'Kids Game Mode',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: ValueKey('kids-level-status-$_levelIndex'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _levelColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: _levelForeground,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'స్థాయి ${_levelIndex + 1} · ${_currentLevel.name}',
                            key: const ValueKey('kids-level'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _levelForeground,
                                ),
                          ),
                          Text(
                            _currentLevel.title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: _levelForeground),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _levelForeground.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '★ $_score',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _levelForeground,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'ప్రశ్న ${_index + 1} / ${_currentLevel.questions.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _levelForeground,
                      ),
                    ),
                    const Spacer(),
                    for (
                      var index = 0;
                      index < _currentLevel.questions.length;
                      index++
                    )
                      Container(
                        key: ValueKey('kids-question-progress-$index'),
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _levelForeground.withValues(
                            alpha: index <= _index ? 1 : 0.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            key: const ValueKey('kids-question-panel'),
            color: scheme.brightness == Brightness.dark
                ? scheme.surfaceContainerHigh
                : AppColors.lightBlue,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'ప్రశ్న',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentQuestion.prompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentQuestion.hint,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'తప్పిన అక్షరాన్ని ఎంచుకోండి',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final option in _currentQuestion.options)
                SizedBox(
                  width: 120,
                  height: 64,
                  child: _selectedAnswer == option
                      ? FilledButton(
                          key: ValueKey('kids-answer-$option'),
                          onPressed: _isAdvancing
                              ? null
                              : () => setState(() => _selectedAnswer = option),
                          child: Text(
                            option,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        )
                      : OutlinedButton(
                          key: ValueKey('kids-answer-$option'),
                          onPressed: _isAdvancing
                              ? null
                              : () => setState(() => _selectedAnswer = option),
                          child: Text(
                            option,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isAdvancing ? null : _check,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Check'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 18),
            Container(
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _wasCorrect == null
                        ? Icons.info_outline_rounded
                        : _wasCorrect!
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: _wasCorrect == null
                        ? scheme.onSecondaryContainer
                        : _wasCorrect!
                        ? AppColors.ink
                        : scheme.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _message!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _wasCorrect == null
                            ? scheme.onSecondaryContainer
                            : _wasCorrect!
                            ? AppColors.ink
                            : scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
