import '../models/puzzle.dart';

abstract class PuzzleRepository {
  Future<List<Puzzle>> getPuzzles();

  Future<Puzzle> getBeginnerPuzzle();
}
