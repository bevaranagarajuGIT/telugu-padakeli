import 'package:flutter/material.dart';

import '../models/puzzle.dart';

class CrosswordGrid extends StatelessWidget {
  const CrosswordGrid({
    required this.puzzle,
    required this.controllers,
    required this.selectedCellIndex,
    required this.selectedCells,
    required this.onCellSelected,
    required this.onAksharaSelected,
    super.key,
  });

  final Puzzle puzzle;
  final List<List<TextEditingController>> controllers;
  final int? selectedCellIndex;
  final List<int> selectedCells;
  final ValueChanged<int> onCellSelected;
  final ValueChanged<String> onAksharaSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final puzzle = this.puzzle;
    final controllers = this.controllers;
    final clueNumbers = <int, int>{};
    for (final clue in [...puzzle.acrossClues, ...puzzle.downClues]) {
      clueNumbers.putIfAbsent(
        clue.row * puzzle.gridSize + clue.column,
        () => clue.number,
      );
    }

    final aksharas = puzzle.rows
        .expand((row) => row)
        .where((cell) => cell != '#')
        .toSet()
        .toList();

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: puzzle.gridSize,
            children: List.generate(puzzle.gridSize * puzzle.gridSize, (index) {
              final row = index ~/ puzzle.gridSize;
              final column = index % puzzle.gridSize;
              if (puzzle.isBlocked(row, column)) {
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: scheme.inverseSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }

              final clueNumber = clueNumbers[index];
              final isSelected = selectedCellIndex == index;
              final isInSelectedWord = selectedCells.contains(index);
              return Container(
                key: isSelected
                    ? const ValueKey('selected-cell')
                    : ValueKey('crossword-cell-container-$index'),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.secondaryContainer
                      : isInSelectedWord
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  border: Border.all(
                    color: isSelected ? scheme.primary : scheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: ValueKey('crossword-cell-$index'),
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => onCellSelected(index),
                          child: Center(
                            child: Text(
                              controllers[row][column].text,
                              key: ValueKey('crossword-cell-value-$index'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
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
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 9,
                                  height: 1,
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'అక్షరాలు',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final akshara in aksharas)
                      OutlinedButton(
                        key: ValueKey('akshara-$akshara'),
                        onPressed: () => onAksharaSelected(akshara),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: Text(akshara),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
