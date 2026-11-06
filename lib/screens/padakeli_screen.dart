import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_colors.dart';
import '../models/puzzle.dart';
import '../services/local_puzzle_repository.dart';
import '../services/puzzle_repository.dart';
import '../widgets/app_page.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/classic_hints_sheet.dart';
import '../widgets/difficulty_selection.dart';
import '../widgets/premium_telugu_text.dart';

class PadakeliScreen extends StatefulWidget {
  const PadakeliScreen({
    this.repository = const LocalPuzzleRepository(),
    this.onBack,
    super.key,
  });

  final PuzzleRepository repository;
  final VoidCallback? onBack;

  @override
  State<PadakeliScreen> createState() => _PadakeliScreenState();
}

class _PadakeliScreenState extends State<PadakeliScreen> {
  String? _loadError;
  List<Puzzle>? _puzzles;
  Puzzle? _puzzle;
  late List<List<TextEditingController>> _controllers;
  String? _message;
  String? _selectedLevel;
  PuzzleDirection _selectedDirection = PuzzleDirection.across;
  PuzzleClue? _selectedClue;
  int? _selectedCellIndex;
  final _scrollController = ScrollController();
  Timer? _advanceTimer;
  bool _isAdvancing = false;
  bool _isComplete = false;
  bool? _wasCorrect;

  List<Puzzle> get _levelPuzzles => _puzzles!
      .where((puzzle) => puzzle.level == _selectedLevel)
      .toList(growable: false);

  int get _puzzleNumber => _levelPuzzles.indexOf(_puzzle!) + 1;

  List<PuzzleClue> _cluesFor(Puzzle puzzle, PuzzleDirection direction) =>
      direction == PuzzleDirection.across
      ? puzzle.acrossClues
      : puzzle.downClues;

  List<int> get _selectedCells {
    final puzzle = _puzzle;
    final clue = _selectedClue;
    if (puzzle == null || clue == null) {
      return const [];
    }
    return puzzle.cellsForClue(clue, _selectedDirection);
  }

  @override
  void initState() {
    super.initState();
    _loadPuzzles();
  }

