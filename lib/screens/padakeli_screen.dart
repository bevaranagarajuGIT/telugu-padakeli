import 'package:flutter/material.dart';

import '../models/puzzle.dart';
import '../services/local_puzzle_repository.dart';
import '../widgets/app_page.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/section_title.dart';

class PadakeliScreen extends StatefulWidget {
  const PadakeliScreen({super.key});

  @override
  State<PadakeliScreen> createState() => _PadakeliScreenState();
}

class _PadakeliScreenState extends State<PadakeliScreen> {
  final _repository = const LocalPuzzleRepository();
  List<Puzzle>? _puzzles;
  Puzzle? _puzzle;
  late List<List<TextEditingController>> _controllers;
  String? _message;
  String? _selectedLevel;
  PuzzleDirection _selectedDirection = PuzzleDirection.across;
  PuzzleClue? _selectedClue;
  int? _selectedCellIndex;

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
    final puzzles = await _repository.getPuzzles();
    if (!mounted) {
      return;
    }
    setState(() => _puzzles = puzzles);
  }

  void _loadPuzzle(String level) {
    final puzzles = _puzzles;
    if (puzzles == null) {
      return;
    }
    final puzzle = puzzles.firstWhere((puzzle) => puzzle.level == level);
    if (_puzzle != null) {
      _disposeControllers();
    }
    _controllers = List.generate(
      puzzle.gridSize,
      (_) => List.generate(puzzle.gridSize, (_) => TextEditingController()),
    );
    setState(() {
      _puzzle = puzzle;
      _selectedLevel = level;
      _message = null;
      _selectedDirection = PuzzleDirection.across;
      _selectedClue = puzzle.acrossClues.firstOrNull;
      _selectedCellIndex = _selectedClue == null
          ? null
          : _selectedClue!.row * puzzle.gridSize + _selectedClue!.column;
    });
  }

  void _disposeControllers() {
    for (final row in _controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
  }

  void _showDifficulties() {
    if (_puzzle != null) {
      _disposeControllers();
    }
    setState(() {
      _puzzle = null;
      _selectedLevel = null;
      _selectedClue = null;
      _selectedCellIndex = null;
      _message = null;
    });
  }

  void _selectClue(PuzzleClue clue, PuzzleDirection direction) {
    final puzzle = _puzzle;
    if (puzzle == null) {
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
    if (puzzle == null) {
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
    if (puzzle == null) {
      return;
    }
    if (_selectedCells.contains(index)) {
      setState(() => _selectedCellIndex = index);
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
    setState(() => _selectedCellIndex = index);
  }

  void _enterAkshara(String akshara) {
    final puzzle = _puzzle;
    final selectedIndex = _selectedCellIndex;
    if (puzzle == null || selectedIndex == null) {
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
    if (puzzle == null || cells.isEmpty) {
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
    if (puzzle == null || cells.isEmpty) {
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
    });
  }

  Future<void> _showHints() async {
    final clue = _selectedClue;
    if (clue == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'సూచనలు',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline_rounded),
                title: const Text('సులభమైన సూచన'),
                subtitle: Text(clue.hint ?? clue.clue),
              ),
              ListTile(
                key: const ValueKey('hint-reveal-first'),
                leading: const Icon(Icons.looks_one_rounded),
                title: const Text('మొదటి అక్షరం చూపించు'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _revealFirstAkshara();
                },
              ),
              ListTile(
                key: const ValueKey('hint-reveal-answer'),
                leading: const Icon(Icons.visibility_rounded),
                title: const Text('ఎంచుకున్న సమాధానం చూపించు'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _revealSelectedAnswer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
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
    if (puzzle == null) {
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
      _message = isCorrect
          ? 'అద్భుతం! సమాధానం సరైనది.'
          : 'ఇంకొంచెం ప్రయత్నించండి.';
    });
  }

  void _reset() {
    final puzzle = _puzzle;
    if (puzzle == null) {
      return;
    }
    for (var row = 0; row < puzzle.gridSize; row++) {
      for (var column = 0; column < puzzle.gridSize; column++) {
        _controllers[row][column].clear();
      }
    }
    setState(() {
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    if (_puzzles == null) {
      return AppPage(
        title: 'Classic Padakeli',
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_selectedLevel == null) {
      return AppPage(
        title: 'Classic Padakeli',
        child: _DifficultySelection(onSelect: _loadPuzzle),
      );
    }
    return AppPage(
      title: 'పదకేళి',
      actions: [
        IconButton(
          tooltip: 'Change difficulty',
          onPressed: _showDifficulties,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
      child: puzzle == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<PuzzleDirection>(
                  segments: const [
                    ButtonSegment(
                      value: PuzzleDirection.across,
                      label: Text('అడ్డం (Across)'),
                    ),
                    ButtonSegment(
                      value: PuzzleDirection.down,
                      label: Text('నిలువు (Down)'),
                    ),
                  ],
                  selected: {_selectedDirection},
                  onSelectionChanged: (selection) =>
                      _changeDirection(selection.first),
                ),
                if (_selectedClue != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedClue!.number}. ${_selectedClue!.clue}',
                    key: const ValueKey('selected-clue'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                CrosswordGrid(
                  puzzle: puzzle,
                  controllers: _controllers,
                  selectedCellIndex: _selectedCellIndex,
                  selectedCells: _selectedCells,
                  onCellSelected: _selectCell,
                  onAksharaSelected: _enterAkshara,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _checkAnswer,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Check Answer'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reset'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('open-hints'),
                      onPressed: _showHints,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Hints'),
                    ),
                  ],
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                _ClueList(
                  title: 'అడ్డం (Across →)',
                  clues: puzzle.acrossClues,
                  direction: PuzzleDirection.across,
                  selectedClue: _selectedClue,
                  selectedDirection: _selectedDirection,
                  onSelect: _selectClue,
                ),
                const SizedBox(height: 18),
                _ClueList(
                  title: 'నిలువు (Down ↓)',
                  clues: puzzle.downClues,
                  direction: PuzzleDirection.down,
                  selectedClue: _selectedClue,
                  selectedDirection: _selectedDirection,
                  onSelect: _selectClue,
                ),
              ],
            ),
    );
  }
}

class _DifficultySelection extends StatelessWidget {
  const _DifficultySelection({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficulties = [
      ('Beginner', 'ప్రారంభ స్థాయి', 'beginner', true),
      ('Easy', 'సులభ స్థాయి', 'easy', true),
      ('Medium', 'మధ్యస్థ స్థాయి', null, false),
      ('Hard', 'కఠిన స్థాయి', null, false),
      ('Expert', 'నిపుణ స్థాయి', null, false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'స్థాయిని ఎంచుకోండి',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        for (final (name, title, level, isAvailable) in difficulties)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              key: ValueKey('difficulty-$name'),
              leading: Icon(
                isAvailable
                    ? Icons.play_circle_fill_rounded
                    : Icons.lock_outline_rounded,
              ),
              title: Text(name),
              subtitle: Text(title),
              trailing: isAvailable
                  ? const Icon(Icons.chevron_right_rounded)
                  : const Text('Coming Soon'),
              enabled: isAvailable,
              onTap: isAvailable ? () => onSelect(level!) : null,
            ),
          ),
      ],
    );
  }
}

class _ClueList extends StatelessWidget {
  const _ClueList({
    required this.title,
    required this.clues,
    required this.direction,
    required this.selectedClue,
    required this.selectedDirection,
    required this.onSelect,
  });

  final String title;
  final List<PuzzleClue> clues;
  final PuzzleDirection direction;
  final PuzzleClue? selectedClue;
  final PuzzleDirection selectedDirection;
  final void Function(PuzzleClue clue, PuzzleDirection direction) onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title),
            for (final clue in clues)
              ListTile(
                key: ValueKey('clue-${direction.name}-${clue.number}'),
                dense: true,
                selected:
                    identical(selectedClue, clue) &&
                    selectedDirection == direction,
                title: Text('${clue.number}. ${clue.clue}'),
                onTap: () => onSelect(clue, direction),
              ),
          ],
        ),
      ),
    );
  }
}
