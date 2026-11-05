enum PuzzleDirection { across, down }

class Puzzle {
  const Puzzle({
    required this.id,
    required this.level,
    required this.gridSize,
    required this.rows,
    required this.acrossClues,
    required this.downClues,
  });

  final int id;
  final String level;
  final int gridSize;
  final List<List<String>> rows;
  final List<PuzzleClue> acrossClues;
  final List<PuzzleClue> downClues;

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    final clues = json['clues'] as Map<String, dynamic>;
    return Puzzle(
      id: json['id'] as int,
      level: json['level'] as String,
      gridSize: json['gridSize'] as int,
      rows: (json['rows'] as List<dynamic>)
          .map(
            (row) => (row as List<dynamic>)
                .map((cell) => cell as String)
                .toList(growable: false),
          )
          .toList(growable: false),
      acrossClues: (clues['across'] as List<dynamic>)
          .map((item) => PuzzleClue.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      downClues: (clues['down'] as List<dynamic>)
          .map((item) => PuzzleClue.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Reject unusable content before it can reach the crossword UI.
  void validate() {
    if (gridSize <= 0 ||
        rows.length != gridSize ||
        rows.any((row) => row.length != gridSize)) {
      throw const FormatException('Puzzle dimensions do not match gridSize.');
    }
    final covered = <int>{};
    final starts = <int, int>{};
    final numbers = <int, int>{};
    final teluguStart = RegExp(r'^[అ-హౘ-ౡ]');
    for (var row = 0; row < gridSize; row++) {
      for (var column = 0; column < gridSize; column++) {
        final cell = rows[row][column];
        if (cell != '#' && !teluguStart.hasMatch(cell)) {
          throw const FormatException('Cells must start with a Telugu letter.');
        }
      }
    }
    for (final direction in PuzzleDirection.values) {
      final clues = direction == PuzzleDirection.across
          ? acrossClues
          : downClues;
      final seenStarts = <int>{};
      for (final clue in clues) {
        final cells = cellsForClue(clue, direction);
        if (cells.isEmpty || clue.number <= 0 || clue.clue.trim().isEmpty) {
          throw const FormatException(
            'Clue has an invalid start or description.',
          );
        }
        final start = cells.first;
        final previousRow =
            clue.row - (direction == PuzzleDirection.down ? 1 : 0);
        final previousColumn =
            clue.column - (direction == PuzzleDirection.across ? 1 : 0);
        if (!seenStarts.add(start) ||
            (previousRow >= 0 &&
                previousColumn >= 0 &&
                !isBlocked(previousRow, previousColumn))) {
          throw const FormatException('Clue must start a unique word.');
        }
        if ((starts.containsKey(start) && starts[start] != clue.number) ||
            (numbers.containsKey(clue.number) &&
                numbers[clue.number] != start)) {
          throw const FormatException('Clue numbering is inconsistent.');
        }
        starts[start] = clue.number;
        numbers[clue.number] = start;
        final answer = cells
            .map((index) => answerAt(index ~/ gridSize, index % gridSize))
            .join();
        if (answer != clue.answer) {
          throw const FormatException(
            'Clue answer does not match its grid cells.',
          );
        }
        covered.addAll(cells);
      }
    }
    for (var row = 0; row < gridSize; row++) {
      for (var column = 0; column < gridSize; column++) {
        if (!isBlocked(row, column) &&
            !covered.contains(row * gridSize + column)) {
          throw const FormatException('Every playable cell needs a clue.');
        }
      }
    }
    if (covered.isEmpty) {
      throw const FormatException('Puzzle has no playable cells.');
    }
  }

  bool isBlocked(int row, int column) => rows[row][column] == '#';

  String answerAt(int row, int column) => rows[row][column];

  List<int> cellsForClue(PuzzleClue clue, PuzzleDirection direction) {
    final cells = <int>[];
    var row = clue.row;
    var column = clue.column;

    while (row >= 0 &&
        row < gridSize &&
        column >= 0 &&
        column < gridSize &&
        !isBlocked(row, column)) {
      cells.add(row * gridSize + column);
      if (direction == PuzzleDirection.across) {
        column++;
      } else {
        row++;
      }
    }
    return cells;
  }
}

class PuzzleClue {
  const PuzzleClue({
    required this.number,
    required this.clue,
    required this.answer,
    required this.row,
    required this.column,
    this.hint,
  });

  final int number;
  final String clue;
  final String answer;
  final int row;
  final int column;
  final String? hint;

  factory PuzzleClue.fromJson(Map<String, dynamic> json) {
    return PuzzleClue(
      number: json['number'] as int,
      clue: json['clue'] as String,
      answer: json['answer'] as String,
      row: json['row'] as int,
      column: json['column'] as int,
      hint: json['hint'] as String?,
    );
  }
}