  Future<void> _loadPuzzles() async {
    setState(() => _loadError = null);
    try {
      final puzzles = await widget.repository.getPuzzles();
      if (puzzles.isEmpty) {
        throw const FormatException('No puzzles are available.');
      }
      for (final puzzle in puzzles) {
        puzzle.validate();
      }
      if (!mounted) return;
      setState(() => _puzzles = puzzles);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _loadError = 'పదకేళిని లోడ్ చేయలేకపోయాము. మళ్ళీ ప్రయత్నించండి.',
      );
    }
  }

  void _loadPuzzle(String level) {
    final puzzles = _puzzles;
    if (puzzles == null) {
      return;
    }
    final puzzle = puzzles.where((puzzle) => puzzle.level == level).firstOrNull;
    if (puzzle == null) return;
    _openPuzzle(puzzle);
  }

  void _openPuzzle(Puzzle puzzle) {
    _advanceTimer?.cancel();
    if (_puzzle != null) {
      _disposeControllers();
    }
    _controllers = List.generate(
      puzzle.gridSize,
      (_) => List.generate(puzzle.gridSize, (_) => TextEditingController()),
    );
    setState(() {
      _puzzle = puzzle;
      _selectedLevel = puzzle.level;
      _message = null;
      _wasCorrect = null;
      _isAdvancing = false;
      _isComplete = false;
      _selectedDirection = PuzzleDirection.across;
      _selectedClue = puzzle.acrossClues.firstOrNull;
      _selectedCellIndex = _selectedClue == null
          ? null
          : _selectedClue!.row * puzzle.gridSize + _selectedClue!.column;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _disposeControllers() {
    for (final row in _controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
  }

  void _showDifficulties() {
    _advanceTimer?.cancel();
    if (_puzzle != null) {
      _disposeControllers();
    }
    setState(() {
      _puzzle = null;
      _selectedLevel = null;
      _selectedClue = null;
      _selectedCellIndex = null;
      _message = null;
      _wasCorrect = null;
      _isAdvancing = false;
      _isComplete = false;
    });
  }

  void _selectClue(PuzzleClue clue, PuzzleDirection direction) {
    final puzzle = _puzzle;
    if (puzzle == null || _isAdvancing || _isComplete) {
      return;
    }
    setState(() {
      _selectedDirection = direction;
      _selectedClue = clue;
      _selectedCellIndex = clue.row * puzzle.gridSize + clue.column;
      _message = null;
    });
  }

  void _changeDirection(PuzzleDirection direction) {
    final puzzle = _puzzle;
    if (puzzle == null || _isAdvancing || _isComplete) {
      return;
    }
    final clues = _cluesFor(puzzle, direction);
    final currentIndex = _selectedCellIndex;
    PuzzleClue? matchingClue;
    if (currentIndex != null) {
      for (final clue in clues) {
        if (puzzle.cellsForClue(clue, direction).contains(currentIndex)) {
          matchingClue = clue;
          break;
        }
      }
    }
    final clue = matchingClue ?? (clues.isEmpty ? null : clues.first);
    setState(() {
      _selectedDirection = direction;
      _selectedClue = clue;
      _selectedCellIndex = clue == null
          ? null
          : matchingClue != null
          ? currentIndex
          : clue.row * puzzle.gridSize + clue.column;
      _message = null;
    });
  }

  void _selectCell(int index) {
    final puzzle = _puzzle;
    if (puzzle == null || _isAdvancing || _isComplete) {
      return;
    }
    if (_selectedCells.contains(index)) {
      setState(() {
        _selectedCellIndex = index;
        _message = null;
      });
      return;
    }

    final directions = [
      _selectedDirection,
      _selectedDirection == PuzzleDirection.across
          ? PuzzleDirection.down
          : PuzzleDirection.across,
    ];
    for (final direction in directions) {
      for (final clue in _cluesFor(puzzle, direction)) {
        if (puzzle.cellsForClue(clue, direction).contains(index)) {
          setState(() {
            _selectedDirection = direction;
            _selectedClue = clue;
            _selectedCellIndex = index;
            _message = null;
          });
          return;
        }
      }
    }
    setState(() {
      _selectedCellIndex = index;
      _selectedClue = null;
      _message = null;
    });
  }

  void _enterAkshara(String akshara) {
    final puzzle = _puzzle;
    final selectedIndex = _selectedCellIndex;
    if (puzzle == null ||
        selectedIndex == null ||
        _isAdvancing ||
        _isComplete) {
      return;
    }
    final row = selectedIndex ~/ puzzle.gridSize;
    final column = selectedIndex % puzzle.gridSize;
    final path = _selectedCells;
    final pathPosition = path.indexOf(selectedIndex);
    setState(() {
      _controllers[row][column].text = akshara;
      _message = null;
      if (pathPosition >= 0 && pathPosition + 1 < path.length) {
        _selectedCellIndex = path[pathPosition + 1];
      }
    });
  }

  void _revealFirstAkshara() {
    final puzzle = _puzzle;
    final cells = _selectedCells;
    if (puzzle == null || cells.isEmpty || _isAdvancing || _isComplete) {
      return;
    }
    final index = cells.first;
    final row = index ~/ puzzle.gridSize;
    final column = index % puzzle.gridSize;
    setState(() {
      _controllers[row][column].text = puzzle.answerAt(row, column);
      _selectedCellIndex = index;
      _message = null;
    });
  }

  void _revealSelectedAnswer() {
    final puzzle = _puzzle;
    final cells = _selectedCells;
    if (puzzle == null || cells.isEmpty || _isAdvancing || _isComplete) {
      return;
    }
    setState(() {
      for (final index in cells) {
        final row = index ~/ puzzle.gridSize;
        final column = index % puzzle.gridSize;
        _controllers[row][column].text = puzzle.answerAt(row, column);
      }
      _selectedCellIndex = cells.last;
      _message = 'ఎంచుకున్న సమాధానం చూపించబడింది.';
      _wasCorrect = null;
    });
  }

  Future<void> _showHints() async {
    final clue = _selectedClue;
    final puzzle = _puzzle;
    if (clue == null || _isAdvancing || _isComplete) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: (sheetContext) => ClassicHintsSheet(
        clue: clue,
        onRevealFirst: () {
          Navigator.of(sheetContext).pop();
          if (mounted && identical(puzzle, _puzzle)) _revealFirstAkshara();
        },
        onRevealAnswer: () {
          Navigator.of(sheetContext).pop();
          if (mounted && identical(puzzle, _puzzle)) _revealSelectedAnswer();
        },
      ),
    );
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _scrollController.dispose();
    if (_puzzle != null) {
      for (final row in _controllers) {
        for (final controller in row) {
          controller.dispose();
        }
      }
    }
    super.dispose();
  }

  void _checkAnswer() {
    final puzzle = _puzzle;
    if (puzzle == null || _isAdvancing || _isComplete) {
      return;
    }

    var isCorrect = true;
    for (var row = 0; row < puzzle.gridSize; row++) {
      for (var column = 0; column < puzzle.gridSize; column++) {
        if (puzzle.isBlocked(row, column)) {
          continue;
        }
        if (_controllers[row][column].text.trim() !=
            puzzle.answerAt(row, column)) {
          isCorrect = false;
        }
      }
    }

    setState(() {
      _wasCorrect = isCorrect;
      _isAdvancing = isCorrect;
      _message = isCorrect
          ? 'అద్భుతం! సమాధానం సరైనది.'
          : 'ఇంకొంచెం ప్రయత్నించండి.';
    });
    if (isCorrect) {
      _advanceTimer = Timer(const Duration(milliseconds: 1100), () {
        if (!mounted || !identical(puzzle, _puzzle) || !_isAdvancing) return;
        final nextIndex = _puzzleNumber;
        if (nextIndex < _levelPuzzles.length) {
          _openPuzzle(_levelPuzzles[nextIndex]);
        } else {
          setState(() {
            _isComplete = true;
            _isAdvancing = false;
          });
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _reset() {
    final puzzle = _puzzle;
    if (puzzle == null) {
      return;
    }
    _advanceTimer?.cancel();
    for (var row = 0; row < puzzle.gridSize; row++) {
      for (var column = 0; column < puzzle.gridSize; column++) {
        _controllers[row][column].clear();
      }
    }
    setState(() {
      _message = null;
      _wasCorrect = null;
      _isAdvancing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    if (_loadError != null) {
      return AppPage(
        title: 'Classic Padakeli',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, key: const ValueKey('puzzle-load-error')),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('retry-puzzles'),
              onPressed: _loadPuzzles,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('మళ్ళీ ప్రయత్నించండి (Retry)'),
            ),
          ],
        ),
      );
    }
    if (_puzzles == null) {
      return AppPage(
        title: 'Classic Padakeli',
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_selectedLevel == null) {
      return DifficultySelection(
        onBack: widget.onBack,
        onSelect: _loadPuzzle,
        availableLevels: _puzzles!.map((puzzle) => puzzle.level).toSet(),
      );
    }
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final titleStyle = theme.textTheme.titleMedium!;
    final titleSize = MediaQuery.textScalerOf(
      context,
    ).scale(titleStyle.fontSize!);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: (titleSize * 1.8 + 16).clamp(64, double.infinity),
        leading: IconButton(
          tooltip: 'Change difficulty',
          onPressed: _showDifficulties,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'పదకేళి · $_puzzleNumber / ${_levelPuzzles.length}',
          key: const ValueKey('classic-puzzle-progress'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle.copyWith(
            fontFamily: PremiumTeluguText.fontFamily,
            height: PremiumTeluguText.lineHeight,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Hints',
            onPressed: _selectedClue == null || _isAdvancing || _isComplete
                ? null
                : _showHints,
            icon: const Icon(Icons.lightbulb_rounded, color: AppColors.gold),
          ),
        ],
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [AppColors.darkBackground, theme.colorScheme.surface]
                : [
                    const Color(0xFFE1EDFF),
                    const Color(0xFFEFE5FF),
                    AppColors.lightBlue,
                  ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            controller: _scrollController,
            key: const ValueKey('classic-game-scroll'),
            padding: const EdgeInsets.all(12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _isComplete
                    ? _completion()
                    : puzzle == null
                    ? const CircularProgressIndicator()
                    : _gameContent(puzzle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameContent(Puzzle puzzle) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final feedbackForeground = _wasCorrect == true
        ? scheme.onTertiaryContainer
        : _wasCorrect == false
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Column(
      key: ValueKey('classic-puzzle-${puzzle.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepBlue.withValues(alpha: 0.15),
                    offset: const Offset(0, 5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: CrosswordGrid(
                puzzle: puzzle,
                controllers: _controllers,
                selectedCellIndex: _selectedCellIndex,
                selectedCells: _selectedCells,
                onCellSelected: _selectCell,
                enabled: !_isAdvancing,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final (direction, label) in [
              (PuzzleDirection.across, 'అడ్డం (Across)'),
              (PuzzleDirection.down, 'నిలువు (Down)'),
            ])
              ChoiceChip(
                label: PremiumTeluguText(
                  label,
                  style: theme.textTheme.labelLarge,
                ),
                selected: _selectedDirection == direction,
                selectedColor: theme.colorScheme.secondaryContainer,
                onSelected: _isAdvancing
                    ? null
                    : (_) => _changeDirection(direction),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _ClueList(
          clues: _cluesFor(puzzle, _selectedDirection),
          direction: _selectedDirection,
          selectedClue: _selectedClue,
          selectedDirection: _selectedDirection,
          onSelect: _selectClue,
          enabled: !_isAdvancing,
        ),
        const SizedBox(height: 8),
        AksharaPalette(
          puzzle: puzzle,
          onSelected: _enterAkshara,
          enabled: !_isAdvancing,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              key: const ValueKey('open-hints'),
              onPressed: _selectedClue == null || _isAdvancing
                  ? null
                  : _showHints,
              style: _actionStyle(AppColors.gold, AppColors.ink),
              icon: const Icon(Icons.lightbulb_rounded),
              label: const Text('Hints'),
            ),
            FilledButton.icon(
              key: const ValueKey('classic-check'),
              onPressed: _isAdvancing ? null : _checkAnswer,
              style: _actionStyle(const Color(0xFF087F42), Colors.white),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Check Answer'),
            ),
            FilledButton.icon(
              onPressed: _reset,
              style: _actionStyle(const Color(0xFFFFCEBE), AppColors.ink),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset'),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _wasCorrect == true
                  ? scheme.tertiaryContainer
                  : _wasCorrect == false
                  ? scheme.errorContainer
                  : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Semantics(
              liveRegion: true,
              child: Column(
                children: [
                  PremiumTeluguText(
                    _message!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: feedbackForeground,
                    ),
                  ),
                  if (_isAdvancing)
                    PremiumTeluguText(
                      _puzzleNumber < _levelPuzzles.length
                          ? 'తదుపరి పదకేళి తెరుచుకుంటోంది...'
                          : 'స్థాయి పూర్తవుతోంది...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: feedbackForeground,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  ButtonStyle _actionStyle(Color background, Color foreground) =>
      FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  Widget _completion() {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('classic-level-complete'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.verified_rounded, size: 72, color: AppColors.teal),
            const SizedBox(height: 16),
            PremiumTeluguText(
              'స్థాయి పూర్తయింది!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            PremiumTeluguText(
              '${_levelPuzzles.length} / ${_levelPuzzles.length} పదకేళీలు పూర్తి చేశారు.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('classic-replay'),
              onPressed: () => _loadPuzzle(_selectedLevel!),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('మళ్లీ ఆడండి'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _showDifficulties,
              child: const Text('స్థాయిని ఎంచుకోండి'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClueList extends StatelessWidget {
  const _ClueList({
    required this.clues,
    required this.direction,
    required this.selectedClue,
    required this.selectedDirection,
    required this.onSelect,
    required this.enabled,
  });

  final List<PuzzleClue> clues;
  final PuzzleDirection direction;
  final PuzzleClue? selectedClue;
  final PuzzleDirection selectedDirection;
  final void Function(PuzzleClue clue, PuzzleDirection direction) onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final clue in clues)
              ListTile(
                key: ValueKey('clue-${direction.name}-${clue.number}'),
                minTileHeight: 48,
                minVerticalPadding: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withValues(alpha: 0.6),
                enabled: enabled,
                selected:
                    identical(selectedClue, clue) &&
                    selectedDirection == direction,
                title: Text(
                  '${clue.number}. ${clue.clue}',
                  key:
                      identical(selectedClue, clue) &&
                          selectedDirection == direction
                      ? const ValueKey('selected-clue')
                      : null,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: PremiumTeluguText.fontFamily,
                    fontFamilyFallback: const ['Roboto'],
                    height: PremiumTeluguText.lineHeight,
                    leadingDistribution: TextLeadingDistribution.even,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: enabled ? () => onSelect(clue, direction) : null,
              ),
          ],
        ),
      ),
    );
  }
}
