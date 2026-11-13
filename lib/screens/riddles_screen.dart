import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_colors.dart';
import '../core/learning_progress.dart';
import '../models/riddle.dart';
import '../services/riddle_repository.dart';
import '../widgets/premium_telugu_text.dart';

class RiddlesScreen extends StatefulWidget {
  const RiddlesScreen({
    this.repository = const LocalRiddleRepository(),
    this.resume = false,
    super.key,
  });

  final RiddleRepository repository;
  final bool resume;

  @override
  State<RiddlesScreen> createState() => _RiddlesScreenState();
}

class _RiddlesScreenState extends State<RiddlesScreen> {
  LearningProgress? _storage;
  List<Riddle>? _riddles;
  final _answers = <String, Map<String, dynamic>>{};
  final _replayAnswers = <String, Map<String, dynamic>>{};
  int _replayRound = 0;
  int? _replayReturnIndex;
  int _index = 0;
  String? _error;
  bool _reviewOpen = false;
  late bool _showJourney;
  final _milestoneKey = GlobalKey();

  Riddle get _current => _riddles![_index];
  bool get _replaying => _replayAnswers.isNotEmpty;
  Map<String, dynamic> _record(Riddle riddle) =>
      _replayAnswers[riddle.id] ?? _answers[riddle.id]!;
  bool _solved(Riddle riddle) => _answers[riddle.id]!['solved'] == true;
  bool _answered(Riddle riddle) => _record(riddle)['solved'] == true;
  RiddleProgress get _progress => RiddleProgress(_riddles!, _answers);
  int get _solvedCount => _progress.solvedCount;
  List<RiddleLevel> get _levels => _progress.levels;
  List<Riddle> _levelRiddles(RiddleLevel level) => _progress.riddlesIn(level);
  bool _levelComplete(RiddleLevel level) => _progress.isLevelComplete(level);
  bool _roundComplete(RiddleLevel level) =>
      _levelRiddles(level).every(_answered);
  bool _unlocked(RiddleLevel level) => _progress.isUnlocked(level);

