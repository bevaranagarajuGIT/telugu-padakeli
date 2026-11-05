import 'dart:convert';

import '../data/puzzle_data_source.dart';
import '../models/puzzle.dart';
import 'puzzle_repository.dart';

class LocalPuzzleRepository implements PuzzleRepository {
  const LocalPuzzleRepository({
    this.dataSource = const AssetPuzzleDataSource(),
  });

  final PuzzleDataSource dataSource;

  @override
  Future<List<Puzzle>> getPuzzles() async {
    final rawJson = await dataSource.loadPuzzlesJson();
    final decoded = jsonDecode(rawJson);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Puzzle data must be a list.');
    }
    if (decoded.isEmpty) {
      throw const FormatException('No puzzles are available.');
    }
    final puzzles = decoded
        .map((item) {
          try {
            return Puzzle.fromJson(item as Map<String, dynamic>);
          } on TypeError {
            throw const FormatException(
              'Puzzle fields are missing or invalid.',
            );
          }
        })
        .toList(growable: false);
    final ids = <int>{};
    for (final puzzle in puzzles) {
      puzzle.validate();
      if (!ids.add(puzzle.id)) {
        throw const FormatException('Puzzle IDs must be unique.');
      }
    }
    return puzzles;
  }

  @override
  Future<Puzzle> getBeginnerPuzzle() async {
    final puzzles = await getPuzzles();
    return puzzles.firstWhere(
      (puzzle) => puzzle.level == 'beginner',
      orElse: () => puzzles.first,
    );
  }
}
