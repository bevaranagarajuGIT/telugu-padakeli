import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../models/puzzle.dart';
import '../models/telugu_akshara.dart';
import 'premium_telugu_text.dart';

class CrosswordGrid extends StatefulWidget {
  const CrosswordGrid({
    required this.puzzle,
    required this.controllers,
    required this.selectedCellIndex,
    required this.selectedCells,
    required this.onCellSelected,
    this.enabled = true,
    this.incorrectCells = const {},
    this.correctCells = const {},
    this.maximumCellExtent = 72,
    super.key,
  });

  final Puzzle puzzle;
  final List<List<TextEditingController>> controllers;
  final int? selectedCellIndex;
  final List<int> selectedCells;
  final ValueChanged<int> onCellSelected;
  final bool enabled;
  final Set<int> incorrectCells;
  final Set<int> correctCells;
  final double maximumCellExtent;

  static double minimumCellExtent(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    return math.max(
      48.0,
      scaler.scale(theme.textTheme.titleLarge!.fontSize!) * 1.6 +
          scaler.scale(theme.textTheme.labelSmall!.fontSize! * 0.82) +
          12,
    );
  }

  @override
  State<CrosswordGrid> createState() => _CrosswordGridState();
}

class _CrosswordGridState extends State<CrosswordGrid> {
  final _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _keepSelectionVisible(double cellExtent, int firstColumn) {
    final puzzle = widget.puzzle;
    final index = widget.selectedCellIndex;
    if (index == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !identical(widget.puzzle, puzzle) ||
          widget.selectedCellIndex != index ||
          !_horizontalScrollController.hasClients) {
        return;
      }
      final position = _horizontalScrollController.position;
      if (!position.hasContentDimensions) return;
      final left = (index % puzzle.gridSize - firstColumn) * cellExtent;
      final right = left + cellExtent;
      final offset = position.pixels;
      final target = left < offset
          ? left
          : right > offset + position.viewportDimension
          ? right - position.viewportDimension
          : offset;
      final bounded = target.clamp(0.0, position.maxScrollExtent);
      if ((bounded - offset).abs() > 0.1) {
        _horizontalScrollController.jumpTo(bounded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final correctBackground = dark
        ? AppColors.darkSuccessBackground
        : AppColors.successBackground;
    final correctForeground = dark
        ? AppColors.darkSuccessForeground
        : AppColors.successForeground;
    final puzzle = widget.puzzle;
    final controllers = widget.controllers;
    final selectedCellIndex = widget.selectedCellIndex;
    final selectedCells = widget.selectedCells;
    final onCellSelected = widget.onCellSelected;
    final enabled = widget.enabled;
    final incorrectCells = widget.incorrectCells;
    var firstRow = puzzle.gridSize;
    var lastRow = 0;
    var firstColumn = puzzle.gridSize;
    var lastColumn = 0;
    for (var row = 0; row < puzzle.gridSize; row++) {
      for (var column = 0; column < puzzle.gridSize; column++) {
        if (puzzle.isBlocked(row, column)) continue;
        firstRow = math.min(firstRow, row);
        lastRow = math.max(lastRow, row);
        firstColumn = math.min(firstColumn, column);
        lastColumn = math.max(lastColumn, column);
      }
    }
    final visibleRows = lastRow - firstRow + 1;
    final visibleColumns = lastColumn - firstColumn + 1;
    final clueNumbers = <int, int>{};
    for (final clue in [...puzzle.acrossClues, ...puzzle.downClues]) {
      clueNumbers.putIfAbsent(
        clue.row * puzzle.gridSize + clue.column,
        () => clue.number,
      );
    }

    final letterStyle = theme.textTheme.titleLarge!.copyWith(
      fontFamily: PremiumTeluguText.fontFamily,
      fontWeight: FontWeight.w700,
      height: PremiumTeluguText.lineHeight,
    );
    final numberStyle = theme.textTheme.labelSmall!.copyWith(
      fontSize: theme.textTheme.labelSmall!.fontSize! * 0.82,
      height: 1,
    );
    final minimumCell = CrosswordGrid.minimumCellExtent(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellExtent = math.max(
          math.min(
            constraints.maxWidth / visibleColumns,
            widget.maximumCellExtent,
          ),
          minimumCell,
        );
        final width = visibleColumns * cellExtent;
        _keepSelectionVisible(cellExtent, firstColumn);
        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: width > constraints.maxWidth,
          child: SingleChildScrollView(
            key: const ValueKey('crossword-grid-scroll'),
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: AspectRatio(
                key: const ValueKey('crossword-visible-board'),
                aspectRatio: visibleColumns / visibleRows,
                child: GridView.count(
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: visibleColumns,
                  children: List.generate(visibleRows * visibleColumns, (
                    position,
                  ) {
                    final row = firstRow + position ~/ visibleColumns;
                    final column = firstColumn + position % visibleColumns;
                    final index = row * puzzle.gridSize + column;
                    if (puzzle.isBlocked(row, column)) {
                      return Container(
                        key: ValueKey('crossword-blocked-cell-$index'),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF24243D)
                              : const Color(0xFFEDE8F7),
                          border: Border.all(
                            color: scheme.outlineVariant,
                            width: 0.5,
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: Center(
                            child: Icon(
                              Icons.star_rounded,
                              key: ValueKey('blocked-cell-motif-$index'),
                              size: math.min(24, cellExtent * 0.38),
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: dark ? 0.5 : 0.35,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final clueNumber = clueNumbers[index];
                    final isSelected = selectedCellIndex == index;
                    final incorrect = incorrectCells.contains(index);
                    final correct = widget.correctCells.contains(index);
                    final isInSelectedWord = selectedCells.contains(index);
                    final foreground = correct
                        ? correctForeground
                        : isSelected
                        ? AppColors.ink
                        : scheme.onSurface;
                    return Container(
                      key: isSelected
                          ? const ValueKey('selected-cell')
                          : ValueKey('crossword-cell-container-$index'),
                      decoration: BoxDecoration(
                        color: correct
                            ? correctBackground
                            : isSelected
                            ? AppColors.gold
                            : isInSelectedWord
                            ? dark
                                  ? AppColors.deepBlue
                                  : AppColors.lightBlue
                            : scheme.surface,
                        border: Border.all(
                          color: isSelected
                              ? correct && !dark
                                    ? AppColors.deepOrange
                                    : AppColors.orange
                              : incorrect
                              ? scheme.error
                              : correct
                              ? correctForeground
                              : dark
                              ? scheme.outlineVariant
                              : AppColors.deepBlue,
                          width: isSelected || incorrect ? 2 : 1,
                        ),
                      ),
                      child: Semantics(
                        button: true,
                        enabled: enabled,
                        selected: isSelected,
                        label:
                            'వరుస ${row + 1}, నిలువు ${column + 1}${clueNumber == null ? '' : ', సూచన $clueNumber'}${incorrect ? ', తప్పు అక్షరం' : ''}${correct ? ', సరైన పదం / Correct word' : ''}',
                        value: controllers[row][column].text.isEmpty
                            ? 'ఖాళీ'
                            : controllers[row][column].text,
                        onTap: enabled ? () => onCellSelected(index) : null,
                        child: ExcludeSemantics(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: ValueKey('crossword-cell-$index'),
                                    onTap: enabled
                                        ? () => onCellSelected(index)
                                        : null,
                                    child: Center(
                                      child: Text(
                                        controllers[row][column].text,
                                        key: ValueKey(
                                          'crossword-cell-value-$index',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: letterStyle.copyWith(
                                          color: foreground,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (clueNumber != null)
                                Positioned(
                                  top: 2,
                                  left: 4,
                                  child: IgnorePointer(
                                    child: Text(
                                      '$clueNumber',
                                      style: numberStyle.copyWith(
                                        color: foreground,
                                      ),
                                    ),
                                  ),
                                ),
                              if (incorrect)
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: IgnorePointer(
                                    child: Icon(
                                      Icons.error_rounded,
                                      key: ValueKey('crossword-error-$index'),
                                      size: 14,
                                      color: isSelected
                                          ? AppColors.ink
                                          : scheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AksharaPalette extends StatelessWidget {
  const AksharaPalette({
    required this.puzzle,
    required this.onSelected,
    this.enabled = true,
    this.label = 'అక్షరాలు',
    super.key,
  });

  final Puzzle puzzle;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aksharas = puzzle.rows
        .expand((row) => row)
        .where((cell) => cell != '#')
        .map(TeluguAkshara.normalize)
        .toSet();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              key: const ValueKey('classic-input-direction'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final akshara in aksharas)
                  OutlinedButton(
                    key: ValueKey('akshara-$akshara'),
                    onPressed: enabled ? () => onSelected(akshara) : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: PremiumTeluguText(
                      akshara,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
