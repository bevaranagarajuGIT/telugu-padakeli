import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../models/puzzle.dart';
import 'premium_telugu_text.dart';

class CrosswordGrid extends StatelessWidget {
  const CrosswordGrid({
    required this.puzzle,
    required this.controllers,
    required this.selectedCellIndex,
    required this.selectedCells,
    required this.onCellSelected,
    this.enabled = true,
    super.key,
  });

  final Puzzle puzzle;
  final List<List<TextEditingController>> controllers;
  final int? selectedCellIndex;
  final List<int> selectedCells;
  final ValueChanged<int> onCellSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final puzzle = this.puzzle;
    final controllers = this.controllers;
    final clueNumbers = <int, int>{};
    for (final clue in [...puzzle.acrossClues, ...puzzle.downClues]) {
      clueNumbers.putIfAbsent(
        clue.row * puzzle.gridSize + clue.column,
        () => clue.number,
      );
    }

    final scaler = MediaQuery.textScalerOf(context);
    final letterStyle = theme.textTheme.titleLarge!.copyWith(
      fontFamily: PremiumTeluguText.fontFamily,
      fontWeight: FontWeight.w700,
      height: PremiumTeluguText.lineHeight,
    );
    final numberStyle = theme.textTheme.labelSmall!.copyWith(
      fontSize: theme.textTheme.labelSmall!.fontSize! * 0.82,
      height: 1,
    );
    final minimumCell = math.max(
      48.0,
      scaler.scale(letterStyle.fontSize!) * 1.6 +
          scaler.scale(numberStyle.fontSize!) +
          12,
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(constraints.maxWidth, puzzle.gridSize * minimumCell),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.count(
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: puzzle.gridSize,
              children: List.generate(puzzle.gridSize * puzzle.gridSize, (
                index,
              ) {
                final row = index ~/ puzzle.gridSize;
                final column = index % puzzle.gridSize;
                if (puzzle.isBlocked(row, column)) {
                  return Container(
                    key: ValueKey('crossword-blocked-cell-$index'),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF24243D)
                          : const Color(0xFFEDE8F7),
                      border: Border.all(
                        color: dark
                            ? scheme.outlineVariant
                            : AppColors.deepBlue,
                        width: 0.5,
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.46,
                          heightFactor: 0.46,
                          child: CustomPaint(
                            key: ValueKey('blocked-cell-motif-$index'),
                            painter: _RangoliPainter(
                              color: dark
                                  ? const Color(0xFF9DAED6)
                                  : const Color(0xFF788BB7),
                            ),
                          ),
                        ),
                      ),
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
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold
                        : isInSelectedWord
                        ? dark
                              ? AppColors.deepBlue
                              : AppColors.lightBlue
                        : scheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.orange
                          : dark
                          ? scheme.outlineVariant
                          : AppColors.deepBlue,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Semantics(
                    button: true,
                    enabled: enabled,
                    selected: isSelected,
                    label:
                        'Row ${row + 1}, column ${column + 1}${clueNumber == null ? '' : ', clue $clueNumber'}',
                    value: controllers[row][column].text.isEmpty
                        ? 'Empty'
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
                                      color: isSelected
                                          ? AppColors.ink
                                          : scheme.onSurface,
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
                                    color: isSelected
                                        ? AppColors.ink
                                        : scheme.onSurface,
                                  ),
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
  }
}

class _RangoliPainter extends CustomPainter {
  const _RangoliPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.shortestSide / 100);
    final petal = Path()
      ..moveTo(0, -46)
      ..cubicTo(-6, -38, -22, -29, -16, -19)
      ..cubicTo(-12, -12, -6, -10, 0, -7)
      ..cubicTo(6, -10, 12, -12, 16, -19)
      ..cubicTo(22, -29, 6, -38, 0, -46)
      ..close();
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < 4; i++) {
      canvas.drawPath(petal, outline);
      canvas.rotate(math.pi / 2);
    }
    final center = Path()
      ..moveTo(0, -4)
      ..lineTo(4, 0)
      ..lineTo(0, 4)
      ..lineTo(-4, 0)
      ..close();
    canvas.drawPath(center, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RangoliPainter oldDelegate) =>
      color != oldDelegate.color;
}

class AksharaPalette extends StatelessWidget {
  const AksharaPalette({
    required this.puzzle,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final Puzzle puzzle;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aksharas = puzzle.rows
        .expand((row) => row)
        .where((cell) => cell != '#')
        .toSet();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'అక్షరాలు',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            for (final akshara in aksharas)
              OutlinedButton(
                key: ValueKey('akshara-$akshara'),
                onPressed: enabled ? () => onSelected(akshara) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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
      ),
    );
  }
}
