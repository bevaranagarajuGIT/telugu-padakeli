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
              'తదుపరి స్థాయి: మధ్యస్థం',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'మధ్యస్థ స్థాయి త్వరలో వస్తుంది.',
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
          Card(
            color: scheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    'స్కోరు: $_score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'స్థాయి ${_levelIndex + 1} · ${_currentLevel.name}',
                    key: const ValueKey('kids-level'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    _currentLevel.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ప్రశ్న ${_index + 1} / ${_currentLevel.questions.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _currentQuestion.prompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentQuestion.hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onTertiaryContainer),
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