  @override
  void initState() {
    super.initState();
    _showJourney = !widget.resume;
    _storage = context.read<LearningProgress?>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _riddles = null;
    });
    try {
      final riddles = await widget.repository.load();
      if (riddles.isEmpty ||
          riddles.map((riddle) => riddle.id).toSet().length != riddles.length) {
        throw const FormatException('Invalid riddle collection.');
      }
      for (final riddle in riddles) {
        riddle.validate();
      }
      if (!mounted) return;
      final saved = _storage?.riddles ?? <String, dynamic>{};
      final answers = savedMap(saved['answers']);
      _answers.clear();
      for (final riddle in riddles) {
        final record = savedMap(answers[riddle.id]);
        final matches = record['signature'] == riddle.signature;
        final tried = record['tried'];
        _answers[riddle.id] = {
          'signature': riddle.signature,
          'solved': matches && record['solved'] == true,
          'hint': matches && record['hint'] == true,
          'tried': matches && tried is List
              ? tried
                    .whereType<String>()
                    .where(riddle.choices.contains)
                    .toSet()
                    .toList()
              : <String>[],
        };
      }
      _index = riddles.indexWhere((riddle) => riddle.id == saved['current']);
      if (_index < 0) {
        _index = riddles.indexWhere((riddle) => !_solved(riddle));
        if (_index < 0) _index = riddles.length - 1;
      }
      setState(() {
        _riddles = riddles;
        if (!_unlocked(_current.level)) {
          final first = _levels.firstWhere((level) => !_levelComplete(level));
          _index = riddles.indexWhere(
            (riddle) => riddle.level == first && !_solved(riddle),
          );
        }
      });
      _persist();
    } on Exception catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Riddle content',
        ),
      );
      if (mounted) {
        setState(
          () => _error =
              'పొడుపు కథలు తెరవలేకపోయాం. మళ్లీ ప్రయత్నించండి.\nCould not load riddles. Please retry.',
        );
      }
    }
  }

  void _persist() {
    if (_replaying) return;
    _storage?.saveRiddles({
      'current': _current.id,
      'answers': {
        for (final entry in _answers.entries)
          entry.key: Map<String, dynamic>.of(entry.value),
      },
    });
  }

  void _choose(Riddle riddle, String choice) {
    if (_showJourney || !identical(riddle, _current) || _answered(riddle)) {
      return;
    }
    final record = _record(riddle);
    final tried = List<String>.from(record['tried'] as List);
    if (tried.contains(choice)) return;
    setState(() {
      record['tried'] = [...tried, choice];
      record['solved'] = choice == riddle.answer;
    });
    _persist();
    if (_roundComplete(riddle.level)) {
      final round = _replayRound;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final milestone = _milestoneKey.currentContext;
        if (mounted &&
            milestone != null &&
            !_showJourney &&
            round == _replayRound &&
            identical(riddle, _current)) {
          Scrollable.ensureVisible(
            milestone,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _hint(Riddle riddle) {
    if (_showJourney ||
        !identical(riddle, _current) ||
        _answered(riddle) ||
        _record(riddle)['hint'] == true) {
      return;
    }
    setState(() => _record(riddle)['hint'] = true);
    _persist();
  }

  void _next(Riddle riddle) {
    if (_showJourney ||
        !identical(riddle, _current) ||
        !_answered(riddle) ||
        _roundComplete(riddle.level)) {
      return;
    }
    final group = _levelRiddles(riddle.level);
    final next =
        group.skip(group.indexOf(riddle) + 1).firstOrNull ??
        group.firstWhere((item) => !_answered(item));
    setState(() {
      _index = _riddles!.indexOf(next);
    });
    _persist();
  }

  void _openLevel(RiddleLevel level) {
    if (!_unlocked(level)) return;
    final group = _levelRiddles(level);
    final next =
        group.where((riddle) => !_solved(riddle)).firstOrNull ??
        (_current.level == level ? _current : group.first);
    setState(() {
      _replayAnswers.clear();
      _replayReturnIndex = null;
      _index = _riddles!.indexOf(next);
      _showJourney = false;
    });
    _persist();
  }

  void _playAgain(Riddle riddle) {
    if (_showJourney ||
        !identical(riddle, _current) ||
        !_roundComplete(riddle.level)) {
      return;
    }
    final group = _levelRiddles(riddle.level);
    setState(() {
      _replayReturnIndex ??= _index;
      _replayRound++;
      _replayAnswers
        ..clear()
        ..addAll({
          for (final item in group)
            item.id: {'solved': false, 'hint': false, 'tried': <String>[]},
        });
      _index = _riddles!.indexOf(group.first);
    });
  }

  void _showLevels() {
    setState(() {
      _index = _replayReturnIndex ?? _index;
      _replayReturnIndex = null;
      _replayAnswers.clear();
      _showJourney = true;
    });
  }

  void _nextLevel(Riddle riddle) {
    if (_showJourney ||
        !identical(riddle, _current) ||
        !_roundComplete(riddle.level)) {
      return;
    }
    final position = _levels.indexOf(riddle.level);
    if (position + 1 < _levels.length) {
      _openLevel(_levels[position + 1]);
    }
  }

  List<String> _choices(Riddle riddle) {
    final seed = riddle.id.codeUnits.fold(
      0,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    final choices = [...riddle.choices]..remove(riddle.answer);
    choices.shuffle(Random(seed));
    choices.insert(_index % 4, riddle.answer);
    return choices;
  }

  Future<void> _review() async {
    if (_reviewOpen || _solvedCount == 0) return;
    _reviewOpen = true;
    final solved = _riddles!.where(_solved).toList();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            key: const ValueKey('riddle-review'),
            appBar: _appBar(context, 'సమాధానాల సమీక్ష'),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: PremiumTeluguText(
                              'సాధించిన పొడుపులు మాత్రమే / Solved riddles only',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      for (final riddle in solved) _reviewCard(context, riddle),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('riddle-review-done'),
                        style: _primaryActionStyle(context),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded),
                        label: const PremiumTeluguText('పూర్తయింది / Done'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      _reviewOpen = false;
    }
  }

  ButtonStyle _primaryActionStyle(BuildContext context) =>
      FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      );

  Widget _reviewCard(BuildContext context, Riddle riddle) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final success = dark
        ? AppColors.darkSuccessForeground
        : AppColors.successForeground;
    return Semantics(
      container: true,
      child: Container(
        key: ValueKey('riddle-review-${riddle.id}'),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: dark ? 0.12 : 0.05),
              offset: const Offset(0, 3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _numberBadge(context, _riddles!.indexOf(riddle) + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: PremiumTeluguText(
                    riddle.question,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: success, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: PremiumTeluguText(
                    riddle.answer,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PremiumTeluguText(
              riddle.explanation,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberBadge(BuildContext context, int number) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.10),
            scheme.surface,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$number',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _reviewButton(BuildContext context, {bool primary = false}) {
    const label = PremiumTeluguText('సమాధానాల సమీక్ష / Review answers');
    if (primary) {
      return FilledButton.icon(
        key: const ValueKey('riddle-review-answers'),
        style: _primaryActionStyle(context),
        onPressed: _review,
        icon: const Icon(Icons.fact_check_outlined),
        label: label,
      );
    }
    return OutlinedButton.icon(
      key: const ValueKey('riddle-review-answers'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: _review,
      icon: const Icon(Icons.fact_check_outlined),
      label: label,
    );
  }

  Widget _journey(BuildContext context, LearningProgress? storage) {
    final theme = Theme.of(context);
    final progress = _progress;
    final colors = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: theme.brightness,
    );
    return SingleChildScrollView(
      key: const ValueKey('riddle-journey'),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: const ValueKey('riddle-journey-summary'),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PremiumTeluguText(
                      'పొడుపుల యాత్ర',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PremiumTeluguText(
                      _solvedCount == _riddles!.length
                          ? 'భలే! యాత్ర పూర్తయింది!'
                          : 'ఒక్కో పొడుపుతో ముందడుగు వేయండి!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_solvedCount / ${_riddles!.length} · సాధించిన పొడుపులు',
                      key: const ValueKey('riddle-journey-solved'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _solvedCount / _riddles!.length,
                      color: colors.primary,
                      backgroundColor: colors.primary.withValues(alpha: 0.16),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                      semanticsLabel:
                          '$_solvedCount of ${_riddles!.length} riddles solved.',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${progress.completedLevelCount} / ${progress.levels.length} '
                      'స్థాయులు పూర్తి · Levels complete',
                      key: const ValueKey('riddle-journey-levels'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (final level in _levels) ...[
                _levelTile(context, level),
                const SizedBox(height: 12),
              ],
              if (storage?.storageError != null ||
                  storage?.recoveryNotice != null) ...[
                const SizedBox(height: 12),
                Text(storage!.storageError ?? storage.recoveryNotice!),
              ],
              if (_solvedCount > 0) ...[
                const SizedBox(height: 16),
                _reviewButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelTile(BuildContext context, RiddleLevel level) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final group = _levelRiddles(level);
    final count = group.where(_solved).length;
    final done = count == group.length;
    final unlocked = _unlocked(level);
    final active = unlocked && !done;
    final dark = theme.brightness == Brightness.dark;
    final accent = switch (level) {
      RiddleLevel.spark => dark ? scheme.primary : AppColors.actionBlue,
      RiddleLevel.trail => dark ? scheme.tertiary : AppColors.purple,
      RiddleLevel.hero => dark ? AppColors.gold : AppColors.deepOrange,
      RiddleLevel.nature =>
        dark ? AppColors.darkSuccessForeground : AppColors.successForeground,
      RiddleLevel.mysteries => dark ? scheme.tertiary : AppColors.pink,
      RiddleLevel.champion => dark ? AppColors.gold : AppColors.deepBlue,
    };
    final icon = switch (level) {
      RiddleLevel.spark => Icons.bolt_rounded,
      RiddleLevel.trail => Icons.lightbulb_rounded,
      RiddleLevel.hero => Icons.emoji_events_rounded,
      RiddleLevel.nature => Icons.eco_rounded,
      RiddleLevel.mysteries => Icons.search_rounded,
      RiddleLevel.champion => Icons.workspace_premium_rounded,
    };
    final status = !unlocked
        ? 'ముందరి స్థాయి పూర్తి చేయండి / Complete the previous level'
        : done
        ? 'పూర్తి! / Complete!'
        : count > 0
        ? 'కొనసాగిద్దాం! / Continue'
        : 'మొదలుపెడదాం! / Let’s begin';
    return OutlinedButton(
      key: ValueKey('riddle-level-${level.name}'),
      onPressed: unlocked ? () => _openLevel(level) : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        disabledForegroundColor: scheme.onSurfaceVariant,
        backgroundColor: Color.alphaBlend(
          accent.withValues(alpha: active ? 0.10 : 0.03),
          scheme.surface,
        ),
        side: BorderSide(
          color: unlocked
              ? Color.alphaBlend(
                  accent.withValues(alpha: active ? 0.50 : 0.18),
                  scheme.surface,
                )
              : scheme.outlineVariant,
          width: active ? 1.5 : 1,
        ),
        padding: EdgeInsets.all(active ? 18 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: unlocked ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 24, color: accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumTeluguText(
                      '${_levels.indexOf(level) + 1}. ${level.title}',
                      style:
                          (active
                                  ? theme.textTheme.titleLarge
                                  : theme.textTheme.titleMedium)
                              ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    Text(
                      level.englishTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$count / ${group.length} · $status',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                !unlocked
                    ? Icons.lock_outline_rounded
                    : done
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                color: unlocked ? accent : scheme.onSurfaceVariant,
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 16),
            PremiumTeluguText(
              level.invitation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: count / group.length,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              minHeight: 5,
              semanticsLabel:
                  '${level.englishTitle}: $count of ${group.length}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _completionBanner(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final riddle = _current;
    final complete = _solvedCount == _riddles!.length;
    final position = _levels.indexOf(riddle.level);
    final hasNext = position + 1 < _levels.length;
    return Container(
      key: _milestoneKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          AppColors.gold.withValues(alpha: 0.18),
          scheme.surface,
        ),
        border: Border.all(
          color: Color.alphaBlend(
            AppColors.gold.withValues(alpha: 0.55),
            scheme.surface,
          ),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: AppColors.navy,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 14),
          PremiumTeluguText(
            _replaying
                ? 'భలే! మళ్లీ సాధించారు!'
                : complete
                ? 'అన్ని పొడుపులు సాధించారు!'
                : 'అద్భుతం! ${riddle.level.title} పూర్తి!',
            key: ValueKey(
              _replaying
                  ? 'riddle-replay-complete'
                  : complete
                  ? 'riddles-complete'
                  : 'riddle-level-complete',
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _replaying
                ? 'Replay complete!'
                : complete
                ? 'Collection complete!'
                : 'Level complete!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          PremiumTeluguText(
            riddle.level.celebration,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (hasNext) ...[
            FilledButton.icon(
              key: const ValueKey('riddle-next-level'),
              style: _primaryActionStyle(context),
              onPressed: () => _nextLevel(riddle),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const PremiumTeluguText('తరువాతి స్థాయి / Next level'),
            ),
            const SizedBox(height: 12),
          ],
          _reviewButton(context, primary: !hasNext),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('riddle-play-again'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 52),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _playAgain(riddle),
            icon: const Icon(Icons.replay_rounded),
            label: const PremiumTeluguText('మళ్లీ ఆడుదాం / Play again'),
          ),
        ],
      ),
    );
  }

  Widget _answerFeedback(BuildContext context, Riddle riddle) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final foreground = dark
        ? AppColors.darkSuccessForeground
        : AppColors.successForeground;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkSuccessBackground
              : AppColors.successBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: PremiumTeluguText(
                    'సరైన సమాధానం! / Correct!',
                    key: const ValueKey('riddle-correct'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PremiumTeluguText(
              riddle.explanation,
              key: const ValueKey('riddle-explanation'),
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(
    BuildContext context,
    String title, {
    bool backToLevels = false,
  }) => AppBar(
    backgroundColor: AppColors.deepBlue,
    foregroundColor: Colors.white,
    leading: backToLevels
        ? IconButton(
            key: const ValueKey('riddle-levels-back'),
            tooltip: 'స్థాయులు / Levels',
            onPressed: _showLevels,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        : null,
    toolbarHeight:
        (MediaQuery.textScalerOf(
                      context,
                    ).scale(Theme.of(context).textTheme.titleLarge!.fontSize!) *
                    1.8 +
                16)
            .clamp(64, double.infinity),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontFamily: PremiumTeluguText.fontFamily,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<LearningProgress?>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final riddles = _riddles;
    final riddle = riddles == null ? null : _current;
    final levelDone = riddle != null && _roundComplete(riddle.level);
    final group = riddle == null ? <Riddle>[] : _levelRiddles(riddle.level);
    final levelSolved = group.where(_answered).length;
    return PopScope(
      canPop: _showJourney || riddles == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showLevels();
      },
      child: Scaffold(
        key: const ValueKey('riddles-screen'),
        appBar: _appBar(
          context,
          'పొడుపు కథలు',
          backToLevels: !_showJourney && riddles != null,
        ),
        body: SafeArea(
          child: _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PremiumTeluguText(_error!),
                        FilledButton(
                          key: const ValueKey('riddles-retry'),
                          onPressed: _load,
                          child: const PremiumTeluguText(
                            'మళ్లీ ప్రయత్నించండి / Retry',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : riddles == null
              ? const Center(child: CircularProgressIndicator())
              : _showJourney
              ? _journey(context, storage)
              : SingleChildScrollView(
                  key: ValueKey('riddle-scroll-${_current.id}-$_replayRound'),
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (levelDone) ...[
                            _completionBanner(context),
                            const SizedBox(height: 20),
                          ],
                          if (storage?.storageError != null ||
                              storage?.recoveryNotice != null) ...[
                            Text(
                              storage!.storageError ?? storage.recoveryNotice!,
                            ),
                            const SizedBox(height: 16),
                          ],
                          PremiumTeluguText(
                            '${_levels.indexOf(_current.level) + 1}. ${_current.level.title}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_replaying) ...[
                            PremiumTeluguText(
                              'సాధన ఆట / Practice round',
                              key: const ValueKey('riddle-replay-status'),
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            '${group.indexOf(_current) + 1} / ${group.length} · సాధించినవి: $levelSolved',
                            key: const ValueKey('riddle-progress'),
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: levelSolved / group.length,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(6),
                            backgroundColor: scheme.primary.withValues(
                              alpha: 0.10,
                            ),
                            semanticsLabel:
                                'Solved riddles in this level: $levelSolved of ${group.length}',
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final question = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Color.alphaBlend(
                                        AppColors.gold.withValues(alpha: 0.15),
                                        scheme.surface,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: PremiumTeluguText(
                                      _current.question,
                                      key: ValueKey(
                                        'riddle-question-${_current.id}',
                                      ),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_record(_current)['hint'] == true)
                                    Semantics(
                                      liveRegion: true,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: scheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.lightbulb_outline_rounded,
                                              color: scheme.onPrimaryContainer,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: PremiumTeluguText(
                                                _current.hint,
                                                key: const ValueKey(
                                                  'riddle-hint-text',
                                                ),
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onPrimaryContainer,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else if (!_answered(_current))
                                    OutlinedButton.icon(
                                      key: const ValueKey('riddle-hint'),
                                      onPressed: () => _hint(riddle!),
                                      icon: const Icon(
                                        Icons.lightbulb_outline_rounded,
                                      ),
                                      label: const PremiumTeluguText(
                                        'సూచన / Hint',
                                      ),
                                    ),
                                ],
                              );
                              final choices = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const PremiumTeluguText('సమాధానం ఎంచుకోండి'),
                                  const SizedBox(height: 8),
                                  for (final (position, choice) in _choices(
                                    _current,
                                  ).indexed) ...[
                                    _option(_current, choice, position + 1),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              );
                              if (constraints.maxWidth >= 700 &&
                                  MediaQuery.textScalerOf(context).scale(
                                        theme.textTheme.bodyMedium!.fontSize!,
                                      ) <=
                                      24) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: question),
                                    const SizedBox(width: 24),
                                    Expanded(child: choices),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  question,
                                  const SizedBox(height: 16),
                                  choices,
                                ],
                              );
                            },
                          ),
                          if (_answered(_current)) ...[
                            _answerFeedback(context, _current),
                            const SizedBox(height: 16),
                            if (!levelDone)
                              FilledButton(
                                key: const ValueKey('riddle-next'),
                                style: _primaryActionStyle(context),
                                onPressed: () => _next(riddle!),
                                child: const PremiumTeluguText(
                                  'తరువాతి పొడుపు / Next',
                                ),
                              ),
                          ] else if ((_record(_current)['tried'] as List)
                              .isNotEmpty)
                            Semantics(
                              liveRegion: true,
                              child: const PremiumTeluguText(
                                'ఇది కాదు. మరో సమాధానం ప్రయత్నించండి.\nNot quite. Try another answer.',
                                key: ValueKey('riddle-try-again'),
                              ),
                            ),
                          if (_solvedCount > 0 && !levelDone) ...[
                            const SizedBox(height: 16),
                            _reviewButton(context),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _option(Riddle riddle, String choice, int position) {
    final scheme = Theme.of(context).colorScheme;
    final correct = _answered(riddle) && choice == riddle.answer;
    final tried = (_record(riddle)['tried'] as List).contains(choice);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = correct
        ? dark
              ? AppColors.darkSuccessForeground
              : AppColors.successForeground
        : tried
        ? scheme.onErrorContainer
        : scheme.onSurface;
    final background = correct
        ? dark
              ? AppColors.darkSuccessBackground
              : AppColors.successBackground
        : tried
        ? scheme.errorContainer
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: dark ? 0.12 : 0.05),
            scheme.surface,
          );
    return OutlinedButton(
      key: ValueKey('riddle-choice-$choice'),
      onPressed: _answered(riddle) || tried
          ? null
          : () => _choose(riddle, choice),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        disabledForegroundColor: foreground,
        backgroundColor: background,
        minimumSize: const Size(48, 56),
        padding: const EdgeInsets.all(12),
        side: BorderSide(
          color: correct || tried ? foreground : scheme.outlineVariant,
          width: correct || tried ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          _numberBadge(context, position),
          const SizedBox(width: 12),
          Expanded(
            child: PremiumTeluguText(
              choice,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (correct || tried) ...[
            const SizedBox(width: 12),
            Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_outlined,
              semanticLabel: correct ? 'Correct answer' : 'Incorrect answer',
            ),
          ],
        ],
      ),
    );
  }
}
