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
