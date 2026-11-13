import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_colors.dart';
import '../core/learning_progress.dart';
import '../models/puzzle.dart';
import '../models/telugu_akshara.dart';
import '../services/local_puzzle_repository.dart';
import '../services/puzzle_repository.dart';
import '../services/daily_puzzle_service.dart';
import '../widgets/app_page.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/classic_hints_sheet.dart';
import '../widgets/difficulty_selection.dart';
import '../widgets/engagement_motion.dart';
import '../widgets/kids_learning_text.dart';
import '../widgets/premium_telugu_text.dart';

class PadakeliScreen extends StatefulWidget {
  const PadakeliScreen({
    this.repository = const LocalPuzzleRepository(),
    this.onBack,
    this.dailyDate,
    super.key,
  });

  final PuzzleRepository repository;
  final VoidCallback? onBack;
  final String? dailyDate;

  @override
  State<PadakeliScreen> createState() => _PadakeliScreenState();
}

class _PadakeliScreenState extends State<PadakeliScreen>
    with WidgetsBindingObserver {
  LearningProgress? _storage;
  Timer? _calendarTimer;
  String get _slot =>
      widget.dailyDate == null ? 'classic' : 'daily:${widget.dailyDate}';
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
  bool _isComplete = false;
  bool _completionDialogOpen = false;
  final _incorrectCells = <int>{};
  int _hintCount = 0;
  bool _resetDialogOpen = false;
  bool _reviewOpen = false;

  bool _isCorrectCell(int index) {
    final puzzle = _puzzle!;
    return TeluguAkshara.equivalent(
      _controllers[index ~/ puzzle.gridSize][index % puzzle.gridSize].text,
      puzzle.answerAt(index ~/ puzzle.gridSize, index % puzzle.gridSize),
    );
  }

  List<int> get _unsolvedSelectedCells =>
      _selectedCells.where((index) => !_isCorrectCell(index)).toList();

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
    _storage = context.read<LearningProgress?>();
    WidgetsBinding.instance.addObserver(this);
    if (widget.dailyDate != null) {
      _calendarTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    _loadPuzzles();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _persist();
    if (state != AppLifecycleState.resumed) {
      unawaited(_storage?.flush());
    } else if (mounted && widget.dailyDate != null) {
      setState(() {});
    }
  }

  void _persist() {
    final puzzle = _puzzle;
    if (puzzle == null || _storage == null) return;
    final snapshot = <String, dynamic>{
      'id': puzzle.id,
      'signature': puzzle.progressSignature,
      'cells': [
        for (final row in _controllers)
          for (final controller in row) controller.text,
      ],
      'direction': _selectedDirection.name,
      'clue': _selectedClue?.number,
      'cell': _selectedCellIndex,
      'hints': _hintCount,
      'complete': _isComplete,
    };
    _storage!.saveBoard(
      _slot,
      snapshot,
      active: TickerMode.valuesOf(context).enabled,
    );
    if (widget.dailyDate == null) {
      _storage!.saveBoard('classic:${puzzle.level}', snapshot, active: false);
    }
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
      final saved = _storage?.board(_slot) ?? <String, dynamic>{};
      if (widget.dailyDate != null && _storage != null) {
        _openPuzzle(
          const DailyPuzzleService().choose(
            puzzles,
            widget.dailyDate!,
            _storage!,
          ),
          saved: saved,
        );
      } else {
        final previous = puzzles
            .where((puzzle) => puzzle.id == saved['id'])
            .firstOrNull;
        if (previous != null) _openPuzzle(previous, saved: saved);
      }
    } catch (error, stack) {
      debugPrint('Local crossword loading failed: $error\n$stack');
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
    final saved = _storage?.board('classic:$level') ?? <String, dynamic>{};
    final current = _storage?.board(_slot) ?? <String, dynamic>{};
    final resume = saved.isNotEmpty ? saved : current;
    final previous = puzzles
        .where((item) => item.level == level && item.id == resume['id'])
        .firstOrNull;
    _openPuzzle(previous ?? puzzle, saved: previous != null ? resume : saved);
  }

  void _openPuzzle(Puzzle puzzle, {Map<String, dynamic> saved = const {}}) {
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
      _isComplete = false;
      _completionDialogOpen = false;
      _incorrectCells.clear();
      _hintCount = 0;
      _selectedDirection = PuzzleDirection.across;
      _selectedClue =
          puzzle.acrossClues.firstOrNull ?? puzzle.downClues.firstOrNull;
      if (puzzle.acrossClues.isEmpty) _selectedDirection = PuzzleDirection.down;
      _selectedCellIndex = _selectedClue == null
          ? null
          : _selectedClue!.row * puzzle.gridSize + _selectedClue!.column;
      if (saved.isNotEmpty && saved['signature'] != puzzle.progressSignature) {
        _message =
            'Saved content changed. This board starts fresh; other progress is kept.';
      } else if (saved.isNotEmpty) {
        final cells = saved['cells'];
        if (cells is List &&
            cells.length == puzzle.gridSize * puzzle.gridSize) {
          for (var index = 0; index < cells.length; index++) {
            final value = cells[index];
            if (value is String &&
                value.isNotEmpty &&
                !puzzle.isBlocked(
                  index ~/ puzzle.gridSize,
                  index % puzzle.gridSize,
                )) {
              try {
                if (TeluguAkshara.split(value).length == 1) {
                  _controllers[index ~/ puzzle.gridSize][index %
                              puzzle.gridSize]
                          .text =
                      value;
                }
              } on FormatException {
                _message =
                    'An unreadable saved cell was cleared. Other answers are kept.';
              }
            }
          }
        }
        _selectedDirection = saved['direction'] == 'down'
            ? PuzzleDirection.down
            : PuzzleDirection.across;
        _selectedClue =
            _cluesFor(
              puzzle,
              _selectedDirection,
            ).where((clue) => clue.number == saved['clue']).firstOrNull ??
            _cluesFor(puzzle, _selectedDirection).firstOrNull;
        final cell = saved['cell'];
        if (cell is int &&
            cell >= 0 &&
            cell < puzzle.gridSize * puzzle.gridSize &&
            !puzzle.isBlocked(
              cell ~/ puzzle.gridSize,
              cell % puzzle.gridSize,
            )) {
          _selectedCellIndex = cell;
        }
        final hints = saved['hints'];
        _hintCount = hints is int && hints >= 0 ? hints : 0;
        _isComplete =
            saved['complete'] == true &&
            List.generate(puzzle.gridSize * puzzle.gridSize, (index) => index)
                .where(
                  (index) => !puzzle.isBlocked(
                    index ~/ puzzle.gridSize,
                    index % puzzle.gridSize,
                  ),
                )
                .every(_isCorrectCell);
      }
    });
    for (final row in _controllers) {
      for (final controller in row) {
        controller.addListener(_persist);
      }
    }
    if (!_isComplete) _validateCompletedWords();
    _persist();
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
    if (_puzzle != null) {
      _disposeControllers();
    }
    setState(() {
      _puzzle = null;
      _selectedLevel = null;
      _selectedClue = null;
      _selectedCellIndex = null;
      _message = null;
      _isComplete = false;
    });
  }

  void _selectClue(PuzzleClue clue, PuzzleDirection direction) {
    final puzzle = _puzzle;
    if (puzzle == null || _isComplete) {
      return;
    }
    setState(() {
      _selectedDirection = direction;
      _selectedClue = clue;
      _selectedCellIndex = _firstUnsolvedCell(clue, direction);
      _message = null;
    });
    _persist();
  }

  int? _firstUnsolvedCell(PuzzleClue clue, PuzzleDirection direction) {
    final cells = _puzzle!.cellsForClue(clue, direction);
    return cells.where((index) => !_isCorrectCell(index)).firstOrNull ??
        cells.firstOrNull;
  }

  void _changeDirection(
    PuzzleDirection direction, {
    bool preserveSelectedCell = false,
  }) {
    final puzzle = _puzzle;
    if (puzzle == null || _isComplete) {
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
    final clue =
        matchingClue ??
        clues
            .where(
              (clue) => puzzle
                  .cellsForClue(clue, direction)
                  .any((index) => !_isCorrectCell(index)),
            )
            .firstOrNull ??
        clues.firstOrNull;
    setState(() {
      _selectedDirection = direction;
      _selectedClue = clue;
      _selectedCellIndex = clue == null
          ? null
          : matchingClue != null &&
                currentIndex != null &&
                (preserveSelectedCell || !_isCorrectCell(currentIndex))
          ? currentIndex
          : _firstUnsolvedCell(clue, direction);
      _message = null;
    });
    _persist();
  }

  void _selectCell(int index) {
    final puzzle = _puzzle;
    if (puzzle == null || _isComplete) {
      return;
    }
    if (_selectedCells.contains(index)) {
      if (_selectedCellIndex == index) {
        final other = _selectedDirection == PuzzleDirection.across
            ? PuzzleDirection.down
            : PuzzleDirection.across;
        if (_cluesFor(
          puzzle,
          other,
        ).any((clue) => puzzle.cellsForClue(clue, other).contains(index))) {
          _changeDirection(other, preserveSelectedCell: true);
          return;
        }
      }
      setState(() {
        _selectedCellIndex = index;
        _message = null;
      });
      _persist();
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
          _persist();
          return;
        }
      }
    }
    setState(() {
      _selectedCellIndex = index;
      _selectedClue = null;
      _message = null;
    });
    _persist();
  }

  void _enterAkshara(String akshara) {
    final puzzle = _puzzle;
    final selectedIndex = _selectedCellIndex;
    if (puzzle == null || selectedIndex == null || _isComplete) {
      return;
    }
    final row = selectedIndex ~/ puzzle.gridSize;
    final column = selectedIndex % puzzle.gridSize;
    final path = _selectedCells;
    final pathPosition = path.indexOf(selectedIndex);
    setState(() {
      _controllers[row][column].text = akshara;
      _incorrectCells.remove(selectedIndex);
      _message = null;
      if (pathPosition >= 0 && pathPosition + 1 < path.length) {
        _selectedCellIndex =
            path
                .skip(pathPosition + 1)
                .where((index) => !_isCorrectCell(index))
                .firstOrNull ??
            selectedIndex;
      }
    });
    _validateCompletedWords();
    _persist();
  }

  void _revealFirstAkshara() {
    final puzzle = _puzzle;
    final cells = _selectedCells;
    if (puzzle == null || cells.isEmpty || _isComplete) {
      return;
    }
    final unsolved = _unsolvedSelectedCells;
    if (unsolved.isEmpty) return;
    _revealCell(unsolved.first);
  }

  void _revealCell(int index) {
    final puzzle = _puzzle!;
    final row = index ~/ puzzle.gridSize;
    final column = index % puzzle.gridSize;
    setState(() {
      _controllers[row][column].text = puzzle.answerAt(row, column);
      _selectedCellIndex = index;
      _incorrectCells.remove(index);
      _hintCount++;
      _message = 'ఒక అక్షరం చూపించబడింది.';
    });
    _validateCompletedWords();
    _persist();
  }

  void _revealOneAkshara() {
    final puzzle = _puzzle;
    final cells = _selectedCells;
    if (puzzle == null || cells.isEmpty || _isComplete) {
      return;
    }
    final unsolved = _unsolvedSelectedCells;
    if (unsolved.isEmpty) return;
    _revealCell(
      unsolved.contains(_selectedCellIndex)
          ? _selectedCellIndex!
          : unsolved.first,
    );
  }

  Future<void> _showHints() async {
    final clue = _selectedClue;
    final puzzle = _puzzle;
    if (clue == null || _isComplete) {
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
        onRevealFirst: _unsolvedSelectedCells.isEmpty
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                if (mounted && identical(puzzle, _puzzle)) {
                  _revealFirstAkshara();
                }
              },
        onRevealCell: _unsolvedSelectedCells.isEmpty
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                if (mounted && identical(puzzle, _puzzle)) _revealOneAkshara();
              },
        onShowSimple: clue.hint == null || clue.hint!.trim().isEmpty
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                if (!mounted || !identical(puzzle, _puzzle)) return;
                setState(() {
                  _hintCount++;
                  _message = clue.hint;
                });
                _persist();
              },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _calendarTimer?.cancel();
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

  void _validateCompletedWords() {
    final puzzle = _puzzle;
    if (puzzle == null || _isComplete) return;
    _incorrectCells.clear();
    for (final direction in PuzzleDirection.values) {
      for (final clue in _cluesFor(puzzle, direction)) {
        final cells = puzzle.cellsForClue(clue, direction);
        if (cells.every(
          (index) =>
              _controllers[index ~/ puzzle.gridSize][index % puzzle.gridSize]
                  .text
                  .isNotEmpty,
        )) {
          _incorrectCells.addAll(
            cells.where((index) => !_isCorrectCell(index)),
          );
        }
      }
    }
    final isCorrect = [
      for (var index = 0; index < puzzle.gridSize * puzzle.gridSize; index++)
        if (!puzzle.isBlocked(
          index ~/ puzzle.gridSize,
          index % puzzle.gridSize,
        ))
          index,
    ].every(_isCorrectCell);
    if (isCorrect && !_resetDialogOpen) {
      setState(() {
        _isComplete = true;
        _message = null;
        _completionDialogOpen = true;
      });
      _storage?.completePuzzle('${puzzle.id}', dailyDate: widget.dailyDate);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(puzzle, _puzzle) && _isComplete) {
          if (TickerMode.valuesOf(context).enabled) {
            unawaited(_showCompletion(puzzle));
          } else {
            setState(() => _completionDialogOpen = false);
          }
        }
      });
    }
  }

  Future<void> _showCompletion(Puzzle puzzle) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        constraints: const BoxConstraints(maxWidth: 420),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: SingleChildScrollView(
          child: _completion(dialogContext: dialogContext),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _completionDialogOpen = false);
    if (identical(puzzle, _puzzle) && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _clearCell({bool backspace = false}) {
    if (_isComplete || _selectedCellIndex == null) return;
    final puzzle = _puzzle!;
    var index = _selectedCellIndex!;
    final path = _selectedCells;
    final position = path.indexOf(index);
    if (backspace &&
        _controllers[index ~/ puzzle.gridSize][index % puzzle.gridSize]
            .text
            .isEmpty &&
        position > 0) {
      index = path[position - 1];
    }
    setState(() {
      _controllers[index ~/ puzzle.gridSize][index % puzzle.gridSize].clear();
      _selectedCellIndex = index;
      _incorrectCells.remove(index);
      _message = null;
    });
    _validateCompletedWords();
    _persist();
  }

  void _resetWord() {
    if (_isComplete || _selectedCells.isEmpty) return;
    final puzzle = _puzzle!;
    setState(() {
      for (final index in _selectedCells) {
        _controllers[index ~/ puzzle.gridSize][index % puzzle.gridSize].clear();
        _incorrectCells.remove(index);
      }
      _selectedCellIndex = _selectedCells.first;
      _message = null;
    });
    _validateCompletedWords();
    _persist();
  }

  Future<void> _confirmReset() async {
    if (_resetDialogOpen) return;
    final puzzle = _puzzle;
    _resetDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.restart_alt_rounded,
                color: AppColors.ink,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'మళ్లీ ఆడాలా?\nRestart this puzzle?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'మీ సమాధానాలు, వాడిన సూచనల లెక్క తీసివేయబడతాయి.\n\n'
              'Your answers and hint count will be cleared.',
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              key: const ValueKey('classic-reset-cancel'),
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 56),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _controlLabel('వద్దు', 'Cancel'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('classic-reset-confirm'),
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 56),
                padding: const EdgeInsets.all(12),
                elevation: 2,
                shadowColor: AppColors.ink.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.restart_alt_rounded),
              label: _controlLabel('మళ్లీ ఆడు', 'Restart'),
            ),
          ],
        ),
      ),
    );
    _resetDialogOpen = false;
    if (!mounted || !identical(puzzle, _puzzle)) return;
    if (confirmed == true) {
      _reset();
    }
  }

  Future<void> _showActions() async {
    final puzzle = _puzzle;
    var chosen = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: (sheetContext) {
        void choose(VoidCallback action) {
          if (chosen || !mounted || !identical(puzzle, _puzzle)) return;
          chosen = true;
          Navigator.pop(sheetContext);
          action();
        }

        return SingleChildScrollView(
          key: const ValueKey('classic-actions-sheet'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _controlLabel('పదకేళి చర్యలు', 'Puzzle actions'),
                  ),
                  IconButton(
                    tooltip: 'Close actions',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final (key, telugu, english, icon, color, foreground, action)
                  in [
                    (
                      'classic-reset-word',
                      'పదం తీసేయి',
                      'Clear word',
                      Icons.clear_all_rounded,
                      AppColors.gold,
                      AppColors.ink,
                      !_isComplete && _selectedCells.isNotEmpty
                          ? _resetWord
                          : null,
                    ),
                    (
                      'classic-reset',
                      'మళ్లీ ఆడు',
                      'Restart',
                      Icons.restart_alt_rounded,
                      AppColors.purple,
                      Colors.white,
                      () => unawaited(_confirmReset()),
                    ),
                  ]) ...[
                FilledButton.icon(
                  key: ValueKey(key),
                  onPressed: action == null ? null : () => choose(action),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: foreground,
                    minimumSize: const Size(48, 56),
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(icon),
                  label: _controlLabel(telugu, english),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _headerActions(
    double buttonWidth,
    double height,
    TextStyle labelStyle,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (key, label, tooltip, icon, background, foreground, action)
            in [
              (
                'open-hints',
                'సహాయం\nHints',
                'Hints',
                Icons.lightbulb_rounded,
                AppColors.gold,
                AppColors.ink,
                _selectedClue == null || _isComplete ? null : _showHints,
              ),
              (
                'classic-more',
                'చర్యలు\nActions',
                'మరిన్ని / More options',
                Icons.tune_rounded,
                AppColors.purple,
                Colors.white,
                _showActions,
              ),
            ]) ...[
          SizedBox(
            width: buttonWidth,
            height: height,
            child: Tooltip(
              message: tooltip,
              child: FilledButton(
                key: ValueKey(key),
                onPressed: action,
                style: FilledButton.styleFrom(
                  backgroundColor: background,
                  foregroundColor: foreground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(child: Icon(icon, size: 18)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: labelStyle.copyWith(
                          color: action == null
                              ? Theme.of(context).colorScheme.onSurface
                              : foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
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
      _isComplete = false;
      _incorrectCells.clear();
      _hintCount = 0;
      _selectedCellIndex = _selectedCells.firstOrNull;
    });
    _persist();
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
    final labelStyle = theme.textTheme.labelMedium!.copyWith(
      fontFamily: PremiumTeluguText.fontFamily,
      height: PremiumTeluguText.lineHeight,
      fontWeight: FontWeight.w700,
    );
    final width = MediaQuery.sizeOf(context).width;
    final separateActions =
        width < 380 ||
        MediaQuery.textScalerOf(context).scale(labelStyle.fontSize!) > 14.5;
    final buttonWidth = separateActions ? (width.clamp(0, 720) - 40) / 2 : 88.0;
    var actionsHeight = 48.0;
    for (final label in ['సహాయం\nHints', 'చర్యలు\nActions']) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: buttonWidth - 38);
      if (painter.height + 12 > actionsHeight) {
        actionsHeight = painter.height + 12;
      }
      painter.dispose();
    }
    final scrollActions =
        separateActions &&
        titleSize * 1.8 + 24 + actionsHeight >
            MediaQuery.sizeOf(context).height * 0.6;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: (titleSize * 1.8 + 16).clamp(
          separateActions ? 64 : (actionsHeight + 8).clamp(64, double.infinity),
          double.infinity,
        ),
        titleSpacing: 8,
        leadingWidth: 48,
        leading: IconButton(
          tooltip: widget.dailyDate == null
              ? 'Change difficulty'
              : 'Back to Home',
          onPressed: widget.dailyDate == null
              ? _showDifficulties
              : () => Navigator.maybePop(context),
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
        actions: separateActions
            ? null
            : [_headerActions(buttonWidth, actionsHeight, labelStyle)],
        bottom: !separateActions || scrollActions
            ? null
            : PreferredSize(
                preferredSize: Size.fromHeight(actionsHeight + 8),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4, bottom: 8),
                  child: _headerActions(buttonWidth, actionsHeight, labelStyle),
                ),
              ),
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
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              controller: _scrollController,
              key: const ValueKey('classic-game-scroll'),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _isComplete ? 720 : 1100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (scrollActions) ...[
                        _headerActions(buttonWidth, actionsHeight, labelStyle),
                        const SizedBox(height: 8),
                      ],
                      if (widget.dailyDate != null) ...[
                        Text(
                          'నేటి పదకేళి / Daily · ${widget.dailyDate}\n'
                          '${_storage?.daily(widget.dailyDate!)['repeat'] == true ? 'Practice repeat · ' : ''}'
                          'Rotating ${_puzzles!.length}-puzzle offline pack; repeats are possible.',
                          key: const ValueKey('daily-puzzle-label'),
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (_storage?.today != widget.dailyDate)
                          const Text(
                            'This is a saved past date. Return Home for today’s puzzle; your answers are kept.',
                          ),
                        const SizedBox(height: 12),
                      ],
                      _isComplete && !_completionDialogOpen
                          ? _completion()
                          : puzzle == null
                          ? const CircularProgressIndicator()
                          : _gameContent(puzzle, viewport),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameContent(Puzzle puzzle, BoxConstraints viewport) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filled = _controllers
        .expand((row) => row)
        .where((controller) => controller.text.isNotEmpty)
        .length;
    final total = puzzle.rows
        .expand((row) => row)
        .where((cell) => cell != '#')
        .length;
    final percentage = (filled * 100 / total).round();
    final correctClues = <PuzzleClue>{};
    final correctCells = <int>{};
    for (final direction in PuzzleDirection.values) {
      for (final clue in _cluesFor(puzzle, direction)) {
        final cells = puzzle.cellsForClue(clue, direction);
        if (cells.every(_isCorrectCell)) {
          correctClues.add(clue);
          correctCells.addAll(cells);
        }
      }
    }
    final occupiedColumns = [
      for (var column = 0; column < puzzle.gridSize; column++)
        if (puzzle.rows.any((row) => row[column] != '#')) column,
    ];
    final visibleColumns = occupiedColumns.last - occupiedColumns.first + 1;
    final occupiedRows = [
      for (var row = 0; row < puzzle.gridSize; row++)
        if (puzzle.rows[row].any((cell) => cell != '#')) row,
    ];
    final visibleRows = occupiedRows.last - occupiedRows.first + 1;
    final split =
        viewport.maxWidth - 24 >= 700 &&
        MediaQuery.textScalerOf(
              context,
            ).scale(theme.textTheme.bodyMedium!.fontSize!) <=
            24;
    final minimumCellExtent = CrosswordGrid.minimumCellExtent(context);
    final maximumCellExtent = split
        ? ((viewport.maxHeight - 52) / visibleRows).clamp(
            minimumCellExtent,
            minimumCellExtent > 72 ? minimumCellExtent : 72.0,
          )
        : 72.0;
    final board = Column(
      key: const ValueKey('classic-board-pane'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            'నింపిన గడులు: $percentage% · సూచనలు: $_hintCount',
            key: const ValueKey('classic-filled-progress'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: visibleColumns * maximumCellExtent + 12,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
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
                maximumCellExtent: maximumCellExtent,
                puzzle: puzzle,
                controllers: _controllers,
                selectedCellIndex: _selectedCellIndex,
                selectedCells: _selectedCells,
                incorrectCells: _incorrectCells,
                correctCells: correctCells,
                onCellSelected: _selectCell,
                enabled: !_isComplete,
              ),
            ),
          ),
        ),
      ],
    );
    final controls = Column(
      key: const ValueKey('classic-controls-pane'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final (direction, label, color) in [
              (
                PuzzleDirection.across,
                'అడ్డం (Across)',
                AppColors.acrossSelection,
              ),
              (PuzzleDirection.down, 'నిలువు (Down)', AppColors.downSelection),
            ])
              ChoiceChip(
                key: ValueKey('classic-direction-${direction.name}'),
                avatar: Icon(
                  direction == PuzzleDirection.across
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_downward_rounded,
                  color: _selectedDirection == direction
                      ? Colors.white
                      : scheme.onSurface,
                  size: 20,
                ),
                showCheckmark: false,
                label: PremiumTeluguText(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _selectedDirection == direction
                        ? Colors.white
                        : scheme.onSurface,
                    fontWeight: _selectedDirection == direction
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                selected: _selectedDirection == direction,
                selectedColor: color,
                backgroundColor: Color.alphaBlend(
                  color.withValues(alpha: 0.12),
                  scheme.surface,
                ),
                side: BorderSide(
                  color: _selectedDirection == direction
                      ? color
                      : scheme.outline,
                  width: _selectedDirection == direction ? 2 : 1,
                ),
                onSelected: _isComplete || _cluesFor(puzzle, direction).isEmpty
                    ? null
                    : (_) => _changeDirection(direction),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _ClueList(
          clues: _cluesFor(puzzle, _selectedDirection),
          direction: _selectedDirection,
          selectedClue: _selectedClue,
          selectedDirection: _selectedDirection,
          correctClues: correctClues,
          onSelect: _selectClue,
          enabled: !_isComplete && _selectedCellIndex != null,
        ),
        const SizedBox(height: 16),
        AksharaPalette(
          puzzle: puzzle,
          onSelected: _enterAkshara,
          enabled: !_isComplete,
          label: _selectedDirection == PuzzleDirection.across
              ? '→ అడ్డం / Across · ${_selectedClue?.number ?? ''}'
              : '↓ నిలువు / Down · ${_selectedClue?.number ?? ''}',
        ),
        const SizedBox(height: 12),
        _editToolbar(context),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
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
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
    return LayoutBuilder(
      key: ValueKey('classic-puzzle-${puzzle.id}'),
      builder: (context, constraints) {
        if (split) {
          return Row(
            key: const ValueKey('classic-split-layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: board),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: controls),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [board, const SizedBox(height: 16), controls],
        );
      },
    );
  }

  Widget _controlLabel(String telugu, String english) =>
      KidsLearningText.control(telugu, english: english, center: true);

  Widget _editToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = !_isComplete && _selectedCellIndex != null;
    return Material(
      key: const ValueKey('classic-edit-toolbar'),
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 240 ||
              MediaQuery.textScalerOf(
                    context,
                  ).scale(theme.textTheme.labelLarge!.fontSize!) >
                  18;
          final buttons = [
            for (final (
                  key,
                  label,
                  english,
                  icon,
                  background,
                  foreground,
                  action,
                )
                in [
                  (
                    'classic-clear-cell',
                    'అక్షరం తీసేయి',
                    'Clear letter',
                    Icons.highlight_remove_rounded,
                    AppColors.gold,
                    AppColors.ink,
                    () => _clearCell(),
                  ),
                  (
                    'classic-backspace',
                    'వెనక్కి',
                    'Backspace',
                    Icons.backspace_outlined,
                    AppColors.purple,
                    Colors.white,
                    () => _clearCell(backspace: true),
                  ),
                ])
              TapFeedback(
                enabled: enabled,
                child: FilledButton(
                  key: ValueKey(key),
                  onPressed: enabled ? action : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: background,
                    foregroundColor: foreground,
                    disabledBackgroundColor: scheme.onSurface.withValues(
                      alpha: 0.12,
                    ),
                    disabledForegroundColor: scheme.onSurface.withValues(
                      alpha: 0.5,
                    ),
                    elevation: enabled ? 2 : 0,
                    shadowColor: AppColors.ink.withValues(alpha: 0.25),
                    minimumSize: const Size(48, 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    side: BorderSide(color: foreground.withValues(alpha: 0.18)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(child: Icon(icon, size: 20)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: KidsLearningText.control(
                          label,
                          english: english,
                          center: true,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: enabled
                                ? foreground
                                : scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ];
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < buttons.length; index++) ...[
                  if (index > 0) const SizedBox(height: 8),
                  buttons[index],
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < buttons.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: buttons[index]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _reviewAnswers() async {
    final puzzle = _puzzle;
    if (!_isComplete || puzzle == null || _reviewOpen) return;
    _reviewOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            key: const ValueKey('classic-answer-review'),
            appBar: AppBar(
              backgroundColor: AppColors.deepBlue,
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              toolbarHeight:
                  (MediaQuery.textScalerOf(context).scale(20) * 1.8 + 16).clamp(
                    64,
                    double.infinity,
                  ),
              title: const Text(
                'సమాధానాలు / Answers',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    key: const ValueKey('classic-answer-review-scroll'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.acrossSelection,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'పూర్తయిన పదకేళి · చదవడానికి మాత్రమే\n'
                              'Completed puzzle · Read only',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      for (final (direction, label, color, clues) in [
                        (
                          PuzzleDirection.across,
                          'అడ్డం / Across',
                          AppColors.acrossSelection,
                          puzzle.acrossClues,
                        ),
                        (
                          PuzzleDirection.down,
                          'నిలువు / Down',
                          AppColors.downSelection,
                          puzzle.downClues,
                        ),
                      ]) ...[
                        const SizedBox(height: 16),
                        Material(
                          key: ValueKey('review-section-${direction.name}'),
                          color: Color.alphaBlend(
                            color.withValues(alpha: 0.08),
                            Theme.of(context).colorScheme.surface,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                key: ValueKey(
                                  'review-header-${direction.name}',
                                ),
                                color: color,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                child: Semantics(
                                  container: true,
                                  header: true,
                                  child: Row(
                                    children: [
                                      Icon(
                                        direction == PuzzleDirection.across
                                            ? Icons.arrow_forward_rounded
                                            : Icons.arrow_downward_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: PremiumTeluguText(
                                          label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              for (final clue in clues) ...[
                                if (clue != clues.first)
                                  const Divider(
                                    height: 1,
                                    indent: 14,
                                    endIndent: 14,
                                  ),
                                Padding(
                                  key: ValueKey(
                                    'review-clue-${direction.name}-${clue.number}',
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Semantics(
                                    container: true,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        PremiumTeluguText(
                                          '${clue.number}. ${clue.clue} (${clue.aksharaCount})',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 20,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? AppColors
                                                        .darkSuccessForeground
                                                  : AppColors.successForeground,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: PremiumTeluguText(
                                                clue.answer,
                                                key: ValueKey(
                                                  'review-answer-${direction.name}-${clue.number}',
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const ValueKey('classic-review-done'),
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 56),
                          padding: const EdgeInsets.all(12),
                          elevation: 2,
                          shadowColor: AppColors.ink.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: _controlLabel('పూర్తయింది', 'Done'),
                      ),
                    ],
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

  Widget _completion({BuildContext? dialogContext}) {
    final theme = Theme.of(context);
    final completedPuzzle = _puzzle;
    void choose(VoidCallback action) {
      if (!_isComplete || !identical(completedPuzzle, _puzzle)) return;
      if (dialogContext != null) {
        if (!_completionDialogOpen) return;
        _completionDialogOpen = false;
        Navigator.pop(dialogContext);
      }
      action();
    }

    void home() {
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.maybePop(context);
      }
    }

    if (widget.dailyDate != null) {
      return Column(
        key: const ValueKey('daily-puzzle-complete'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.teal, size: 64),
          const SizedBox(height: 12),
          Text(
            'నేటి పదకేళి పూర్తయింది! / Daily completed',
            style: theme.textTheme.headlineSmall,
          ),
          Text(
            '${widget.dailyDate} · One daily completion reward per saved date. '
            'Replaying never awards another daily star.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => choose(home),
            child: _controlLabel('హోమ్‌కు వెళ్లు', 'Back to Home'),
          ),
          OutlinedButton(
            key: const ValueKey('daily-replay'),
            onPressed: () => choose(() => _openPuzzle(_puzzle!)),
            child: _controlLabel('మళ్లీ ఆడు', 'Practice again'),
          ),
        ],
      );
    }
    final availableLevels = _puzzles!.map((puzzle) => puzzle.level).toSet();
    final nextLevel = Puzzle.levels
        .skip(Puzzle.levels.indexOf(_selectedLevel!) + 1)
        .where(availableLevels.contains)
        .firstOrNull;
    final hasNextPuzzle = _puzzleNumber < _levelPuzzles.length;
    ButtonStyle filledStyle(Color background, Color foreground) =>
        FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.all(12),
          elevation: 2,
          shadowColor: AppColors.ink.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        );

    return Padding(
      key: const ValueKey('classic-level-complete'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 56,
                color: AppColors.successForeground,
              ),
            ),
          ),
          const SizedBox(height: 16),
          PremiumTeluguText(
            hasNextPuzzle ? 'పదకేళి పూర్తయింది!' : 'స్థాయి పూర్తయింది!',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          PremiumTeluguText(
            '$_puzzleNumber / ${_levelPuzzles.length} పదకేళీలు పూర్తి చేశారు.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          if (hasNextPuzzle) ...[
            FilledButton.icon(
              key: const ValueKey('classic-next-puzzle'),
              onPressed: () =>
                  choose(() => _openPuzzle(_levelPuzzles[_puzzleNumber])),
              style: filledStyle(AppColors.deepBlue, Colors.white),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: _controlLabel('తదుపరి పదకేళి', 'Next puzzle'),
            ),
            const SizedBox(height: 12),
          ] else if (nextLevel != null) ...[
            FilledButton.icon(
              key: const ValueKey('classic-next-level'),
              onPressed: () => choose(() => _loadPuzzle(nextLevel)),
              style: filledStyle(AppColors.deepBlue, Colors.white),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: _controlLabel('తరువాతి స్థాయి', 'Next level'),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            key: const ValueKey('classic-review-answers'),
            onPressed: () => choose(() => unawaited(_reviewAnswers())),
            style: filledStyle(AppColors.acrossSelection, Colors.white),
            icon: const Icon(Icons.fact_check_outlined),
            label: _controlLabel('సమాధానాలు చూడండి', 'Review answers'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('classic-replay'),
            onPressed: () => choose(() => _openPuzzle(_puzzle!)),
            style: filledStyle(AppColors.purple, Colors.white),
            icon: const Icon(Icons.replay_rounded),
            label: _controlLabel('మళ్లీ ఆడు', 'Play again'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('classic-choose-level'),
            onPressed: () => choose(_showDifficulties),
            style: filledStyle(AppColors.gold, AppColors.ink),
            icon: const Icon(Icons.grid_view_rounded),
            label: _controlLabel('స్థాయిని ఎంచుకోండి', 'Choose level'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('classic-completion-home'),
            onPressed: () => choose(home),
            style: filledStyle(AppColors.teal, AppColors.ink),
            icon: const Icon(Icons.home_rounded),
            label: _controlLabel('హోమ్‌కు వెళ్లు', 'Home'),
          ),
        ],
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
    required this.correctClues,
    required this.onSelect,
    required this.enabled,
  });

  final List<PuzzleClue> clues;
  final PuzzleDirection direction;
  final PuzzleClue? selectedClue;
  final PuzzleDirection selectedDirection;
  final Set<PuzzleClue> correctClues;
  final void Function(PuzzleClue clue, PuzzleDirection direction) onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final correctBackground = dark
        ? AppColors.darkSuccessBackground
        : AppColors.successBackground;
    final correctForeground = dark
        ? AppColors.darkSuccessForeground
        : AppColors.successForeground;
    bool isSelected(PuzzleClue clue) =>
        identical(selectedClue, clue) && selectedDirection == direction;
    final selectionColor = direction == PuzzleDirection.across
        ? AppColors.acrossSelection
        : AppColors.downSelection;
    return Card(
      key: const ValueKey('classic-clue-list'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final clue in clues)
              ListTile(
                key: ValueKey('clue-${direction.name}-${clue.number}'),
                minTileHeight: 48,
                dense: false,
                visualDensity: VisualDensity.standard,
                minVerticalPadding: 8,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: correctClues.contains(clue)
                    ? correctBackground
                    : null,
                selectedTileColor: selectionColor,
                selectedColor: Colors.white,
                leading: isSelected(clue)
                    ? Icon(
                        direction == PuzzleDirection.across
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_downward_rounded,
                        key: const ValueKey('active-clue-direction'),
                        color: Colors.white,
                        size: 20,
                        semanticLabel: direction == PuzzleDirection.across
                            ? 'ప్రస్తుత అడ్డం / Current Across'
                            : 'ప్రస్తుత నిలువు / Current Down',
                      )
                    : null,
                minLeadingWidth: 20,
                horizontalTitleGap: 8,
                trailing: correctClues.contains(clue)
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey(
                          'clue-correct-${direction.name}-${clue.number}',
                        ),
                        color: isSelected(clue)
                            ? Colors.white
                            : correctForeground,
                        size: 20,
                        semanticLabel: 'సరైన సమాధానం / Correct answer',
                      )
                    : null,
                enabled: enabled,
                selected: isSelected(clue),
                title: Text(
                  '${clue.number}. ${clue.clue} (${clue.aksharaCount})',
                  key: isSelected(clue)
                      ? const ValueKey('selected-clue')
                      : null,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected(clue)
                        ? Colors.white
                        : correctClues.contains(clue)
                        ? correctForeground
                        : null,
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
