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
    final decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map((item) => Puzzle.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
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
